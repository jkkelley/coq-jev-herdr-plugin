// The owner lane and the health line, read from the board's files (WO-20261013-b221, Roadmap K6, SPEC-17 s-owner).
//
// The page PULLS both on every /state poll; nothing pushes them. Two readers, both pure functions of files:
//   readOwnerLane(board)  - every open item of the owner lane as one decision card (deduplicated per ticket, kind and code), plus
//                           the files it could not turn into a card, so a bad item is a visible problem and never a silent gap.
//   readHealthLine(board) - the board's health file, normalised and capped for drawing; a missing, unreadable or malformed file
//                           is a state of its own ("unavailable" with the reason), never an empty strip.
//
// BREADCRUMB 2026-10-13 - WO-20261013-b221. What broke: SPEC-17 H19, the owner had to ask where the line stood, and decisions
//   reached the owner in prose; nothing on the page read the board. Why this shape: the board script (K1, WO-20261013-f268) and the
//   health watch (K2, WO-20261013-ba44) are not merged, so this file reads the item and health fields SPEC-17 s-lanes and s-board
//   name (id, kind, code, ticket, priority, posted_at; state, lanes, seats, stalls, counters) and tolerates the rest; the card text
//   rides on the item as `card` {about, decide, options[{label,then}], rec}, the same shape as questions.json, so the page's card
//   deck, the answer endpoint and wait.mjs need no second code path. Rejected: a lane directory of questions.json files (a second
//   store beside the board) and rendering from records directly (the lane is the one consumer-per-item contract, s-board).
//   Cost: if K1 settles a different item layout, only the field names in cardOf() below change.
import fs from "node:fs";
import path from "node:path";

const ID_RE = /^[A-Za-z0-9][A-Za-z0-9._:-]{0,63}$/;
const PRIORITY = { p0: 0, p1: 1, p2: 2, p3: 3 };
const cut = (s, n) =>
  String(s ?? "")
    .trim()
    .slice(0, n);
const isObj = (v) => v && typeof v === "object" && !Array.isArray(v);
const num = (v) => (Number.isFinite(v) && v >= 0 ? Math.floor(v) : null);

const readJsonFile = (file, maxBytes) => {
  const st = fs.statSync(file);
  if (!st.isFile()) throw new Error("not a regular file");
  if (st.size > maxBytes) throw new Error(`over ${maxBytes} bytes`);
  return JSON.parse(fs.readFileSync(file, "utf8"));
};

// The card an item carries, or the reason it has none. Options are 2 to 4 (the page's own deck rule); rec is an index.
function cardOf(item, lim) {
  const c = item.card;
  if (!isObj(c))
    return { reason: "no card object (about, decide, options, rec)" };
  const decide = cut(c.decide, lim.decide);
  if (!decide) return { reason: "card.decide is empty" };
  if (!Array.isArray(c.options) || c.options.length < 2 || c.options.length > 4)
    return { reason: "card.options must hold 2 to 4 options" };
  const options = [];
  for (const [i, o] of c.options.entries()) {
    const label = cut(o?.label, lim.label);
    if (!label) return { reason: `card.options[${i}].label is empty` };
    options.push({ label, then: cut(o?.then, lim.then) });
  }
  const rec =
    Number.isInteger(c.rec) && c.rec >= 0 && c.rec < options.length ? c.rec : 0;
  return {
    card: {
      about: cut(c.about, lim.about) || cut(item.ticket, 64),
      decide,
      options,
      rec,
    },
  };
}

