// Session sync: keeps <page dir>/session.json true to the live Claude Code seat it names.
//
// BREADCRUMB 2026-10-14 UTC (owner: "none of this shit gets updated automatically, why not? when you change models or when the
// session and from and the ticket"; screenshot of the stable page showing a model, a ticket and a start time four days old).
//   What broke: server.mjs wrote session.json once in start() from --session/--model/--working-on and never read the seat again
//   (scripts/server.mjs, the `if (sessionArg || modelArg ...)` block), and page.html only drew what that file held, so every
//   field was frozen at the moment the server started. FROM (cwd) was empty because nothing ever supplied --cwd.
//   Why it mattered: the owner could not tell which model, session, pane or ticket he was talking to.
//   Why this fix: the transcript Claude Code already writes (~/.claude/projects/<slug>/<session>.jsonl) is the one record that
//   changes the moment the model, the cwd or the branch does, so the sync derives from it; nothing has to remember to push.
//   Rejected (a): a hook or a skill step that agents must call on a model change - the very "someone must remember" that
//   broke this. Rejected (b): a spawned scripts/session-sync.mjs child - a second pid per tier with its own lifecycle (orphans,
//   a stop path, a restart path) for two small file reads; this module runs inside server.mjs on a timer instead, and the
//   herdr and git calls are async execFile with a timeout so a slow socket never blocks the page.
//   Cost: the sync lives and dies with the page server; a server that is not running does not sync (and then the page is not
//   being served either). A stable server only picks this file up on its next restart.
//
// Reading cost: a transcript grows into tens of megabytes. Only a head chunk (first timestamp, read once and cached) and a tail
// chunk (newest records) are read, never the whole file; the tail doubles up to tail_max_bytes if it holds no assistant record.
//
// Honesty rule: a value that cannot be derived is null, never guessed. A missing transcript leaves the old values and sets
// stale:true with checked_at (the moment it flipped), so the page shows the marker instead of fresh-looking lies.
import { execFile } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

export const DEFAULTS = {
  interval_seconds: 5,
  projects_dir: "${HOME}/.claude/projects",
  head_bytes: 65536,
  tail_bytes: 262144,
  tail_max_bytes: 4194304,
  exec_timeout_ms: 3000,
  herdr_bin: "herdr",
  git_bin: "git",
  // Window sizes per model-id prefix, in tokens. Empty on purpose: the transcript does not carry the window, and the one
  // place that knows it (the statusline's context_window.used_percentage) writes no file. Rejected: assuming 200k or 1M for
  // every model, which would print a confident wrong percentage. With no entry context_pct is null and the page says n/a.
  context_windows: {},
  work_orders_dir: "work-orders",
};

export const resolveSyncConfig = (c = {}) => {
  const m = { ...DEFAULTS, ...c };
  m.projects_dir = String(m.projects_dir).replace("${HOME}", os.homedir());
  return m;
};

const WO_RE = /WO-\d{8}-[0-9a-f]{4}/;

// Claude Code's project folder name: the cwd with every non-alphanumeric turned into '-'.
export const slugOf = (cwd) => String(cwd || "").replace(/[^A-Za-z0-9]/g, "-");

export const findTranscript = (cfg, sessionId, cwd) => {
  if (!sessionId || !/^[A-Za-z0-9._-]+$/.test(sessionId)) return null;
  const tryDir = (d) => {
    const f = path.join(cfg.projects_dir, d, `${sessionId}.jsonl`);
    return fs.existsSync(f) ? f : null;
  };
  try {
    if (cwd) {
      const hit = tryDir(slugOf(cwd));
      if (hit) return hit;
    }
    // The cwd may have moved (a seat cd'd, a worktree) so the slug no longer matches: search every project dir.
    for (const d of fs.readdirSync(cfg.projects_dir)) {
      const hit = tryDir(d);
      if (hit) return hit;
    }
  } catch {
    /* projects_dir missing */
  }
  return null;
};

const readChunk = (fd, pos, len) => {
  const buf = Buffer.alloc(len);
  const n = fs.readSync(fd, buf, 0, len, pos);
  return buf.toString("utf8", 0, n);
};
const parseLines = (text, dropFirst, dropLast) => {
  const lines = text.split("\n");
  if (dropFirst) lines.shift();
  if (dropLast) lines.pop();
  const rows = [];
  for (const l of lines) {
    if (!l) continue;
    try {
      rows.push(JSON.parse(l));
    } catch {
      /* partial or corrupt line */
    }
  }
  return rows;
};

