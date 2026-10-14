// Unit test for scripts/lib/session-sync.mjs (node --test tests/session-sync.test.mjs; also run by tests/inside.sh).
// Feeds a fake transcript and asserts the derived fields, the working_on rule, the stale rule and the atomic rewrite.
// herdr and git are replaced by a stub runner, so nothing here touches the real seat, pane list or repo.
import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { findTranscript, resolveSyncConfig, slugOf, syncOnce } from "../scripts/lib/session-sync.mjs";

const SID = "11111111-2222-3333-4444-555555555555";
const mkWorld = () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "sync-"));
  const projects = path.join(root, "projects");
  const cwd = path.join(root, "repo", "wt");
  fs.mkdirSync(cwd, { recursive: true });
  const dir = path.join(projects, slugOf(cwd));
  fs.mkdirSync(dir, { recursive: true });
  const transcript = path.join(dir, `${SID}.jsonl`);
  const rec = (o) => `${JSON.stringify(o)}\n`;
  fs.writeFileSync(
    transcript,
    rec({ type: "custom-title", customTitle: "x" }) + // no timestamp: started must skip it
      rec({ type: "user", timestamp: "2026-10-10T19:59:30.132Z", cwd, gitBranch: "main", message: { role: "user", content: "hi" } }) +
      rec({ type: "assistant", timestamp: "2026-10-10T20:00:00.000Z", cwd, gitBranch: "main", message: { model: "old-model", usage: { input_tokens: 1 } } }) +
      rec({ type: "assistant", timestamp: "2026-10-14T03:00:00.000Z", cwd, gitBranch: "feat/WO-20261014-abcd-thing", message: { model: "new-model", usage: { input_tokens: 2, cache_read_input_tokens: 1000, cache_creation_input_tokens: 500 } } }) +
      rec({ type: "assistant", isSidechain: true, timestamp: "2026-10-14T03:01:00.000Z", cwd, message: { model: "sidechain-model" } }) +
      rec({ type: "attachment", timestamp: "2026-10-14T03:02:00.000Z", cwd }) +
      '{"type":"assistant","timestamp":"2026-10-14T03:03', // a partial last line must be ignored
  );
  const file = path.join(root, "session.json");
  fs.writeFileSync(file, JSON.stringify({ session: SID, model: "stale-model", started: "2020-01-01T00:00:00Z", working_on: "", tier: "dev", ticket: null }));
  const cfg = resolveSyncConfig({ projects_dir: projects, context_windows: { "new-": 10000 } });
  const runner = async (bin, args) => {
    if (bin === "herdr") return JSON.stringify({ result: { panes: [{ pane_id: "wX:p1", workspace_id: "wX", label: "seat", agent_session: { value: SID } }, { pane_id: "wX:p2", agent_session: { value: "other" } }] } });
    if (args.includes("--abbrev-ref")) return "rebuild/x-WO-20261014-abcd-thing\n";
    return null; // rev-parse --show-toplevel: no work-order file lookup
  };
  return { root, file, cfg, runner, transcript, cwd };
};
const read = (f) => JSON.parse(fs.readFileSync(f, "utf8"));

test("derives model, started, last_active, cwd, ticket, pane and context from the transcript", async () => {
  const w = mkWorld();
  const r = await syncOnce({ file: w.file, cfg: w.cfg, runner: w.runner });
  assert.equal(r.changed, true);
  const s = read(w.file);
  assert.equal(s.model, "new-model");
  assert.equal(s.started, "2026-10-10T19:59:30.132Z");
  assert.equal(s.last_active, "2026-10-14T03:02:00.000Z");
  assert.equal(s.cwd, w.cwd);
  assert.equal(s.ticket, "WO-20261014-abcd");
  assert.deepEqual(s.from, { label: "seat", pane_id: "wX:p1", workspace_id: "wX" });
  assert.equal(s.context_tokens, 1502);
  assert.equal(s.context_pct, 15);
  assert.equal(s.stale, false);
  assert.equal(s.working_on, "rebuild/x-WO-20261014-abcd-thing");
  assert.equal(s.tier, "dev");
});

