#!/usr/bin/env python3
"""server.py - the blueprint's own local web client server (WO-20261011-ceea, DEC-blueprint-server-tiers).

    server.py --tier dev|uat|stable [--root DIR] [--config-dir DIR] [--port N]

One process serves one tier's page from that tier's out_dir, on the tier's port, from the tier's config. python3 standard library
only, so it runs from the lint image or any host with python3 and installs nothing. Routes, and nothing else:

    GET /blueprint, /blueprint/        the page (index.html)
    GET /blueprint/data.json           the entry the page polls
    GET /healthz                       {"ok", "tier", "build"}: 200 when a page is served, 503 when none was ever built
    GET /                              302 to /blueprint

The served directory is out_dir for a live tier (dev) and out_dir/current for a released tier (uat, stable): promote.sh fills
those. A live tier also refreshes its own page: refresh_once() runs `loop.sh --view blueprint watch --iterations 1` every
watch_seconds of config/blueprint.json, from a thread of this process, so the one labelled pane holds the server and its
refresher and nothing is detached. Only two files are ever read from disk and the paths are fixed, so a request path cannot
name any other file.
"""
import argparse
import json
import os
import subprocess
import sys
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parent.parent
ROUTES = {"/blueprint": "index.html", "/blueprint/": "index.html", "/blueprint/data.json": "data.json"}
TYPES = {"index.html": "text/html; charset=utf-8", "data.json": "application/json; charset=utf-8"}


def load_tier(tier, config_dir):
    cfg = json.loads((Path(config_dir) / f"{tier}.json").read_text())
    if cfg.get("tier") != tier:
        raise SystemExit(f"server: {tier}.json says tier {cfg.get('tier')!r}")
    return cfg


def served_dir(cfg, root):
    out = Path(root) / cfg["out_dir"]
    return out / "current" if cfg["mode"] == "released" else out


def build_of(directory):
    try:
        return json.loads((directory / "data.json").read_text()).get("number")
    except (OSError, ValueError):
        return None


def refresh_once(root, out_dir, loop_sh=None):
    """One watch pass of the blueprint view into out_dir. Returns the exit code; a failing pass keeps the last good page."""
    loop_sh = loop_sh or REPO / "report" / "loop" / "loop.sh"
    env = dict(os.environ, LOOP_ROOT=str(root))
    try:
        p = subprocess.run([str(loop_sh), "--view", "blueprint", "watch", "--iterations", "1", "--out", str(out_dir)],
                           env=env, capture_output=True, text=True, timeout=60)
    except subprocess.TimeoutExpired:
        print("server: refresh pass timed out, keeping the last page", file=sys.stderr, flush=True)
        return 124
    if p.stderr.strip():
        print(p.stderr.strip(), file=sys.stderr, flush=True)
    return p.returncode


def make_server(cfg, root, port=None, host=None):
    directory = served_dir(cfg, root)

    class Handler(BaseHTTPRequestHandler):
        server_version = "blueprint"

        def _send(self, code, body, ctype="text/plain; charset=utf-8", extra=()):
            data = body if isinstance(body, bytes) else body.encode()
            self.send_response(code)
            self.send_header("Content-Type", ctype)
            self.send_header("Content-Length", str(len(data)))
            self.send_header("Cache-Control", "no-store")
            for k, v in extra:
                self.send_header(k, v)
            self.end_headers()
            if self.command != "HEAD":
                self.wfile.write(data)

        def do_GET(self):
            path = self.path.split("?", 1)[0]
            if path == "/":
                return self._send(302, "", extra=[("Location", "/blueprint")])
            if path == "/healthz":
                build = build_of(directory)
                ok = (directory / "index.html").is_file()
                return self._send(200 if ok else 503, json.dumps({"ok": ok, "tier": cfg["tier"], "build": build}), "application/json")
            name = ROUTES.get(path)
            if name is None:
                return self._send(404, "not found\n")
            try:
                return self._send(200, (directory / name).read_bytes(), TYPES[name])
            except OSError:
                return self._send(503, "blueprint not built\n")

        do_HEAD = do_GET

        def log_message(self, fmt, *args):
            print(f"{cfg['tier']}: {self.address_string()} {fmt % args}", file=sys.stderr, flush=True)

    return ThreadingHTTPServer((host or cfg.get("host", "127.0.0.1"), cfg["port"] if port is None else port), Handler)


def main(argv=None):
    ap = argparse.ArgumentParser(description="serve one tier of the blueprint")
    ap.add_argument("--tier", required=True, choices=["dev", "uat", "stable"])
    ap.add_argument("--root", default=str(REPO))
    ap.add_argument("--config-dir", default=str(HERE / "config"))
    ap.add_argument("--port", type=int)
    a = ap.parse_args(argv)
    cfg = load_tier(a.tier, a.config_dir)
    root = Path(a.root)
    if cfg["mode"] == "live":
        out = root / cfg["out_dir"]
        interval = json.loads((REPO / "report" / "loop" / "config" / "blueprint.json").read_text())["watch_seconds"]
        refresh_once(root, out)

        def loop():
            while True:
                time.sleep(interval)
                refresh_once(root, out)

        threading.Thread(target=loop, daemon=True, name="refresh").start()
    srv = make_server(cfg, root, a.port)
    print(f"server: {cfg['tier']} on {srv.server_address[0]}:{srv.server_address[1]} serving {served_dir(cfg, root)}", file=sys.stderr, flush=True)
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        pass
    return 0


if __name__ == "__main__":
    sys.exit(main())
