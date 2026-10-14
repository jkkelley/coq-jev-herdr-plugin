---
{
  "id": "WO-20261013-0bda",
  "slug": "cause-h-a-stale-queued-seat-down-killed-a-freshl",
  "title": "Cause h: a stale queued seat down killed a freshly seated seat of the same name; a down names the seat's up record and is refused when a newer seat is up",
  "type": "bug",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-14",
  "created_at": "2026-10-13T16:37:22+00:00",
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
    "WO-20261013-a0e2",
    "WO-20261013-7af7"
  ],
  "blocks": [
    "WO-20261013-496d",
    "WO-20261012-6f13",
    "WO-20261013-0ad7"
  ],
  "files": [
    "herdr/bin/seat.sh",
    "herdr/tests/cases/34-stale-down-refused.test.sh"
  ]
}
---

# WO-20261013-0bda - Cause h: a stale queued seat down killed a freshly seated seat of the same name; a down names the seat's up record and is refused when a newer seat is up

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

Cause h (ruling gl8yx, 2026-10-13): a --down queued for an old K5 tester ran after a fresh tester of the same name was seated and killed it.

## Scope

**In**

- herdr/bin/seat.sh --down NAME --up-record ID: refused with exit 3 and a note when the live seat's up record is newer; the belt passes the id it saw
- herdr/tests/cases/34-stale-down-refused.test.sh

**Out - non-goals**

- the kill itself (cause g)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* a down naming an older up record leaves the newer seat running and posts one note; a matching down works

## Test plan

```sh
make lint && make -C herdr test, in Podman through the repository targets
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