test("a second pass with nothing new rewrites nothing; atomic write leaves no temp file", async () => {
  const w = mkWorld();
  await syncOnce({ file: w.file, cfg: w.cfg, runner: w.runner });
  const m1 = fs.statSync(w.file).mtimeMs;
  await new Promise((r) => setTimeout(r, 20));
  const r = await syncOnce({ file: w.file, cfg: w.cfg, runner: w.runner });
  assert.equal(r.changed, false);
  assert.equal(fs.statSync(w.file).mtimeMs, m1);
  assert.deepEqual(fs.readdirSync(w.root).filter((n) => n.endsWith(".tmp")), []);
});

test("working_on written by a human is never touched; one the sync wrote follows the branch", async () => {
  const w = mkWorld();
  await syncOnce({ file: w.file, cfg: w.cfg, runner: w.runner });
  const s = read(w.file);
  fs.writeFileSync(w.file, JSON.stringify({ ...s, working_on: "hand written line" }));
  const branch2 = async (bin, args) => (args?.includes("--abbrev-ref") ? "other-branch\n" : w.runner(bin, args));
  await syncOnce({ file: w.file, cfg: w.cfg, runner: branch2 });
  assert.equal(read(w.file).working_on, "hand written line");
  assert.equal(read(w.file).ticket, "other-branch");
  fs.writeFileSync(w.file, JSON.stringify({ ...s })); // back to the auto-written value
  await syncOnce({ file: w.file, cfg: w.cfg, runner: branch2 });
  assert.equal(read(w.file).working_on, "other-branch");
});

test("no herdr: from is null; detached HEAD: ticket falls back to the recorded branch", async () => {
  const w = mkWorld();
  const noHerdr = async (bin, args) => (bin === "herdr" ? null : args?.includes("--abbrev-ref") ? "HEAD\n" : null);
  await syncOnce({ file: w.file, cfg: w.cfg, runner: noHerdr });
  const s = read(w.file);
  assert.equal(s.from, null);
  assert.equal(s.ticket, "WO-20261014-abcd"); // transcript gitBranch feat/WO-20261014-abcd-thing
});

test("missing transcript keeps old values and sets stale with checked_at once", async () => {
  const w = mkWorld();
  fs.rmSync(w.transcript);
  const r = await syncOnce({ file: w.file, cfg: w.cfg, runner: w.runner, now: () => "2026-10-14T04:00:00.000Z" });
  assert.equal(r.stale, true);
  const s = read(w.file);
  assert.equal(s.model, "stale-model");
  assert.equal(s.stale, true);
  assert.equal(s.checked_at, "2026-10-14T04:00:00.000Z");
  const r2 = await syncOnce({ file: w.file, cfg: w.cfg, runner: w.runner, now: () => "2026-10-14T04:00:05.000Z" });
  assert.equal(r2.changed, false);
});

test("never throws: garbage session.json, missing file, unreadable transcript", async () => {
  const w = mkWorld();
  fs.writeFileSync(w.file, "{not json");
  assert.equal((await syncOnce({ file: w.file, cfg: w.cfg, runner: w.runner })).changed, false);
  assert.equal((await syncOnce({ file: path.join(w.root, "nope.json"), cfg: w.cfg, runner: w.runner })).changed, false);
  fs.writeFileSync(w.file, JSON.stringify({ session: SID }));
  fs.writeFileSync(w.transcript, "\u0000garbage\nnot json\n");
  assert.doesNotThrow(() => {});
  await syncOnce({ file: w.file, cfg: w.cfg, runner: w.runner });
});

test("findTranscript searches every project dir when the cwd slug no longer matches", () => {
  const w = mkWorld();
  assert.equal(findTranscript(w.cfg, SID, "/some/where/else"), w.transcript);
  assert.equal(findTranscript(w.cfg, "../etc/passwd", null), null);
});
