---
{
  "id": "WO-20261013-9189",
  "slug": "k5-reland-part-2-factory-cases-10-11-12-and-13-p",
  "title": "K5 reland, part 2: factory cases 10, 11, 12 and 13 post every gate record with its sha",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T14:36:00+00:00",
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
  "depends_on": [
    "WO-20261013-d1cd"
  ],
  "blocks": [
    "WO-20261013-e9c0"
  ],
  "files": [
    "factory/tests/cases/10-sha.test.sh",
    "factory/tests/cases/11-down.test.sh",
    "factory/tests/cases/12-gate.test.sh",
    "factory/tests/cases/12-policy.test.sh",
    "factory/tests/cases/13-gate-route.test.sh"
  ]
}
---

# WO-20261013-9189 - K5 reland, part 2: factory cases 10, 11, 12 and 13 post every gate record with its sha

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

Same cause as part 1 (32fc429 reverted for breaking the factory suite); these cases post gate records with no sha.

## Scope

**In**

- factory/tests/cases/10-sha, 11-down, 12-gate, 12-policy and 13-gate-route pass --sha on every gate record

**Out - non-goals**

- the writer (the reland part)
- factory/tests/lib/world.sh (part 1)

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
