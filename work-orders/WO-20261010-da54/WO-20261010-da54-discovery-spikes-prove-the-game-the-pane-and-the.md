---
{
  "id": "WO-20261010-da54",
  "slug": "discovery-spikes-prove-the-game-the-pane-and-the",
  "title": "Discovery spikes: prove the game, the pane and the seat before building",
  "type": "feature",
  "status": "draft",
  "priority": "p0",
  "created": "2026-10-10",
  "updated": "2026-10-10",
  "created_at": "2026-10-10T19:24:16+00:00",
  "parent": null,
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": null,
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": []
}
---

# WO-20261010-da54 - Discovery spikes: prove the game, the pane and the seat before building

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

Nine unknowns from SITREP 001 decide the design; each is a cheap experiment with a pass signal

## Scope

**In**

- spikes 1,2,3,4,6,7,8,9,10,11 as children; spike 5 passed 2026-10-10

**Out - non-goals**

- production code

## Degrees of freedom

- [free] order of spikes beyond declared dependencies

## Acceptance criteria

- [ ] `AC-H1` *(human)* every child records 201 or 422 with evidence

## Test plan

```sh
podman run --rm --network=none ... per spike; pass/fail signal recorded with events/bin/event.sh add --kind test --code 201|422 --evidence <path>
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
