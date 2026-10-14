---
{
  "id": "WO-20261014-7f99",
  "slug": "r2-result-records-down-their-own-seat-through-th",
  "title": "R2 - Result records down their own seat through the route down key and patrol reports survivors as a defect",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-14",
  "updated": "2026-10-14",
  "created_at": "2026-10-14T00:39:12+00:00",
  "parent": "WO-20261013-16f1",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "Architect-approved design C29 2026-10-14T00:45Z",
    "at": "2026-10-14"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261014-d93a"
  ],
  "blocks": [],
  "files": [
    "factory/lib/route-down.sh",
    "factory/tests/cases/31-result-downs-seat.test.sh"
  ]
}
---

# WO-20261014-7f99 - R2 - Result records down their own seat through the route down key and patrol reports survivors as a defect

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

Seats that posted a result linger; the patrol and orchestrators down them by hand. Design: plans/2026/10/20261014004500-line-ops-are-code-design.md (in COQ_STATE), section Tickets. Owner 2026-10-14 00:42Z: no agent does a mechanical step.

## Scope

**In**

- route.sh down path, patrol check, tests: test.passed, review.passed, review.changes and pr.opened down their seat by the route down key; patrol reports a seat that outlived its result by 2 minutes as a defect record

**Out - non-goals**

- Each result record downs its seat; patrol posts a defect record for a survivor older than 2 minutes; tests prove both

## Degrees of freedom

- [free] Any shell structure that keeps the ladder: 3 retries, one clean rerun, then a record.

## Acceptance criteria

- [ ] `AC-H1` *(human)* Each result record downs its seat; patrol posts a defect record for a survivor older than 2 minutes; tests prove both

## Test plan

```sh
Test case with a stubbed seat.sh --down asserts each result record downs its seat; patrol case asserts the defect record; make lint.
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
