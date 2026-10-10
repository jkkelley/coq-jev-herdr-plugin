---
{
  "id": "WO-20261010-4c71",
  "slug": "per-package-ci-github-actions-matrix-semver-tags",
  "title": "Per-package CI: GitHub Actions matrix, semver tags per package, ghcr push via kaniko",
  "type": "feature",
  "status": "draft",
  "priority": "p1",
  "created": "2026-10-10",
  "updated": "2026-10-10",
  "created_at": "2026-10-10T19:25:27+00:00",
  "parent": "WO-20261010-e1e5",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": null,
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": []
}
---

# WO-20261010-4c71 - Per-package CI: GitHub Actions matrix, semver tags per package, ghcr push via kaniko

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

Each package needs its own pipeline and version (DEC-per-package-cicd-semver)

## Scope

**In**

- .github/workflows per package path filter, tags <package>/vX.Y.Z, kaniko build and push to ghcr for images; Jenkins shared lib hook if a job needs the cluster

**Out - non-goals**

- security stages

## Degrees of freedom

- [free] Actions vs Jenkins per package

## Acceptance criteria

- [ ] `AC-H1` *(human)* a change under terminals/variant-a runs only that package's workflow and tags it

## Test plan

```sh
workflow run on a PR; act or a dry run documented in SPEC-12
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
