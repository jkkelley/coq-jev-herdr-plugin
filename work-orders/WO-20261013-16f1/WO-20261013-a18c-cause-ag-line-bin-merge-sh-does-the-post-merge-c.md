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

- [x] `AC-H1` *(human)* A merge while main is checked out elsewhere deletes the remote and local branch and returns the slot
  - observed `2026-10-14` bash line/tests/cases/merge-cleanup.test.sh from test pane wD3:p1S0: pass, 65 checks. main checked out in another worktree, merge.sh run from a detached worktree: remote and local branch deleted, treehouse return PATH --if-lease-holder TICKET --force run once, slot free, main and HEADs unmoved, work-order.sh never called. make lint 0; make -C line test: 16 passed, 0 failed.

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

- `2026-10-14` Retro: also built the architect rulings 00:30Z (foreign process in the slot: no return, slot left leased, one blocked 423 naming it) and 00:34Z (cwd-in-slot claude bg-spare and bg-pty-host are reaped, not foreign). Lesson: the old cleanup was a checkout of main, which fails whenever another worktree holds main; none of the three new steps needs a checkout. Open edge: git branch -D refuses a branch checked out in a worktree; the slot is returned before it so the slot no longer holds it, and a failure is named in the 423.
- `2026-10-14` Architect ruling 00:30Z added to the build: merge cleanup refuses treehouse return while processes not belonging to the downed seat remain in the slot; it posts a note naming them and leaves the slot leased. Built in line/bin/merge.sh with a case in line/tests/cases/merge-cleanup.test.sh. Order: remote branch, slot, local branch.

## Outcome

_Written by `work-order done`. Empty until then._
