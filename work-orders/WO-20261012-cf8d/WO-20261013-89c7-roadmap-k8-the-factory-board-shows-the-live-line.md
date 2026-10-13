---
{
  "id": "WO-20261013-89c7",
  "slug": "roadmap-k8-the-factory-board-shows-the-live-line",
  "title": "Roadmap K8 - The factory board shows the live line: ticket status read from open pull requests and ticket branches (or the SPEC-17 board lane once K1 lands), no in-progress ticket on main without a branch or a pull request and a check that fails on one, and the belt judged from the runner's real belt file",
  "type": "feature",
  "status": "in-progress",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T01:00:27+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": "feat/roadmap-k8-the-factory-board-shows-the-live-line",
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "owner accepted SPEC-17 on card C25; lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [],
  "files": [
    "report/loop/*",
    "work-orders/WO-20261010-da54/WO-20261010-eaa3-*",
    "work-orders/WO-20261010-329d/WO-20261011-38c7-*",
    "work-orders/archive/2026/WO-20261010-eaa3-*",
    "work-orders/archive/2026/WO-20261011-38c7-*"
  ]
}
---

# WO-20261013-89c7 - Roadmap K8 - The factory board shows the live line: ticket status read from open pull requests and ticket branches (or the SPEC-17 board lane once K1 lands), no in-progress ticket on main without a branch or a pull request and a check that fails on one, and the belt judged from the runner's real belt file

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

The owner asked 2026-10-13 00:55Z where the new line with the work is. The factory board (report/loop, served at /board/) is wrong three ways: it reads ticket status from the main checkout, so a started ticket whose status lives on its branch is invisible (A1 WO-20261012-7e13 with pull request 83 does not show); main holds three tickets as in-progress that finished long ago (WO-20261010-eaa3, WO-20261011-23df, WO-20261011-38c7), so they show as live lines; and belt_state reads factory/state/runner.json, which route.sh never writes, so the belt always shows stopped.

## Scope

**In**

- loop.sh collect derives a ticket's live state from the open pull requests (number, head branch, title) and the ticket branches on origin, not only from the main checkout: a started ticket shows as live with its branch, its pull request and its latest gate record; the SPEC-17 board lane is read when line/bin/board.sh exists (K1), the pull requests and branches otherwise
- loop.sh validate exits 3 naming the ticket when a ticket on main is in-progress with neither a live branch on origin nor an open pull request; report/loop's test target carries the case, so the repository's test run fails on one
- the two stale tickets without a pull request, WO-20261010-eaa3 and WO-20261011-38c7, closed by the work-order tool with the proof found on their branches (done with evidence when the work is on main, cancelled with the reason otherwise); WO-20261011-23df is carried by pull request 15 and is left alone
- the belt judged from the runner's belt file (runner.json state_dir plus belt, written by route.sh belt_touch) against belt_max_age_seconds, through a board.json key that uses the repository variable; the runner.json belt_state key is dropped
- the SPEC-17 health line (the board's health file) read for the view when present, so the owner's question has one answer

**Out - non-goals**

- the board, health and orchestrator scripts (K1 to K3)
- cards on the bearings page (K6)
- lint/lint.sh, held by A4 and pull request 35; wiring the stale-ticket check into it is a one-line follow-up when the file is free

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [x] `AC-H1` *(human)* with pull request 83 open for WO-20261012-7e13 the board shows that ticket as live with its branch and pull request, and a ticket started in the test fixture shows the same way
  - observed `2026-10-13` 2026-10-13 case 16-live from wD3:pT1: a ready ticket WO-20261012-7e13 with an open pull request 83 on feat/a1-state-root is a line with sub 'in-review · feat/a1-state-root · PR 83'; a ready ticket whose branch is on origin shows in-progress; a pull request for a ticket main lacks is drawn from its title
- [x] `AC-H2` *(human)* loop.sh validate exits 3 naming a fixture ticket that is in-progress with no branch and no pull request and exits 0 once it is closed; no in-progress ticket on main is left without a branch or a pull request
  - observed `2026-10-13` 2026-10-13 case 16-live: an in-progress ticket with no branch and no pull request is listed in stale and loop.sh validate exits 3 naming it, exit 0 once done; the repository's own tickets validate clean after WO-20261011-38c7 was closed done (PR 14) and WO-20261010-eaa3 cancelled; WO-20261011-23df keeps its live branch on origin
- [x] `AC-H3` *(human)* with route.sh running the board says the belt is fresh within belt_max_age_seconds and stopped once the belt file is older; make lint and make -C report/loop test pass in Podman
  - observed `2026-10-13` 2026-10-13 case 16-live: a belt file 5s old is running, 31s old and absent are stopped, state_dir ${tree:run} finds the belt under the state root; make lint exit 0 and make -C report/loop test 18 passed 0 failed in Podman from wD3:pT1

## Test plan

```sh
make lint && make -C report/loop test, in Podman through the repository targets
```

## Assumptions

1. gh and git on the host answer for the board watch pane; inside the test image the pull requests and branches come from fixture files

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-13` Retro: deferred the SPEC-17 board lane and health line because K1 to K3 do not exist yet; the pull request and branch merge stands in and RUNBOOK.md says so. Stale check is a validate verb on the entry, not part of collect, so one stale ticket never blanks the page. After A2 (PR 88) merges runner.json state_dir is ${tree:run}; belt_file resolves it through bin/state-root.sh.

## Outcome

_Written by `work-order done`. Empty until then._
