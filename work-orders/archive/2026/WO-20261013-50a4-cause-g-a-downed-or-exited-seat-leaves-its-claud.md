---
{
  "id": "WO-20261013-50a4",
  "slug": "cause-g-a-downed-or-exited-seat-leaves-its-claud",
  "title": "Cause g: a downed or exited seat leaves its claude running in a background session that holds the slot; seat.sh --down and retire.sh kill the pane's whole process tree and check",
  "type": "bug",
  "status": "done",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T16:37:18+00:00",
  "parent": "WO-20261013-16f1",
  "branch": "feat/cause-g-a-downed-or-exited-seat-leaves-its-claud",
  "pr": 111,
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
    "WO-20261012-6f13"
  ],
  "files": [
    "herdr/bin/seat-lib.sh",
    "herdr/bin/retire.sh",
    "herdr/tests/cases/33-down-leaves-no-process.test.sh"
  ]
}
---

# WO-20261013-50a4 - Cause g: a downed or exited seat leaves its claude running in a background session that holds the slot; seat.sh --down and retire.sh kill the pane's whole process tree and check

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

Cause g (records of 2026-10-13: the PR 87 tester and tester-wo-20261013-f298 stayed alive minutes after seat.down or /exit and held slots 6 and 9; killed by hand).

## Scope

**In**

- herdr/bin/seat-lib.sh: the down path kills every process of the pane's tree and any claude session whose cwd is the seat's slot, then checks none is left; three tries, then a 500 naming the pid
- herdr/bin/retire.sh uses the same function; herdr/tests/cases/33-down-leaves-no-process.test.sh

**Out - non-goals**

- who decides to down (the orchestrator and the patrol)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [x] `AC-H1` *(human)* after seat.sh --down or retire.sh no process of the seat remains and its slot is free; the case fails with a planted background session
  - observed `2026-10-13` herdr/tests/cases/33-down-leaves-no-process.test.sh, run in the test pane through make -C herdr test: with a stub claude planted by setsid in the leased slot (cwd) and one carrying COQ_SEAT elsewhere, seat.sh --down exits 0, both are gone, the slot is free (treehouse status holds 0 leases for the ticket) and seat.down 100 is recorded; a bystander claude is left running. The same case on the unmodified HEAD fails 13 checks (planted sessions survive, --down exits 3, slot stays held). make lint ok; full suite 27 passed, 1 failed - 12-blueprint-panes (dev serves a built page), which fails the same way on unmodified HEAD.

## Test plan

```sh
make lint && make -C herdr test, in Podman through the repository targets
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-13` Retro: retire.sh stopped at 'herdr no longer answers' and never looked at the host, so a claude outside the pane tree (setsid, bg session) or an orphaned MCP child kept the slot. Fix: seat-lib.sh sl_end_seat_procs ends the agent pane tree, the pre-/exit snapshot (pid plus start time) and every claude with COQ_SEAT=name or cwd in the seat's own leased slot, three SIGTERM/SIGKILL rounds, then a 500 note naming the pid and retire.sh exit 3; seat.sh --down then exits 4 with the seat un-ended. Learned: seat.sh runs under set -e, so a trailing '[ ] && printf' in a library loop can fail the caller; and the world stub claude has comm 'bash' in the 500 text, so the note prints the cmdline. Not done: case 12 (dev serves a built page) fails on main, outside this ticket's files; the playbook lease check could not pass because this seat was started with --worktree (no treehouse lease), proceeded on the architect's brief naming the worktree.

## Outcome

_Written by `work-order done`. Empty until then._
