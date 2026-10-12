---
{
  "id": "WO-20261011-6842",
  "slug": "flow-watch-a-shell-watcher-in-a-monitors-pane-tu",
  "title": "Flow watch: a shell watcher in a monitors pane turns a stalled line into a 500 (gate record with no consumer, belt heartbeat stale, runner pane gone) and recover.sh restarts the belt",
  "type": "feature",
  "status": "done",
  "priority": "p0",
  "created": "2026-10-11",
  "updated": "2026-10-11",
  "created_at": "2026-10-11T18:40:02+00:00",
  "parent": "WO-20261010-329d",
  "branch": "feat/flow-watch-a-shell-watcher-in-a-monitors-pane-tu",
  "pr": 19,
  "closed": "2026-10-11",
  "approval": {
    "via": "override",
    "reason": "Claude seat; Lavish is prohibited for Claude seats by the owner hard rule; owner order 18:38Z get the system operational",
    "at": "2026-10-11"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": []
}
---

# WO-20261011-6842 - Flow watch: a shell watcher in a monitors pane turns a stalled line into a 500 (gate record with no consumer, belt heartbeat stale, runner pane gone) and recover.sh restarts the belt

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

On 2026-10-11 the line sat still from 18:01Z to 18:23Z with every gate record posted and no seat picking them up, and nothing in the system said so: the monitor seat has no wake source, bringup and recover check health not flow, and the architect's own record watch had died silently. A stalled line looked identical to a quiet one. DEC-system-runs-the-loop and DEC-automate-recover-retry require the system to see it and act, not an agent.

## Scope

**In**

- factory/bin/flow.sh: one tick reads the event log and the ledger, and writes a 500 note to the monitor for a gate record (201, 422, 409, 200, pr.opened) older than stall_seconds with no consumer record, for a belt file older than stale_seconds, and for a runner pane that is not running; a run verb ticks every poll_seconds in a labelled monitors pane
- recover.sh gains a belt node: runner pane alive and belt fresh, else restart through monitors.sh take and record fixed; bringup.sh gains the flow watch pane after the runner
- lint gains a check that fails on a merge conflict marker in any tracked text file
- factory/config/flow.json with schema (thresholds, pane labels, consumer map per kind); RUNBOOK section; suite cases

**Out - non-goals**

- the monitor seat's playbook beyond reading the new 500s
- owner notification wording (the monitor seat already does herdr notification show on a 5xx)

## Degrees of freedom

- [free] consumer map shape, as long as it is config and the watcher reads no prose
- [free] poll and stall thresholds, as long as both are config and the sum keeps a stall visible on the board within two minutes

## Acceptance criteria

- [x] `AC-H1` *(human)* with a 201 on disk and no consumer record for stall_seconds, one 500 note to the monitor names the record; a second tick does not repeat it
  - observed `2026-10-11` Case 09-flow-gate (make -C factory test, 10 passed from the test pane): a test.passed 201 backdated 100s with no review record writes one 500 note, seat flow-watch, kind note, to monitor, on the ticket, text 'stall: test.passed 201 <id> has no reviewer record after 90s'; two more ticks leave the count at one; a record 10s old, a taken gate and a consumer on another ticket behave as specified; all 7 gates rows of flow.json stall the same way; status prints the stall and exits 1 with no note written; poll 30 + stall 100 is refused with exit 3.
- [x] `AC-H2` *(human)* with the belt file stale, one 500 names the belt; recover.sh --check reports FAILED belt and --apply restarts the runner pane and reports fixed
  - observed `2026-10-11` Case 10-flow-belt (factory) and case 13-recover-belt (herdr, real route.sh run in its monitors pane; make -C herdr test, 13 passed): a belt 61s old writes one 500 'stall: belt stopped (last touched 6Ns ago, stale after 60s)', not repeated, and noted again after a recover; recover.sh --check prints 'FAILED belt (belt stopped (last touched 101s ago, stale after 60s))' and exit 1 with no event written; --apply prints 'fixed belt (runner restarted through monitors.sh take runner ...)', the runner is in the same pane, route.sh status exits 0, one closing note 100 says 1 repaired; with the runner pane closed --apply draws the grid and restarts the runner.
- [x] `AC-H3` *(human)* a tracked file with a conflict marker fails make lint naming the file
  - observed `2026-10-11` Case 08-conflict-lint (factory, passed): lint/check-conflict-markers.sh, called by lint/lint.sh as 'conflicts: no merge markers', exits 3 and prints 'docs/guide.md:2: conflict marker <<<<<<<' and ':6: ... >>>>>>>' for a file with a column 0 marker; a clean tree, prose quoting a marker mid-line or indented, node_modules, .claude and binary files pass; make lint on this branch prints ok for the new step (rc 0 in each make step).
- [x] `AC-H4` *(human)* bringup.sh --check lists runner and flow-watch panes ok; make -C factory test and make lint green
  - observed `2026-10-11` Case 04-bringup-monitors (herdr, passed): bringup fixes pane-board, pane-runner, pane-flow in order, status shows '2.2.2 route runner - runner' and '2.2.3 flow watch - flow' in use, 9 note 100 records, and bringup --check lists 'ok pane-runner ok pane-flow'. make -C factory test: 10 passed, 0 failed. make -C herdr test: 13 passed, 0 failed. make lint ran green inside every make step of this branch (rc 0).

## Test plan

```sh
make -C factory test
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-11` Retro 2026-10-11: all four criteria evidenced from the suites (factory 10 passed, herdr 13 passed, lint green in every make step); nothing was started in the live stable session, so recover.sh --check there will print FAILED belt until bringup.sh plugs in the runner and flow panes. Findings. (1) WO-20261011-5355 - Belt on: bringup.sh starts the route runner in its own pane before any seat and seat.sh refuses a seat while the belt is stopped: the runner pane now exists as monitors slot 2.2.2, so 5355 is left with the seat.sh refusal while the belt is stopped. (2) Graph is denied to workers, handed to the architect: RUN-recover gains a belt node as step 5 (seats, guard and tickets renumber to 6, 7, 8), WFL-bringup gains pane-runner and pane-flow, and a flow watch component (factory/bin/flow.sh, factory/config/flow.json, RUNBOOK section in factory/RUNBOOK.md) has no node yet. (3) The test pane is shared and a command queues behind other seats' suites for 10 to 25 minutes; make step also outruns the harness 120s timeout, so run it through testpane.sh with output to a file. (4) The herdr test world now runs the runner and flow slots as sleep loops and sets belt.status to true, because a live runner writes 500 notes that break the 'no event was written' counts; case 13 puts the real commands back. (5) Gate consumers are config (flow.json gates), the stall is judged by the record's at, and the first start judges only records after it.

## Outcome

_Written by `work-order done`. Empty until then._
