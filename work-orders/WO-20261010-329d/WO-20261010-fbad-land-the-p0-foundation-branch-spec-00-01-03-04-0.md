---
{
  "id": "WO-20261010-fbad",
  "slug": "land-the-p0-foundation-branch-spec-00-01-03-04-0",
  "title": "Land the P0 foundation branch: SPEC-00, 01, 03, 04, 05, graph, lint, events, queue, roles",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-10",
  "updated": "2026-10-10",
  "created_at": "2026-10-10T19:24:15+00:00",
  "parent": "WO-20261010-329d",
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

# WO-20261010-fbad - Land the P0 foundation branch: SPEC-00, 01, 03, 04, 05, graph, lint, events, queue, roles

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

The foundation exists on feat/p0-foundation in treehouse slot 2 and is not on main

## Scope

**In**

- review of every file on the branch against SPEC-01 conventions
- PR, merge

**Out - non-goals**

- new content beyond what the branch holds

## Degrees of freedom

- [free] commit squashing

## Acceptance criteria

- [ ] `AC-H1` *(human)* make lint green on the PR
- [ ] `AC-H2` *(human)* graph/bin/graph.sh check reports 90+ nodes and sync-specs passes
- [ ] `AC-H3` *(human)* every AGENTS.md has a Contents block in sync (bin/md-contents.sh --check)

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
