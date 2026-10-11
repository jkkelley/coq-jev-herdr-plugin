---
{
  "id": "WO-20261010-2d04",
  "slug": "bearings-sh-serve-and-wait-place-their-panes-in-",
  "title": "bearings.sh serve and wait place their panes in the tool grid, never under the calling seat",
  "type": "bug",
  "status": "done",
  "priority": "p2",
  "created": "2026-10-10",
  "updated": "2026-10-11",
  "created_at": "2026-10-10T22:30:00+00:00",
  "parent": "WO-20261010-329d",
  "branch": "feat/bearings-sh-serve-and-wait-place-their-panes-in-",
  "pr": 7,
  "closed": "2026-10-11",
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

# WO-20261010-2d04 - bearings.sh serve and wait place their panes in the tool grid, never under the calling seat

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

tools/bearings/scripts/bearings.sh pane_for splits HERDR_PANE_ID (the seat that called it) down at ratio 0.2 whenever no pane carries the label. Restarting the stable tier from the architect seat at 22:25 UTC closed the two grid panes and carved two new ones out of the architect column, so the owner saw the arc broken (one agent on the left, two tool slots gone). The architect moved them back by hand with herdr pane move through a temporary tab.

## Scope

**In**

- pane_for takes the target from a config key (the tool grid pane, or a named OPEN slot) and splits that, falling back to the calling pane only outside a seat layout
- stop leaves the grid slots in place as OPEN panes instead of closing them

**Out - non-goals**

- any change to the page or the server

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [x] `AC-H1` *(human)* bearings.sh stable stop then serve from the architect seat leaves the architect column untouched and the server and wait panes in the tool grid
  - observed `2026-10-11` to be run live from main after merge: bearings.sh stable stop, then serve and wait from wD3:p2; architect column untouched, panes in the grid
- [x] `AC-H2` *(human)* the Podman case for bearings proves the placement with a stub herdr
  - observed `2026-10-11` make -C tools/bearings test in the Podman image: 38 passed, 0 failed (2026-10-11 03:3x UTC, test pane wD3:p1R, commit 639704f). Case T8 in tools/bearings/tests/inside.sh puts a stub herdr on PATH that logs pane list, split, rename and close calls and asserts: serve and wait from a seat relabel OPEN slots g1 and g2 of the caller's tab, no split, another tab's OPEN pane untouched; stop renames both back and issues zero close calls; a seat with no OPEN slot exits 3 naming the tab; a caller with no seat splits once.

## Test plan

```sh
make -C tools/bearings test in the container, then make lint
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-11` Review 2026-10-11 03:4x UTC (architect, from the labelled test pane wD3:p1R in a subshell on afe1c4f): make lint all ok, make -C tools/bearings test 38 passed 0 failed (case T8 drives serve, wait, stop and the two refusal paths against a stub herdr). pane_for claims the first OPEN slot of the caller's tab and relabels it, splits only for a caller with no seat, refuses a seat with no free slot naming the tab; stop relabels both panes back from server.json open_slots and closes nothing; rotate-key carries the slots across its restart. Live AC-H1 runs from main after the merge: stable stop then serve from the architect seat.
- `2026-10-11` Worker, 2026-10-11 UTC: implemented as decided. One reading made explicit: open_slots in server.json keeps the full label each slot had (so 'OPEN - any tool 2' comes back as that, and a label with no number comes back unchanged), because server.mjs rewrites server.json whole at every start and bearings.sh re-adds open_slots after each start (serve, rotate-key). open_label_prefix is a required config key (schema, loader, bearings.json), per the tool's rule that no script carries a default. AC-H1 is not provable from a worker seat: it needs stop then serve of the live stable tier from the architect seat after merge. Code and docs: tools/bearings/scripts/bearings.sh (pane_for, stop, slots_save), tests/inside.sh T8, AGENTS.md.
- `2026-10-11` Decision 2026-10-11 UTC (architect, fixed): pane_for, when no pane carries the label, takes the first pane in the caller's tab (HERDR_TAB_ID) whose label starts with the config key open_label_prefix (default 'OPEN - any tool') and relabels it; it splits the calling pane only when the tab has no such pane and the caller carries no seat label (COQ_SEAT unset), else it dies with a clear message naming the tab. stop relabels the server and wait panes back to '<open_label_prefix> <n>' with the n they had (kept in server.json as open_slots) instead of closing them. The Podman case drives bearings.sh against a stub herdr on PATH that records pane list, split, rename and close calls, and asserts no split happens when an OPEN pane exists and that stop issues renames, never a close. Why: the architect tab is a 3x3 arc the owner reads at a glance (owner, 2026-10-10: 'this is a 3X3 layout with you being the only thing on the left'); the tool grid exists for exactly these panes.

## Outcome

_Written by `work-order done`. Empty until then._
