#!/usr/bin/env node
// front-door.mjs - a user-space TCP forwarder that lets a phone on the owner's tailnet reach a bearings tier.
//
// It binds the box's Tailscale IPv4 on the tier's own port and pipes every connection to 127.0.0.1:<server port>.
// No header is touched, so the Host a phone sends (`100.122.200.108:44900`, `whoadudette-1:44900`) reaches server.mjs
// unchanged and passes lib/host.mjs, which already allows those names with the server's own port.
//
// BREADCRUMB 2026-10-14 UTC (PR 186 follow-up, "Rebuild - bearings stable page front door on the tailnet, no root").
// What broke: PR 186 taught server.mjs to accept the tailnet Host names, but nothing listened on the tailnet address.
//   server.mjs binds 127.0.0.1 only (config listen_host), so the iPhone on the same tailnet could not connect at all.
//   The documented way in, `tailscale serve`, needs root on this box and sudo asks for a password; the owner wants no
//   sudo step.
// Why this fix: a dependency-free forwarder on the Tailscale address, run as the owner, in a labelled herdr pane like the
//   server and the wait. The server stays on loopback and is not changed or restarted.
// Rejected: `sudo tailscale serve --bg --http=80 http://127.0.0.1:44900` (root and a password; kept as the later
//   alternative in AGENTS.md), socat (not installed), rebinding server.mjs to the tailnet address (exposes the port to the
//   whole tailnet from the page process itself, needs a restart of the live stable server and its wait loops), and an
//   SSH or iptables redirect (root again).
// Cost: plain HTTP between the phone and this box (inside the WireGuard-encrypted tailnet, but no TLS of its own); one
//   more process to keep alive; it must be restarted when the Tailscale IP changes (the bind is read once at start).
//
//   node front-door.mjs --tier stable [--ticket ID] [--config P] [--bind IP] [--listen-port N] [--target-port N] [--retry-ms N]
//
// Bind address: --bind, else `tailscale ip -4`, else config front_door.bind. Lock file <state dir>/front-door.json
// {pid, bind, port, at}; a start while it names a live pid refuses (exit 3); it is removed on exit.
// Exit codes: 0 stopped by signal, 2 usage, 3 refused or config problem, 4 could not bind after 3 tries.
// Log: one line per start and stop, on stderr only.
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import net from "node:net";
import path from "node:path";
import { argv, loadConfig, resolveTier } from "./lib/config.mjs";

const { val } = argv(process.argv.slice(2));
const log = (m) => process.stderr.write(`front-door: ${new Date().toISOString()} ${m}\n`);
const die = (code, m) => {
  process.stderr.write(`front-door: ${m}\n`);
  process.exit(code);
};
const alive = (pid) => {
  try {
    process.kill(pid, 0);
    return true;
  } catch (e) {
    return e.code === "EPERM";
  }
};
const intArg = (flag, v) => {
  if (v === undefined) return undefined;
  const n = Number(v);
  if (!Number.isInteger(n) || n < 1 || n > 65535) die(2, `${flag} must be an integer 1..65535: got ${v}`);
  return n;
};

const tierName = val("--tier");
if (!tierName) die(2, "usage: front-door.mjs --tier <tier> [--ticket ID] [--config P] [--bind IP] [--listen-port N] [--target-port N]");
const { cfg } = loadConfig(val("--config"));
const T = resolveTier(cfg, tierName, val("--ticket"));
const lockFile = path.join(T.stateDir, "front-door.json");

let serverPort;
try {
  serverPort = JSON.parse(fs.readFileSync(path.join(T.stateDir, "server.json"), "utf8")).port;
} catch {
  /* no server.json yet: a tier with a fixed port still works */
}
const port = intArg("--listen-port", val("--listen-port")) ?? T.port ?? serverPort;
const targetPort = intArg("--target-port", val("--target-port")) ?? serverPort ?? T.port;
if (!port || !targetPort) die(3, `tier ${tierName} has no fixed port and no server.json port in ${T.stateDir}; start its server first`);
const retryMs = Number(val("--retry-ms") ?? 2000);

// Idempotent: a live holder of the lock means the front door is already up.
try {
  const held = JSON.parse(fs.readFileSync(lockFile, "utf8"));
  if (held.pid && alive(held.pid)) die(3, `already running: pid ${held.pid} on ${held.bind}:${held.port} (${lockFile})`);
} catch (e) {
  if (e instanceof SyntaxError) log(`ignoring unreadable ${lockFile}`);
}

const findBind = () => {
  const given = val("--bind") ?? process.env.BEARINGS_FRONT_DOOR_BIND;
  if (given) return given;
  try {
    const ip = execFileSync("tailscale", ["ip", "-4"], { encoding: "utf8", timeout: 5000, stdio: ["ignore", "pipe", "ignore"] })
      .split("\n")[0]
      .trim();
    if (net.isIPv4(ip)) return ip;
  } catch {
    /* tailscale missing or down: fall back to the config */
  }
  if (cfg.front_door?.bind) return cfg.front_door.bind;
  return die(3, "no bind address: `tailscale ip -4` gave none and config front_door.bind is not set");
};
const bind = findBind();
if (!net.isIPv4(bind)) die(3, `bind address ${bind} is not an IPv4 address`);

const conns = new Set();
const server = net.createServer((client) => {
  const back = net.connect({ host: "127.0.0.1", port: targetPort });
  conns.add(client).add(back);
  const drop = () => {
    client.destroy();
    back.destroy();
    conns.delete(client);
    conns.delete(back);
  };
  client.on("error", drop).on("close", drop);
  back.on("error", drop).on("close", drop);
  client.pipe(back);
  back.pipe(client);
});

const listenOnce = () =>
  new Promise((resolve, reject) => {
    const onErr = (e) => reject(e);
    server.once("error", onErr);
    server.listen(port, bind, () => {
      server.off("error", onErr);
      resolve();
    });
  });

let bound = false;
for (let attempt = 1; attempt <= 3 && !bound; attempt++) {
  try {
    await listenOnce();
    bound = true;
  } catch (e) {
    log(`bind ${bind}:${port} failed (try ${attempt} of 3): ${e.code ?? e.message}`);
    if (attempt < 3) await new Promise((r) => setTimeout(r, retryMs));
    else die(4, `could not bind ${bind}:${port} after 3 tries (${e.code ?? e.message}); is another process on it, or did the Tailscale IP change?`);
  }
}

fs.mkdirSync(T.stateDir, { recursive: true });
fs.writeFileSync(lockFile, `${JSON.stringify({ pid: process.pid, bind, port, at: new Date().toISOString() }, null, 2)}\n`);
log(`start pid ${process.pid} ${bind}:${port} -> 127.0.0.1:${targetPort}`);

let stopping = false;
const stop = (why, code = 0) => {
  if (stopping) return;
  stopping = true;
  try {
    // Only remove a lock that is still ours; a successor must keep its own.
    if (JSON.parse(fs.readFileSync(lockFile, "utf8")).pid === process.pid) fs.rmSync(lockFile, { force: true });
  } catch {
    /* already gone */
  }
  log(`stop pid ${process.pid} (${why})`);
  for (const s of conns) s.destroy();
  server.close(() => process.exit(code));
  setTimeout(() => process.exit(code), 1000).unref();
};
process.on("SIGTERM", () => stop("SIGTERM"));
process.on("SIGINT", () => stop("SIGINT"));
process.on("SIGHUP", () => stop("SIGHUP"));
server.on("error", (e) => {
  log(`listener error: ${e.code ?? e.message}`);
  stop("listener error", 1);
});
