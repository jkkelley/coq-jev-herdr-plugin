// Unit test for scripts/front-door.mjs (node --test tests/front-door.test.mjs; also run by tests/inside.sh).
// A throwaway backend on 127.0.0.1 stands in for the page server; the forwarder binds 127.0.0.1 on another port
// (--bind overrides the Tailscale IP, which a test box may not have). HOME points at a temp dir so the lock file
// lands in a scratch state_root and never in the owner's ~/.bearings.
import assert from "node:assert/strict";
import { spawn, spawnSync } from "node:child_process";
import fs from "node:fs";
import net from "node:net";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const TOOL = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const SCRIPT = path.join(TOOL, "scripts", "front-door.mjs");
const CONFIG = path.join(TOOL, "config", "bearings.json");

const freePort = () =>
  new Promise((resolve) => {
    const s = net.createServer().listen(0, "127.0.0.1", () => {
      const { port } = s.address();
      s.close(() => resolve(port));
    });
  });
const waitFor = async (fn, ms = 5000) => {
  const end = Date.now() + ms;
  for (;;) {
    const v = fn();
    if (v) return v;
    if (Date.now() > end) throw new Error("timed out");
    await new Promise((r) => setTimeout(r, 50));
  }
};
const exchange = (port, payload) =>
  new Promise((resolve, reject) => {
    const chunks = [];
    const c = net.connect({ host: "127.0.0.1", port }, () => c.write(payload));
    c.on("data", (d) => chunks.push(d));
    c.on("end", () => resolve(Buffer.concat(chunks).toString()));
    c.on("error", reject);
  });

const home = fs.mkdtempSync(path.join(os.tmpdir(), "front-door-test-"));
const lock = path.join(home, ".bearings", "coq-stable", "front-door.json");
const run = (args, extra = {}) =>
  spawn(process.execPath, [SCRIPT, "--tier", "stable", "--config", CONFIG, "--bind", "127.0.0.1", ...args], {
    env: { ...process.env, HOME: home },
    stdio: ["ignore", "ignore", "pipe"],
    ...extra,
  });
const exited = (child) => new Promise((resolve) => (child.exitCode !== null ? resolve(child.exitCode) : child.once("exit", (code) => resolve(code))));

test("bytes pass both ways, the lock file appears and goes away, a second start refuses", async () => {
  const received = [];
  const backend = net.createServer((s) => {
    s.on("data", (d) => {
      received.push(d.toString());
      s.end(`echo:${d}`);
    });
  });
  await new Promise((r) => backend.listen(0, "127.0.0.1", r));
  const target = backend.address().port;
  const listen = await freePort();

  const first = run(["--listen-port", String(listen), "--target-port", String(target)]);
  let log = "";
  first.stderr.on("data", (d) => (log += d));
  try {
    const held = await waitFor(() => fs.existsSync(lock) && JSON.parse(fs.readFileSync(lock, "utf8")));
    assert.equal(held.pid, first.pid);
    assert.equal(held.bind, "127.0.0.1");
    assert.equal(held.port, listen);
    assert.ok(!Number.isNaN(Date.parse(held.at)));

    assert.equal(await exchange(listen, "GET / HTTP/1.1\r\nHost: 100.122.200.108:44900\r\n\r\n"), "echo:GET / HTTP/1.1\r\nHost: 100.122.200.108:44900\r\n\r\n");
    assert.equal(received.length, 1, "the backend saw the bytes untouched, Host header included");

    const second = spawnSync(process.execPath, [SCRIPT, "--tier", "stable", "--config", CONFIG, "--bind", "127.0.0.1", "--listen-port", String(await freePort()), "--target-port", String(target)], {
      env: { ...process.env, HOME: home },
      encoding: "utf8",
    });
    assert.equal(second.status, 3, "a second start while one runs is refused");
    assert.match(second.stderr, /already running: pid \d+/);
    assert.equal(JSON.parse(fs.readFileSync(lock, "utf8")).pid, first.pid, "the refusal left the first lock alone");

    first.kill("SIGTERM");
    assert.equal(await exited(first), 0);
    assert.ok(!fs.existsSync(lock), "the lock file is removed on exit");
    assert.equal(log.split("\n").filter((l) => /front-door: .* (start|stop) pid/.test(l)).length, 2, "one line per start and per stop, on stderr");
  } finally {
    first.kill("SIGKILL");
    backend.close();
  }
});

test("a stale lock naming a dead pid does not block a start", async () => {
  fs.mkdirSync(path.dirname(lock), { recursive: true });
  fs.writeFileSync(lock, JSON.stringify({ pid: 2 ** 22 + 12345, bind: "127.0.0.1", port: 1, at: "2026-01-01T00:00:00.000Z" }));
  const listen = await freePort();
  const child = run(["--listen-port", String(listen), "--target-port", String(await freePort())]);
  try {
    await waitFor(() => fs.existsSync(lock) && JSON.parse(fs.readFileSync(lock, "utf8")).pid === child.pid);
  } finally {
    child.kill("SIGTERM");
    await exited(child);
  }
  assert.ok(!fs.existsSync(lock));
});

test("a busy port exits 4 after three tries with a clear message", async () => {
  const hog = net.createServer();
  await new Promise((r) => hog.listen(0, "127.0.0.1", r));
  const child = run(["--listen-port", String(hog.address().port), "--target-port", "1", "--retry-ms", "50"]);
  let log = "";
  child.stderr.on("data", (d) => (log += d));
  try {
    assert.equal(await exited(child), 4);
    assert.equal((log.match(/failed \(try \d of 3\)/g) ?? []).length, 3);
    assert.match(log, /could not bind 127\.0\.0\.1:\d+ after 3 tries/);
    assert.ok(!fs.existsSync(lock), "no lock file for a front door that never bound");
  } finally {
    hog.close();
  }
});

test.after(() => fs.rmSync(home, { recursive: true, force: true }));
