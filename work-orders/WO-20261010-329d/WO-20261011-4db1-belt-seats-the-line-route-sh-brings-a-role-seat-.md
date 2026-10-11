---
{
  "id": "WO-20261011-4db1",
  "slug": "belt-seats-the-line-route-sh-brings-a-role-seat-",
  "title": "Belt seats the line: route.sh brings a role seat up before a wake, takes a seat down after its gate record, and ignores housekeeping records by table",
  "type": "feature",
  "status": "in-progress",
  "priority": "p0",
  "created": "2026-10-11",
  "updated": "2026-10-11",
  "created_at": "2026-10-11T18:39:49+00:00",
  "parent": "WO-20261010-329d",
  "branch": "feat/belt-seats-the-line-route-sh-brings-a-role-seat-",
  "pr": null,
  "closed": null,
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

- [ ] `AC-H1` *(human)* a pr.opened 100 for a ticket with no tester seat brings tester-<ticket> up through seat.sh and prompts it; the stub herdr shows one seat.sh call and one prompt
- [ ] `AC-H2` *(human)* a test 201 routed to the reviewer takes the tester seat down (seat.down 100 recorded) and brings the reviewer up
- [ ] `AC-H3` *(human)* seat.up, seat.down, note and record.routed records produce no 500; a record with no row still does
- [ ] `AC-H4` *(human)* the merger wake line carries the PR head sha from the record
- [ ] `AC-H5` *(human)* make -C factory test passes with the new cases and make lint is green; RUNBOOK.md documents every row

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

## Outcome

_Written by `work-order done`. Empty until then._