// Answer records: a record whose `answer` field names an item id marks that item done (SPEC-17 s-owner, event.sh --answer). Records
// are immutable, so each file is parsed once and remembered; the directory is listed at most once per answer_scan_seconds, and only
// from the month of the oldest open item on, because an answer cannot come before its question.
const answerCache = new Map(); // path -> answered id or ""
let lastScan = { at: 0, key: "", ids: new Set() };
function answeredIds(board, sinceMonth, now) {
  const key = `${board.records_dir}|${sinceMonth}`;
  if (
    key === lastScan.key &&
    now - lastScan.at < board.answer_scan_seconds * 1000
  )
    return lastScan.ids;
  const ids = new Set();
  let years = [];
  try {
    years = fs.readdirSync(board.records_dir).filter((y) => /^\d{4}$/.test(y));
  } catch {
    /* no records tree yet: nothing is answered */
  }
  for (const y of years) {
    let months = [];
    try {
      months = fs
        .readdirSync(path.join(board.records_dir, y))
        .filter((m) => /^\d{2}$/.test(m));
    } catch {
      continue;
    }
    for (const m of months) {
      if (`${y}-${m}` < sinceMonth) continue;
      const dir = path.join(board.records_dir, y, m);
      let names = [];
      try {
        names = fs.readdirSync(dir).filter((n) => n.endsWith(".json"));
      } catch {
        continue;
      }
      for (const n of names) {
        const p = path.join(dir, n);
        let a = answerCache.get(p);
        if (a === undefined) {
          try {
            const rec = readJsonFile(p, board.owner_item_max_bytes);
            a = typeof rec.answer === "string" ? rec.answer : "";
          } catch {
            continue; // a half-written record is read again on the next scan
          }
          answerCache.set(p, a);
        }
        if (a) ids.add(a);
      }
    }
  }
  lastScan = { at: now, key, ids };
  return ids;
}

export function readOwnerLane(board, now = Date.now()) {
  const empty = { cards: [], problems: [], open: 0 };
  if (!board) return empty;
  const dir = path.join(board.dir, board.owner_lane);
  let names;
  try {
    names = fs
      .readdirSync(dir)
      .filter((n) => n.endsWith(".json") && !n.startsWith("."));
  } catch (e) {
    if (e.code === "ENOENT") return empty; // no owner item has ever been posted
    return {
      ...empty,
      problems: [
        {
          file: board.owner_lane,
          reason: `lane unreadable: ${e.code || e.message}`,
        },
      ],
    };
  }
  const lim = { about: 200, decide: 300, label: 80, then: 300 };
  const items = [];
  const problems = [];
  for (const n of names.sort()) {
    let item;
    try {
      item = readJsonFile(path.join(dir, n), board.owner_item_max_bytes);
    } catch (e) {
      problems.push({ file: n, reason: `unreadable: ${e.message}` });
      continue;
    }
    if (!isObj(item) || !ID_RE.test(String(item.id ?? ""))) {
      problems.push({ file: n, reason: "no usable id" });
      continue;
    }
    const { card, reason } = cardOf(item, lim);
    if (!card) {
      problems.push({ file: n, reason });
      continue;
    }
    items.push({
      id: item.id,
      kind: cut(item.kind, 64),
      code: num(item.code),
      ticket: item.ticket ? cut(item.ticket, 64) : null,
      priority: PRIORITY[item.priority] ?? 3,
      posted_at:
        typeof item.posted_at === "string" &&
        !Number.isNaN(Date.parse(item.posted_at))
          ? item.posted_at
          : null,
      card,
    });
  }
  // One card per ticket, kind and code: a second 423 on one ticket is the same decision, not a second one (AC-H1). The card keeps the
  // id and text of the OLDEST item, so an id the owner has seen never changes as repeats arrive; every member id is kept so an
  // answer record naming any of them clears the card.
  const order = (a, b) =>
    a.priority - b.priority ||
    (a.posted_at ?? "").localeCompare(b.posted_at ?? "") ||
    a.id.localeCompare(b.id);
  items.sort(order);
  const groups = new Map();
  for (const it of items) {
    const g = it.ticket ? `${it.ticket}|${it.kind}|${it.code}` : `id|${it.id}`;
    if (!groups.has(g)) groups.set(g, []);
    groups.get(g).push(it);
  }
  const oldest = items
    .map((i) => i.posted_at)
    .filter(Boolean)
    .sort()[0];
  const since = oldest ? oldest.slice(0, 7) : "0000-00";
  const answered = items.length ? answeredIds(board, since, now) : new Set();
  const cards = [];
  for (const members of groups.values()) {
    const first = [...members].sort(
      (a, b) =>
        (a.posted_at ?? "").localeCompare(b.posted_at ?? "") ||
        a.id.localeCompare(b.id),
    )[0];
    const ids = members.map((m) => m.id);
    cards.push({
      id: first.id,
      about:
        members.length > 1
          ? `${first.card.about} - raised ${members.length} times`
          : first.card.about,
      decide: first.card.decide,
      options: first.card.options,
      rec: first.card.rec,
      ...(first.posted_at ? { asked: first.posted_at } : {}),
      lane: board.owner_lane,
      item_ids: ids,
      done: ids.some((i) => answered.has(i)),
      priority: Math.min(...members.map((m) => m.priority)),
    });
  }
  cards.sort(
    (a, b) =>
      a.priority - b.priority ||
      (a.asked ?? "").localeCompare(b.asked ?? "") ||
      a.id.localeCompare(b.id),
  );
  return { cards, problems, open: cards.filter((c) => !c.done).length };
}

