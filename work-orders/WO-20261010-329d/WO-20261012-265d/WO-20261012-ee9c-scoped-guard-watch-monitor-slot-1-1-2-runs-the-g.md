---
{
  "id": "WO-20261012-ee9c",
  "slug": "scoped-guard-watch-monitor-slot-1-1-2-runs-the-g",
  "title": "Scoped guard watch: monitor slot 1.1.2 runs the guard only for live seats, each pane resolved to the Claude session running in it every tick",
  "type": "feature",
  "status": "in-progress",
  "priority": "p0",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T16:32:49+00:00",
  "parent": "WO-20261012-265d",
  "branch": "feat/scoped-guard-watch-monitor-slot-1-1-2-runs-the-g",
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "lavish is prohibited for Claude seats; owner answered card C4 on the bearings page 2026-10-12 16:32Z: cut all four",
    "at": "2026-10-12"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [
    "WO-20261012-898a"
  ]
}
---

# WO-20261012-ee9c - Scoped guard watch: monitor slot 1.1.2 runs the guard only for live seats, each pane resolved to the Claude session running in it every tick

## Contents

- Problem
- Scope
- Degrees of freedom
- Acceptance criteria
- Test plan
- Assumptions
- Open questions
- Notes
- Outcome

## Problem

compaction-guard watch --interval 15 (herdr/config/monitors.json:19-24) walks every host-wide binding (231 at 15:45Z, 115 from other projects) and memos any session bound to a pane, live or dead; on 2026-10-12 02:16Z that flooded the architect pane with about 189 GOV-100 memos and the watch has been off since, so stall recovery is off too. unfreeze.sh sessions_of (herdr/bin/unfreeze.sh:43-51) has the same flaw.

## Scope

**In**

- a repo script herdr/bin/guardwatch.sh in slot 1.1.2 replacing the bare guard watch
- each tick: live seats as unfreeze.sh lists them, pane to claude pid via herdr pane process-info, pid to sessionId via ~/.claude/sessions/<pid>.json, then compaction-guard watch --once --session <sid> for exactly those
- the same live-session filter in unfreeze.sh sessions_of
- seat.sh writes the resolved session into seat.json at seat up and when it changes, so recover.sh gets its per-seat --session

**Out - non-goals**

- any compaction-guard change
- a compact request (sibling ticket)

## Degrees of freedom

- [free] tick interval, as long as it comes from herdr/config, never hard-coded
- [free] script name, as long as monitors.json and the runbook name it

## Acceptance criteria

- [x] `AC-H1` *(human)* a Podman case with two bindings on one pane, one dead, gets exactly one memo, for the live session
  - observed `2026-10-12` herdr/tests/cases/17-guardwatch.test.sh, run as make -C herdr test from test pane wD3:pB7 (full suite: tests: 17 passed, 0 failed): three guard bindings on one worker pane (live session stub-3427 and dead s-dead-one, s-dead-two); one guardwatch.sh --once tick printed 'watched w2:p1 worker-wo-20261010-8777 stub-3427' and the guard stub log held exactly one line 'watch --once --session stub-3427'; no dead session was named.
- [x] `AC-H2` *(human)* a pane with no claude process is skipped with one line and no guard call
  - observed `2026-10-12` Same case 17: a plain shell pane named only by an exemption printed exactly one line 'skipped <pane> <pane> (no claude process in the pane)' and the guard call count stayed at 1 (the worker); with the worker's session file removed the tick printed 'skipped ... (claude has no session file yet)' and the guard call count was 0.
- [x] `AC-H3` *(human)* unfreeze.sh never releases a dead session's lease into a live seat's pane
  - observed `2026-10-12` herdr/tests/cases/06-unfreeze.test.sh: live session plus s-dead-one (compacting 900s) and s-dead-two (armed 900s) bound to the worker pane; one unfreeze.sh --all printed one 'released w2:p1 worker-wo-20261010-8777 (compacting 600s, lease 180s)' line, both dead sessions stayed compacting and armed, one note 100 written; with the live session idle no release line and no wake prompt. Mutation check: the same case against the previous unfreeze.sh printed 3 release lines for the pane and failed 6 assertions.
- [x] `AC-H4` *(human)* seat.json carries the resolved session id after seat up
  - observed `2026-10-12` Case 17 asserts, straight after seat.sh --ticket WO-20261010-8777 --role worker returns and before any guardwatch tick, that seat.json claude_session equals the session id in ~/.claude/sessions/<pid>.json of the pane's claude (stub-3427); passes in the full suite. Live read-only check on the stable herdr session: sl_pane_session wD3:pB5 printed this seat's own session id 5c6fa701-61b3-4ea2-86c6-7107b9a6fa68, wD3:p2 the architect's, wD3:pB7 (shell) nothing.
- [x] `AC-H5` *(human)* slot 1.1.2 runs guardwatch.sh from monitors.json and lh51y's done-when holds
  - observed `2026-10-12` herdr/config/monitors.json slot 1.1.2 command is ${repo}/herdr/bin/guardwatch.sh --watch; case 04-bringup-monitors passes: '1.1.2 compaction-guard watch - guard [..] in use' and its pane printed 'tick: N watched, M skipped, rc 0'. lh51y done-when (dead sessions registered to a live pane: that pane gets at most one memo, for the session running in it) is the AC-H1 case 17 result. docs/sops/SOP-0003 names guardwatch.sh; docs.sh verify ok. The slot on the live stable session restarts with the next bringup.sh or monitors.sh take guard.

## Test plan

```sh
make -C herdr test
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-12` Retro. Went well: the pane is the truth - herdr pane process-info plus the claude pid's own session file gave an exact live session with no change to the guard, and a mutation run of case 06 against the old unfreeze.sh (3 releases into one pane) proved the new assertions have teeth. Slowed down: the suite stub runs as 'bash .../stubs/claude', so the first matcher on process name missed it (fixed by also matching argv[1]); a poll loop over 120 s was moved to a harness background job by the tool, so poll in bursts. Left for later (not in this ticket): recover.sh can now scope compaction-guard recover per seat with --session read from seat.json claude_session (its step 7 breadcrumb rejected that only because the field did not exist); backlog item lh51y is not moved to done here; the live stable slot 1.1.2 picks up guardwatch.sh at the next bringup.sh or monitors.sh take guard, which is the architect's or monitor's call.

## Outcome

_Written by `work-order done`. Empty until then._
