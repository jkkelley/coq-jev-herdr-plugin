---
{
  "id": "WO-20261013-e2f9",
  "slug": "the-blueprint-dev-page-builds-again-the-factory-",
  "title": "The blueprint dev page builds again: the factory board entry takes more than 120 ticket rows, so herdr case 12 passes on main",
  "type": "bug",
  "status": "in-progress",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T17:55:24+00:00",
  "parent": "WO-20261013-16f1",
  "branch": "feat/the-blueprint-dev-page-builds-again-the-factory-",
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

- [x] `AC-H1` *(human)* AC-H1 CASES=12 bash herdr/tests/run.sh exits 0 on the branch
  - observed `2026-10-13` CASES=12 bash herdr/tests/run.sh run from the labelled test pane wD3:p15H on this branch: '12-blueprint-panes: pass', 'tests: 1 passed, 0 failed', exit 0. Also make -C report/loop test (18 passed, 0 failed) and make -C report/loop lint exit 0.

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

- `2026-10-13` Retro: the blueprint board lists every open ticket plus board_done_max done ones (lib/blueprint/entry.jq), 144 open + 12 done = 156 rows on 2026-10-13 against maxItems 120. Raised the schema cap to 400 with the breadcrumb in the board description (JSON has no comments) and added two cases in report/loop/tests/cases/01-schema.test.sh (156 rows validates, 401 refused). Capping rows in collect was rejected: an open ticket missing from the board reads as a ticket that does not exist. Step 1 passed by architect ruling imu40 (start worktree, no pool slot). Early on I ran two short read-only checks outside the test pane before re-running everything through testpane.sh.

## Outcome

_Written by `work-order done`. Empty until then._
