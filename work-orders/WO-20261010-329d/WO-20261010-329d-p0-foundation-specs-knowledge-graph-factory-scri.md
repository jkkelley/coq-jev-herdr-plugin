---
{
  "id": "WO-20261010-329d",
  "slug": "p0-foundation-specs-knowledge-graph-factory-scri",
  "title": "P0 foundation: specs, knowledge graph, factory scripts",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-10",
  "updated": "2026-10-10",
  "created_at": "2026-10-10T19:24:14+00:00",
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

# WO-20261010-329d - P0 foundation: specs, knowledge graph, factory scripts

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

The factory needs its source of truth (graph), its contracts (XML specs), its lint, its event log, its queue and its roles before any seat runs

## Scope

**In**

- specs/ graph/ lint/ events/ queue/ roles/ playbooks/ factory/ bin/ root Makefile

**Out - non-goals**

- the control plane service itself
- herdr seat scripts (own epic)

## Degrees of freedom

- [free] order in which children land, as long as lint stays green

## Acceptance criteria

- [ ] `AC-H1` *(human)* every child done; make lint green on main

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
