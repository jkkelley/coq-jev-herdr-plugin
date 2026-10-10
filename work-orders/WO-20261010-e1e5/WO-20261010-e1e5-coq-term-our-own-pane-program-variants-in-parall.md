---
{
  "id": "WO-20261010-e1e5",
  "slug": "coq-term-our-own-pane-program-variants-in-parall",
  "title": "coq-term: our own pane program, variants in parallel, per-package CI and semver",
  "type": "feature",
  "status": "draft",
  "priority": "p0",
  "created": "2026-10-10",
  "updated": "2026-10-10",
  "created_at": "2026-10-10T19:25:24+00:00",
  "parent": null,
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

# WO-20261010-e1e5 - coq-term: our own pane program, variants in parallel, per-package CI and semver

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

The game must render inside a herdr pane with a decision trace; Spike 5 proved the pipeline; the owner wants several variants to compare

## Scope

**In**

- terminals/<variant>/ packages, shared frame and input protocol, each with Makefile, suite, CI workflow, semver tags; uat per variant in its own herdr session

**Out - non-goals**

- the game host and adapter (own epic)

## Degrees of freedom

- [free] number of variants beyond two

## Acceptance criteria

- [ ] `AC-H1` *(human)* owner picked a variant from side-by-side uat sessions

## Test plan

```sh
make -C terminals/<variant> test per package
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
