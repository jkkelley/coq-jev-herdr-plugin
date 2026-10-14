---
{
  "id": "WO-20261013-8c6a",
  "slug": "cause-p-a-gate-was-seated-twice-once-by-the-belt",
  "title": "Cause p: a gate was seated twice, once by the belt and once by hand; seat.sh refuses a second seat for the same pull request, head sha and role",
  "type": "bug",
  "status": "cancelled",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T18:38:30+00:00",
  "parent": "WO-20261013-16f1",
  "branch": null,
  "pr": null,
  "closed": "2026-10-13",
  "approval": {
    "via": "override",
    "reason": "architect order 18:39Z: cause p, a gate seated twice (belt and hand); approved by the architect in the owner place",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [],
  "files": [
    "herdr/bin/seat.sh",
    "herdr/tests/cases/33-seat-refuses-second-gate.test.sh"
  ],
  "superseded_by": "WO-20261013-0ad7"
}
---

# WO-20261013-8c6a - Cause p: a gate was seated twice, once by the belt and once by hand; seat.sh refuses a second seat for the same pull request, head sha and role

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

On PR 114 tester-wo-20261013-c17f (belt) and tester-test-pr-114-wo-20261-bdbb (by hand) both ran; the second posted nothing useful and wasted a slot. WO-20261013-439d drops the duplicate in route.sh only; a hand seat goes through seat.sh and bypasses it.

## Scope

**In**

- herdr/bin/seat.sh: a gate seat request (tester or reviewer) whose pull request, head sha and role already have a live seat exits 3 with one line naming the live seat
- herdr/tests/cases/33-seat-refuses-second-gate.test.sh

**Out - non-goals**

- factory/bin/route.sh (WO-20261013-439d)

## Degrees of freedom

- [free] Where the live-seat lookup lives (seat.sh or seat-lib.sh); a --force is not allowed

## Acceptance criteria

- [ ] `AC-H1` *(human)* A second tester for the same pr, sha and role is refused with exit 3 naming the first
- [ ] `AC-H2` *(human)* A tester for a new sha or a reviewer for the same sha is still seated

## Test plan

```sh
herdr case 33 seats a tester twice for one head in the test world and asserts exit 3 on the second, then a different sha and a different role succeed
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

Cancelled `2026-10-13` - nothing shipped.

- reason: Duplicate audit F1, ruled 2026-10-13T23:55Z: the seat.sh half of WO-20261013-0ad7; its two criteria moved into WO-20261013-0ad7 by note, and its case name 33-seat-refuses-second-gate collided with 33-down-leaves-no-process on main.
- superseded by: `WO-20261013-0ad7`

No branch, no PR and no merge commit exist for this work order.

