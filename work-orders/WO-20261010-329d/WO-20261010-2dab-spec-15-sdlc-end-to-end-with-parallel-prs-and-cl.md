---
{
  "id": "WO-20261010-2dab",
  "slug": "spec-15-sdlc-end-to-end-with-parallel-prs-and-cl",
  "title": "SPEC-15 SDLC end to end with parallel PRs and cleanup",
  "type": "feature",
  "status": "draft",
  "priority": "p1",
  "created": "2026-10-10",
  "updated": "2026-10-10",
  "created_at": "2026-10-10T19:24:16+00:00",
  "parent": "WO-20261010-329d",
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

# WO-20261010-2dab - SPEC-15 SDLC end to end with parallel PRs and cleanup

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

SPEC-15 is a stub; the merge path, who merges, and how PRs never queue are undefined

## Scope

**In**

- SPEC-15 s-sdlc, s-parallel-prs, s-cleanup; routes.json rows for merge and verify checked against it

**Out - non-goals**

- changing routes.json semantics

## Degrees of freedom

- [free] diagram layout

## Acceptance criteria

- [ ] `AC-H1` *(human)* make lint green; every record kind in routes.json appears in the SDLC mermaid

## Test plan

```sh
make lint
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
