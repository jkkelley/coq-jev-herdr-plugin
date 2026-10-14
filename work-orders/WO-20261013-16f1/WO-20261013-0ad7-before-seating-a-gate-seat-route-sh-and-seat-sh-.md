---
{
  "id": "WO-20261013-0ad7",
  "slug": "before-seating-a-gate-seat-route-sh-and-seat-sh-",
  "title": "Before seating a gate seat, route.sh and seat.sh refuse when a seat of that role is live for the PR or that gate result already exists for the head sha (cause af)",
  "type": "bug",
  "status": "ready",
  "priority": "p1",
  "created": "2026-10-13",
  "updated": "2026-10-14",
  "created_at": "2026-10-13T23:22:59+00:00",
  "parent": "WO-20261013-16f1",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect 23:24Z: duplicate gate seats seen on PR 157 and 158",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261013-e2c3",
    "WO-20261013-0bda"
  ],
  "blocks": [
    "WO-20261013-04b8",
    "WO-20261013-b839",
    "WO-20261013-bcba"
  ],
  "files": [
    "factory/bin/route.sh",
    "herdr/bin/seat.sh",
    "factory/tests/cases/gate-seat-dedup.test.sh"
  ]
}
---

# WO-20261013-0ad7 - Before seating a gate seat, route.sh and seat.sh refuse when a seat of that role is live for the PR or that gate result already exists for the head sha (cause af)

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

Cause p covered only the same seat name. On 2026-10-13 23:20Z PR 157 had two live reviewers (reviewer-review-pr-157-wo-2-dd90 and reviewer-wo-20261013-b6f3) and PR 158 got a tester seat although test.passed already existed on its head. Duplicate seats waste capacity and double-post results.

## Scope

**In**

- route.sh and seat.sh check, before seating a tester or reviewer for a PR: no live seat of that role for the PR, and no test.passed or review.passed record already on the head sha. A refusal is a record, not a silent skip. A herdr or factory case proves both refusals.

**Out - non-goals**

- Changing roles, gate content, or the belt tick.

## Degrees of freedom

- [free] Put the check in the one place both paths share.

## Acceptance criteria

- [ ] `AC-H1` *(human)* A second tester or reviewer seat for the same PR is refused while one is live. A seat for a gate whose result exists for the head sha is refused. A new head sha is seated normally. Tests cover all three.

## Test plan

```sh
factory or herdr case via suites.sh plan.
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-13` Duplicate audit ruling 2026-10-13T23:55Z (F1): WO-20261013-439d and WO-20261013-8c6a are cancelled as superseded by this ticket; their cases move here. Case 1, factory/tests/cases/21-one-gate-per-head.test.sh (route.sh half): a second pr.opened for the same head seats no second gate seat, the drop writes one note naming the live seat, and a new head seats one. Case 2, the seat.sh half in herdr/tests/cases (number past 36, because 33 on main is 33-down-leaves-no-process; the old name 33-seat-refuses-second-gate collides): a second seat for the same pr, sha and role exits 3 naming the first; a tester for a new sha and a reviewer for the same sha are still seated. Both cases are required, so AC-H1 is proved by the route.sh case and the seat.sh case together. Order: this ticket depends on WO-20261013-e2c3 (in flight on route.sh), not the reverse.

## Outcome

_Written by `work-order done`. Empty until then._
