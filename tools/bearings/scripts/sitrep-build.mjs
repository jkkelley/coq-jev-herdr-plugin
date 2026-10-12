#!/usr/bin/env node
// name: sitrep-build
// purpose: assemble a #SITREP/v1# payload from this repository's records, so a figure is read and never typed
// inputs: --tier T [--ticket ID] [--config bearings.json] [--sitrep-config sitrep.json] [--repo DIR] [--prs-json FILE]
//         [--now ISO] [--out FILE] [--save]
// outputs: the message text (tag then one JSON object) on stdout or in --out; notes and violations on stderr
// exit: 0 built and the payload passes the checker, 2 usage, 3 the payload breaks a rule (nothing is written) or the template
//       names a fact that does not exist, 4 a source could not be read
//
// Sources, all named in config/sitrep.json "build" and never typed here: the work-order tickets (their frontmatter is a JSON
// object between two --- lines), the event log (events/YYYY/MM/*.json), the open pull requests (prs_command, or --prs-json),
// and main_ref's short sha. The shape and the sentences are config/sitrep.template.json. --save records this briefing's queue
// counts in the tier's state directory so the next briefing can show a delta; without it a build changes nothing on disk.
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { TOOL_ROOT, argv, loadConfig, resolveTier } from "./lib/config.mjs";
import { check, loadSitrepConfig } from "./lib/sitrep.mjs";

const args = process.argv.slice(2);
const { val, has } = argv(args);
const fail = (code, msg) => {
  console.error(`sitrep-build: ${msg}`);
  process.exit(code);
};
const tier = val("--tier");
if (!tier) fail(2, "usage: sitrep-build.mjs --tier T [--ticket ID] [--config P] [--sitrep-config P] [--repo DIR] [--prs-json FILE] [--now ISO] [--out FILE] [--save]");

const { cfg } = loadConfig(val("--config"));
const T = resolveTier(cfg, tier, val("--ticket"));
let sitrep;
try {
  sitrep = loadSitrepConfig(val("--sitrep-config"));
} catch (e) {
  fail(e.exitCode ?? 3, e.message);
}
const B = sitrep.build;
if (!B) fail(3, `${sitrep.file} has no "build" section`);
const REPO = path.resolve(val("--repo") || path.join(TOOL_ROOT, "..", ".."));
const now = val("--now") ? new Date(val("--now")) : new Date();
if (Number.isNaN(now.getTime())) fail(2, `--now is not a date: ${val("--now")}`);
const rel = (p) => path.resolve(path.dirname(sitrep.file), "..", p);

// ---- sources -----------------------------------------------------------------------------------------------------------
const walk = (dir, test, out = []) => {
  let ents = [];
  try {
    ents = fs.readdirSync(dir, { withFileTypes: true });
  } catch {
    return out;
  }
  for (const e of ents.sort((a, b) => a.name.localeCompare(b.name))) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p, test, out);
    else if (test(e.name)) out.push(p);
  }
  return out;
};

const tickets = new Map();
for (const f of walk(path.join(REPO, B.work_orders_dir), (n) => /^WO-\d{8}-[0-9a-f]{4}.*\.md$/.test(n))) {
  const m = fs.readFileSync(f, "utf8").match(/^---\n([\s\S]*?)\n---\n/);
  if (!m) continue;
  try {
    const d = JSON.parse(m[1]);
    if (d.id && d.title && d.status) tickets.set(d.id, d);
  } catch {
    console.error(`sitrep-build: skipped ${path.relative(REPO, f)}: frontmatter is not JSON`);
  }
}
if (!tickets.size) fail(4, `no tickets found under ${path.join(REPO, B.work_orders_dir)}`);

const events = [];
for (const f of walk(path.join(REPO, B.events_dir), (n) => /\.json$/.test(n))) {
  if (!/\/\d{4}\/\d{2}\//.test(f)) continue;
  try {
    events.push(JSON.parse(fs.readFileSync(f, "utf8")));
  } catch {
    /* an unreadable event is the event lint's finding, not the briefing's */
  }
}
events.sort((a, b) => String(a.at).localeCompare(String(b.at)));

let prsRaw;
try {
  prsRaw = val("--prs-json")
    ? fs.readFileSync(val("--prs-json"), "utf8")
    : execFileSync(B.prs_command[0], B.prs_command.slice(1), { cwd: REPO, encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] });
} catch (e) {
  fail(4, `open pull requests could not be read (${B.prs_command.join(" ")}): ${String(e.stderr || e.message).trim().split("\n")[0]}`);
}
let prsList;
try {
  prsList = JSON.parse(prsRaw);
} catch {
  fail(4, "open pull requests are not JSON");
}

let mainSha = "unknown";
try {
  mainSha = execFileSync("git", ["-C", REPO, "rev-parse", "--short", B.main_ref], { encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] }).trim();
} catch {
  console.error(`sitrep-build: ${B.main_ref} is not resolvable in ${REPO}, the MAIN card shows "unknown"`);
}

