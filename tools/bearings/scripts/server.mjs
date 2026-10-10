#!/usr/bin/env node
// Bearings server, vendored into coq/tools/bearings from the owner's bearings skill
// (~/.claude/skills/bearings, Sep 2026 snapshot) and de-hardcoded: every port, path,
// host, limit and timeout comes from config/bearings.json through lib/config.mjs.
//
//   node server.mjs --tier <tier> [--ticket ID] [--config PATH]      start
//   node server.mjs --tier <tier> [--ticket ID] --stop                stop it
//   --session <id> --model M --cwd DIR --working-on TEXT              written to session.json
//   --join                                                            share a page owned by another session
//
// One page per tier (and per ticket for uat/dev). The page folder lives under
// <state_root>/<page>/ and holds questions.json, answers.jsonl, messages.jsonl,
// delivered.json, session.json, server.json, stopped.json. wait.mjs blocks on it.
import crypto from "node:crypto";
import fs from "node:fs";
import http from "node:http";
import net from "node:net";
import path from "node:path";
import { TOOL_ROOT, argv, loadConfig, resolveTier } from "./lib/config.mjs";

const ASSETS = path.join(TOOL_ROOT, "assets");
const args = process.argv.slice(2);
const { val, has } = argv(args);
const usage = () => {
  console.error(
    "usage: node server.mjs --tier <tier> [--ticket ID] [--config PATH] [--stop] [--session <id>] [--join] [--model M] [--cwd DIR] [--working-on TEXT]",
  );
  process.exit(2);
};
const tier = val("--tier");
if (!tier) usage();
const { cfg } = loadConfig(val("--config"));
const T = resolveTier(cfg, tier, val("--ticket"));
const DIR = T.stateDir;
const file = (f) => path.join(DIR, f);
fs.mkdirSync(DIR, { recursive: true });

const IDLE_MS = cfg.idle_minutes * 60_000;
const sessionArg = val("--session");
const modelArg = val("--model");
const cwdArg = val("--cwd");
const workingOnArg = val("--working-on");
const join = has("--join");

const README = `# Bearings pages (${cfg.project})

Each folder here is one page. The page name encodes the tier and, for uat and dev, the ticket.
Served by coq/tools/bearings (scripts/server.mjs); stop one with
  node scripts/server.mjs --tier <tier> [--ticket ID] --stop

## Files in each page folder

| File | Written by | What it is |
| --- | --- | --- |
| questions.json | agent | The decision cards shown on the page |
| answers.jsonl | page | Every queued answer, one JSON line each, latest per id wins |
| messages.jsonl | page and agent | The chat: owner messages and the agent's replies |
| delivered.json | wait.mjs | Which answers and messages already reached the agent |
| session.json | agent | Model, cwd, session id, started time and a one-line "working on" |
| server.json | server.mjs | Link, port, pid and key of the page server; the key opens the page |
| stopped.json | server.mjs | Why the server last stopped; removed when it starts again |

A folder is safe to delete when its server is not running: server.json's pid is gone, or stopped.json exists.
Deleting a folder deletes that page's answers and chat for good.
`;
const readJson = (f, fallback) => {
  try {
    return JSON.parse(fs.readFileSync(file(f), "utf8"));
  } catch {
    return fallback;
  }
};
const info = readJson("server.json", null);
const alive = (pid) => {
  try {
    process.kill(pid, 0);
    return true;
  } catch {
    return false;
  }
};

