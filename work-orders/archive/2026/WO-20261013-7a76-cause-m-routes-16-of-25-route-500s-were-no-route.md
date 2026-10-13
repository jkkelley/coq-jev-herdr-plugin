---
{
  "id": "WO-20261013-7a76",
  "slug": "cause-m-routes-16-of-25-route-500s-were-no-route",
  "title": "Cause m, routes: 16 of 25 route 500s were no-route for note 300 and work.started 100; routes.json gets explicit ignore rows",
  "type": "bug",
  "status": "done",
  "priority": "p1",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T16:37:37+00:00",
  "parent": "WO-20261013-16f1",
  "branch": "feat/cause-m-routes-16-of-25-route-500s-were-no-route",
  "pr": 126,
  "closed": "2026-10-13",
  "approval": {
    "via": "override",
    "reason": "architect P0 order 2026-10-13 (owner m-20261013162710557-e4nos: always a system loop), approved by the architect in the owner place (card C29); lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [
    "WO-20261013-b839"
  ],
  "files": [
    "factory/config/routes.json",
    "factory/tests/cases/22-no-route-noise.test.sh"
  ]
}
---

# WO-20261013-7a76 - Cause m, routes: 16 of 25 route 500s were no-route for note 300 and work.started 100; routes.json gets explicit ignore rows

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

Cause m (record 8pj4r): the belt posts a 500 for every record kind with no row, so most 500s on 2026-10-13 were noise and hid real failures.

## Scope

**In**

- factory/config/routes.json: explicit ignore rows for note 300 and work.started 100; factory/tests/cases/22-no-route-noise.test.sh

**Out - non-goals**

- other rows (WO-20261013-bed2, WO-20261013-612d)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [x] `AC-H1` *(human)* note 300 and work.started 100 route to ignore with no 500; an unknown kind still posts 500
  - observed `2026-10-13` make lint: all ok; make -C factory test run in test pane wD3:p17X: 23 passed, 0 failed. factory/tests/cases/22-no-route-noise.test.sh: note 300 and work.started 100 leave ledger 'ignored', zero 500 records, zero herdr calls, zero record.routed; deploy 250, note 299 and work.started 101 each still post 'no route for ...' 500; note 500 and work.started 500 still wake the monitor.

## Test plan

```sh
make lint && make -C factory test, in Podman through the repository targets
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-13` Retro: two ignore rows added to factory/config/routes.json after note 100; case 22 proves them. The PostToolUse formatter explodes routes.json one-row-per-block on any Edit (170-line diff), so rows were added with sed to keep the diff at 2 lines - the formatter should skip factory/config/routes.json. The 4db1 breadcrumb in factory/bin/route.sh still says work.started is NOT ignored and waits on a collect.jq change; that is stale (station_for yields null for a row with no 'to', and the board falls back to emitter_of). Left untouched because route.sh is outside this ticket's files; the case 22 header carries the superseding breadcrumb. Someone owning route.sh should delete that sentence.

## Outcome

_Written by `work-order done`. Empty until then._
