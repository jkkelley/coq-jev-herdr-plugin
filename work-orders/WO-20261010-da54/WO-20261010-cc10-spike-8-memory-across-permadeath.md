---
{
  "id": "WO-20261010-cc10",
  "slug": "spike-8-memory-across-permadeath",
  "title": "Spike 8: memory across permadeath",
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
    "WO-20261010-0651"
  ],
  "blocks": []
}
---

# WO-20261010-cc10 - Spike 8: memory across permadeath

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

Repeated deaths from the same cause would make play pointless

## Scope

**In**

- a notes file plus a death post-mortem step over 10 short lives

**Out - non-goals**

- production code; any Steam client automation

## Degrees of freedom

- [free] note format

## Acceptance criteria

- [ ] `AC-H1` *(human)* same-cause deaths drop across runs
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
