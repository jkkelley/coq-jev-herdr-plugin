---
{
  "id": "WO-20261010-3593",
  "slug": "handoff-to-the-interface-agent-page-state-transc",
  "title": "Handoff to the interface agent: page state, transcript, memory, hydration",
  "type": "feature",
  "status": "draft",
  "priority": "p0",
  "created": "2026-10-10",
  "updated": "2026-10-10",
  "created_at": "2026-10-10T19:25:23+00:00",
  "parent": "WO-20261010-98ea",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": null,
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261010-ba08"
  ],
  "blocks": []
}
---

# WO-20261010-3593 - Handoff to the interface agent: page state, transcript, memory, hydration

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

At P0 completion everything the discovery session knows must transfer to the interface agent seat, scripted

## Scope

**In**

- a handoff script: bearings migrate into the stable tier, CONTEXT_STATE and HYDRATION entries, memory files copied into the seat's project memory, the SITREP link, the open cards; the interface agent seat brought up through seat.sh with roles/interface-agent.json

**Out - non-goals**

- any new design

## Degrees of freedom

- [free] order of migration steps

## Acceptance criteria

- [ ] `AC-H1` *(human)* the interface agent answers a message on the stable page within one tick of its first prompt
- [ ] `AC-H2` *(human)* diff of answers.jsonl and messages.jsonl before and after migration is empty

## Test plan

```sh
make -C tools/bearings test; herdr/tests seat up for interface-agent in a scratch session
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