// The health line. The file is the board's `health` verb output (SPEC-17 s-lanes) widened by the health watch (s-health); the reader
// keeps what it can draw and drops the rest. It never invents a figure: a field that is absent stays absent.
const STATES = new Set(["running", "draining", "halted"]);
export function readHealthLine(board, now = Date.now()) {
  if (!board) return null;
  const file = path.join(board.dir, board.health_file);
  let h;
  try {
    h = readJsonFile(file, board.health_max_bytes);
  } catch (e) {
    const why =
      e.code === "ENOENT"
        ? "no health file yet"
        : `health file unreadable: ${e.code || e.message}`;
    return { available: false, reason: why };
  }
  if (!isObj(h) || !STATES.has(h.state))
    return {
      available: false,
      reason: "health file has no state of running, draining or halted",
    };
  const at =
    typeof h.at === "string" && !Number.isNaN(Date.parse(h.at)) ? h.at : null;
  const lanes = [];
  if (isObj(h.lanes))
    for (const [name, l] of Object.entries(h.lanes)) {
      if (!isObj(l)) continue;
      lanes.push({
        name: cut(name, 32),
        open: num(l.open) ?? 0,
        leased: num(l.leased) ?? 0,
        ...(num(l.oldest_age_seconds) !== null
          ? { oldest_age_seconds: num(l.oldest_age_seconds) }
          : {}),
      });
    }
  const seats = [];
  if (Array.isArray(h.seats))
    for (const s of h.seats) {
      if (!isObj(s)) continue;
      seats.push({
        seat: cut(s.seat ?? s.label, 64),
        role: cut(s.role, 32),
        check: cut(s.check, 32) || "unknown",
        ...(s.detail ? { detail: cut(s.detail, 160) } : {}),
      });
    }
  const stalls = [];
  if (Array.isArray(h.stalls))
    for (const s of h.stalls) {
      if (!isObj(s)) continue;
      stalls.push({
        title: cut(s.title ?? s.note, 200),
        ...(num(s.age_seconds) !== null
          ? { age_seconds: num(s.age_seconds) }
          : {}),
      });
    }
  const counters = [];
  if (isObj(h.counters))
    for (const [name, v] of Object.entries(h.counters))
      if (Number.isFinite(v)) counters.push({ name: cut(name, 48), value: v });
  return {
    available: true,
    state: h.state,
    ...(h.reason ? { reason: cut(h.reason, 200) } : {}),
    at,
    stale: at ? now - Date.parse(at) > board.health_stale_seconds * 1000 : true,
    lanes,
    seats,
    stalls,
    counters,
  };
}