if (has("--stop")) {
  if (info?.pid && alive(info.pid)) {
    process.kill(info.pid);
    console.log(`stopped ${T.page} (pid ${info.pid})`);
  } else console.log(`${T.page} was not running`);
  setTimeout(() => {
    if (!fs.existsSync(file("stopped.json")))
      fs.writeFileSync(
        file("stopped.json"),
        `${JSON.stringify({ reason: "stopped", forced: false, at: new Date().toISOString() }, null, 2)}\n`,
      );
    process.exit(0);
  }, 1500);
} else {
  // A tier runs once. A second start is refused with the live url, so two agents
  // never race for one page and the owner never gets two links for one tier.
  if (info?.pid && alive(info.pid) && !fs.existsSync(file("stopped.json"))) {
    console.error(`${T.page} is already running: ${info.url}`);
    process.exit(3);
  }
  const wantedSession = sessionArg || process.env.SESSION;
  const existingSession = readJson("session.json", null);
  if (wantedSession && existingSession?.session && existingSession.session !== wantedSession && !join) {
    console.error(`page ${T.page} belongs to session ${existingSession.session}; pass --join to share it`);
    process.exit(3);
  }
  const KEY = info?.key || crypto.randomBytes(16).toString("hex");
  const readJsonl = (f) => {
    let text = "";
    try {
      text = fs.readFileSync(file(f), "utf8");
    } catch {
      return [];
    }
    const rows = [];
    for (const line of text.split("\n")) {
      try {
        rows.push(JSON.parse(line));
      } catch {
        /* blank or partial line */
      }
    }
    return rows;
  };
  const answersNow = () => {
    const latest = {};
    for (const a of readJsonl("answers.jsonl")) latest[a.id] = a;
    return latest;
  };
  const readQuestions = () => {
    let text;
    try {
      text = fs.readFileSync(file("questions.json"), "utf8");
    } catch {
      return { questions: { title: "Bearings", items: [] }, error: null };
    }
    let q;
    try {
      q = JSON.parse(text);
    } catch (err) {
      return { questions: null, error: `questions.json is not valid JSON: ${err.message}` };
    }
    if (!q || typeof q !== "object" || !Array.isArray(q.items))
      return { questions: null, error: "questions.json has no items array" };
    return { questions: q, error: null };
  };
  const readBody = (req, res, handle) => {
    let body = "";
    req.on("data", (c) => {
      body += c;
      if (body.length > cfg.max_body_bytes) req.destroy();
    });
    req.on("end", () => {
      try {
        handle(JSON.parse(body));
      } catch {
        send(res, 400, { error: "not JSON" });
      }
    });
  };
  const send = (res, code, body, type = "application/json") => {
    res.writeHead(code, { "content-type": type, "cache-control": "no-store" });
    res.end(typeof body === "string" ? body : JSON.stringify(body));
  };
  const cookieRe = new RegExp(`(?:^|;\\s*)${cfg.cookie_name}=([a-f0-9]+)`);

  const server = http.createServer((req, res) => {
    const url = new URL(req.url, "http://localhost");
    const port = server.address().port;
    const host = req.headers.host || "";
    if (!cfg.allowed_hosts.some((h) => host === `${h}:${port}`))
      return send(res, 403, { error: "bad host" });
    const cookieKey = cookieRe.exec(req.headers.cookie || "")?.[1];
    const keyed = url.searchParams.get("key") === KEY || cookieKey === KEY;
    if (!keyed) return send(res, 403, "Open the full link with ?key= from the agent.", "text/plain");

    if (req.method === "GET" && url.pathname === "/") {
      touch();
      const html = fs
        .readFileSync(path.join(ASSETS, "page.html"), "utf8")
        .replace(/@@THEME@@;?/, () => fs.readFileSync(path.join(ASSETS, "theme.css"), "utf8"));
      res.setHeader("set-cookie", `${cfg.cookie_name}=${KEY}; HttpOnly; SameSite=Strict; Path=/`);
      return send(res, 200, `<!doctype html>\n${html}`, "text/html; charset=utf-8");
    }
    if (req.method === "GET" && url.pathname === "/health") {
      return send(res, 200, { ok: true, page: T.page, tier: T.tier, ticket: T.ticket, pid: process.pid });
    }
    if (req.method === "GET" && url.pathname === "/state") {
      const { questions, error } = readQuestions();
      return send(res, 200, {
        questions,
        error,
        session: readJson("session.json", null),
        answers: answersNow(),
        delivered: readJson("delivered.json", {}),
        messages: readJsonl("messages.jsonl").slice(-cfg.messages_window),
      });
    }
    if (req.method === "POST" && url.pathname === "/message") {
      readBody(req, res, (m) => {
        const text = String(m.text || "").trim();
        if (!/^m-[A-Za-z0-9._:-]{1,64}$/.test(String(m.id)) || !text)
          return send(res, 400, { error: "message needs an id and text" });
        const existing = readJsonl("messages.jsonl").find((x) => x.id === m.id);
        if (existing) return send(res, 200, existing);
        const line = {
          id: m.id,
          from: "you",
          text: text.slice(0, cfg.max_message_chars),
          at: typeof m.at === "string" ? m.at : new Date().toISOString(),
        };
        fs.appendFileSync(file("messages.jsonl"), `${JSON.stringify(line)}\n`);
        touch();
        send(res, 200, line);
      });
      return;
    }
    if (req.method === "POST" && url.pathname === "/answer") {
      readBody(req, res, (a) => {
        const items = readJson("questions.json", { items: [] }).items || [];
        const q = items.find((i) => i.id === a.id);
        if (!q || !q.options?.[a.pick]) return send(res, 400, { error: "unknown question or option" });
        const line = {
          id: q.id,
          decide: q.decide,
          pick: a.pick,
          choice: q.options[a.pick].label,
          words: String(a.words || "").slice(0, cfg.max_words_chars),
          at: typeof a.at === "string" ? a.at : new Date().toISOString(),
        };
        fs.appendFileSync(file("answers.jsonl"), `${JSON.stringify(line)}\n`);
        touch();
        send(res, 200, line);
      });
      return;
    }
    send(res, 404, { error: "not found" });
  });

  // Port policy from config: a fixed port for a tier like stable (one link the
  // owner keeps), or the first free port in a range for per-ticket tiers.
  const portFree = (p) =>
    new Promise((resolve) => {
      const s = net.createServer();
      s.once("error", () => resolve(false));
      s.listen(p, cfg.listen_host, () => s.close(() => resolve(true)));
    });
  const choosePort = async () => {
    if (info?.port && (await portFree(info.port))) return info.port;
    if (T.port) return T.port;
    for (let p = T.portRange[0]; p <= T.portRange[1]; p++) if (await portFree(p)) return p;
    console.error(`no free port in ${T.portRange[0]}..${T.portRange[1]} for ${T.page}`);
    process.exit(3);
  };
  const start = (port) =>
    server.listen(port, cfg.listen_host, () => {
      const p = server.address().port;
      const out = { name: T.page, tier: T.tier, ticket: T.ticket, url: `http://localhost:${p}/?key=${KEY}`, port: p, pid: process.pid, key: KEY, dir: DIR };
      fs.writeFileSync(file("server.json"), `${JSON.stringify(out, null, 2)}\n`);
      if (sessionArg || modelArg || cwdArg || workingOnArg)
        fs.writeFileSync(
          file("session.json"),
          `${JSON.stringify(
            {
              ...existingSession,
              ...(sessionArg && { session: sessionArg }),
              ...(modelArg && { model: modelArg }),
              ...(cwdArg && { cwd: cwdArg }),
              ...(workingOnArg && { working_on: workingOnArg }),
              tier: T.tier,
              ticket: T.ticket,
              started: existingSession?.started || new Date().toISOString(),
            },
            null,
            2,
          )}\n`,
        );
      console.log(JSON.stringify(out));
    });
  server.on("error", (err) => {
    if (err.code === "EADDRINUSE") {
      console.error(`port busy for ${T.page}${info?.url ? `; if it is already running, use ${info.url}` : ""}`);
      process.exit(3);
    }
    throw err;
  });

  let lastActivity = Date.now();
  function touch() {
    lastActivity = Date.now();
  }
  const mtimes = {};
  let stopping = false;
  let testFails = Number(process.env.BEARINGS_TEST_CLOSE_FAILS || 0); // test seam
  const record = (reason, forced) =>
    fs.writeFileSync(file("stopped.json"), `${JSON.stringify({ reason, forced, at: new Date().toISOString() }, null, 2)}\n`);
  const tryClose = () =>
    new Promise((resolve) => {
      if (testFails > 0) {
        testFails -= 1;
        return setTimeout(() => resolve(false), 10);
      }
      const timer = setTimeout(() => resolve(false), cfg.stop_try_ms);
      server.close((err) => {
        clearTimeout(timer);
        resolve(!err || err.code === "ERR_SERVER_NOT_RUNNING");
      });
      server.closeAllConnections?.();
    });
  async function shutdown(reason) {
    if (stopping) return;
    stopping = true;
    for (let t = 1; t <= cfg.stop_tries; t++) {
      if (await tryClose()) {
        record(reason, false);
        console.log(`bearings ${T.page}: stopped (${reason})`);
        process.exit(0);
      }
      console.error(`bearings ${T.page}: clean stop failed, try ${t} of ${cfg.stop_tries}`);
    }
    record(reason, true);
    console.error(`bearings ${T.page}: forced exit after ${cfg.stop_tries} failed tries`);
    process.exit(0);
  }
  setInterval(
    () => {
      for (const f of ["questions.json", "messages.jsonl"]) {
        try {
          const m = fs.statSync(file(f)).mtimeMs;
          if (m !== (mtimes[f] ?? 0)) {
            mtimes[f] = m;
            touch();
          }
        } catch {
          /* not written yet */
        }
      }
      if (Date.now() - lastActivity >= IDLE_MS) shutdown(`idle ${cfg.idle_minutes} minutes`);
    },
    Math.min(60_000, Math.max(1000, IDLE_MS / 4)),
  );
  process.on("SIGTERM", () => shutdown("stopped"));
  process.on("SIGINT", () => shutdown("stopped"));
  fs.rmSync(file("stopped.json"), { force: true });
  fs.writeFileSync(path.join(T.stateRoot, "README.md"), README);
  choosePort().then(start);
}
