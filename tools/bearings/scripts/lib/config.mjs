// Config loader for the bearings tool. One place reads config/bearings.json,
// validates it, and resolves a tier into concrete names, so server.mjs, wait.mjs,
// reply.mjs and bearings.sh never carry a default of their own.
//
// Exit 3 on any problem, naming the key, because a tool that silently falls
// back to a built-in port is the hardcoding this file exists to remove.
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

export const TOOL_ROOT = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  "..",
  "..",
);

const die = (msg) => {
  console.error(`config: ${msg}`);
  process.exit(3);
};

// Hand-rolled check of the shape the schema file describes. The JSON schema in
// config/bearings.schema.json is the contract and `make lint` validates against
// it in a container; this is the runtime guard so a bad file fails at start.
const INT_KEYS = [
  "idle_minutes",
  "settle_ms",
  "stop_tries",
  "stop_try_ms",
  "max_body_bytes",
  "max_message_chars",
  "max_reply_chars",
  "max_words_chars",
  "messages_window",
];
const STR_KEYS = ["schema_version", "project", "state_root", "listen_host", "cookie_name", "open_label_prefix"];

// The owner reader's text caps, age thresholds and poll interval live in lib/owner-board.json (WO-20261013-b221, review of PR 92:
// literals in owner.mjs and the page were a second place to change a limit, and config/bearings.json is outside the ticket's files).
// A config's owner_board may override any of them; the merged result is checked here so a bad value stops the start (exit 3).
const OWNER_DEFAULTS = JSON.parse(fs.readFileSync(path.join(path.dirname(fileURLToPath(import.meta.url)), "owner-board.json"), "utf8"));
export function resolveOwnerBoard(o) {
  const m = { ...OWNER_DEFAULTS, ...o, caps: { ...OWNER_DEFAULTS.caps, ...(o.caps ?? {}) } };
  for (const k of ["dur_minutes_from_seconds", "dur_hours_from_seconds", "poll_seconds"])
    if (!Number.isInteger(m[k]) || m[k] < 1) die(`owner_board.${k} must be a positive integer`);
  for (const k of Object.keys(OWNER_DEFAULTS.caps))
    if (!Number.isInteger(m.caps[k]) || m.caps[k] < 1) die(`owner_board.caps.${k} must be a positive integer`);
  return m;
}

export function validate(cfg) {
  if (!cfg || typeof cfg !== "object" || Array.isArray(cfg)) die("root is not an object");
  for (const k of STR_KEYS)
    if (typeof cfg[k] !== "string" || !cfg[k]) die(`missing or empty string key ${k}`);
  if (!/^[a-z][a-z0-9-]{0,23}$/.test(cfg.project))
    die(`project must match ^[a-z][a-z0-9-]{0,23}$: got ${cfg.project}`);
  for (const k of INT_KEYS)
    if (!Number.isInteger(cfg[k]) || cfg[k] < 0) die(`missing or non-integer key ${k}`);
  if (cfg.board_dir !== undefined && (typeof cfg.board_dir !== "string" || !cfg.board_dir)) die("board_dir must be a non-empty string");
  if (cfg.session_sync !== undefined) {
    const o = cfg.session_sync;
    if (!o || typeof o !== "object" || Array.isArray(o)) die("session_sync must be an object");
    for (const k of ["interval_seconds", "stale_minutes", "watcher_grace_seconds"])
      if (o[k] !== undefined && (!Number.isInteger(o[k]) || o[k] < 1)) die(`session_sync.${k} must be a positive integer`);
    if (o.context_windows !== undefined && (!o.context_windows || typeof o.context_windows !== "object" || Array.isArray(o.context_windows)))
      die("session_sync.context_windows must be an object of model prefix to token count");
  }
  if (cfg.owner_board !== undefined) {
    const o = cfg.owner_board;
    if (!o || typeof o !== "object" || Array.isArray(o)) die("owner_board must be an object");
    for (const k of ["dir", "records_dir", "owner_lane", "health_file"])
      if (typeof o[k] !== "string" || !o[k]) die(`missing or empty string key owner_board.${k}`);
    if (!/^[A-Za-z0-9._-]+$/.test(o.health_file)) die("owner_board.health_file must be a plain file name");
    if (!/^[a-z][a-z0-9-]{0,31}$/.test(o.owner_lane)) die("owner_board.owner_lane must match ^[a-z][a-z0-9-]{0,31}$");
    for (const k of ["answer_scan_seconds", "owner_item_max_bytes", "health_max_bytes", "health_stale_seconds"])
      if (!Number.isInteger(o[k]) || o[k] < 0) die(`missing or non-integer key owner_board.${k}`);
    if (o.caps !== undefined && (!o.caps || typeof o.caps !== "object" || Array.isArray(o.caps))) die("owner_board.caps must be an object");
    resolveOwnerBoard(o);
  }
  if (cfg.front_door !== undefined) {
    if (!cfg.front_door || typeof cfg.front_door !== "object" || Array.isArray(cfg.front_door)) die("front_door must be an object");
    if (cfg.front_door.bind !== undefined && (typeof cfg.front_door.bind !== "string" || !cfg.front_door.bind)) die("front_door.bind must be a non-empty string");
  }
  if (cfg.idle_minutes < 1) die("idle_minutes must be >= 1");
  if (cfg.stop_tries < 1) die("stop_tries must be >= 1");
  if (!Array.isArray(cfg.allowed_hosts) || !cfg.allowed_hosts.length)
    die("allowed_hosts must be a non-empty array");
  if (!cfg.pane_split || !["down", "right"].includes(cfg.pane_split.direction))
    die("pane_split.direction must be down or right");
  if (!(cfg.pane_split.ratio > 0 && cfg.pane_split.ratio < 1))
    die("pane_split.ratio must be between 0 and 1");
  if (!cfg.tiers || typeof cfg.tiers !== "object" || !Object.keys(cfg.tiers).length)
    die("tiers must be a non-empty object");
  for (const [name, t] of Object.entries(cfg.tiers)) {
    if (!/^[a-z][a-z0-9-]{0,15}$/.test(name)) die(`tier name ${name} is not ^[a-z][a-z0-9-]{0,15}$`);
    for (const k of ["page", "pane_label", "wait_pane_label", "checkout"])
      if (typeof t[k] !== "string" || !t[k]) die(`missing key tiers.${name}.${k}`);
    const hasPort = Number.isInteger(t.port);
    const hasRange =
      Array.isArray(t.port_range) &&
      t.port_range.length === 2 &&
      t.port_range.every(Number.isInteger) &&
      t.port_range[0] <= t.port_range[1];
    if (t.idle_minutes !== undefined && (!Number.isInteger(t.idle_minutes) || t.idle_minutes < 0))
      die(`tiers.${name}.idle_minutes must be an integer >= 0 (0 = never idle-stop)`);
    if (t.front_door_pane_label !== undefined && (typeof t.front_door_pane_label !== "string" || !t.front_door_pane_label))
      die(`tiers.${name}.front_door_pane_label must be a non-empty string`);
    if (hasPort === hasRange)
      die(`tiers.${name} needs exactly one of port or port_range`);
    for (const p of hasPort ? [t.port] : t.port_range)
      if (p < 1024 || p > 65535) die(`tiers.${name} port ${p} outside 1024..65535`);
  }
  return cfg;
}

