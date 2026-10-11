---
{
  "id": "WO-20261011-f896",
  "slug": "test-pane-per-seat-seat-sh-opens-a-labelled-test",
  "title": "Test pane per seat: seat.sh opens a labelled test pane in the seat's own tab and exports it as COQ_TEST_PANE, so sixteen seats test in parallel instead of queueing on the architect tab's one pane",
  "type": "feature",
  "status": "done",
  "priority": "p1",
  "created": "2026-10-11",
  "updated": "2026-10-11",
  "created_at": "2026-10-11T19:28:24+00:00",
  "parent": "WO-20261010-329d",
  "branch": "feat/test-pane-per-seat-seat-sh-opens-a-labelled-test",
  "pr": 20,
  "closed": "2026-10-11",
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

- [x] `AC-H1` *(human)* two worker seats brought up back to back have different COQ_TEST_PANE values and each id is a pane in that seat's own tab (herdr pane list)
  - observed `2026-10-11` 21:3x UTC, scratch herdr (make -C herdr test, case 14-test-pane-per-seat, pass, /tmp/claude-1000/-home-luna--treehouse-coq-jev-herdr-plugin-f314e6-9-coq-jev-herdr-plugin/599a69af-ffd1-462c-b4c8-a8872d03df76/scratchpad/step2.log): seats worker-wo-20261010-8777 and worker-wo-20261010-c274 brought up back to back got different tabs and different COQ_TEST_PANE ids; pane list shows each id in its own seat's tab with label 'test - herdr - <seat>'; each environment line and brief names its own id; neither is the architect fixture pane. Not run on the live stable session.
- [x] `AC-H2` *(human)* testpane.sh in seat A refuses seat B's test pane with exit 3 and the fence message
  - observed `2026-10-11` case 14 (pass): COQ_TEST_PANE=A with pane B exits 3 with 'testpane: refused - <B> is not the test pane your brief names (<A>)'; B in A's pane exits 3; A in the architect fixture pane exits 3; each seat's own pane runs its command, both at the same time. testpane.sh unchanged.
- [x] `AC-H3` *(human)* seat.sh --down leaves no pane of the seat's tab behind and the test pane's shell had its cwd in the main checkout, so treehouse return never kills it
  - observed `2026-10-11` case 14 (pass): the test pane shell's cwd, read from /proc/<shell_pid>/cwd, is the checkout that brought the seat up and not the slot (slot is a separate directory); seat.sh --down A leaves 0 panes of A's tab, A's test pane id is gone, B's pane and the architect fixture pane are untouched. A lost test pane is named by --check ('pane missing: test - herdr - <seat>') and rebuilt by a rerun.
- [x] `AC-H4` *(human)* a role whose layout has no test pane still gets the architect tab's 'test - herdr' pane, as today
  - observed `2026-10-11` cases 01 and 08 (pass) with role_layout worker seat-nt (seat-1x2 minus its test slot): a ticket seat started outside the architect tab is refused exit 3 before any lease; case 14: the same layout inside the tab gets COQ_TEST_PANE equal to the architect fixture pane 'test - herdr fixture', in the environment line, with 2 panes in the seat tab as before.
- [x] `AC-H5` *(human)* make -C herdr test green with the new case; make lint ok; render-playbook --check ok
  - observed `2026-10-11` make -C herdr test: 'tests: 12 passed, 0 failed' (cases 01-11 and the new 14; this branch has 12 cases because 12 and 13 sit on other open PRs), TEST_RC=0; make lint 'lint: all ok' including 'herdr: layouts against layout.schema.json ok' and 'roles: schema + playbooks in sync ok' (render-playbook --check); both from the test pane via testpane.sh (/tmp/claude-1000/-home-luna--treehouse-coq-jev-herdr-plugin-f314e6-9-coq-jev-herdr-plugin/599a69af-ffd1-462c-b4c8-a8872d03df76/scratchpad/step2.log). Case 03, red on main since 26f6daa raised reviewer max_seats to 4, now pins the cap in its world copy.

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

- `2026-10-11` Retro, worker 21:4x UTC. Built: layout kind test plus an optional split (the grid cannot give the agent half of a 1x3 tab), seat-1x2 slot c split down from the monitor at 0.4, seat.sh resolves COQ_TEST_PANE from that slot and keeps the architect-tab pane as the fallback for a layout without one, seat.json and the printed JSON carry test_pane, case 14, SOP-0002. Found and fixed: case 03 was red on main since 26f6daa (reviewer max_seats 4); the branch was first cut from the records branch (rebuilt on origin/main, the architect force-pushed). Costs and handoffs for the architect: (1) specs/ is denied to a worker, so SPEC-04 s-seat and specs/exports/factory-spec.xml S1-059 ('every role but the player uses the 1x2 seat layout') still describe two panes; (2) the layout is still called seat-1x2 with three panes until roles/ is renamed; (3) a running agent keeps the COQ_TEST_PANE it started with, so a rebuilt test pane needs --down and a fresh up (SOP-0002 step 5); (4) not run on the live stable session: the acceptance evidence is the scratch herdr suite. The shared pane queued my commands about 20 minutes at a time behind other seats, which is the problem this ticket removes.

## Outcome

_Written by `work-order done`. Empty until then._
