---
{
  "id": "WO-20261013-7000",
  "slug": "cause-x-claims-sh-start-sees-a-ticket-that-is-li",
  "title": "Cause x: claims.sh start sees a ticket that is live in a treehouse slot, so two starts that overlap on seat.sh are refused",
  "type": "bug",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T20:19:53+00:00",
  "parent": "WO-20261013-16f1",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect orders 20:31Z (cause w stale containers, cause x claims blind to slots); approved by the architect in the owner place",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [],
  "files": [
    "factory/bin/claims.sh",
    "factory/tests/cases/24-claims-sees-slots.test.sh"
  ]
}
---

# WO-20261013-7000 - Cause x: claims.sh start sees a ticket that is live in a treehouse slot, so two starts that overlap on seat.sh are refused

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

Reported by spec-author-d127: claims.sh start checks open PRs and in-progress tickets but not a ticket live in a treehouse slot with no PR yet, so two starts that both name herdr/bin/seat.sh were both allowed and overlapped.

## Scope

**In**

- factory/bin/claims.sh: start refuses a file overlap with any ticket whose lease is held in a treehouse slot (read from treehouse status), naming the holder
- factory/tests/cases/24-claims-sees-slots.test.sh: a stub treehouse status with a leased ticket makes an overlapping start exit 3

**Out - non-goals**

- PR overlap logic (the behaviour of WO-20261012-0677 - No file is ever touched by two open PRs stays unchanged)

## Degrees of freedom

- [free] How treehouse status is read (--json if available)

## Acceptance criteria

- [ ] `AC-H1` *(human)* An overlapping start with a slot-leased ticket exits 3 naming the holder
- [ ] `AC-H2` *(human)* A non-overlapping start is unaffected

## Test plan

```sh
bash factory/tests/cases/24-claims-sees-slots.test.sh
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
