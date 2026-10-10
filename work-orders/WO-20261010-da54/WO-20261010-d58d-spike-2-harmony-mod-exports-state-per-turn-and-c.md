---
{
  "id": "WO-20261010-d58d",
  "slug": "spike-2-harmony-mod-exports-state-per-turn-and-c",
  "title": "Spike 2: Harmony mod exports state per turn and consumes actions",
  "type": "feature",
  "status": "draft",
  "priority": "p0",
  "created": "2026-10-10",
  "updated": "2026-10-10",
  "created_at": "2026-10-10T19:24:17+00:00",
  "parent": "WO-20261010-da54",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": null,
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261010-eaa3"
  ],
  "blocks": [
    "WO-20261010-6624",
    "WO-20261010-0651",
    "WO-20261010-5f68"
  ]
}
---

# WO-20261010-d58d - Spike 2: Harmony mod exports state per turn and consumes actions

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

QudAI proves the hooks on Windows; unproven on Linux here

## Scope

**In**

- port the AIBrainPart skeleton: PlayerTurn prefix, state.json, action.json, popup suppression; approve scripting mods

**Out - non-goals**

- production code; any Steam client automation

## Degrees of freedom

- [free] file names and JSON shape of the state record, within SPEC-08 once written

## Acceptance criteria

- [ ] `AC-H1` *(human)* 100 turns of Pass driven from a loop with no freeze; build_log.txt success
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
