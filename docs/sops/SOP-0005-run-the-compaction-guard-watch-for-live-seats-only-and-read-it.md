# SOP-0005: Run the compaction-guard watch for live seats only and read it

## Contents

- Purpose
- When to run this
- Steps
- Verification
- GOOD and NEVER

Diataxis mode: **how-to**.
Last reviewed: 2026-10-12.

## Purpose

The guard watch of monitor slot 1.1.2 acts on the one Claude session running in each live seat pane, never on every session the guard ever bound to a pane (WO-20261012-ee9c - Scoped guard watch: monitor slot 1.1.2 runs the guard only for live seats, each pane resolved to the Claude session running in it every tick). On 2026-10-12 at 02:16Z the bare watch typed about 189 GOV-100 memos into the architect pane, one per dead session, and was switched off, which also switched off stall recovery (backlog lh51y). Portable: herdr/bin/guardwatch.sh and the keys in herdr/config/herdr.json carry the behaviour.

## When to run this

The guard watch pane (slot 1.1.2) is read, restarted or suspected of memoing a pane twice, a seat is brought up and its claude_session is wanted, unfreeze.sh woke a seat for a session that was not its own, or the factory is set up on another repo.

## Steps

1. Nothing to start by hand: monitor slot 1.1.2 (`herdr/config/monitors.json`) runs `herdr/bin/guardwatch.sh --watch`, brought up with the grid by `herdr/bin/bringup.sh`.
   The tick interval is `guard_watch_interval_seconds` in `herdr/config/herdr.json`, never a literal in the script.
2. Each tick lists the panes the watchers govern (`sl_guard_targets` in `herdr/bin/seat-lib.sh`): every open seat record's pane, then the hand-started panes `herdr/config/exemptions.json` names, each once.
3. For each pane it asks herdr which claude process is in the foreground (`herdr pane process-info --pane <id>`), reads that pid's `<claude_sessions_dir>/<pid>.json` (`sessionId`), and runs `compaction-guard watch --once --session <sessionId>` for exactly that session.
   A session the guard has bound to the same pane in the past, live or dead, is never named, so it is never sent a memo.
4. A pane with no claude process prints `skipped <pane> <name> (no claude process in the pane)` and the guard is not called.
   A claude that has not written its session file yet prints `skipped ... (claude has no session file yet)` and is picked up on the next tick.
5. The resolved session is written to the seat's `seat.json` as `claude_session` whenever it differs (`seat.sh` also writes it once the agent is up, waiting at most `session_wait_seconds`), so `recover.sh` and the operator read it off the record.
6. `herdr/bin/unfreeze.sh` uses the same resolution: `sessions_of <pane>` returns only the session running in the pane, so a dead session still in phase armed or compacting is never released, and the seat is never woken for it.
7. Read the pane of slot 1.1.2: one summary line per tick (`<UTC> tick: N watched, M skipped, rc R`), then one line per skipped or failed pane.
   Run one tick by hand from a tool pane with `herdr/bin/guardwatch.sh --once`.
8. Restart it with `herdr/bin/monitors.sh take guard guard -- '<repo>/herdr/bin/guardwatch.sh --watch'` (what `bringup.sh` and `recover.sh` do), never by starting `compaction-guard watch` on its own: that walks every binding on the host and is the 2026-10-12 02:16Z flood (backlog lh51y).

## Verification

A step that cannot be verified is a wish.
Record what the successful run actually printed.

Observed 2026-10-12 against a headless scratch herdr (not the live `stable` session), run as `make -C herdr test` from the seat's test pane, which finished `tests: 17 passed, 0 failed`:

- `herdr/tests/cases/17-guardwatch.test.sh`: three guard bindings on one worker pane (the live session `stub-<pid>` and two dead ones) gave one tick that printed `watched <pane> worker-wo-20261010-8777 stub-<pid>`, and the guard stub's log held exactly one line, `watch --once --session stub-<pid>`; neither dead session was named.
  A plain shell pane that only an exemption names printed `skipped <pane> <pane> (no claude process in the pane)` once and the guard was called for the worker only.
  `seat.json` carried `claude_session` straight after `seat.sh` brought the seat up, and a stale value written into it was replaced by the next tick.
- `herdr/tests/cases/06-unfreeze.test.sh`: with the live session and two dead ones all frozen on the worker's pane, one `unfreeze.sh --all` printed a single `released` line for that pane and left both dead sessions in phase compacting and armed.
  The same case against the previous `unfreeze.sh` printed three release lines for the pane and failed six assertions.
- `herdr/tests/cases/04-bringup-monitors.test.sh`: slot 1.1.2 reads `1.1.2 compaction-guard watch - guard  [..]  in use` and its pane printed `tick: N watched, M skipped, rc 0`.

## GOOD and NEVER

GOOD: a pane that hosted two hundred sessions gets one memo, for the session its claude process reports.
GOOD: a seat's `seat.json` names its session, and `guardwatch.sh` corrects it when the seat is resumed in place.
NEVER: `compaction-guard watch` started bare in any pane, or a script that walks `$COMPACTION_GUARD_STATE/sessions/*/binding.json` and trusts its `pane`.
NEVER: a tick interval or a sessions directory written into a script; both are keys in `herdr/config/herdr.json`.