// ---- facts -------------------------------------------------------------------------------------------------------------
const PRI = (p) => String(p ?? "p9");
const bySeq = (a, b) => PRI(a.priority).localeCompare(PRI(b.priority)) || a.id.localeCompare(b.id);
const row = (t) => ({ id: t.id, title: t.title, priority: PRI(t.priority).toUpperCase() === "P9" ? "?" : PRI(t.priority), updated: t.updated ?? "", closed: t.closed ?? "", status: t.status });
const all = [...tickets.values()];
const isDone = new Set(all.filter((t) => t.status === "done").map((t) => t.id));
const ready = all.filter((t) => t.status === "ready");
const startable = ready.filter((t) => (t.depends_on || []).every((d) => isDone.has(d))).sort(bySeq).map(row);
const waiting = ready.filter((t) => !(t.depends_on || []).every((d) => isDone.has(d))).sort(bySeq).map(row);
const inProgress = all.filter((t) => t.status === "in-progress").sort((a, b) => String(b.updated).localeCompare(String(a.updated)) || a.id.localeCompare(b.id)).map(row);
const cutoff = new Date(now.getTime() - cfgDays(B.recent_done_days) * 86_400_000).toISOString().slice(0, 10);
function cfgDays(n) {
  return Number.isFinite(n) && n > 0 ? n : 7;
}
const doneRecent = all
  .filter((t) => t.status === "done" && String(t.closed || t.updated) >= cutoff)
  .sort((a, b) => String(b.closed || b.updated).localeCompare(String(a.closed || a.updated)) || a.id.localeCompare(b.id))
  .map(row);

// The newest failure record, inside friction_window_hours, that nothing later answered. "Answered" means a later record on the
// same ticket (or, for a record with no ticket, the same seat) with a code under friction_min_code: a 409 followed by a 100
// on that ticket is solved. Limit: a failure older than the window is not shown, however open it still is.
let friction;
const windowStart = now.getTime() - B.friction_window_hours * 3_600_000;
for (let i = events.length - 1; i >= 0 && !friction; i--) {
  const e = events[i];
  if (!(e.code >= B.friction_min_code) || new Date(e.at).getTime() < windowStart) continue;
  const same = (l) => (e.ticket ? l.ticket === e.ticket : l.seat === e.seat);
  if (events.slice(i + 1).some((l) => same(l) && l.code < B.friction_min_code)) continue;
  const mins = Math.max(0, Math.round((now.getTime() - new Date(e.at).getTime()) / 60_000));
  const t = e.ticket ? tickets.get(e.ticket) : undefined;
  friction = { code: e.code, ago: mins >= 120 ? `${Math.round(mins / 60)} hours ago` : `${mins} minutes ago`, ticket: t ? { id: t.id, title: t.title } : undefined };
}

// BREADCRUMB 2026-10-12 - WO-20261012-8f4f, IN FLIGHT. What broke: the IN FLIGHT card read in_progress.count, which is ticket status
//   on THIS checkout (the `inProgress` filter above). work-order start flips a ticket to in-progress on its feature branch only, so
//   on main it stays `ready` until its PR lands, and the SITREP sent 2026-10-12 14:24Z showed almost nothing in flight with six PRs
//   open. Why this fix: the work the line is doing is the union of two sets, deduplicated by ticket id so a ticket that is both
//   in-progress here and has an open PR counts once: tickets an open PR's title names (the first WO id in the title is the ticket
//   the PR is for; a PR with no id in its title is not counted, it is not tracked work) and tickets whose status here is in-progress
//   or in-review. A PR naming an id this checkout has never seen still counts, as the id alone: main may simply be behind the
//   branch. Rejected: reading headRefName (the title is the convention the merger and the owner read, and the ticket says title)
//   and listing every remote branch (a pushed branch with no PR is not yet work anyone can review). Cost: a ticket started on a
//   branch with no PR yet and still `ready` here is invisible until its PR opens; prs_command lists at most 20 PRs
//   (config/sitrep.json), so beyond 20 open PRs the figure is a floor. The queues (IN PROGRESS, OPEN PRS) are unchanged on purpose.
const WO_ID = /\bWO-\d{8}-[0-9a-f]{4}\b/;
const prTicketIds = new Set(prsList.map((p) => WO_ID.exec(String(p.title ?? ""))?.[0]).filter(Boolean));
const statusIds = all.filter((t) => t.status === "in-progress" || t.status === "in-review").map((t) => t.id);
const inFlight = [...new Set([...prTicketIds, ...statusIds])].sort().map((id) => ({ id, title: tickets.get(id)?.title ?? id }));
const withoutPr = inFlight.filter((t) => !prTicketIds.has(t.id)).length;
const inFlightSource =
  [prTicketIds.size ? `${prTicketIds.size} open ${prTicketIds.size === 1 ? "PR" : "PRs"}` : "", withoutPr ? `${withoutPr} without a PR` : ""].filter(Boolean).join(", ") ||
  "nothing in flight";

