---
{
  "id": "WO-20261011-23df",
  "slug": "tester-reviewer-and-merger-seats-come-up-through",
  "title": "Tester, reviewer and merger seats come up through seat.sh and each writes one record on a real PR",
  "type": "feature",
  "status": "done",
  "priority": "p0",
  "created": "2026-10-11",
  "updated": "2026-10-11",
  "created_at": "2026-10-11T14:39:38+00:00",
  "parent": "WO-20261010-329d",
  "branch": "feat/tester-reviewer-and-merger-seats-come-up-through",
  "pr": 15,
  "closed": "2026-10-11",
  "approval": {
    "via": "override",
    "reason": "Claude seat; Lavish is prohibited for Claude seats by the owner hard rule, decisions recorded in the ticket note",
    "at": "2026-10-11"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [
    "WO-20261011-5355",
    "WO-20261011-fa78"
  ]
}
---

# WO-20261011-23df - Tester, reviewer and merger seats come up through seat.sh and each writes one record on a real PR

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

The three roles exist as files but no seat has ever run them; PR 11 and PR 12 wait on a reviewer and a merger that do not exist

## Scope

**In**

- seat.sh brings up tester, reviewer and merger seats (model per role file) in their own tabs with a monitor pane
- each brief names one PR and demands exactly one record: test.passed 201 or test.failed 422 with repro and observation; review.passed 201 or review.changes 422; merged 200 after squash merge, work-order.sh cleanup and slot release
- fixes to seat.sh, roles or playbooks found on the way, each with a breadcrumb
- RUNBOOK.md section: bringing up a non-worker seat and waking it by hand until the runner owns it

**Out - non-goals**

- the route runner (seats are woken by herdr agent prompt until B4)
- changing a role's model

## Degrees of freedom

- [free] bring-up order
- [free] which PR each seat proves itself on, as long as it is PR 11 or PR 12

## Acceptance criteria

- [x] `AC-H1` *(human)* tester seat up, runs the PR's test plan, writes exactly one test record with repro and observation
  - observed `2026-10-11` tester-wo-20261011-3d78 came up via seat.sh door 1 on PR 12 (slot 4, branch derived from origin), ran make -C report/sitrep test and make lint through testpane.sh in wD3:p1V, posted one test 201 (20261011T151036Z-201-u7zur) with the observation; tester-wo-20261011-9639 did the same on PR 13 (ftoqv, lost to the slot return, rerun after the fix)
- [x] `AC-H2` *(human)* reviewer seat up, verifies the evidence against the acceptance criteria, writes exactly one review record
  - observed `2026-10-11` reviewer-wo-20261011-3d78 came up on PR 12 sharing the ticket's lease, woken with the test record id, checked the evidence against AC-H1..H3 and posted one review 201 (20261011T151228Z-201-9bpqo); reviewer-wo-20261011-9639 posted review 201 gkkza on PR 13 the same way
- [x] `AC-H3` *(human)* merger seat up, squash-merges a review-passed PR, runs work-order.sh cleanup, releases the slot, writes merged 200
  - observed `2026-10-11` merger seat (fixed name merger, door 1 on WO-20261011-3d78) squash-merged PR 13 at 57b7eae (merged 200 66gbp) and PR 12 at 444e2af (merged 200 xa5c3), ran work-order.sh cleanup for PR 12 in its slot; slot release failed because the slot is the PR ticket's shared lease (WO-20261011-af9d cut); on PR 13 it skipped cleanup on the architect's instruction and the architect ran it
- [x] `AC-H4` *(human)* the event log shows the three records from three different seats and no git or gh command typed by the architect in the chain
  - observed `2026-10-11` PR 13 chain in events/: test 201 a24h8 (tester-wo-20261011-9639), review 201 gkkza (reviewer-wo-20261011-9639), merged 200 66gbp (merger); the architect typed no git or gh inside that chain, only herdr agent prompt wakes, seat.sh up/down and the post-merge cleanup. PR 12's chain needed one architect git step: the merge.conflict 409 resolution as the ticket's own worker
- [x] `AC-H5` *(human)* RUNBOOK.md section exists and a fresh reader can bring up one of the three seats from it
  - observed `2026-10-11` docs/sops/SOP-0001 (bring up a tester, reviewer or merger seat and wake it by hand) exists with Contents, Diataxis mode, steps 1-7 and verification; graph RUN-role-seats-on-a-pr points at it and CMP-role-seats has defined_in to it (graph.sh check ok, 101 nodes); the PR 13 seats were brought up from it by this seat

## Test plan

```sh
herdr/bin/seat.sh --check for each of the three seats events/bin/event.sh check events/bin/event.sh list --ticket <the PR's ticket>
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-11` Suite CASES='01 08 10 11' bash herdr/tests/run.sh ran in test pane wD3:p1V at 15:47Z: 4 passed, 0 failed (log suite-b3.log in the architect scratchpad). make lint green on every step.
- `2026-10-11` Slot 4 release blocked a third time: a forked Claude session (claude --fork-session under a claude daemon bg-pty-host, cwd slot 4, with its MCP servers) outlived seat.sh --down of the merger. retire.sh ends the agent pane but not forks the agent spawned through the daemon. Killed by hand at 15:45Z. Fix belongs with WO-20261011-af9d or a retire.sh ticket: retire must end every process whose cwd is the slot before the tab closes.
- `2026-10-11` Found after PR 12 merged: (1) treehouse slots are git worktrees of the project checkout, so the merger's cleanup (git checkout main in slot 4) blocked 'checkout main' here until the slot returned; WO-20261011-af9d covers the merger's own slot. (2) seat.sh --down merger left a 5-minute orphan shell in slot 4 (bfs over / for work-order.sh, started by the merger's Bash) that blocked the lease owner's return; killed by hand. retire.sh should end the seat's child shells before the tab closes.
- `2026-10-11` Hand steps in the PR 12 and PR 13 chains, 2026-10-11 15:09-15:30Z: woke each seat with the record id (SOP-0001 step 3); resolved merge.conflict 409 enmnn on PR 12 as the ticket's worker (origin/main merged in slot 4, CHANGELOG.md and INDEX.md regenerated, f266924); downed finished seats to free the agent cap; told the merger to skip work-order cleanup on PR 13 because its slot is PR 12's worktree and cleanup checks out main. Design gap: a fixed merger seat needs its own leased worktree, cut as its own ticket.

## Outcome

_Written by `work-order done`. Empty until then._
