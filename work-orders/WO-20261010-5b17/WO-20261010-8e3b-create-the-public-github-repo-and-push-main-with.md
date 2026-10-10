---
{
  "id": "WO-20261010-8e3b",
  "slug": "create-the-public-github-repo-and-push-main-with",
  "title": "Create the public GitHub repo and push main with branch protection",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-10",
  "updated": "2026-10-10",
  "created_at": "2026-10-10T19:25:30+00:00",
  "parent": "WO-20261010-5b17",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect: sure of it; owner 2026-10-10 UTC: approval is the architect's job, Lavish is prohibited for this project",
    "at": "2026-10-10"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": []
}
---

# WO-20261010-8e3b - Create the public GitHub repo and push main with branch protection

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

No remote exists; PRs cannot open

## Scope

**In**

- gh repo create, Apache-2.0 already in tree, protect main, push, set the work-order cleanup path

**Out - non-goals**

- README content

## Degrees of freedom

- [free] none

## Acceptance criteria

- [ ] `AC-H1` *(human)* git remote origin points at the public repo; a PR from a slot branch opens

## Test plan

```sh
gh pr create from feat/p0-foundation succeeds
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
