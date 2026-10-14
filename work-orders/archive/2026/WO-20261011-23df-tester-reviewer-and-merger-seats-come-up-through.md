---
{
  "id": "WO-20261011-23df",
  "slug": "tester-reviewer-and-merger-seats-come-up-through",
  "title": "Tester, reviewer and merger seats come up through seat.sh and each writes one record on a real PR",
  "type": "feature",
  "status": "cancelled",
  "priority": "p0",
  "created": "2026-10-11",
  "updated": "2026-10-13",
  "created_at": "2026-10-11T14:39:38+00:00",
  "parent": "WO-20261010-329d",
  "branch": "feat/tester-reviewer-and-merger-seats-come-up-through",
  "pr": null,
  "closed": "2026-10-13",
  "approval": {
    "via": "override",
    "reason": "Claude seat; Lavish is prohibited for Claude seats by the owner hard rule, decisions recorded in the ticket note",
    "at": "2026-10-11"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [],
  "superseded_by": null
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

- [ ] `AC-H1` *(human)* tester seat up, runs the PR's test plan, writes exactly one test record with repro and observation
- [ ] `AC-H2` *(human)* reviewer seat up, verifies the evidence against the acceptance criteria, writes exactly one review record
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

Cancelled `2026-10-13` - nothing shipped.

- reason: Duplicate audit F8, ruled 2026-10-13T23:55Z: PR 15 closed unmerged on 2026-10-12T22:17:15Z; seat.sh already seats tester, reviewer and merger seats today, so the scope is overtaken.

No branch, no PR and no merge commit exist for this work order.

