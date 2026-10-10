---
{
  "id": "WO-20261010-d3a8",
  "slug": "spike-6-windows-capture-and-sendinput-microservi",
  "title": "Spike 6: Windows capture and SendInput microservice from WSL",
  "type": "feature",
  "status": "draft",
  "priority": "p1",
  "created": "2026-10-10",
  "updated": "2026-10-10",
  "created_at": "2026-10-10T19:24:18+00:00",
  "parent": "WO-20261010-da54",
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

# WO-20261010-d3a8 - Spike 6: Windows capture and SendInput microservice from WSL

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

The any-Steam-game track needs frames and keys from the Windows host

## Scope

**In**

- Python on Windows with DXcam plus ctypes SendInput exposing /frame and /keys on localhost; called from WSL

**Out - non-goals**

- production code; any Steam client automation

## Degrees of freedom

- [free] language of the service, as long as it is a single file and config-driven

## Acceptance criteria

- [ ] `AC-H1` *(human)* under 30 ms per frame and keys land in a focused Steam game
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
