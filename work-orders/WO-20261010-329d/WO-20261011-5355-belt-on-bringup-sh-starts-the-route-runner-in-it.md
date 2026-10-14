---
{
  "id": "WO-20261011-5355",
  "slug": "belt-on-bringup-sh-starts-the-route-runner-in-it",
  "title": "Belt on: bringup.sh starts the route runner in its own pane before any seat and seat.sh refuses a seat while the belt is stopped",
  "type": "feature",
  "status": "draft",
  "priority": "p0",
  "created": "2026-10-11",
  "updated": "2026-10-13",
  "created_at": "2026-10-11T14:39:40+00:00",
  "parent": "WO-20261010-329d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": null,
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261011-38c7"
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

Narrowed by the duplicate audit (F8), 2026-10-13T23:55Z. The first half is built: herdr/bin/bringup.sh slots 2.2.2 and 2.2.3 start the route runner and the flow watch (breadcrumb at bringup.sh:80-85 names this ticket). What remains is the second half: herdr/bin/seat.sh has no check of the belt state file, so a seat comes up into a factory where records do not move.

## Scope

**In**

- herdr/bin/seat.sh --check and bring-up refuse when the belt state file is stale, naming the pane to start

**Out - non-goals**

- bringup.sh starting the route runner (built)
- an orchestrator agent seat (the orchestrator is the runner applying the table; roles/orchestrator.json stays for the day a model is needed in that position)
- NATS
- the scheduler's belt-held rule (SPEC-16); if that rule covers a stale belt, cancel this ticket instead

## Degrees of freedom

- [free] the stale threshold, as long as it is between 30 and 120 seconds and read from config

## Acceptance criteria

- [ ] `AC-H1` *(human)* with the runner pane killed, seat.sh --check fails naming the belt and bring-up of a worker refuses

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

## Outcome

_Written by `work-order done`. Empty until then._
