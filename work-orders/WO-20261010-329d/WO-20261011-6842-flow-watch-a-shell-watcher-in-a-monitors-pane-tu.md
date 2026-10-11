---
{
  "id": "WO-20261011-6842",
  "slug": "flow-watch-a-shell-watcher-in-a-monitors-pane-tu",
  "title": "Flow watch: a shell watcher in a monitors pane turns a stalled line into a 500 (gate record with no consumer, belt heartbeat stale, runner pane gone) and recover.sh restarts the belt",
  "type": "feature",
  "status": "in-progress",
  "priority": "p0",
  "created": "2026-10-11",
  "updated": "2026-10-11",
  "created_at": "2026-10-11T18:40:02+00:00",
  "parent": "WO-20261010-329d",
  "branch": "feat/flow-watch-a-shell-watcher-in-a-monitors-pane-tu",
  "pr": null,
  "closed": null,
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

- [ ] `AC-H1` *(human)* with a 201 on disk and no consumer record for stall_seconds, one 500 note to the monitor names the record; a second tick does not repeat it
- [ ] `AC-H2` *(human)* with the belt file stale, one 500 names the belt; recover.sh --check reports FAILED belt and --apply restarts the runner pane and reports fixed
- [ ] `AC-H3` *(human)* a tracked file with a conflict marker fails make lint naming the file
- [ ] `AC-H4` *(human)* bringup.sh --check lists runner and flow-watch panes ok; make -C factory test and make lint green

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

## Outcome

_Written by `work-order done`. Empty until then._
