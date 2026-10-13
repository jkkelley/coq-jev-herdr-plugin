---
{
  "id": "WO-20261013-e2f9",
  "slug": "the-blueprint-dev-page-builds-again-the-factory-",
  "title": "The blueprint dev page builds again: the factory board entry takes more than 120 ticket rows, so herdr case 12 passes on main",
  "type": "bug",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T17:55:24+00:00",
  "parent": "WO-20261013-16f1",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect ruling on case 12 (acting orchestrator sched-worker-2)",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [],
  "files": [
    "report/loop/schema/loop.schema.json",
    "report/loop/loop.sh",
    "report/loop/tests/*"
  ]
}
---

# WO-20261013-e2f9 - The blueprint dev page builds again: the factory board entry takes more than 120 ticket rows, so herdr case 12 passes on main

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

Verify-main on c903d8b and 29c1b34 failed herdr case 12-blueprint-panes (dev serves a built page: got 'ok dev up, no page yet'). The blueprint watch pass fails validation on board: the entry has more than the 120 rows report/loop/schema/loop.schema.json allows, as ticket count grew past 120 on 2026-10-13, so the dev server never gets a first page. Found by running report/loop/loop.sh --view blueprint collect at c903d8b: the error starts with the board list.

## Scope

**In**

_none_

**Out - non-goals**

- report/loop/schema/loop.schema.json: the board maxItems no longer rejects the real ticket count (raise it, or have collect cap the rows by status), with the reason as a comment-bearing note in the schema description

## Degrees of freedom

- [free] [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* AC-H1 CASES=12 bash herdr/tests/run.sh exits 0 on the branch

## Test plan

```sh
CASES=12 bash herdr/tests/run.sh, run from the repository root
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
