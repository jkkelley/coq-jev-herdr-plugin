---
{
  "id": "WO-20261013-496d",
  "slug": "roadmap-a3-a-seat-started-in-a-treehouse-slot-po",
  "title": "Roadmap A3 - A seat started in a treehouse slot posts its records into the state root, proven by a herdr test case",
  "type": "feature",
  "status": "done",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T14:11:12+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": "feat/roadmap-a3-a-seat-started-in-a-treehouse-slot-po",
  "pr": 108,
  "closed": "2026-10-13",
  "approval": {
    "via": "override",
    "reason": "architect P1 order 2026-10-13: A3 split under the owner size rule (03:00Z); lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [
    "WO-20261012-6f13",
    "WO-20261012-99d6"
  ],
  "files": [
    "herdr/tests/cases/26-seat-records-state-root.test.sh",
    "herdr/bin/seat.sh"
  ]
}
---

# WO-20261013-496d - Roadmap A3 - A seat started in a treehouse slot posts its records into the state root, proven by a herdr test case

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

On 2026-10-12 22:05Z a seat in a slot wrote and searched records in the slot's events/. Since A1 (WO-20261012-7e13) the writer resolves the state root, but no test pins that a seat in a slot lands its record there, and seat.sh still describes records by COQ_EVENTS_ROOT. Split from WO-20261012-541a.

## Scope

**In**

- herdr/tests/cases/26-seat-records-state-root.test.sh: a seat brought up from a copy of the repository as a slot posts seat.up, and the record is under COQ_STATE/records, none under the slot's events/; the case sets COQ_STATE itself and leaves herdr/tests/lib/world.sh as it is
- herdr/bin/seat.sh: the comment that names COQ_EVENTS_ROOT names the state root instead; no behaviour change

**Out - non-goals**

- the merger's merge and verify and the branch from origin (Roadmap B, WO-20261012-6f13)
- herdr/tests/lib/world.sh

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [x] `AC-H1` *(human)* the case passes and fails when event.sh is pointed back at the slot's events/
  - observed `2026-10-13` CASES=26 make -C herdr test: 13 checks ok. The case's last block rewrites the world's event-real.sh to write into the slot's events/ (recs=$ROOT) and then sees one record in the slot and none new in the state root, so the case's checks fail for that fault.
- [x] `AC-H2` *(human)* make -C herdr test passes with COQ_STATE at a temp dir; make lint passes
  - observed `2026-10-13` make lint: all ok. make -C herdr test with COQ_STATE at a temp dir: 27 passed, 1 failed. The one failure is 12-blueprint-panes ('dev serves a built page', got 'ok dev up, no page yet'); it fails identically on an untouched checkout of main (HEAD 65a4f02), touches none of this ticket's files, so it is NOT fixed here and needs its own ticket. Case 26 passes.

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

- `2026-10-13` Retro: the world already exports COQ_STATE and shims event.sh, so case 26 needed no world.sh change. The seat is brought up with --worktree on the world copy, which stands in for the slot. Pre-existing: herdr case 12 fails on main (dev tier has no build after the case removes report/blueprint/out); cut a ticket for it.

## Outcome

_Written by `work-order done`. Empty until then._
