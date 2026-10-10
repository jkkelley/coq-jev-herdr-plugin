---
{
  "id": "WO-20261010-c6e9",
  "slug": "spike-9-haiku-5-5-seat-with-bypasspermissions-re",
  "title": "Spike 9: Haiku 5.5 seat with bypassPermissions, remote-control, hooks and compaction-guard",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-10",
  "updated": "2026-10-10",
  "created_at": "2026-10-10T19:24:20+00:00",
  "parent": "WO-20261010-da54",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect: sure of it; owner 2026-10-10 UTC: approval is the architect's job, Lavish is prohibited for this project",
    "at": "2026-10-10"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261010-8777"
  ],
  "blocks": []
}
---

# WO-20261010-c6e9 - Spike 9: Haiku 5.5 seat with bypassPermissions, remote-control, hooks and compaction-guard

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

No spawner passes --remote-control today; the guard sensor read 0 on a session started without its tap

## Scope

**In**

- seat.sh brings a Haiku 5.5 seat up with the role's flags, guard bound, tap wired; drive it past 30 percent; kill and recover it

**Out - non-goals**

- production code; any Steam client automation

## Degrees of freedom

- [free] how context is filled for the test

## Acceptance criteria

- [ ] `AC-H1` *(human)* seat up, compacts at 30 with a checkpoint, survives a pane kill through recover.sh
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
