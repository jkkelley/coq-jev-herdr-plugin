---
{
  "id": "WO-20261010-6624",
  "slug": "spike-3-file-ipc-vs-socket-for-the-adapter",
  "title": "Spike 3: file IPC vs socket for the adapter",
  "type": "feature",
  "status": "draft",
  "priority": "p1",
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
    "WO-20261010-d58d"
  ],
  "blocks": []
}
---

# WO-20261010-6624 - Spike 3: file IPC vs socket for the adapter

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

Torn reads or latency would break the turn loop

## Scope

**In**

- measure state write to action read round trip with inotify; prototype a TcpListener in the mod

**Out - non-goals**

- production code; any Steam client automation

## Degrees of freedom

- [free] transport choice if both pass

## Acceptance criteria

- [ ] `AC-H1` *(human)* under 50 ms round trip and no torn JSON over 1000 turns
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
