---
{
  "id": "WO-20261011-f896",
  "slug": "test-pane-per-seat-seat-sh-opens-a-labelled-test",
  "title": "Test pane per seat: seat.sh opens a labelled test pane in the seat's own tab and exports it as COQ_TEST_PANE, so sixteen seats test in parallel instead of queueing on the architect tab's one pane",
  "type": "feature",
  "status": "ready",
  "priority": "p1",
  "created": "2026-10-11",
  "updated": "2026-10-11",
  "created_at": "2026-10-11T19:28:24+00:00",
  "parent": "WO-20261010-329d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "Claude seat: Lavish prohibited for Claude runtimes; architect approves on the owner's 18:52Z speed order",
    "at": "2026-10-11"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": []
}
---

# WO-20261011-f896 - Test pane per seat: seat.sh opens a labelled test pane in the seat's own tab and exports it as COQ_TEST_PANE, so sixteen seats test in parallel instead of queueing on the architect tab's one pane

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

seat.sh test_pane() resolves one pane, the 'test - herdr' pane of the architect tab, and exports it to every seat. With five workers live (19:25Z) three of them reported their make step queued behind other seats' runs in that pane; at the owner's 16-agent budget the line serialises on it. Owner 18:52Z: speed and efficiency always. Assumes herdr pane split from the agent pane works inside a seat's tab the same way seat.sh already splits the MONITOR pane (seat.sh:490).

## Scope

**In**

- herdr/layouts/seat-1x2.json (or a seat-1x3 layout the roles then name) gains a pane of kind test labelled 'test - herdr - ${seat}' whose command leaves the pane shell's cwd in the main checkout
- seat.sh test_pane() prefers the test pane in the seat's own tab and falls back to the architect tab's pane only when the layout has none; the brief and the environment line carry the resolved id
- seat.sh --down closes the seat's test pane with the tab, after the slot-process check it already does
- a herdr/tests case proves two seats up at once hold two distinct COQ_TEST_PANE ids, each in its own tab, and testpane.sh from one refuses the other's pane
- docs/runbooks seat runbook and SPEC-04 s-seat line for COQ_TEST_PANE updated by the scripts that own them

**Out - non-goals**

- the fence rules themselves (WO-20261011-3435 owns the send-text and send-keys gaps)
- removing the architect tab's test pane; it stays as the fallback and the owner's watch pane
- any change to testpane.sh's comparison

## Degrees of freedom

- [free] layout shape, as long as every role that names seat-1x2 today resolves to a layout with the test pane and layout.schema.json still validates it
- [free] split ratio and direction of the test pane, as long as the agent pane keeps at least half the tab

## Acceptance criteria

- [ ] `AC-H1` *(human)* two worker seats brought up back to back have different COQ_TEST_PANE values and each id is a pane in that seat's own tab (herdr pane list)
- [ ] `AC-H2` *(human)* testpane.sh in seat A refuses seat B's test pane with exit 3 and the fence message
- [ ] `AC-H3` *(human)* seat.sh --down leaves no pane of the seat's tab behind and the test pane's shell had its cwd in the main checkout, so treehouse return never kills it
- [ ] `AC-H4` *(human)* a role whose layout has no test pane still gets the architect tab's 'test - herdr' pane, as today
- [ ] `AC-H5` *(human)* make -C herdr test green with the new case; make lint ok; render-playbook --check ok

## Test plan

```sh
make -C herdr test
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
