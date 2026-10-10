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
  "max_words_chars",
  "messages_window",
];
const STR_KEYS = ["schema_version", "project", "state_root", "listen_host", "cookie_name"];

export function validate(cfg) {
  if (!cfg || typeof cfg !== "object" || Array.isArray(cfg)) die("root is not an object");
  for (const k of STR_KEYS)
    if (typeof cfg[k] !== "string" || !cfg[k]) die(`missing or empty string key ${k}`);
  if (!/^[a-z][a-z0-9-]{0,23}$/.test(cfg.project))
    die(`project must match ^[a-z][a-z0-9-]{0,23}$: got ${cfg.project}`);
  for (const k of INT_KEYS)
    if (!Number.isInteger(cfg[k]) || cfg[k] < 0) die(`missing or non-integer key ${k}`);
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
    checkout: t.checkout,
  };
}

// Shared argv helper: --flag value, or bare --flag.
export function argv(args) {
  const val = (f) => {
    const i = args.indexOf(f);
    return i >= 0 ? args[i + 1] : undefined;
  };
  return { val, has: (f) => args.includes(f) };
}