const prs = prsList.map((p) => ({ id: `PR ${p.number}`, title: p.title, url: p.url, number: p.number, priority: "" }));
const facts = {
  project: cfg.project.toUpperCase(),
  main_sha: mainSha,
  main_ref: B.main_ref,
  recent_days: cfgDays(B.recent_done_days),
  startable,
  waiting,
  in_progress: inProgress,
  in_flight: inFlight,
  in_flight_source: inFlightSource,
  done_recent: doneRecent,
  prs,
  friction,
};

// ---- template ----------------------------------------------------------------------------------------------------------
const step = (v, k) => {
  if (v === undefined || v === null) return undefined;
  if (Array.isArray(v)) {
    if (k === "count") return v.length;
    if (k === "p0") return v.filter((x) => String(x.priority).toLowerCase() === "p0").length;
    return /^\d+$/.test(k) ? v[Number(k)] : undefined;
  }
  return typeof v === "object" ? v[k] : undefined;
};
const resolve = (p) => p.split(".").reduce(step, facts);
const truthy = (v) => !(v === undefined || v === null || v === false || v === 0 || v === "" || (Array.isArray(v) && !v.length));
const fill = (s) =>
  s.replace(/\{\{([A-Za-z0-9_.]+)\}\}/g, (m, p) => {
    const v = resolve(p);
    if (v === undefined || v === null) fail(3, `the template names ${m}, which is not a fact (known: ${Object.keys(facts).join(", ")})`);
    return String(v);
  });

let tpl;
try {
  tpl = JSON.parse(fs.readFileSync(rel(B.template), "utf8"));
} catch (e) {
  fail(4, `cannot read template ${rel(B.template)}: ${e.message}`);
}

const countsFile = path.join(T.stateDir, B.counts_file);
let previous = null;
try {
  previous = JSON.parse(fs.readFileSync(countsFile, "utf8")).counts ?? null;
} catch {
  /* no earlier briefing */
}
const counts = {};

const buildItem = (t) => {
  if (t.when !== undefined && !truthy(resolve(t.when))) return null;
  const it = { label: fill(t.label).toUpperCase(), text: fill(t.text) };
  if (t.tone) it.tone = t.tone;
  if (t.check) it.check = true;
  if (t.ref_from) {
    const r = resolve(t.ref_from);
    if (r && r.id && r.title) {
      it.ref = r.id;
      it.ref_title = r.title;
    }
  }
  if (t.links_from) {
    const l = (resolve(t.links_from) || []).filter((x) => x.url).slice(0, sitrep.rules.max_links_per_item);
    if (l.length) it.links = l.map((x) => ({ href: x.url }));
  }
  return it;
};
const buildQueue = (q) => {
  const list = facts[q.list];
  if (!Array.isArray(list)) fail(3, `queue ${q.name} names list ${q.list}, which is not a fact`);
  const next = list.slice(0, sitrep.rules.max_queue_next);
  counts[q.name] = list.length;
  const was = previous?.[q.name];
  const delta = was === undefined ? "new" : list.length - was === 0 ? "0" : `${list.length - was > 0 ? "+" : "-"}${Math.abs(list.length - was)}`;
  return {
    name: q.name,
    count: String(list.length),
    delta,
    tone: list.length ? q.tone : "mute",
    urgency: fill(q.urgency),
    next_items: next.map((x) => ({ id: x.id, title: x.title })),
    next: next.map((x) => `${x.id} - ${x.title}`),
  };
};

const rule = (tpl.state_rules || []).find((r) => truthy(resolve(r.when)));
const st = rule || tpl.state_default;
const payload = {
  scope: fill(tpl.scope),
  state: st.state,
  state_label: st.label,
  updated: `${now.toISOString().slice(0, 16).replace("T", " ")} UTC`,
  stats: (tpl.stats || []).map((s) => ({ label: s.label, value: fill(s.value), note: fill(s.note), tone: s.tone })),
  blocks: (tpl.blocks || []).map((b) => {
    const out = { n: b.n, name: b.name };
    if (b.queues) out.queues = b.queues.map(buildQueue);
    else out.items = (b.items || []).map(buildItem).filter(Boolean);
    return out;
  }),
};

const text = `${sitrep.tag}${JSON.stringify(payload)}`;
const { bad, total, items } = check(payload, sitrep, { text, maxChars: cfg.max_reply_chars });
if (bad.length) {
  for (const b of bad) console.error(`VIOLATION ${b}`);
  fail(3, `the built payload breaks ${bad.length} rule(s); fix the template or the records, nothing was written`);
}
console.error(`sitrep-build: ${items} items, ${total} words of prose, ${text.length} characters, 0 violations`);

if (has("--save")) {
  fs.mkdirSync(T.stateDir, { recursive: true });
  fs.writeFileSync(countsFile, `${JSON.stringify({ at: now.toISOString(), counts }, null, 2)}\n`);
  console.error(`sitrep-build: queue counts saved to ${countsFile}`);
}
if (val("--out")) fs.writeFileSync(val("--out"), `${text}\n`);
else console.log(text);
