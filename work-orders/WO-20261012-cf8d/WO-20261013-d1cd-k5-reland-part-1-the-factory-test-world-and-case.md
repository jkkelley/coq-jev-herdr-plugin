---
{
  "id": "WO-20261013-d1cd",
  "slug": "k5-reland-part-1-the-factory-test-world-and-case",
  "title": "K5 reland, part 1: the factory test world and cases 03, 06 and 09 post every gate record with its sha",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T14:35:57+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect orders 2026-10-13: 9c50 split (reviewer max_seats 2 to 4), K5 reland, post-merge as code; lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [
    "WO-20261013-9189",
    "WO-20261013-5dce",
    "WO-20261013-e9c0"
  ],
  "files": [
    "factory/tests/lib/world.sh",
    "factory/tests/cases/03-escalate.test.sh",
    "factory/tests/cases/06-belt.test.sh",
    "factory/tests/cases/09-flow-gate.test.sh",
    "factory/tests/cases/09-seat.test.sh"
  ]
}
---

# WO-20261013-d1cd - K5 reland, part 1: the factory test world and cases 03, 06 and 09 post every gate record with its sha

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

32fc429 (Roadmap K5, WO-20261013-f298) made event.sh refuse a gate record without --sha and broke the factory suite on main, because fixtures post gate records with no sha; it is being reverted. The fixtures are fixed first, which passes with today's writer, so the reland never breaks main.

## Scope

**In**

- factory/tests/lib/world.sh and factory/tests/cases/03-escalate, 06-belt, 09-flow-gate and 09-seat pass --sha on every test.*, review.*, merged, verified and rejected record they post

**Out - non-goals**

- the writer itself (the reland part)
- the other cases (parts 2 and 3)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* make -C factory test passes with today's writer, and these files post no gate record without --sha

## Test plan

```sh
make lint && make -C factory test, in Podman through the repository targets
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
