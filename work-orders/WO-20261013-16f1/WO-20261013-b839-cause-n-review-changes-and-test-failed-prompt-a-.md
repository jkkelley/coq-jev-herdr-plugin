---
{
  "id": "WO-20261013-b839",
  "slug": "cause-n-review-changes-and-test-failed-prompt-a-",
  "title": "Cause n: review.changes and test.failed prompt a worker that was already downed; the route seats a fresh worker for the ticket",
  "type": "bug",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-14",
  "created_at": "2026-10-13T16:37:41+00:00",
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
  "depends_on": [
    "WO-20261013-7a76",
    "WO-20261013-0ad7"
  ],
  "blocks": [
    "WO-20261013-bed2"
  ],
  "files": [
    "factory/config/routes.json",
    "factory/tests/cases/23-changes-seat-fresh.test.sh"
  ]
}
---

# WO-20261013-b839 - Cause n: review.changes and test.failed prompt a worker that was already downed; the route seats a fresh worker for the ticket

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

Cause n (record 8pj4r): every seat leaves after its output (record 3h4ih), so a review.changes or test.failed woke nobody and the ticket sat.

## Scope

**In**

- factory/config/routes.json: review.changes 422 and test.failed 422 rows seat a fresh worker on the ticket's branch with the record id in its brief instead of waking one; factory/tests/cases/23-changes-seat-fresh.test.sh

**Out - non-goals**

- route.sh's actions beyond seat (WO-20261013-04b8)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* a review.changes for a ticket with no live worker seats one with the record in its brief; a live worker is prompted once

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

- `2026-10-14` Duplicate audit ruling 2026-10-13T23:55Z (F4, F1): first in the routes.json order (WO-20261013-b839, WO-20261013-bed2, WO-20261013-612d, WO-20261013-3eac). Its dependency on the cancelled WO-20261013-439d now points at WO-20261013-0ad7.

## Outcome

_Written by `work-order done`. Empty until then._
