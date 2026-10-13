---
{
  "id": "WO-20261013-32bd",
  "slug": "cause-q-the-starter-leaves-the-main-checkout-dir",
  "title": "Cause q: the starter leaves the main checkout dirty; bin/wo-start.sh commits the in-progress frontmatter on the ticket branch and leaves the checkout it ran from clean",
  "type": "bug",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T19:06:14+00:00",
  "parent": "WO-20261013-16f1",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect P0 order 19:08Z, system loop: cause q; approved by the architect in the owner place",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [],
  "files": [
    "bin/wo-start.sh",
    "factory/tests/cases/22-wo-start-leaves-checkout-clean.test.sh"
  ]
}
---

# WO-20261013-32bd - Cause q: the starter leaves the main checkout dirty; bin/wo-start.sh commits the in-progress frontmatter on the ticket branch and leaves the checkout it ran from clean

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

Starting a ticket (bin/wo-start.sh, work-order start) edits the ticket frontmatter to in-progress in the checkout it runs from and does not commit it on the ticket branch, so the main checkout shows residue (fe37 and 44b3 seen at 19:08Z) and the next start or pull trips on it.

## Scope

**In**

- factory/tests/cases/22-wo-start-leaves-checkout-clean.test.sh (the factory suite; replaces the generic test-case line above)

**Out - non-goals**

- herdr/bin/seat.sh and the branch-null refusal (cause f, WO-20261013-a0e2)

## Degrees of freedom

- [free] Where the new test case lives; commit message wording

## Acceptance criteria

- [ ] `AC-H1` *(human)* After bin/wo-start.sh the checkout it ran from has no modified or untracked file
- [ ] `AC-H2` *(human)* The ticket branch has one commit that carries the in-progress frontmatter

## Test plan

```sh
Scratch-repo case: run wo-start on a ready ticket, assert git status --porcelain is empty in the starting checkout and git log on the branch shows the frontmatter commit
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
