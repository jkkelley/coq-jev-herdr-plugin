---
{
  "id": "WO-20261013-496d",
  "slug": "roadmap-a3-a-seat-started-in-a-treehouse-slot-po",
  "title": "Roadmap A3 - A seat started in a treehouse slot posts its records into the state root, proven by a herdr test case",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T14:11:12+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect P1 order 2026-10-13: A3 split under the owner size rule (03:00Z); lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261013-0bda",
    "WO-20261013-d127"
  ],
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

- [ ] `AC-H1` *(human)* the case passes and fails when event.sh is pointed back at the slot's events/
- [ ] `AC-H2` *(human)* make -C herdr test passes with COQ_STATE at a temp dir; make lint passes

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

## Outcome

_Written by `work-order done`. Empty until then._
