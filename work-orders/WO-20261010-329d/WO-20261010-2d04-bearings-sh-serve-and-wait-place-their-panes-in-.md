---
{
  "id": "WO-20261010-2d04",
  "slug": "bearings-sh-serve-and-wait-place-their-panes-in-",
  "title": "bearings.sh serve and wait place their panes in the tool grid, never under the calling seat",
  "type": "bug",
  "status": "ready",
  "priority": "p2",
  "created": "2026-10-10",
  "updated": "2026-10-11",
  "created_at": "2026-10-10T22:30:00+00:00",
  "parent": "WO-20261010-329d",
  "branch": null,
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

- [ ] `AC-H1` *(human)* bearings.sh stable stop then serve from the architect seat leaves the architect column untouched and the server and wait panes in the tool grid
- [ ] `AC-H2` *(human)* the Podman case for bearings proves the placement with a stub herdr

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

- `2026-10-11` Decision 2026-10-11 UTC (architect, fixed): pane_for, when no pane carries the label, takes the first pane in the caller's tab (HERDR_TAB_ID) whose label starts with the config key open_label_prefix (default 'OPEN - any tool') and relabels it; it splits the calling pane only when the tab has no such pane and the caller carries no seat label (COQ_SEAT unset), else it dies with a clear message naming the tab. stop relabels the server and wait panes back to '<open_label_prefix> <n>' with the n they had (kept in server.json as open_slots) instead of closing them. The Podman case drives bearings.sh against a stub herdr on PATH that records pane list, split, rename and close calls, and asserts no split happens when an OPEN pane exists and that stop issues renames, never a close. Why: the architect tab is a 3x3 arc the owner reads at a glance (owner, 2026-10-10: 'this is a 3X3 layout with you being the only thing on the left'); the tool grid exists for exactly these panes.

## Outcome

_Written by `work-order done`. Empty until then._
