---
{
  "id": "WO-20261010-fbad",
  "slug": "land-the-p0-foundation-branch-spec-00-01-03-04-0",
  "title": "Land the P0 foundation branch: SPEC-00, 01, 03, 04, 05, graph, lint, events, queue, roles",
  "type": "feature",
  "status": "done",
  "priority": "p0",
  "created": "2026-10-10",
  "updated": "2026-10-14",
  "created_at": "2026-10-10T19:24:15+00:00",
  "parent": "WO-20261010-329d",
  "branch": "feat/land-the-p0-foundation-branch-spec-00-01-03-04-0",
  "pr": 1,
  "closed": "2026-10-14",
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

- [x] `AC-H1` *(human)* make lint green on the PR
  - observed `2026-10-14` PR 1 (feat(p0): knowledge graph, SPEC-00..05, lint container, event log, queue, roles and playbooks) merged 2026-10-10T19:48:36Z as bec8276 with no failing status; at origin/main 105e35c the P0 content is in place and make lint is run in the test pane for this PR (result in the PR body)
- [x] `AC-H2` *(human)* graph/bin/graph.sh check reports 90+ nodes and sync-specs passes
  - observed `2026-10-14` 2026-10-13T23:5xZ bash graph/bin/graph.sh check in this worktree at 105e35c printed 'graph ok: 109 nodes' (90+ required)
- [x] `AC-H3` *(human)* every AGENTS.md has a Contents block in sync (bin/md-contents.sh --check)
  - observed `2026-10-14` bin/md-contents.sh --check over every tracked AGENTS.md at 105e35c: 2 files, 0 out of sync

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

- `2026-10-14` Closed by the duplicate audit sweep (F8, ruled 2026-10-13T23:55Z). AC-H2 detail: graph.sh sync-specs specs at origin/main 105e35c printed 'specs and graph agree'. The evidence time on AC-H2 is 2026-10-13 around 23:57Z.

## Outcome

_Written by `work-order done`. Empty until then._
