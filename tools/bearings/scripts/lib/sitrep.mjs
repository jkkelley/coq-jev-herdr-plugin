// The SITREP content rules, in one place, so the checker, the builder and the sender can never disagree about what a
// briefing may say. The rules are STD-owner-sitrep-001 (tools/bearings/standards/) measured, not judged: the sitrep-check.py
// of the sitrep-panel-v1 handoff ported case for case, plus the structural rules the standard states but that script never
// measured (marked "added" below). Every limit comes from config/sitrep.json; nothing here carries a number of its own.
import fs from "node:fs";
import path from "node:path";
import { TOOL_ROOT } from "./config.mjs";

export const SITREP_CONFIG = path.join(TOOL_ROOT, "config", "sitrep.json");

export function loadSitrepConfig(p) {
  const file = p || process.env.BEARINGS_SITREP_CONFIG || SITREP_CONFIG;
  let cfg;
  try {
    cfg = JSON.parse(fs.readFileSync(file, "utf8"));
  } catch (e) {
    const err = new Error(`sitrep config ${file}: ${e.message}`);
    err.exitCode = 4;
    throw err;
  }
  const r = cfg.rules;
  const ints = ["max_words_per_item", "max_items_per_block", "max_prose_words", "max_queue_next", "max_stats", "max_links_per_item"];
  const bad = !cfg.tag || !r || ints.some((k) => !Number.isInteger(r[k]) || r[k] < 1) || !Array.isArray(r.block_names) || !Array.isArray(r.ticket_id_patterns);
  if (bad) {
    const err = new Error(`sitrep config ${file} is missing tag, rules.<limit> or rules.block_names / ticket_id_patterns`);
    err.exitCode = 3;
    throw err;
  }
  return { ...cfg, file };
}

// The raw message text (tag then JSON) or the bare JSON object. Throws on JSON that does not parse: a payload the page
// cannot parse renders as a bubble, which is never what a SITREP sender wants.
export function parsePayload(text, tag) {
  let raw = String(text).trim();
  if (raw.startsWith(tag)) raw = raw.slice(tag.length);
  return JSON.parse(raw);
}

const SENTENCE_END = /[.!?](?:\s|$)/g;
const words = (t) => t.split(/\s+/).filter(Boolean).length;

// Returns { bad: [string], total, items }. Pure: no I/O, no exit.
export function check(d, sitrep, opts = {}) {
  const r = sitrep.rules;
  const ticketRes = r.ticket_id_patterns.map((p) => new RegExp(p));
  const bad = [];
  let total = 0;
  let items = 0;
  if (!d || typeof d !== "object" || Array.isArray(d)) return { bad: ["payload is not a JSON object"], total, items };
  const blocks = Array.isArray(d.blocks) ? d.blocks : [];
  // added: the five blocks are fixed and in order, nothing follows block 5 (STD-owner-sitrep-001).
  if (blocks.length !== r.block_names.length || blocks.some((b, i) => b.name !== r.block_names[i]))
    bad.push(`blocks must be exactly ${r.block_names.length} in this order: ${r.block_names.join(", ")}`);
  if (Array.isArray(d.stats) && d.stats.length > r.max_stats) bad.push(`stats: ${d.stats.length} cards, limit is ${r.max_stats}`);
  for (const b of blocks) {
    const n = b.n ?? "?";
    const blockItems = Array.isArray(b.items) ? b.items : [];
    if (blockItems.length > r.max_items_per_block) bad.push(`${n}: ${blockItems.length} items, limit is ${r.max_items_per_block}`);
    for (const it of blockItems) {
      items += 1;
      const label = it.label ?? "?";
      const t = typeof it.text === "string" ? it.text : "";
      if (typeof it.text !== "string") bad.push(`${n}/${label}: text is missing or not a string`);
      const w = words(t);
      total += w;
      if (w > r.max_words_per_item) bad.push(`${n}/${label}: ${w} words, limit is ${r.max_words_per_item}`);
      if ((t.match(SENTENCE_END) || []).length > 1) bad.push(`${n}/${label}: more than one sentence`);
      if (t.includes(";")) bad.push(`${n}/${label}: semicolon, split it or cut it`);
      if (ticketRes.some((re) => re.test(t))) bad.push(`${n}/${label}: ticket id in the prose, it belongs on the ref line`);
      if (it.ref && !it.ref_title) bad.push(`${n}/${label}: ref ${it.ref} carries no full title`);
      // added: the renderer drops a link that is not http(s) silently, so the sender would never learn it was lost.
      const links = Array.isArray(it.links) ? it.links : [];
      if (links.length > r.max_links_per_item) bad.push(`${n}/${label}: ${links.length} links, limit is ${r.max_links_per_item}`);
      for (const l of links) if (!l || !/^https?:\/\//i.test(String(l.href ?? ""))) bad.push(`${n}/${label}: link ${JSON.stringify(l?.href)} is not an http(s) url`);
    }
    for (const q of Array.isArray(b.queues) ? b.queues : []) {
      const nxt = Array.isArray(q.next) ? q.next : [];
      const nxtItems = Array.isArray(q.next_items) ? q.next_items : [];
      if (nxt.length > r.max_queue_next) bad.push(`${n}/${q.name}: ${nxt.length} next entries, limit is ${r.max_queue_next}`);
      if (nxtItems.length > r.max_queue_next) bad.push(`${n}/${q.name}: ${nxtItems.length} next_items, limit is ${r.max_queue_next}`);
      for (const e of nxt.slice(0, r.max_queue_next)) {
        // sitrep-check.py read a dict here; the payload's plain-string form is "ID - title", so the title is what follows " - ".
        if (e && typeof e === "object" ? !e.title : !/^.+ - \S/.test(String(e))) bad.push(`${n}/${q.name}: ${typeof e === "object" ? e.id : String(e).slice(0, 24)} carries no full title`);
      }
      for (const e of nxtItems.slice(0, r.max_queue_next)) if (!e || !e.id || !e.title) bad.push(`${n}/${q.name}: ${e?.id ?? "?"} carries no full title`);
    }
  }
  if (total > r.max_prose_words) bad.push(`whole briefing: ${total} words of prose, budget is ${r.max_prose_words}`);
  // added: the page cannot show a payload the reply cap would cut, so the sender refuses it instead of sending broken JSON.
  if (opts.maxChars && opts.text && opts.text.length > opts.maxChars) bad.push(`message is ${opts.text.length} characters, the reply cap is ${opts.maxChars}`);
  return { bad, total, items };
}
