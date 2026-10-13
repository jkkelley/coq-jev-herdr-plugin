---
{
  "id": "WO-20261013-0ad7",
  "slug": "before-seating-a-gate-seat-route-sh-and-seat-sh-",
  "title": "Before seating a gate seat, route.sh and seat.sh refuse when a seat of that role is live for the PR or that gate result already exists for the head sha (cause af)",
  "type": "bug",
  "status": "ready",
  "priority": "p1",
  "created": "2026-10-13",
  "updated": "2026-10-13",
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
  "depends_on": [],
  "blocks": [],
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

## Outcome

_Written by `work-order done`. Empty until then._
