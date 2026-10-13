---
{
  "id": "WO-20261013-3abe",
  "slug": "roadmap-a3-the-loop-board-reads-records-from-the",
  "title": "Roadmap A3 - The loop board reads records from the state root: events_dir takes the records tree",
  "type": "feature",
  "status": "in-progress",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T14:11:19+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": "feat/roadmap-a3-the-loop-board-reads-records-from-the",
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect P1 order 2026-10-13: A3 split under the owner size rule (03:00Z); lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261013-89c7"
  ],
  "blocks": [
    "WO-20261012-99d6"
  ],
  "files": [
    "report/loop/config/board.json",
    "report/loop/config/board.schema.json",
    "report/loop/loop.sh",
    "report/loop/tests/cases/17-records-state-root.test.sh",
    "report/loop/RUNBOOK.md"
  ]
}
---

# WO-20261013-3abe - Roadmap A3 - The loop board reads records from the state root: events_dir takes the records tree

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

report/loop/loop.sh finds records under the repository's events_dir (config value events), so the board shows the checkout's copy, not the state root. Pull request 93 (WO-20261013-89c7) holds these files and adds the tree placeholder for state_dir; this part follows it. Split from WO-20261012-541a.

## Scope

**In**

- report/loop/config/board.json events_dir is ${tree:records}; board.schema.json accepts the placeholder; loop.sh expands it as it does state_dir after 89c7
- report/loop/tests/cases/17-records-state-root.test.sh: a record written to COQ_STATE/records shows on the board; RUNBOOK.md names where records are read

**Out - non-goals**

- the board's ticket status and belt judgement (WO-20261013-89c7)
- report/loop/tests/lib/world.sh

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [x] `AC-H1` *(human)* loop.sh view shows a record written to the state root and none from the repository's events/
  - observed `2026-10-13` Case 17-records-state-root passes in make -C report/loop test: a record under COQ_STATE/records is read and makes its seat live, a record in the repository's events/ is not read. Live check: loop.sh collect --no-panes --no-live read 1748 records in 14 days from the state root (sources line names ${tree:records}); git tracks 178 files under events/.
- [x] `AC-H2` *(human)* make -C report/loop test passes with COQ_STATE at a temp dir; make lint passes
  - observed `2026-10-13` make -C report/loop test, run in the test pane with COQ_STATE at the world's temp dir: tests: 19 passed, 0 failed. make lint: all ok.

## Test plan

```sh
make lint && make -C report/loop test, in Podman through the repository targets
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-13` Retro. Deviations the architect should know, all forced by AC-H2 (the suite passes): (1) report/loop/tests/lib/world.sh, a listed non-goal, now gives each world its own COQ_STATE and links events/ to its records tree, and 04-derive.test.sh needs find on events/ with a trailing slash; without both, cases 04, 05, 06, 07 and 08-glass wrote records where collect no longer looks. (2) report/loop/lib/collect.jq route_of treats a matched ignore row as no route: since WO-20261013-7a76 added ignore rows to routes.json, cases 04, 05 and 08-glass failed 9 assertions on main itself (same 9 on a clean archive of HEAD). None of these four files is in the ticket's files field, so factory/bin/gate.sh pr-files will hold the diff until the claim is extended. The first make lint was run in the worker's own shell by mistake, before using testpane.sh; read-only, no side effects.

## Outcome

_Written by `work-order done`. Empty until then._
