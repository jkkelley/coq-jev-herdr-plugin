---
{
  "id": "WO-20261010-976e",
  "slug": "spec-02-roles-and-permissions-written-from-roles",
  "title": "SPEC-02 roles and permissions written from roles/*.json",
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

# WO-20261010-976e - SPEC-02 roles and permissions written from roles/*.json

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

SPEC-02 is a draft stub; roles exist only as JSON and rendered playbooks

## Scope

**In**

- SPEC-02 sections s-roles, s-permissions, s-models filled from the role files with GOOD and NEVER examples; a renderer so the spec's role table is generated, not typed

**Out - non-goals**

- changing any role's allow or deny

## Degrees of freedom

- [free] renderer language (bash+jq or python), as long as it runs in the lint container

## Acceptance criteria

- [ ] `AC-H1` *(human)* make lint green; SPEC-02 under 1000 lines; every ROL node referenced

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
