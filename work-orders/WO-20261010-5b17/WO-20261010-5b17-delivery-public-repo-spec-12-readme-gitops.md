---
{
  "id": "WO-20261010-5b17",
  "slug": "delivery-public-repo-spec-12-readme-gitops",
  "title": "Delivery: public repo, SPEC-12, README, gitops",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-10",
  "updated": "2026-10-10",
  "created_at": "2026-10-10T19:25:29+00:00",
  "parent": null,
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

# WO-20261010-5b17 - Delivery: public repo, SPEC-12, README, gitops

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

The monorepo must be public under Apache-2.0 with a README humans want to read and a gitops path for anything on the cluster

## Scope

**In**

- GitHub repo, branch protection, SPEC-12 delivery, README, Helm chart skeleton and Argo app for the SITREP server

**Out - non-goals**

- security stages

## Degrees of freedom

- [free] README design

## Acceptance criteria

- [ ] `AC-H1` *(human)* repo public, main protected, first PR merged through CI

## Test plan

```sh
make lint on the first PR
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
