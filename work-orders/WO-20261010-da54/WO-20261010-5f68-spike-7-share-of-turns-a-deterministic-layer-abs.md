---
{
  "id": "WO-20261010-5f68",
  "slug": "spike-7-share-of-turns-a-deterministic-layer-abs",
  "title": "Spike 7: share of turns a deterministic layer absorbs",
  "type": "feature",
  "status": "draft",
  "priority": "p2",
  "created": "2026-10-10",
  "updated": "2026-10-10",
  "created_at": "2026-10-10T19:24:19+00:00",
  "parent": "WO-20261010-da54",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": null,
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261010-d58d"
  ],
  "blocks": []
}
---

# WO-20261010-5f68 - Spike 7: share of turns a deterministic layer absorbs

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

Cost model depends on how often the model is needed

## Scope

**In**

- 2000 turns with a rules layer (autoexplore, rest, flee) counting escalations

**Out - non-goals**

- production code; any Steam client automation

## Degrees of freedom

- [free] rule set

## Acceptance criteria

- [ ] `AC-H1` *(human)* under 20 percent of turns escalate to the model
- [ ] `AC-H2` *(human)* result recorded with events/bin/event.sh (201 pass or 422 fail) and a graph node with evidence paths

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
