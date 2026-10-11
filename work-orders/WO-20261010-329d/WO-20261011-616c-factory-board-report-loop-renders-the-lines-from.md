---
{
  "id": "WO-20261011-616c",
  "slug": "factory-board-report-loop-renders-the-lines-from",
  "title": "Factory board: report/loop renders the lines from records and bearings stable serves it live",
  "type": "feature",
  "status": "in-progress",
  "priority": "p0",
  "created": "2026-10-11",
  "updated": "2026-10-11",
  "created_at": "2026-10-11T14:39:35+00:00",
  "parent": "WO-20261010-329d",
  "branch": "feat/factory-board-report-loop-renders-the-lines-from",
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "Claude seat; Lavish is prohibited for Claude seats by the owner hard rule, decisions recorded in the ticket note",
    "at": "2026-10-11"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": []
}
---

# WO-20261011-616c - Factory board: report/loop renders the lines from records and bearings stable serves it live

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

The owner watches the factory through a hand-published page; nothing regenerates it from the records, so it drifts from the truth and an agent has to touch it

## Scope

**In**

- report/loop: loop.sh collect|render|watch, schema/loop.schema.json, assets/template.html (design iteration 5: floor, lines, key, build board), tests/run.sh, Makefile, RUNBOOK.md
- collect derives every value: station state and work-here from record kinds in factory/config/routes.json, by-hand from a ticket with a PR but no pr.opened record, seats from seat.up/seat.down records cross-checked with herdr pane list, belt from the runner state file age, lines from tickets in-progress or in-review, board bars from ticket status
- tools/bearings stable: GET /board serves report/loop/out/index.html and GET /board/data.json serves the entry; the page polls data.json and redraws in place
- a monitor pane in the monitors grid runs loop.sh watch via monitors.sh take; writes only when the data changed
- graph nodes CMP-factory-board and RUN-factory-board with a defined_in edge; lint rule: a Component node without a defined_in edge to a RUN node fails make lint

**Out - non-goals**

- upstream bearings-v2 (backlog item, after the north star)
- the Go SITREP site (P1)
- publishing claude.ai artifacts (the interface agent snapshots the rendered file on owner request; separate act)
- the route runner

## Degrees of freedom

- [free] the poll interval, as long as it is between 5 and 30 seconds and read from config
- [free] data.json field names, as long as the schema carries no project name or absolute path and every field is validated
- [free] the belt state file path, as long as it sits under factory/state and is declared in config

## Acceptance criteria

- [ ] `AC-H1` *(human)* loop.sh collect builds an entry from events/, work-orders/ and the herdr pane list with zero hand-written values and it validates against the schema
- [ ] `AC-H2` *(human)* a ticket with a pr.opened record shows its work at the tester; a ticket with a PR in its frontmatter and no pr.opened record shows by hand
- [ ] `AC-H3` *(human)* bearings stable serves /board and /board/data.json; after a new record file appears the open page redraws within 30 seconds without a reload
- [ ] `AC-H4` *(human)* the watch pane runs in the monitors grid through monitors.sh take and leaves the output untouched when nothing changed
- [ ] `AC-H5` *(human)* the rendered page matches design iteration 5 (floor table, stacked lines with fold, key panel, build board, legend)
- [ ] `AC-H6` *(human)* RUNBOOK.md lets a fresh reader set the board up on another repo by config only; CMP-factory-board carries defined_in RUN-factory-board and make lint fails when the edge is removed

## Test plan

```sh
make -C report/loop test # lint image, --network=none; cases: collect from fixtures, by-hand derivation, schema refusal, render parity make -C tools/bearings test # board routes make lint
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
