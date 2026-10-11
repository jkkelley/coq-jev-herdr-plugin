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
const REPO_ROOT = path.resolve(TOOL_ROOT, "..", "..");
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
// Where the factory board's page is built; relative to the repository root, or absolute. Absent: /board answers 404.
const BOARD_DIR = cfg.board_dir ? path.resolve(REPO_ROOT, cfg.board_dir) : null;
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
  // Attachments (WK-20260916-068): one files/ dir per page, one files.jsonl line per upload,
  // the same append-only shape as answers.jsonl and messages.jsonl.
  const FILES_DIR = file("files");
  fs.mkdirSync(FILES_DIR, { recursive: true });
  const FILE_MAX_BYTES = cfg.file_max_bytes;
  // R1 of the WK-20260916-066 design review: inline rendering is an allowlist, not a denylist.
  // Serving a stored file inline puts it on the page's own origin; an HTML file or an SVG (a
  // script container wearing an image's MIME type) would then run as the page, with the page's
  // key and DOM. Only these four ever render inline; everything else, whatever it is, downloads.
  const INLINE_MIME_TYPES = new Set([
    "image/png",
    "image/jpeg",
    "image/gif",
    "image/webp",
  ]);
  // B2 of the design review: an allowlist of claimed types is only as honest as the client, and
  // a browser that sniffs content will render whatever the bytes actually are, on the page's own
  // origin, however the upload declared itself. Checked once at upload time, by magic bytes, not
  // trusted from the content-type header the way EXT_BY_MIME's cosmetic extension is.
  const MAGIC_CHECKS = {
    "image/png": (b) =>
      b.length >= 8 &&
      b[0] === 0x89 &&
      b[1] === 0x50 &&
      b[2] === 0x4e &&
      b[3] === 0x47 &&
      b[4] === 0x0d &&
      b[5] === 0x0a &&
      b[6] === 0x1a &&
      b[7] === 0x0a,
    "image/jpeg": (b) =>
      b.length >= 3 && b[0] === 0xff && b[1] === 0xd8 && b[2] === 0xff,
    "image/gif": (b) =>
      b.length >= 6 &&
      (b.toString("latin1", 0, 6) === "GIF87a" ||
        b.toString("latin1", 0, 6) === "GIF89a"),
    "image/webp": (b) =>
      b.length >= 12 &&
      b.toString("latin1", 0, 4) === "RIFF" &&
      b.toString("latin1", 8, 12) === "WEBP",
  };
  // The file is stored either way (the owner accepts any type); only whether it is later
  // eligible for inline serving changes. A declared type outside the inline set is not checked
  // here at all, since only a false inline claim can turn a render into a script execution.
  const effectiveMime = (declaredMime, buf) => {
    const check = MAGIC_CHECKS[declaredMime];
    return check && !check(buf) ? "application/octet-stream" : declaredMime;
  };
  // B1 and the CSP addition: nosniff belongs on the inline branch too, since a lying declared
  // type is now caught by effectiveMime, but a future inline type added without a magic check
  // should not rely on the allowlist alone. default-src 'none'; sandbox costs nothing for an
  // image and makes even a genuine inline render inert if it somehow carried anything active.
  const FILE_RESPONSE_HEADERS = {
    "x-content-type-options": "nosniff",
    "content-security-policy": "default-src 'none'; sandbox",
    "cache-control": "no-store",
  };
  // Cosmetic only, for a save-as dialog: the server always serves by the MIME type it recorded
  // at upload time, never by guessing from this extension.
  const EXT_BY_MIME = {
    "image/png": "png",
    "image/jpeg": "jpg",
    "image/gif": "gif",
    "image/webp": "webp",
    "application/pdf": "pdf",
    "text/plain": "txt",
    "text/csv": "csv",
    "application/json": "json",
    "application/zip": "zip",
  };
  const fileId = () =>
    `f-${new Date().toISOString().replace(/[^0-9]/g, "")}-${Math.random().toString(36).slice(2, 7)}`;
  // R2 of the design review: a client-supplied name is attacker-shaped data by the time it
  // reaches a header value. Strip CR, LF and quotes regardless of where this name came from or
  // where it is going next, and cap its length so a header is never built from something absurd.
  const sanitizeName = (raw) => {
    const cleaned = String(raw || "")
      .replace(/[\r\n"]/g, "")
      .slice(0, 200)
      .trim();
    return cleaned || "file";
  };
  // x-file-name is a request header, latin-1 by specification; the client percent-encodes it
  // before sending so a Windows filename outside that range survives the trip intact.
  const decodeHeaderName = (raw) => {
    if (!raw) return "file";
    try {
      return sanitizeName(decodeURIComponent(raw));
    } catch {
      return "file";
    }
  };
  // filename*=UTF-8''<percent-encoded>, per R2: a quote or a newline in the name is header
  // injection if it lands inside a plain quoted filename="..." value instead.
  const dispositionHeader = (kind, name) =>
    `${kind}; filename*=UTF-8''${encodeURIComponent(sanitizeName(name))}`;
  const filesNow = () => {
    const byId = {};
    for (const f of readJsonl("files.jsonl")) byId[f.id] = f;
    return byId;
  };
  const readBinaryBody = (req, res, handle) => {
    const declared = Number(req.headers["content-length"] || 0);
    if (declared > FILE_MAX_BYTES) {
      send(res, 413, { error: `file over ${FILE_MAX_BYTES} bytes` });
      req.destroy();
      return;
    }
    // A declared Content-Length past the cap is refused above without reading a byte. A body
    // that lies about its length (no header, or a smaller one) is caught here instead, the same
    // way the existing readBody caps a JSON body: destroy without a graceful response, since the
    // socket has already been torn down mid-upload and nothing sent now would reach the client.
    const chunks = [];
    let size = 0;
    req.on("data", (c) => {
      size += c.length;
      if (size > FILE_MAX_BYTES) return req.destroy();
      chunks.push(c);
    });
    req.on("end", () => {
      if (req.destroyed) return;
      handle(Buffer.concat(chunks));
    });
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
    // The factory board (WO-20261011-616c): report/loop's watch writes index.html and data.json into cfg.board_dir and this serves
    // them, behind the same key and cookie as the bearings page. The cookie is set here too because the board page polls
    // /board/data.json with no ?key= of its own: opened by key link on /board first, it would be refused on its first poll
    // otherwise (the same 403 the bearings page avoids by setting it on /). Nothing is cached: the page redraws from data.json
    // every few seconds and a cached copy would show a stale floor. A board that was never built answers 503 in JSON naming the
    // fix, not a bare 404, so the owner's page says "not built" instead of "not found". touch() only for the page, not the
    // poll: an open board must not keep a bearings tier alive past idle_minutes.
    if (req.method === "GET" && (url.pathname === "/board" || url.pathname === "/board/" || url.pathname === "/board/data.json")) {
      if (!BOARD_DIR) return send(res, 404, { error: "no board_dir in the bearings config" });
      const isPage = url.pathname !== "/board/data.json";
      let text;
      try {
        text = fs.readFileSync(path.join(BOARD_DIR, isPage ? "index.html" : "data.json"), "utf8");
      } catch (e) {
        if (e.code === "ENOENT") return send(res, 503, { error: "board not built", fix: "run loop.sh watch (report/loop) so it writes the page" });
        return send(res, 500, { error: "board unreadable" });
      }
      if (isPage) {
        touch();
        res.setHeader("set-cookie", `${cfg.cookie_name}=${KEY}; HttpOnly; SameSite=Strict; Path=/`);
      }
      return send(res, 200, text, isPage ? "text/html; charset=utf-8" : "application/json");
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
    // An upload ahead of the message text it will ride in with (WK-20260916-068). The body is
    // the raw file bytes; content-type and x-file-name (percent-encoded, R2) describe it.
    if (req.method === "POST" && url.pathname === "/file") {
      readBinaryBody(req, res, (buf) => {
        if (!buf.length) return send(res, 400, { error: "empty file" });
        const declaredMime = String(
          req.headers["content-type"] || "application/octet-stream",
        )
          .split(";")[0]
          .trim()
          .toLowerCase();
        // B2: the file is kept either way, whatever it is; only whether it is later eligible for
        // inline serving depends on its bytes actually matching what was declared.
        const mime = effectiveMime(declaredMime, buf);
        const name = decodeHeaderName(req.headers["x-file-name"]);
        const id = fileId();
        const ext = EXT_BY_MIME[mime] || "bin";
        const storedPath = path.join(FILES_DIR, `${id}.${ext}`);
        fs.writeFileSync(storedPath, buf);
        const line = {
          id,
          name,
          mime,
          size: buf.length,
          path: storedPath,
          at: new Date().toISOString(),
        };
        fs.appendFileSync(file("files.jsonl"), `${JSON.stringify(line)}\n`);
        touch();
        send(res, 200, { id, name, mime, size: buf.length });
      });
      return;
    }
    // A stored attachment served back. R1: inline only for the four image types nothing browser-
    // side will run as a script, decided on the bytes recorded at upload time (B2), never on a
    // fresh read of the declared type; every response, inline or not, carries nosniff and a CSP
    // that makes even a genuine inline render inert (B1).
    if (req.method === "GET" && /^\/file\/[^/]+$/.test(url.pathname)) {
      const id = url.pathname.slice("/file/".length);
      if (!/^f-[A-Za-z0-9._:-]{1,64}$/.test(id))
        return send(res, 400, { error: "bad file id" });
      const rec = filesNow()[id];
      if (!rec || !fs.existsSync(rec.path))
        return send(res, 404, { error: "not found" });
      if (INLINE_MIME_TYPES.has(rec.mime)) {
        res.writeHead(200, {
          ...FILE_RESPONSE_HEADERS,
          "content-type": rec.mime,
          "content-disposition": dispositionHeader("inline", rec.name),
        });
      } else {
        res.writeHead(200, {
          ...FILE_RESPONSE_HEADERS,
          "content-type": "application/octet-stream",
          "content-disposition": dispositionHeader("attachment", rec.name),
        });
      }
      touch();
      fs.createReadStream(rec.path).pipe(res);
      return;
    }
    // A message typed at the bottom of the page. Retries after a refresh reuse the id, so
    // a message is stored once no matter how many times the page sends it.
    if (req.method === "POST" && url.pathname === "/message") {
      readBody(req, res, (m) => {
        const text = String(m.text || "").trim();
        const knownFiles = filesNow();
        const files = [];
        for (const f of Array.isArray(m.files) ? m.files : []) {
          const rec = knownFiles[f?.id];
          if (!rec)
            return send(res, 400, { error: `unknown file id ${f?.id}` });
          files.push({
            id: rec.id,
            name: rec.name,
            mime: rec.mime,
            size: rec.size,
          });
        }
        if (
          !/^m-[A-Za-z0-9._:-]{1,64}$/.test(String(m.id)) ||
          (!text && !files.length)
        )
          return send(res, 400, {
            error: "message needs an id and text or a file",
          });
        const existing = readJsonl("messages.jsonl").find((x) => x.id === m.id);
        if (existing) return send(res, 200, existing);
        const line = {
          id: m.id,
          from: "you",
          text: text.slice(0, cfg.max_message_chars),
          at: typeof m.at === "string" ? m.at : new Date().toISOString(),
          ...(files.length ? { files } : {}),
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
