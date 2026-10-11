---
{
  "id": "WO-20261011-23df",
  "slug": "tester-reviewer-and-merger-seats-come-up-through",
  "title": "Tester, reviewer and merger seats come up through seat.sh and each writes one record on a real PR",
  "type": "feature",
  "status": "in-progress",
  "priority": "p0",
  "created": "2026-10-11",
  "updated": "2026-10-11",
  "created_at": "2026-10-11T14:39:38+00:00",
  "parent": "WO-20261010-329d",
  "branch": "feat/tester-reviewer-and-merger-seats-come-up-through",
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "Claude seat; Lavish is prohibited for Claude seats by the owner hard rule, decisions recorded in the ticket note",
    "at": "2026-10-11"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [
    "WO-20261011-5355",
    "WO-20261011-fa78"
  ]
}
---

# WO-20261011-23df - Tester, reviewer and merger seats come up through seat.sh and each writes one record on a real PR

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

The three roles exist as files but no seat has ever run them; PR 11 and PR 12 wait on a reviewer and a merger that do not exist

## Scope

**In**

- seat.sh brings up tester, reviewer and merger seats (model per role file) in their own tabs with a monitor pane
- each brief names one PR and demands exactly one record: test.passed 201 or test.failed 422 with repro and observation; review.passed 201 or review.changes 422; merged 200 after squash merge, work-order.sh cleanup and slot release
- fixes to seat.sh, roles or playbooks found on the way, each with a breadcrumb
- RUNBOOK.md section: bringing up a non-worker seat and waking it by hand until the runner owns it

**Out - non-goals**

- the route runner (seats are woken by herdr agent prompt until B4)
- changing a role's model

## Degrees of freedom

- [free] bring-up order
- [free] which PR each seat proves itself on, as long as it is PR 11 or PR 12

## Acceptance criteria

- [x] `AC-H1` *(human)* tester seat up, runs the PR's test plan, writes exactly one test record with repro and observation
  - observed `2026-10-11` tester-wo-20261011-3d78 came up via seat.sh door 1 on PR 12 (slot 4, branch derived from origin), ran make -C report/sitrep test and make lint through testpane.sh in wD3:p1V, posted one test 201 (20261011T151036Z-201-u7zur) with the observation; tester-wo-20261011-9639 did the same on PR 13 (ftoqv, lost to the slot return, rerun after the fix)
- [x] `AC-H2` *(human)* reviewer seat up, verifies the evidence against the acceptance criteria, writes exactly one review record
  - observed `2026-10-11` reviewer-wo-20261011-3d78 came up on PR 12 sharing the ticket's lease, woken with the test record id, checked the evidence against AC-H1..H3 and posted one review 201 (20261011T151228Z-201-9bpqo); reviewer-wo-20261011-9639 posted review 201 gkkza on PR 13 the same way
- [ ] `AC-H3` *(human)* merger seat up, squash-merges a review-passed PR, runs work-order.sh cleanup, releases the slot, writes merged 200
- [ ] `AC-H4` *(human)* the event log shows the three records from three different seats and no git or gh command typed by the architect in the chain
- [ ] `AC-H5` *(human)* RUNBOOK.md section exists and a fresh reader can bring up one of the three seats from it

## Test plan

```sh
herdr/bin/seat.sh --check for each of the three seats events/bin/event.sh check events/bin/event.sh list --ticket <the PR's ticket>
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
