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

- [x] `AC-H1` *(human)* loop.sh collect builds an entry from events/, work-orders/ and the herdr pane list with zero hand-written values and it validates against the schema
  - observed `2026-10-11` Live run on this repository: loop.sh collect built an entry from events/, work-orders/ and the herdr pane list with no hand value, loop.sh validate printed VALID, headline 'Floor: 3 lines, 1 blocked, belt stopped' with lines eaa3, 616c (at arch, blocked, because my own blocked 423 record is in events/) and dc0d. Case 04-derive and 06-board (make -C report/loop test, 7 passed) cover seats, panes, belt, bars, legend and that no path or repository name reaches the entry.
- [x] `AC-H2` *(human)* a ticket with a pr.opened record shows its work at the tester; a ticket with a PR in its frontmatter and no pr.opened record shows by hand
  - observed `2026-10-11` Case 05-by-hand: a pr.opened record (as kind or as a 'pr.opened:' note) puts the work at the tester with its record waiting on a stopped belt and carried on a running one; a ticket with pr 13 in its frontmatter and no pr.opened record puts the PR at the tester and marks the worker station hand=true ('PR 13 opened by hand, no pr.opened record'); a ticket with no PR is not by hand. 7 of 7 cases passed.
- [ ] `AC-H3` *(human)* bearings stable serves /board and /board/data.json; after a new record file appears the open page redraws within 30 seconds without a reload
- [x] `AC-H4` *(human)* the watch pane runs in the monitors grid through monitors.sh take and leaves the output untouched when nothing changed
  - observed `2026-10-11` herdr/config/monitors.json slot 2.2.1 board runs report/loop/loop.sh watch; herdr case 04-bringup-monitors passes (bringup plugs it through monitors.sh take, status shows '2.2.1 factory board watch - board in use', the pane prints loop.sh watch's start line; 04 and 05 passed, 2 of 2). Case 07-watch: an unchanged floor, a later pass, an ageing stale belt and three passes in one run leave index.html, data.json and .watch.json with the same inode, mtime and size; a new record is build 2; a broken input keeps the last page.
- [x] `AC-H5` *(human)* the rendered page matches design iteration 5 (floor table, stacked lines with fold, key panel, build board, legend)
  - observed `2026-10-11` make -C report/loop test-browser, 12 of 12 passed in Chromium: the rendered page screenshots byte for byte like report/loop/design/loop-design-iteration-5.html at 1100 px and at 390 px (floor table, stacked lines with fold, key panel, build board, legend), zero page errors.
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

- `2026-10-11` Review fix 2026-10-11 (record 20261011T163507Z-422-uii0r): report/loop/RUNBOOK.md now opens with a contents list, the binding rules and GOOD/NEVER lines inside its first 100 lines; make lint rc 0. AC-H3 and AC-H6 stay unchecked on purpose and are the architect's, no evidence line is faked: AC-H3 needs a live bearings stable restart with board_dir set (a worker may not restart a tier, and the key never goes in a record), then post a record and watch /board redraw inside 30 seconds; AC-H6 needs a role that may write graph/, run bash report/loop/graph-handoff/apply.sh (adds CMP-factory-board and RUN-factory-board with defined_in, patches graph.sh, runs graph.sh check) then remove the edge and confirm make lint fails. After each, work-order.sh evidence --id WO-20261011-616c --match AC-H3 (or AC-H6) --observed ...
- `2026-10-11` Retro 2026-10-11: AC-H1, H2, H4 and H5 observed and ticked; AC-H3 (live stable restart, which is the architect's) and AC-H6 (graph/ is denied to workers, blocked 423 lvhaz; apply report/loop/graph-handoff/apply.sh) left unchecked on purpose. Findings: the global prettier hook re-indents the locked template (now .prettierignore); the belt age in the entry made every watch pass a change (now 'over 30s old'); the test pane is shared and a long herdr suite from another seat queues your commands behind it; the graph rule is a ratchet with a closed list of 19 Components because a global rule fails all of them.

## Outcome

_Written by `work-order done`. Empty until then._
