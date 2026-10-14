---
{
  "id": "WO-20261014-d93a",
  "slug": "r1-routes-json-run-action-review-passed-and-merg",
  "title": "R1 - routes.json run action: review.passed and merged run merge.sh and after-merge.sh, the architect wake on merged deleted",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-14",
  "updated": "2026-10-14",
  "created_at": "2026-10-14T00:39:01+00:00",
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
  "blocks": [
    "WO-20261014-7f99"
  ],
  "files": [
    "factory/bin/route.sh",
    "factory/config/routes.json",
    "factory/config/routes.schema.json",
    "factory/tests/cases/30-routes-run-action.test.sh"
  ]
}
---

# WO-20261014-d93a - R1 - routes.json run action: review.passed and merged run merge.sh and after-merge.sh, the architect wake on merged deleted

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

routes.json answers review.passed by seating a merger agent and merged by waking the architect; both are mechanical steps. Design: plans/2026/10/20261014004500-line-ops-are-code-design.md (in COQ_STATE), section Tickets. Owner 2026-10-14 00:42Z: no agent does a mechanical step.

## Scope

**In**

- factory/bin/route.sh, factory/config/routes.json, its schema, factory tests: add a run action {do: run, cmd, with} executed under the ladder, exit code mapped to a record

**Out - non-goals**

- route.sh executes run actions under the ladder; review.passed runs merge.sh; merged runs after-merge.sh; the merger seat route and the architect wake on merged are deleted; a factory test proves each route

## Degrees of freedom

- [free] Any shell structure that keeps the ladder: 3 retries, one clean rerun, then a record.

## Acceptance criteria

- [ ] `AC-H1` *(human)* route.sh executes run actions under the ladder; review.passed runs merge.sh; merged runs after-merge.sh; the merger seat route and the architect wake on merged are deleted; a factory test proves each route

## Test plan

```sh
Factory test case runs route.sh on a stubbed review.passed and merged record and asserts the cmd ran and the record posted; make lint.
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