export function interpolate(s, vars) {
  return s.replace(/\$\{([A-Za-z_][A-Za-z0-9_:]*)\}/g, (m, k) => {
    if (k === "HOME") return os.homedir();
    if (k.startsWith("ENV:")) {
      const v = process.env[k.slice(4)];
      if (v === undefined) die(`variable ${m} is not set in the environment`);
      return v;
    }
    if (k in vars && vars[k] !== undefined && vars[k] !== null) return String(vars[k]);
    die(`variable ${m} has no value (known: ${Object.keys(vars).join(", ")})`);
  });
}

export function loadConfig(explicitPath) {
  const p = explicitPath || process.env.BEARINGS_CONFIG || path.join(TOOL_ROOT, "config", "bearings.json");
  let text;
  try {
    text = fs.readFileSync(p, "utf8");
  } catch (e) {
    die(`cannot read ${p}: ${e.message}`);
  }
  let cfg;
  try {
    cfg = JSON.parse(text);
  } catch (e) {
    die(`${p} is not valid JSON: ${e.message}`);
  }
  return { cfg: validate(cfg), path: p };
}

// A tier plus an optional ticket becomes the concrete names everything else uses.
export function resolveTier(cfg, tier, ticket) {
  const t = cfg.tiers[tier];
  if (!t) die(`unknown tier ${tier} (known: ${Object.keys(cfg.tiers).join(", ")})`);
  if (ticket !== undefined && !/^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$/.test(ticket))
    die(`ticket must be letters, digits, dot, underscore or dash: got ${ticket}`);
  const vars = { project: cfg.project, tier, ticket };
  const page = interpolate(t.page, vars);
  if (!/^[A-Za-z0-9._-]+$/.test(page)) die(`resolved page name ${page} has characters outside [A-Za-z0-9._-]`);
  const stateRoot = interpolate(cfg.state_root, vars);
  return {
    tier,
    ticket: ticket ?? null,
    page,
    port: t.port ?? null,
    portRange: t.port_range ?? null,
    stateRoot,
    stateDir: path.join(stateRoot, page),
    paneLabel: interpolate(t.pane_label, vars),
    waitPaneLabel: interpolate(t.wait_pane_label, vars),
    frontDoorPaneLabel: t.front_door_pane_label === undefined ? null : interpolate(t.front_door_pane_label, vars),
    checkout: t.checkout,
    idleMinutes: idleMinutesFor(cfg, tier),
  };
}

// Idle-stop window for a tier, in minutes; 0 means the tier never idle-stops.
// BREADCRUMB (2026-10-14, defect: stable page server stopped itself at 2026-10-14T08:43:55Z with reason "idle 240 minutes"):
//   What broke: the global "idle_minutes": 240 in config/bearings.json was applied to every tier by the idle check in
//   scripts/server.mjs (the `Date.now() - lastActivity >= IDLE_MS` test in the setInterval near the end of the file), stable included.
//   Why it mattered: the stable page is the owner's always-on monitor ("a halt never stops it"); it went dark and every wait loop ended.
//   Fix: an optional per-tier tiers.<tier>.idle_minutes overrides the global value, and 0 means never; stable is set to 0 in
//   config/bearings.json. dev and uat set no override, so they keep the global idle stop.
//   Rejected: a cron or supervisor that restarts stable after it idles out. A restart still drops the page and ends the waits, so the
//   outage happens anyway.
//   Cost: a forgotten stable server runs forever. That is the owner's intent for the stable tier.
export function idleMinutesFor(cfg, tier) {
  const o = cfg.tiers?.[tier]?.idle_minutes;
  return o === undefined ? cfg.idle_minutes : o;
}

// Shared argv helper: --flag value, or bare --flag.
export function argv(args) {
  const val = (f) => {
    const i = args.indexOf(f);
    return i >= 0 ? args[i + 1] : undefined;
  };
  return { val, has: (f) => args.includes(f) };
}
