---
{
  "id": "WO-20261013-cc5b",
  "slug": "cause-z-follow-up-1-seat-sh-passes-worktree-to-r",
  "title": "Cause z follow-up 1: seat.sh passes --worktree to roles/bin/brief.sh so the brief names the seat's worktree, and a tester's suites.sh plan is computed on that worktree's diff",
  "type": "bug",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T23:16:00+00:00",
  "parent": "WO-20261013-16f1",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect order 23:15Z (174aa): cause z follow-ups; approved by the architect in the owner place",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261013-7af7"
  ],
  "blocks": []
}
---

# WO-20261013-cc5b - Cause z follow-up 1: seat.sh passes --worktree to roles/bin/brief.sh so the brief names the seat's worktree, and a tester's suites.sh plan is computed on that worktree's diff

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

WO-20261013-b6f3 (PR 157) makes the tester prompt carry the suites.sh plan output, but seat.sh calls brief.sh without the seat's worktree, so the plan cannot be computed on the PR diff of the seat's own worktree.

## Scope

**In**

- herdr/bin/seat.sh: pass --worktree <seat worktree> to roles/bin/brief.sh
- herdr/tests/cases/37-brief-gets-worktree.test.sh: the brief printed for a seat started in a second worktree names that worktree

**Out - non-goals**

- the suites.sh plan content (WO-20261013-b6f3)

## Degrees of freedom

- [free] [free] Whether the flag or an env var carries the path

## Acceptance criteria

- [ ] `AC-H1` *(human)* A seat's brief names the seat's own worktree

## Test plan

```sh
bash herdr/tests/cases/37-brief-gets-worktree.test.sh
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
