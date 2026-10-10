---
{
  "id": "WO-20261010-1c23",
  "slug": "spec-13-testing-and-lint-local-fast-ci-full-cont",
  "title": "SPEC-13 testing and lint: local fast, CI full, container-sandbox as source of truth",
  "type": "feature",
  "status": "draft",
  "priority": "p1",
  "created": "2026-10-10",
  "updated": "2026-10-10",
  "created_at": "2026-10-10T19:24:15+00:00",
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

# WO-20261010-1c23 - SPEC-13 testing and lint: local fast, CI full, container-sandbox as source of truth

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

Testing rules live in the owner's head and chat: local runs what proves the change, CI runs everything, container-sandbox is the method, suites are generated

## Scope

**In**

- SPEC-13 with the Makefile target contract, the generator (new-podman-suite.sh), pane rule, CI matrix per package

**Out - non-goals**

- writing the CI workflows (delivery epic)

## Degrees of freedom

- [free] section order

## Acceptance criteria

- [ ] `AC-H1` *(human)* make lint green; SPEC-13 cites DEC-local-fast-ci-full and DEC-templates-over-handwriting

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
