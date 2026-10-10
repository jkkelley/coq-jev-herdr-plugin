#!/usr/bin/env node
// Blocks until the owner queues an answer or sends a message on a bearings page,
// prints what is new, marks it delivered, and exits. Run it in a labelled herdr
// pane in a loop (bearings.sh <tier> wait does that); its output is what the
// agent's monitor reads.
//
//   node wait.mjs --tier <tier> [--ticket ID] [--config PATH]
import fs from "node:fs";
import path from "node:path";
import { argv, loadConfig, resolveTier } from "./lib/config.mjs";

const { val } = argv(process.argv.slice(2));
const tier = val("--tier");
if (!tier) {
  console.error("usage: node wait.mjs --tier <tier> [--ticket ID] [--config PATH]");
  process.exit(2);
}
const { cfg } = loadConfig(val("--config"));
const T = resolveTier(cfg, tier, val("--ticket"));
const file = (f) => path.join(T.stateDir, f);
const SETTLE_MS = cfg.settle_ms;

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
const mtime = (f) => {
  try {
    return fs.statSync(file(f)).mtimeMs;
  } catch {
    return 0;
  }
};

const tick = () => {
  let delivered = {};
  try {
    delivered = JSON.parse(fs.readFileSync(file("delivered.json"), "utf8"));
  } catch {
    /* nothing delivered yet */
  }
  const latestAnswers = {};
  for (const a of readJsonl("answers.jsonl")) latestAnswers[a.id] = a;
  const fresh = [
    ...Object.values(latestAnswers).map((a) => ({ ...a, kind: "ANSWER" })),
    ...readJsonl("messages.jsonl")
      .filter((m) => m.from !== "claude")
      .map((m) => ({ ...m, kind: "MESSAGE" })),
  ]
    .filter((x) => delivered[x.id] !== x.at)
    .sort((x, y) => x.at.localeCompare(y.at));

  if (!fresh.length && fs.existsSync(file("stopped.json"))) {
    const s = JSON.parse(fs.readFileSync(file("stopped.json"), "utf8"));
    console.log(`STOPPED ${s.reason}${s.forced ? " (forced)" : ""} at ${s.at} - restart the server if the page is still needed`);
    process.exit(0);
  }
  const last = Math.max(mtime("answers.jsonl"), mtime("messages.jsonl"));
  if (!fresh.length || Date.now() - last < SETTLE_MS) return setTimeout(tick, 1000);
  // Ported from getting-my-bearings wait.mjs (WK-20260916-069): a message's files array names
  // an id, not a path; the path only lives in files.jsonl. Resolved once per tick, so the agent
  // is handed the path in the same line that wakes it instead of a lookup it has to know to make.
  const filesById = {};
  for (const f of readJsonl("files.jsonl")) filesById[f.id] = f;
  for (const x of fresh) {
    if (x.kind === "ANSWER")
      console.log(`ANSWER ${x.id} - ${x.decide} -> ${x.choice}${x.words ? ` | words: ${x.words}` : ""}`);
    else {
      const paths = (x.files || []).map((f) => filesById[f.id]?.path).filter(Boolean);
      console.log(`MESSAGE ${x.id} - ${x.text}${paths.length ? ` | files: ${paths.join(", ")}` : ""}`);
    }
    delivered[x.id] = x.at;
  }
  fs.writeFileSync(file("delivered.json"), `${JSON.stringify(delivered, null, 2)}\n`);
  process.exit(0);
};
tick();
