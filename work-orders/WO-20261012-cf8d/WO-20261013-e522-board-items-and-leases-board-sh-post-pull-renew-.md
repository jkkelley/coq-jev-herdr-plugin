---
{
  "id": "WO-20261013-e522",
  "slug": "board-items-and-leases-board-sh-post-pull-renew-",
  "title": "Board items and leases: board.sh post, pull, renew, done and release, the item id is the record id, a lease has a deadline, a second pull exits 6, done moves the item to the done tree (SPEC-17 T01; K1 part 3 of 5)",
  "type": "feature",
  "status": "ready",
  "priority": "p1",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T03:17:23+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "owner 2026-10-13 03:00Z (record 57h60): one concern, at most 5 files, under about 300 lines; lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261013-d6e1"
  ],
  "blocks": [
    "WO-20261013-3796"
  ],
  "files": [
    "line/bin/board.sh",
    "line/tests/cases/board-lease*"
  ]
}
---

# WO-20261013-e522 - Board items and leases: board.sh post, pull, renew, done and release, the item id is the record id, a lease has a deadline, a second pull exits 6, done moves the item to the done tree (SPEC-17 T01; K1 part 3 of 5)

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

Split of WO-20261013-f268 (Roadmap K1 - Board) under the owner's size rule of 2026-10-13 03:00Z.

## Scope

**In**

- board.sh post, pull, renew, done, release: items are files under the state root, a lease is a field with a deadline, done is a move into the done tree named by the state-root rule
- case line/tests/cases/board-lease.sh (T01)

**Out - non-goals**

- sweep, digest and health (K1 part 4)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* an item posted to lane tester is pulled once by one holder, a second pull exits 6, done moves it to the done tree, and the item id equals the record id
- [ ] `AC-H2` *(human)* make lint and make -C line test pass in Podman

## Test plan

```sh
make lint && make -C line test, in Podman through the repository targets
```

## Assumptions

1. SPEC-16 does this job once the scheduler is active (owner 02:50Z, record lvvtd); this part is the interim

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
