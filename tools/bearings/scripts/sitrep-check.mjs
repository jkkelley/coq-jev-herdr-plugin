#!/usr/bin/env node
// name: sitrep-check
// purpose: enforce STD-owner-sitrep-001's content discipline on a SITREP payload before it is sent
// inputs: <file> holding either the raw message text starting with #SITREP/v1# or the bare JSON object; [--sitrep-config PATH]
//         [--config bearings.json]  also refuses a message longer than max_reply_chars, which the reply cap would cut into broken JSON
//         [--emit]                  stdout is then only the normalised message text (tag then minified JSON), the summary goes to stderr
// outputs: one line per violation on stderr, a one line summary on stdout
// exit: 0 the payload may be sent, 1 it may not, 2 usage, 3 bad config, 4 unreadable input
// Ported from sitrep-check.py (sitrep-panel-v1 handoff); the rules live in scripts/lib/sitrep.mjs, the limits in config/sitrep.json.
import fs from "node:fs";
import { argv, loadConfig } from "./lib/config.mjs";
import { check, loadSitrepConfig, parsePayload } from "./lib/sitrep.mjs";

const args = process.argv.slice(2);
const { val, has } = argv(args);
const positional = args.filter((a, i) => !a.startsWith("--") && !(i > 0 && ["--sitrep-config", "--config"].includes(args[i - 1])));
if (positional.length !== 1) {
  console.error("usage: sitrep-check.mjs <payload-file> [--sitrep-config PATH] [--config bearings.json] [--emit]");
  process.exit(2);
}
let sitrep;
try {
  sitrep = loadSitrepConfig(val("--sitrep-config"));
} catch (e) {
  console.error(`sitrep-check: ${e.message}`);
  process.exit(e.exitCode ?? 3);
}
let text;
try {
  text = fs.readFileSync(positional[0], "utf8");
} catch (e) {
  console.error(`sitrep-check: cannot read ${positional[0]}: ${e.message}`);
  process.exit(4);
}
let payload;
try {
  payload = parsePayload(text, sitrep.tag);
} catch (e) {
  console.error(`VIOLATION payload does not parse as JSON: ${e.message}`);
  console.log("0 items, 0 words of prose, 1 violations");
  process.exit(1);
}
const message = `${sitrep.tag}${JSON.stringify(payload)}`;
const maxChars = val("--config") || process.env.BEARINGS_CONFIG ? loadConfig(val("--config")).cfg.max_reply_chars : undefined;
const { bad, total, items } = check(payload, sitrep, { text: message, maxChars });
for (const b of bad) console.error(`VIOLATION ${b}`);
const summary = `${items} items, ${total} words of prose, ${bad.length} violations`;
if (has("--emit")) {
  console.error(summary);
  if (!bad.length) process.stdout.write(message);
} else console.log(summary);
process.exit(bad.length ? 1 : 0);
