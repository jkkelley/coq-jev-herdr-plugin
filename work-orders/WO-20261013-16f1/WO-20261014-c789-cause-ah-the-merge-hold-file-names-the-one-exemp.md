---
{
  "id": "WO-20261014-c789",
  "slug": "cause-ah-the-merge-hold-file-names-the-one-exemp",
  "title": "Cause ah: the merge hold file names the one exempt fix ticket, line/bin/merge.sh honours it, and every merge path (hand or script) goes through merge.sh so the hold applies to all",
  "type": "bug",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-14",
  "updated": "2026-10-14",
  "created_at": "2026-10-14T00:03:46+00:00",
  "parent": "WO-20261013-16f1",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect order 23:47Z cause ah; approved by the architect in the owner place",
    "at": "2026-10-14"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [],
  "files": [
    "line/bin/merge.sh",
    "playbooks/merger.md",
    "line/tests/cases/merge-hold-exempt.test.sh"
  ]
}
---

# WO-20261014-c789 - Cause ah: the merge hold file names the one exempt fix ticket, line/bin/merge.sh honours it, and every merge path (hand or script) goes through merge.sh so the hold applies to all

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

Main was red from 23:3xZ (factory case 12-policy, PR 136's spec-author label equal to the worker's). merge.sh held the fix PR 167 on its own hold because the hold file had no exemption, so the fix was hand merged on an architect order; and PR 165 merged through the hold by hand, which was a defect.

## Scope

**In**

- line/bin/merge.sh: the hold file may name one exempt fix ticket; a PR for that ticket merges through the hold, any other PR is held
- line/bin/merge.sh and playbooks/merger.md: the merge path is merge.sh only; a hand gh pr merge during a hold is refused by the hand-merge fence
- line/tests/cases/merge-hold-exempt.test.sh: a hold naming ticket X merges X and holds Y

**Out - non-goals**

- the verify-main script and the hold's lift rule

## Degrees of freedom

- [free] [free] Hold file format (a ticket line or a JSON field)

## Acceptance criteria

- [ ] `AC-H1` *(human)* With a hold naming ticket X, merge.sh merges the PR for X and holds every other PR
- [ ] `AC-H2` *(human)* No path merges during a hold except through merge.sh

## Test plan

```sh
bash line/tests/cases/merge-hold-exempt.test.sh
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