// Pure read of one transcript: model, started, last_active, cwd, gitBranch, last usage. Throws on I/O, callers catch.
export const deriveFromTranscript = (file, cfg, cache = {}) => {
  const fd = fs.openSync(file, "r");
  try {
    const size = fs.fstatSync(fd).size;
    if (!cache.started) {
      const head = parseLines(
        readChunk(fd, 0, Math.min(size, cfg.head_bytes)),
        false,
        size > cfg.head_bytes,
      );
      cache.started =
        head.find((r) => typeof r.timestamp === "string")?.timestamp ?? null;
    }
    let want = Math.min(size, cfg.tail_bytes);
    let rows;
    for (;;) {
      const pos = size - want;
      rows = parseLines(readChunk(fd, pos, want), pos > 0, false).reverse();
      if (
        rows.some(
          (r) => r.type === "assistant" && r.message?.model && !r.isSidechain,
        ) ||
        want >= size ||
        want >= cfg.tail_max_bytes
      )
        break;
      want = Math.min(size, want * 2, cfg.tail_max_bytes);
    }
    const stamped = rows.filter((r) => typeof r.timestamp === "string");
    // A sub-agent (isSidechain) runs its own model; the seat's model is the main thread's newest assistant record.
    const assistant = rows.find(
      (r) =>
        r.type === "assistant" &&
        r.message?.model &&
        r.message.model !== "<synthetic>" &&
        !r.isSidechain,
    );
    const u = assistant?.message?.usage;
    const tokens = u
      ? (u.input_tokens ?? 0) +
        (u.cache_read_input_tokens ?? 0) +
        (u.cache_creation_input_tokens ?? 0)
      : null;
    return {
      model: assistant?.message?.model ?? null,
      started: cache.started,
      last_active: stamped[0]?.timestamp ?? null,
      cwd: rows.find((r) => typeof r.cwd === "string")?.cwd ?? null,
      git_branch:
        rows.find((r) => typeof r.gitBranch === "string" && r.gitBranch)
          ?.gitBranch ?? null,
      context_tokens: tokens,
    };
  } finally {
    fs.closeSync(fd);
  }
};

const run = (bin, args, cfg, opts = {}) =>
  new Promise((resolve) => {
    execFile(
      bin,
      args,
      { timeout: cfg.exec_timeout_ms, maxBuffer: 8 * 1024 * 1024, ...opts },
      (err, stdout) => resolve(err ? null : stdout),
    );
  });

// The herdr pane that runs this session, matched on agent_session.value. Null when herdr is absent or has no such pane.
export const findPane = async (cfg, sessionId, runner = run) => {
  const out = await runner(cfg.herdr_bin, ["pane", "list"], cfg);
  if (!out) return null;
  try {
    const panes = JSON.parse(out)?.result?.panes ?? [];
    const p = panes.find((x) => x.agent_session?.value === sessionId);
    return p
      ? {
          label: p.label ?? null,
          pane_id: p.pane_id ?? null,
          workspace_id: p.workspace_id ?? null,
        }
      : null;
  } catch {
    return null;
  }
};

// Live branch of the seat's cwd; the transcript's gitBranch is the fallback (it is as fresh as the newest record).
const branchOf = async (cfg, cwd, recorded, runner = run) => {
  const clean = (x) => (x && x.trim() && x.trim() !== "HEAD" ? x.trim() : null); // detached HEAD names no branch
  const live = cwd && fs.existsSync(cwd) ? clean(await runner(cfg.git_bin, ["-C", cwd, "rev-parse", "--abbrev-ref", "HEAD"], cfg)) : null;
  return live ?? clean(recorded);
};

const titleCache = new Map();
// The ticket's own title from its work-order file (frontmatter "title"), so the page can show the id and the title together.
export const workOrderTitle = async (cfg, cwd, id, runner = run) => {
  if (!id) return null;
  if (titleCache.has(id)) return titleCache.get(id);
  let title = null;
  try {
    const top = (
      await runner(
        cfg.git_bin,
        ["-C", cwd, "rev-parse", "--show-toplevel"],
        cfg,
      )
    )?.trim();
    const root = path.join(top || cwd, cfg.work_orders_dir);
    const stack = [root];
    while (stack.length && !title) {
      const d = stack.pop();
      for (const e of fs.readdirSync(d, { withFileTypes: true })) {
        if (e.isDirectory()) stack.push(path.join(d, e.name));
        else if (e.name.startsWith(`${id}-`) && e.name.endsWith(".md")) {
          const head = fs
            .readFileSync(path.join(d, e.name), "utf8")
            .slice(0, 4096);
          title = /"title":\s*"((?:[^"\\]|\\.)*)"/.exec(head)?.[1] ?? null;
          break;
        }
      }
    }
  } catch {
    /* no work-orders dir here */
  }
  if (title) titleCache.set(id, title);
  return title;
};

const sameJson = (a, b) => JSON.stringify(a) === JSON.stringify(b);

// Atomic rewrite: temp file in the same directory, then rename, so a reader (the page's /state poll) never sees half a file.
export const writeAtomic = (file, obj) => {
  const tmp = `${file}.${process.pid}.tmp`;
  fs.writeFileSync(tmp, `${JSON.stringify(obj, null, 2)}\n`);
  fs.renameSync(tmp, file);
};

