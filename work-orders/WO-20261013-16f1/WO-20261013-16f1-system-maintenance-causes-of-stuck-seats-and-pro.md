---
{
  "id": "WO-20261013-16f1",
  "slug": "system-maintenance-causes-of-stuck-seats-and-pro",
  "title": "System maintenance - causes of stuck seats and processes",
  "type": "chore",
  "status": "ready",
  "priority": "p1",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T01:23:58+00:00",
  "parent": null,
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect P0 order 2026-10-13 (owner m-20261013162710557-e4nos: always a system loop), approved by the architect in the owner place (card C29); lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": []
}
---

# WO-20261013-16f1 - System maintenance - causes of stuck seats and processes

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

Seats and line processes (belt, route-retry, record bus, digest, merge watch, turnwatch, board watch, unfreeze, bearings stable) stall or die, and each was restarted by hand with no record of why, so the same cause stalls the line again. Owner 2026-10-13 01:15Z: restart allowed, cause recorded, cause becomes a system ticket (rulings 3a18l, cp6cv, kvloh).

## Scope

**In**

- one child ticket per distinct cause found by the acting maintenance worker, each with file:line proof and the restart record that found it

**Out - non-goals**

- product tickets: system tickets never mix with them (owner card C26, record 16o3w)
- choosing the loop that runs these tickets: the system loop design owns that (C26); every child stays draft until it lands
- the restarts themselves: they are records, not tickets

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* every child ticket is done or cancelled with a reason
- [ ] `AC-H2` *(human)* no cause listed by a child recurs in a patrol record after its child is done

## Test plan

_none recorded - Rule 14 says this runs in a container_

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-13` Causes j and k need no ticket of their own: j (a rejected main holds merges) is written by WO-20261013-9bdd verify-main.sh and read by WO-20261013-2d35 (cause l); k (plans run every suite touching changed files) is WO-20261013-f1ff on PR 98.

## Outcome

_Written by `work-order done`. Empty until then._
