// Unit test for the per-tier idle window (node --test tests/idle.test.mjs; also run by tests/inside.sh and make test-sync).
// Defect covered: the stable page server idle-stopped at 2026-10-14T08:43:55Z because the global idle_minutes applied to every tier.
// See the breadcrumb on idleMinutesFor in scripts/lib/config.mjs.
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";
import { idleMinutesFor, loadConfig, resolveTier } from "../scripts/lib/config.mjs";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const SHIPPED = path.join(HERE, "..", "config", "bearings.json");

test("shipped config: stable never idle-stops, dev and uat keep the global idle stop", () => {
  const { cfg } = loadConfig(SHIPPED);
  assert.equal(resolveTier(cfg, "stable").idleMinutes, 0);
  assert.ok(cfg.idle_minutes >= 1);
  assert.equal(resolveTier(cfg, "dev", "WO-1").idleMinutes, cfg.idle_minutes);
  assert.equal(resolveTier(cfg, "uat", "WO-1").idleMinutes, cfg.idle_minutes);
});

test("a tier override replaces the global value, an absent override inherits it", () => {
  const cfg = { idle_minutes: 240, tiers: { a: { idle_minutes: 0 }, b: { idle_minutes: 7 }, c: {} } };
  assert.equal(idleMinutesFor(cfg, "a"), 0);
  assert.equal(idleMinutesFor(cfg, "b"), 7);
  assert.equal(idleMinutesFor(cfg, "c"), 240);
});

test("a negative or non-integer tier idle_minutes stops the start with exit 3 naming the key", () => {
  const good = JSON.parse(fs.readFileSync(SHIPPED, "utf8"));
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "idle-test-"));
  try {
    for (const bad of [-1, 1.5, "0"]) {
      good.tiers.stable.idle_minutes = bad;
      const f = path.join(dir, "bad.json");
      fs.writeFileSync(f, JSON.stringify(good));
      const r = spawnSync(
        process.execPath,
        ["--input-type=module", "-e", `import { loadConfig } from ${JSON.stringify(path.join(HERE, "..", "scripts", "lib", "config.mjs"))}; loadConfig(${JSON.stringify(f)});`],
        { encoding: "utf8" },
      );
      assert.equal(r.status, 3, `idle_minutes ${JSON.stringify(bad)} should exit 3`);
      assert.match(r.stderr, /tiers\.stable\.idle_minutes/);
    }
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
});
