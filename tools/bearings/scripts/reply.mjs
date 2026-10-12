#!/usr/bin/env node
// Replies on a bearings page to a message the owner sent from it. Lands in
// messages.jsonl as from "claude"; wait.mjs never wakes on these.
//
//   node reply.mjs --tier <tier> [--ticket ID] [--config PATH] --to <message-id> "text"
//   node reply.mjs --tier <tier> --to <message-id> <<'EOF'   (text on stdin)
import fs from "node:fs";
import path from "node:path";
import { argv, loadConfig, resolveTier } from "./lib/config.mjs";

const args = process.argv.slice(2);
const { val } = argv(args);
const tier = val("--tier");
const replyTo = val("--to");
if (!tier || !/^m-[A-Za-z0-9._:-]{1,64}$/.test(String(replyTo))) {
  console.error('usage: node reply.mjs --tier <tier> [--ticket ID] [--config PATH] --to <message-id> "text"   (or text on stdin)');
  process.exit(2);
}
const { cfg } = loadConfig(val("--config"));
const T = resolveTier(cfg, tier, val("--ticket"));
const file = path.join(T.stateDir, "messages.jsonl");
// The text is the last positional argument, or stdin when none is given.
const positional = args.filter((a, i) => !a.startsWith("--") && !(i > 0 && args[i - 1].startsWith("--")));
const text = (positional[0] ?? fs.readFileSync(0, "utf8")).trim();
if (!text) {
  console.error("reply text is empty");
  process.exit(2);
}
let asked = false;
try {
  asked = fs.readFileSync(file, "utf8").split("\n").some((line) => line.includes(`"id":"${replyTo}"`));
} catch {
  /* no messages file */
}
if (!asked) {
  console.error(`no message ${replyTo} on page ${T.page}`);
  process.exit(6);
}
// max_reply_chars, not max_message_chars: a SITREP payload with full ticket titles runs past the 8000 the owner's typed
// messages are capped at (WO-20261012-668a). Rejected: raising the shared cap, which would loosen the owner input limit too.
const at = new Date().toISOString();
const line = { id: `m-c${at.replace(/[^0-9]/g, "")}`, from: "claude", reply_to: replyTo, text: text.slice(0, cfg.max_reply_chars), at };
fs.appendFileSync(file, `${JSON.stringify(line)}\n`);
console.log(`replied to ${replyTo} on ${T.page}`);
