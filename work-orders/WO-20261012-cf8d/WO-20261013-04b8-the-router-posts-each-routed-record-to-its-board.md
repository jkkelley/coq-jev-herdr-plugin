---
{
  "id": "WO-20261013-04b8",
  "slug": "the-router-posts-each-routed-record-to-its-board",
  "title": "The router posts each routed record to its board lane and prompts the owning seat once, held while that seat is busy; the wake line with the record id is retired (K7 part 3 of 4)",
  "type": "feature",
  "status": "ready",
  "priority": "p1",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T03:29:36+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "owner 2026-10-13 03:00Z (record 57h60) size rule and 02:50Z (lvvtd) SPEC-16 is the engine; lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261012-0229",
    "WO-20261013-f268"
  ],
  "blocks": [],
  "files": [
    "factory/bin/route.sh",
    "factory/tests/cases/*route-board*"
  ]
}
---

# WO-20261013-04b8 - The router posts each routed record to its board lane and prompts the owning seat once, held while that seat is busy; the wake line with the record id is retired (K7 part 3 of 4)

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

Split of WO-20261013-70c4 (Roadmap K7) under the owner's size rule of 2026-10-13 03:00Z, in the delivery model of 02:41Z (one prompt per status change to the item's owner).

## Scope

**In**

- factory/bin/route.sh posts through line/bin/board.sh post and sends one herdr agent prompt to the owning seat; case factory/tests/cases/*route-board*

**Out - non-goals**

- the architect digest (dropped: the delivery model replaces it)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* fifty records through the router give at most one prompt per owning seat per status change, none to a busy seat until it is idle
- [ ] `AC-H2` *(human)* make lint and make -C factory test pass in Podman

## Test plan

```sh
make lint && make -C factory test, in Podman through the repository targets
```

## Assumptions

1. interim until SPEC-16.B and C are active (owner 02:50Z)

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
