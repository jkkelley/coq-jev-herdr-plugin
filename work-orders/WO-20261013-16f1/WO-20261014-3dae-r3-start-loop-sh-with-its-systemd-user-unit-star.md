---
{
  "id": "WO-20261014-3dae",
  "slug": "r3-start-loop-sh-with-its-systemd-user-unit-star",
  "title": "R3 - start-loop.sh with its systemd user unit starts the next ready ticket when depends are done, files are free and a slot is free",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-14",
  "updated": "2026-10-14",
  "created_at": "2026-10-14T00:39:23+00:00",
  "parent": "WO-20261013-16f1",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "Architect-approved design C29 2026-10-14T00:45Z",
    "at": "2026-10-14"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [],
  "files": [
    "line/bin/start-loop.sh",
    "line/systemd/coq-start-loop.service",
    "line/systemd/coq-start-loop.timer",
    "line/tests/cases/start-loop.test.sh"
  ]
}
---

# WO-20261014-3dae - R3 - start-loop.sh with its systemd user unit starts the next ready ticket when depends are done, files are free and a slot is free

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

Orchestrator agents start tickets by prompt, a mechanical step. Design: plans/2026/10/20261014004500-line-ops-are-code-design.md (in COQ_STATE), section Tickets. Owner 2026-10-14 00:42Z: no agent does a mechanical step.

## Scope

**In**

- New files only: line/bin/start-loop.sh, its systemd --user unit, a test; 1-minute tick plus a record trigger on merged and seat.down, starts through start-tickets.sh, system-fix slots stay reserved

**Out - non-goals**

- start-loop.sh starts the next ready ticket whose depends are done, whose files are free, when a slot is free; reserves 2 system slots; unit file ships; test proves selection and the reserve

## Degrees of freedom

- [free] Any shell structure that keeps the ladder: 3 retries, one clean rerun, then a record.

## Acceptance criteria

- [ ] `AC-H1` *(human)* start-loop.sh starts the next ready ticket whose depends are done, whose files are free, when a slot is free; reserves 2 system slots; unit file ships; test proves selection and the reserve

## Test plan

```sh
Test case with stubbed start-tickets.sh and claims asserts which ticket is picked, that blocked ones are skipped, and that the reserve holds; make lint.
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
