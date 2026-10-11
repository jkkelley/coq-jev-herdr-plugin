---
{
  "id": "WO-20261011-5355",
  "slug": "belt-on-bringup-sh-starts-the-route-runner-in-it",
  "title": "Belt on: bringup.sh starts the route runner in its own pane before any seat and seat.sh refuses a seat while the belt is stopped",
  "type": "feature",
  "status": "draft",
  "priority": "p0",
  "created": "2026-10-11",
  "updated": "2026-10-11",
  "created_at": "2026-10-11T14:39:40+00:00",
  "parent": "WO-20261010-329d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": null,
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261011-38c7",
    "WO-20261011-23df"
  ],
  "blocks": []
}
---

# WO-20261011-5355 - Belt on: bringup.sh starts the route runner in its own pane before any seat and seat.sh refuses a seat while the belt is stopped

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

Until the runner is part of bring-up the belt depends on someone starting it, and seats come up into a factory where records do not move (WFL-bringup is proposed, not real)

## Scope

**In**

- herdr/bin/bringup.sh starts factory/bin/route.sh in a labelled pane (TOOL - route runner) in the monitors grid after the monitor seat and before worker seats
- herdr/bin/seat.sh --check and bring-up refuse when the belt state file is stale, naming the pane to start
- WFL-bringup node to locked; RUN-bringup runbook updated; the board shows the belt running

**Out - non-goals**

- an orchestrator agent seat (the orchestrator is the runner applying the table; roles/orchestrator.json stays for the day a model is needed in that position)
- NATS

## Degrees of freedom

- [free] the stale threshold, as long as it is between 30 and 120 seconds and read from config

## Acceptance criteria

- [ ] `AC-H1` *(human)* bringup.sh brings the runner pane up and records seat.up for it; the board's belt turns green
- [ ] `AC-H2` *(human)* with the runner pane killed, seat.sh --check fails naming the belt and bring-up of a worker refuses
- [ ] `AC-H3` *(human)* a record written by event.sh on main wakes a real seat end to end with no human command between
- [ ] `AC-H4` *(human)* RUN-bringup names the runner step and WFL-bringup is locked with defined_in RUN-bringup

## Test plan

```sh
herdr/bin/bringup.sh --check herdr/bin/seat.sh --check <seat> # once with the runner up, once with it down events/bin/event.sh add --kind pr.opened --code 100 ... then watch the tester pane
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-11` Owner law 2026-10-11 15:34Z (graph DEC-system-runs-the-loop, on REQ-north-star): the system runs the loop, not agents. Notification sound, automated, deterministic; cleanup done by the system; no idle agents; greens visible from records. Every hand step in SOP-0001 (wake by prompt, down after record, salvage, cleanup) must be owned by the belt when this lands.

## Outcome

_Written by `work-order done`. Empty until then._
