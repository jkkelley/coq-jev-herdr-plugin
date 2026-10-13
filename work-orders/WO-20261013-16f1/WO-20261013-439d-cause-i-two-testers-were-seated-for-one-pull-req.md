---
{
  "id": "WO-20261013-439d",
  "slug": "cause-i-two-testers-were-seated-for-one-pull-req",
  "title": "Cause i: two testers were seated for one pull request head; route.sh seats at most one gate seat per pull request and sha",
  "type": "bug",
  "status": "ready",
  "priority": "p1",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T16:37:26+00:00",
  "parent": "WO-20261013-16f1",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect P0 order 2026-10-13 (owner m-20261013162710557-e4nos: always a system loop), approved by the architect in the owner place (card C29); lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [
    "WO-20261013-b839",
    "WO-20261013-04b8"
  ],
  "files": [
    "factory/bin/route.sh",
    "factory/tests/cases/21-one-gate-per-head.test.sh"
  ]
}
---

# WO-20261013-439d - Cause i: two testers were seated for one pull request head; route.sh seats at most one gate seat per pull request and sha

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

Cause i (2026-10-13 15:37Z): PR 97 got a duplicate tester on the same head 2e223ae, doubling the test load.

## Scope

**In**

- factory/bin/route.sh: a seat request for a gate whose pull request and sha already have a live seat of that role is dropped with one note naming the live seat
- factory/tests/cases/21-one-gate-per-head.test.sh

**Out - non-goals**

- the route rows (WO-20261013-bed2, WO-20261013-612d)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* a second pr.opened for the same head seats no second tester; a new head seats one

## Test plan

```sh
make lint && make -C factory test, in Podman through the repository targets
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
