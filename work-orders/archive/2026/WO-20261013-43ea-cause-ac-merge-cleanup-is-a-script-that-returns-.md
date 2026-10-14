---
{
  "id": "WO-20261013-43ea",
  "slug": "cause-ac-merge-cleanup-is-a-script-that-returns-",
  "title": "Cause ac: merge cleanup is a script that returns a treehouse slot with treehouse return and never runs git worktree remove on a path under ~/.treehouse",
  "type": "bug",
  "status": "cancelled",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T22:23:22+00:00",
  "parent": "WO-20261013-16f1",
  "branch": null,
  "pr": null,
  "closed": "2026-10-13",
  "approval": {
    "via": "override",
    "reason": "architect ruling 22:25Z cause ac",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [],
  "files": [
    "line/bin/after-merge-clean.sh",
    "line/tests/cases/after-merge-clean.test.sh"
  ],
  "superseded_by": "WO-20261013-48f2"
}
---

# WO-20261013-43ea - Cause ac: merge cleanup is a script that returns a treehouse slot with treehouse return and never runs git worktree remove on a path under ~/.treehouse

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

The post-merge cleanup is done by hand by the acting orchestrator. At 22:17Z it ran git worktree remove --force on a treehouse slot path (PR 132, slot 3) and deleted a pool slot; treehouse has no verb to re-add it, so the pool shrank from 10 to 9. Hand cleanup is a defect to turn into a script (architect ruling 22:25Z).

## Scope

**In**

- line/bin/after-merge-clean.sh PR: deletes the PR's remote and local branch, removes its gate, start and pr worktrees under the cache worktrees root with git worktree remove, and for any worktree under ~/.treehouse it checks for a seat process and calls treehouse return --if-lease-holder TICKET, never git worktree remove; one line/tests case with a fake treehouse proving a slot path is never passed to git worktree remove

**Out - non-goals**

- No change to merge.sh or merge-watch.sh wiring; the script is run by the orchestrator until the after-merge route row calls it

## Degrees of freedom

- [free] Argument shape is the worker's; a dry-run flag is welcome

## Acceptance criteria

- [ ] `AC-H1` *(human)* AC-H1: the script returns a leased slot with treehouse return and never runs git worktree remove on a path under ~/.treehouse. AC-H2: a case with a fake treehouse proves AC-H1. AC-H3: make lint and the line suite exit 0

## Test plan

```sh
make lint && bash line/tests/run.sh
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

Cancelled `2026-10-13` - nothing shipped.

- reason: Duplicate audit F2, ruled 2026-10-13T23:55Z: the cleanup and slot-return half of WO-20261013-48f2 is the whole of this ticket; its safety criterion (never git worktree remove on a ~/.treehouse path, treehouse return --if-lease-holder, fake treehouse case) was added to WO-20261013-48f2 by note.
- superseded by: `WO-20261013-48f2`

No branch, no PR and no merge commit exist for this work order.

