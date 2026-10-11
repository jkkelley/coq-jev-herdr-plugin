"""Unit tests for report/blueprint/server.py: the routes, the two served-directory modes and one refresh pass (WO-20261011-ceea).
Run by report/loop/tests/cases/15-bp-serve.test.sh, in the lint container, no network: the server runs in a thread of this process
on an ephemeral port, so no process is left behind."""
import importlib.util
import json
import os
import shutil
import subprocess
import tempfile
import threading
import unittest
import urllib.error
import urllib.request
from pathlib import Path

REPO = Path(os.environ.get("REPO_ROOT", Path(__file__).resolve().parents[3]))
spec = importlib.util.spec_from_file_location("blueprint_server", REPO / "report" / "blueprint" / "server.py")
server = importlib.util.module_from_spec(spec)
spec.loader.exec_module(server)
FIX = REPO / "report" / "loop" / "tests" / "fixtures" / "blueprint"
LOOP = REPO / "report" / "loop" / "loop.sh"


def build(root_fixture, out):
    env = dict(os.environ, LOOP_ROOT=str(root_fixture))
    subprocess.run([str(LOOP), "--view", "blueprint", "watch", "--iterations", "1", "--out", str(out)], env=env, check=True, capture_output=True)


def get(srv, path, method="GET"):
    url = f"http://127.0.0.1:{srv.server_address[1]}{path}"
    req = urllib.request.Request(url, method=method)

    class NoRedirect(urllib.request.HTTPRedirectHandler):
        def redirect_request(self, *a, **k):
            return None

    try:
        r = urllib.request.build_opener(NoRedirect).open(req, timeout=5)
        return r.status, dict(r.headers), r.read()
    except urllib.error.HTTPError as e:
        return e.code, dict(e.headers), e.read()


class Serving:
    def __init__(self, cfg, root):
        self.srv = server.make_server(cfg, root, port=0)
        self.t = threading.Thread(target=self.srv.serve_forever, daemon=True)

    def __enter__(self):
        self.t.start()
        return self.srv

    def __exit__(self, *a):
        self.srv.shutdown()
        self.srv.server_close()


def tier(name):
    return json.loads((REPO / "report" / "blueprint" / "config" / f"{name}.json").read_text())


class Routes(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp, True)
        self.cfg = dict(tier("dev"), out_dir="out/dev")
        build(FIX, self.tmp / "out" / "dev")

    def test_page_and_data(self):
        with Serving(self.cfg, self.tmp) as srv:
            for path in ("/blueprint", "/blueprint/"):
                code, h, body = get(srv, path)
                self.assertEqual(code, 200, path)
                self.assertTrue(h["Content-Type"].startswith("text/html"))
                self.assertIn(b"CMP-alpha", body)
            code, h, body = get(srv, "/blueprint/data.json")
            self.assertEqual(code, 200)
            self.assertTrue(h["Content-Type"].startswith("application/json"))
            self.assertEqual(json.loads(body)["lines"][0]["name"], "CMP-alpha")
            self.assertEqual(h["Cache-Control"], "no-store")

    def test_health_names_tier_and_build(self):
        with Serving(self.cfg, self.tmp) as srv:
            code, _, body = get(srv, "/healthz")
            self.assertEqual((code, json.loads(body)), (200, {"ok": True, "tier": "dev", "build": 1}))

    def test_root_redirects_and_unknown_is_404(self):
        with Serving(self.cfg, self.tmp) as srv:
            code, h, _ = get(srv, "/")
            self.assertEqual((code, h["Location"]), (302, "/blueprint"))
            for path in ("/nope", "/blueprint/other", "/blueprint/../../etc/passwd", "/blueprint/index.html", "/out/dev/data.json"):
                self.assertEqual(get(srv, path)[0], 404, path)

    def test_head_has_no_body(self):
        with Serving(self.cfg, self.tmp) as srv:
            code, h, body = get(srv, "/blueprint", "HEAD")
            self.assertEqual((code, body), (200, b""))
            self.assertGreater(int(h["Content-Length"]), 1000)

    def test_a_tier_with_no_page_says_so(self):
        empty = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, empty, True)
        with Serving(self.cfg, empty) as srv:
            self.assertEqual(get(srv, "/blueprint")[0], 503)
            code, _, body = get(srv, "/healthz")
            self.assertEqual((code, json.loads(body)["ok"]), (503, False))

    def test_a_released_tier_serves_current(self):
        rel = self.tmp / "out" / "uat"
        (rel / "releases").mkdir(parents=True)
        shutil.copytree(self.tmp / "out" / "dev", rel / "releases" / "7")
        os.symlink("releases/7", rel / "current")
        cfg = dict(tier("uat"), out_dir="out/uat")
        with Serving(cfg, self.tmp) as srv:
            self.assertEqual(get(srv, "/blueprint")[0], 200)
            self.assertEqual(json.loads(get(srv, "/healthz")[2])["tier"], "uat")


class Refresh(unittest.TestCase):
    def test_one_pass_builds_then_follows_the_graph(self):
        tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, tmp, True)
        root, out = tmp / "root", tmp / "out"
        shutil.copytree(FIX, root)
        self.assertEqual(server.refresh_once(root, out), 0)
        first = json.loads((out / "data.json").read_text())
        node = root / "graph" / "nodes" / "CMP-alpha.json"
        d = json.loads(node.read_text())
        d["title"] = "Alpha, renamed in the graph"
        node.write_text(json.dumps(d))
        self.assertEqual(server.refresh_once(root, out), 0)
        second = json.loads((out / "data.json").read_text())
        self.assertEqual(second["lines"][0]["sub"], "Alpha, renamed in the graph")
        self.assertEqual(second["number"], first["number"] + 1)
        self.assertEqual(server.refresh_once(root, out), 0)
        self.assertEqual(json.loads((out / "data.json").read_text())["number"], second["number"], "a pass with no change adds no build")

    def test_a_failing_pass_keeps_the_last_page(self):
        tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, tmp, True)
        root, out = tmp / "root", tmp / "out"
        shutil.copytree(FIX, root)
        server.refresh_once(root, out)
        before = (out / "data.json").read_text()
        (root / "graph" / "GRAPH.mmd").unlink()
        self.assertNotEqual(server.refresh_once(root, out), 0)
        self.assertEqual((out / "data.json").read_text(), before)


if __name__ == "__main__":
    unittest.main(verbosity=1)
