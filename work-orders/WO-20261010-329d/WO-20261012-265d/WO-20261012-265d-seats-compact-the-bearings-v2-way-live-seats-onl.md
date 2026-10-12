---
{
  "id": "WO-20261012-265d",
  "slug": "seats-compact-the-bearings-v2-way-live-seats-onl",
  "title": "Seats compact the bearings-v2 way: live seats only, on request after each step, from their own checkpoint, at their role's threshold",
  "type": "feature",
  "status": "ready",
  "priority": "p1",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T16:32:47+00:00",
  "parent": "WO-20261010-329d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "lavish is prohibited for Claude seats; owner answered card C4 on the bearings page 2026-10-12 16:32Z: cut all four",
    "at": "2026-10-12"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": []
}
---

# WO-20261012-265d - Seats compact the bearings-v2 way: live seats only, on request after each step, from their own checkpoint, at their role's threshold

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

Every coq seat compacts only at the guard's 30 percent default, binds with schema null, resumes from a generic guard checkpoint, and the host-wide guard watch memoed dead sessions into the architect pane (02:16Z flood, backlog lh51y). Research compared local-k8s-docs and bearings-v2, which already do this, and found four fixes.

## Scope

**In**

- the four children A1 to A4 of the compaction research report

**Out - non-goals**

- changes to compaction-guard itself (portable rule, until the north star)
- the owner's global SessionStart hooks

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* all four children are done and verified on main

## Test plan

```sh
make -C herdr test
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