// One sync pass. Returns {changed, stale}. Never throws.
export async function syncOnce({
  file,
  cfg,
  cache = {},
  now = () => new Date().toISOString(),
  runner = run,
}) {
  try {
    let cur;
    try {
      cur = JSON.parse(fs.readFileSync(file, "utf8"));
    } catch {
      return { changed: false, stale: false, reason: "no session.json" };
    }
    if (!cur?.session)
      return { changed: false, stale: false, reason: "no session id" };
    if (cache.session !== cur.session) {
      for (const k of Object.keys(cache)) delete cache[k];
      cache.session = cur.session;
    }
    if (!cache.transcript || !fs.existsSync(cache.transcript))
      cache.transcript = findTranscript(cfg, cur.session, cur.cwd);
    let d = null;
    if (cache.transcript) {
      try {
        d = deriveFromTranscript(cache.transcript, cfg, cache);
      } catch {
        d = null;
      }
    }
    const next = { ...cur };
    if (!d) {
      // Missing or unreadable transcript: keep every old value, flag it. checked_at is set only when the flag flips so an
      // unchanged stale file is not rewritten every tick.
      if (cur.stale !== true) {
        next.stale = true;
        next.checked_at = now();
      }
    } else {
      const branch = await branchOf(cfg, d.cwd, d.git_branch, runner);
      // BREADCRUMB 2026-10-14 UTC (coordinator, owner page review: TICKET must not read "main").
      // What broke: this line fell back to the branch name when it carried no WO- id (first version, PR 184), so a seat on
      // main showed the bare word "main" in the TICKET field, and main is a place, not a ticket.
      // Why this fix: ticket is the work-order id or null; page.html draws null as a muted "none", the same style WORKING ON
      // uses for "not set". `branch` stays in session.json untouched, so no information is lost (it is also the tooltip).
      // Rejected: writing the string "none" into the file, which would be data that looks like a ticket to every other reader.
      // Cost: a seat on a non-WO branch (main, master, a hotfix) has no ticket value; read `branch` for where it is.
      const ticket = branch ? (WO_RE.exec(branch)?.[0] ?? null) : null;
      const pane = await findPane(cfg, cur.session, runner);
      const win = Object.entries(cfg.context_windows).find(([p]) =>
        d.model?.startsWith(p),
      )?.[1];
      Object.assign(next, {
        model: d.model ?? cur.model ?? null,
        started: d.started ?? cur.started ?? null,
        last_active: d.last_active,
        cwd: d.cwd,
        branch,
        ticket,
        ticket_title: WO_RE.test(ticket ?? "")
          ? await workOrderTitle(cfg, d.cwd, ticket, runner)
          : null,
        from: pane,
        context_tokens: d.context_tokens,
        context_pct:
          win && d.context_tokens != null
            ? Math.round((d.context_tokens / win) * 1000) / 10
            : null,
        stale: false,
      });
      delete next.checked_at;
      // working_on is the one hand-written field. Empty, or still equal to what this sync wrote last time, it follows the
      // ticket title; once a human writes anything else it is theirs and is never touched.
      // BREADCRUMB 2026-10-14 UTC (coordinator, owner page review: WORKING ON must never show a bare branch like "main").
      // What broke: this defaulted to the branch name when no work-order title was found, so a seat on main showed
      // "main" as what it was working on, which is a place, not a task (this line, first version of PR 184).
      // Why this fix: only a ticket title is a statement of work; with none, working_on is "" and the page shows a muted
      // "not set". TICKET keeps the branch, so no information is lost. Rejected: a placeholder string in the file
      // (it would count as hand-written text and block the auto value later). Cost: a seat on a non-WO branch has an
      // empty cell until a human writes one.
      const auto = next.ticket_title ? `${next.ticket} - ${next.ticket_title}` : "";
      if (!cur.working_on || cur.working_on === cur.working_on_auto) {
        next.working_on = auto;
        next.working_on_auto = auto;
      }
    }
    if (sameJson(next, cur))
      return { changed: false, stale: next.stale === true };
    writeAtomic(file, next);
    return { changed: true, stale: next.stale === true };
  } catch (err) {
    return { changed: false, stale: false, error: String(err?.message ?? err) };
  }
}

// Starts the timer inside the server. `status` is a mutable object the server exposes on /state (in memory only, so the
// timer itself never forces a file write).
export function startSessionSync({ file, cfg, status }) {
  const sc = resolveSyncConfig(cfg);
  const cache = {};
  let busy = false;
  const tick = async () => {
    if (busy) return;
    busy = true;
    const r = await syncOnce({ file, cfg: sc, cache });
    status.at = new Date().toISOString();
    status.ok = !r.error;
    busy = false;
  };
  tick();
  const t = setInterval(tick, sc.interval_seconds * 1000);
  t.unref();
  return () => clearInterval(t);
}
