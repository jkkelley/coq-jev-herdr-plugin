---
{
  "id": "WO-20261011-4db1",
  "slug": "belt-seats-the-line-route-sh-brings-a-role-seat-",
  "title": "Belt seats the line: route.sh brings a role seat up before a wake, takes a seat down after its gate record, and ignores housekeeping records by table",
  "type": "feature",
  "status": "done",
  "priority": "p0",
  "created": "2026-10-11",
  "updated": "2026-10-11",
  "created_at": "2026-10-11T18:39:49+00:00",
  "parent": "WO-20261010-329d",
  "branch": "feat/belt-seats-the-line-route-sh-brings-a-role-seat-",
  "pr": 21,
  "closed": "2026-10-11",
  "approval": {
    "via": "override",
    "reason": "Claude seat; Lavish is prohibited for Claude seats by the owner hard rule; owner order 18:38Z get the system operational",
    "at": "2026-10-11"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": []
}
---

# WO-20261011-4db1 - Belt seats the line: route.sh brings a role seat up before a wake, takes a seat down after its gate record, and ignores housekeeping records by table

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

The route runner wakes by herdr agent prompt only, so a pr.opened 100 for a ticket with no tester seat fails (500 route failed, 18:31Z muiv4) and the architect seats every tester, reviewer and merger by hand; every seat.up, seat.down and note record with no row becomes a 500 to the monitor (nine in six minutes at 18:32Z), which buries the real 500s. DEC-system-runs-the-loop says the system wakes, hands off and cleans up; today the architect is the belt.

## Scope

**In**

- a do:seat action in routes.json rows that runs herdr/bin/seat.sh --ticket <ticket> --role <role> (idempotent: a live seat is left as is) and then prompts it with the record id and playbook
- a do:down action and rows so a tester or reviewer seat is taken down by seat.sh --down once its gate record (201 or 422) is routed, and the merger after merged 200 or merge.conflict 409
- a do:ignore action and rows for seat.up 100, seat.down 100, note 100 and record.routed 300, so only a record with no row at all is a 500
- a sha field read from the record (PR head) passed on the wake line so the merger gate never holds on a note
- factory/RUNBOOK.md and the route table documented row by row; runner suite cases for seat, down and ignore against the stub herdr

**Out - non-goals**

- bringup.sh and recover.sh ownership of the runner pane (WO-20261011-5355 - Belt on: bringup.sh starts the route runner in its own pane before any seat and seat.sh refuses a seat while the belt is stopped)
- a flow watch for unconsumed records (its own ticket)
- any change to seat.sh beyond what seat needs; roles stay as they are

## Degrees of freedom

- [free] names of the new actions, as long as routes.json stays the only place behaviour lives and route.sh reads no kind or code outside a row match
- [free] how the runner finds a seat's name from role and ticket, as long as it is the seat.sh naming rule and not a second one
- [free] down timing, as long as a seat is never taken down before its record is on disk and never left up after it

## Acceptance criteria

- [x] `AC-H1` *(human)* a pr.opened 100 for a ticket with no tester seat brings tester-<ticket> up through seat.sh and prompts it; the stub herdr shows one seat.sh call and one prompt
  - observed `2026-10-11` make -C factory test on the merged tree 8f72207, test pane, 2026-10-11 22:03Z: tests: 14 passed, 0 failed. Case 09-seat: a pr.opened 100 for WO-20261011-aaaa with no tester seat makes one seat.sh call (--ticket WO-20261011-aaaa --role tester), then one herdr agent prompt to tester-wo-20261011-aaaa carrying the record id and playbooks/tester.md; the order log reads seat then herdr; the receipt note is 'routed pr.opened 100 (id): seat tester'; no 500. A second record for the live seat calls seat.sh again, which leaves it as is (one seat.up in total).
- [x] `AC-H2` *(human)* a test 201 routed to the reviewer takes the tester seat down (seat.down 100 recorded) and brings the reviewer up
  - observed `2026-10-11` make -C factory test on the merged tree 8f72207, test pane, 2026-10-11 22:03Z: tests: 14 passed, 0 failed. Case 11-down: a test.passed 201 brings reviewer-wo-20261011-aaaa up and prompts it, then seat.sh --down tester-wo-20261011-aaaa runs (order: seat, herdr, seat); one seat.down 100 for the tester is recorded and a following tick ignores it with no 500; a second gate record for the same ticket adds no seat.down. The same case covers review.passed (merger up, reviewer down), test.failed and review.changes (worker woken, seat down), attempt 3 escalation, merged and merge.conflict (merger down), a failed prompt (seat still taken down) and a failed --down (500 names it, prompt still sent).
- [x] `AC-H3` *(human)* seat.up, seat.down, note and record.routed records produce no 500; a record with no row still does
  - observed `2026-10-11` make -C factory test on the merged tree 8f72207, test pane, 2026-10-11 22:03Z: tests: 14 passed, 0 failed. Case 08-ignore: seat.up 100, seat.down 100, note 100 and record.routed 300 records leave 0 records of code 500, 0 receipts and 0 herdr calls; each ledger entry reads ignored; a second tick adds nothing. A note 500 still wakes the monitor, and a note 429 and a gate 150 with no row are still 500 'no route for' notes.
- [x] `AC-H4` *(human)* the merger wake line carries the PR head sha from the record
  - observed `2026-10-11` make -C factory test on the merged tree 8f72207, test pane, 2026-10-11 22:03Z: tests: 14 passed, 0 failed. Case 10-sha: event.sh add --sha <40 hex> --pr 18 writes both as fields (a non-hex sha, a sha under 7 characters, pr 0 and pr 1x exit 2); the review.passed 201 record makes the merger line 'agent prompt merger record <id> pr 18 sha 9ed0690f3a1c5b7d2e4f60718293a4b5c6d7e8f9 playbook .../merger.md'; a malformed sha on disk is a 500 and nothing is typed into the seat.
- [x] `AC-H5` *(human)* make -C factory test passes with the new cases and make lint is green; RUNBOOK.md documents every row
  - observed `2026-10-11` make -C factory test on the merged tree 8f72207, test pane, 2026-10-11 22:03Z: tests: 14 passed, 0 failed (cases 01 to 07 unchanged and green, 08 to 11 new). make lint from the test pane: 'lint: all ok'. factory/RUNBOOK.md has 'The routes, row by row' with all 20 rows of routes.json, the seat, ignore and down parts, and new rows in When something goes wrong.

## Test plan

```sh
make -C factory test
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-11` Retro. Built as four runner parts in five steps: do ignore (4 rows), event.sh --sha and --pr with pr and sha on the wake line of a with pr row, do seat (seat.sh --ticket T --role R then the wake line; pr.opened, test.passed, review.passed rows), a down field on eight rows (seat.sh --down after the action, even when the action failed), RUNBOOK row by row. Deviations: (1) no standalone do:down - a record matches one row, so the same test.passed that seats the reviewer must also release the tester; down is a field on the row. (2) event.sh and its schema gained --sha and --pr, which the ticket text did not list; without them no record could carry a sha and AC-H4 could not hold in the live system. (3) The first branch was cut from the records branch; the architect ordered a rebuild on origin/main (record 20261011T203650Z-422-4xk1v), done by cherry-pick, then origin/main (flow watch, PR 19) merged in; the ticket file is restored from its started state because it is not on main. Findings for the architect: (a) work.started 100 has no row and made four 500s in the live log; it is not ignored here because report/loop/lib/collect.jq places a line at the first matching row's to, so an ignore row with no to would move a ticket whose newest record is work.started to the owner station - route_of there needs select(.do != "ignore"), then add the row. (b) ticket.cut still wakes a worker that does not exist; making it do seat is one row once the owner wants it. (c) a seat.sh bring-up can take about 45 s and the belt goes stale at 60 s; belt_touch runs after each seat.sh call but one long bring-up still reads as stopped (WO-20261011-5355 - Belt on: bringup.sh starts the route runner in its own pane before any seat and seat.sh refuses a seat while the belt is stopped). (d) the merger is one shared seat named merger, so down merger after merged 200 is safe for one ticket at a time. (e) WO-20261011-4562 - Break glass edits route.sh, event.sh and routes.json too; expect a textual merge with this PR. (f) the runner pane must sit in the architect tab or seat.sh refuses every bring-up. (g) the shared test pane queued my runs 20 to 40 minutes each; a run per step was the cost.

## Outcome

_Written by `work-order done`. Empty until then._
