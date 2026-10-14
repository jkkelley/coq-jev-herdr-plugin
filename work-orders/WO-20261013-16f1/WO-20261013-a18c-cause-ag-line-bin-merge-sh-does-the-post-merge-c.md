---
{
  "id": "WO-20261013-a18c",
  "slug": "cause-ag-line-bin-merge-sh-does-the-post-merge-c",
  "title": "Cause ag: line/bin/merge.sh does the post-merge cleanup itself without checking out main (git push origin --delete, git branch -D from a detached HEAD, treehouse return), and never calls work-order.sh cleanup inside a slot",
  "type": "bug",
  "status": "in-progress",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-14",
  "created_at": "2026-10-13T23:38:20+00:00",
  "parent": "WO-20261013-16f1",
  "branch": "feat/cause-ag-line-bin-merge-sh-does-the-post-merge-c",
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect order 23:36Z cause ag (record vn435); approved by the architect in the owner place",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [],
  "files": [
    "line/bin/merge.sh",
    "line/tests/cases/merge-cleanup.test.sh"
  ]
}
---

# WO-20261013-a18c - Cause ag: line/bin/merge.sh does the post-merge cleanup itself without checking out main (git push origin --delete, git branch -D from a detached HEAD, treehouse return), and never calls work-order.sh cleanup inside a slot

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

After PR 136 merged, the merger ran work-order.sh cleanup and it failed 'cannot check out main' because main is checked out in another worktree (record vn435), leaving the branch and slot for hand cleanup. Slots stay leased and the treehouse pool fills.

## Scope

**In**

- line/bin/merge.sh: after the squash merge, delete the remote branch (git push origin --delete), delete the local branch from a detached HEAD (git branch -D), and return the slot (treehouse return after the process check); never call work-order.sh cleanup in a slot
- line/tests/cases/merge-cleanup.test.sh: a merge while main is checked out in another worktree still removes the branch and returns the slot

**Out - non-goals**

- the verify-main step and the merge gate rules

## Degrees of freedom

- [free] [free] Order of the three cleanup steps

## Acceptance criteria

- [ ] `AC-H1` *(human)* A merge while main is checked out elsewhere deletes the remote and local branch and returns the slot

## Test plan

```sh
bash line/tests/cases/merge-cleanup.test.sh
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
