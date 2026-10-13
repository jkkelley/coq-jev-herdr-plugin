---
{
  "id": "WO-20261013-a7e6",
  "slug": "the-stall-policy-in-flow-sh-wakes-the-seat-that-",
  "title": "The stall policy in flow.sh wakes the seat that owes the next record, retries, then hands the item to the maintenance lane; owner notices capped (K7 part 4 of 4)",
  "type": "feature",
  "status": "ready",
  "priority": "p1",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T03:29:40+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "owner 2026-10-13 03:00Z (record 57h60) size rule and 02:50Z (lvvtd) SPEC-16 is the engine; lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261012-0229"
  ],
  "blocks": [],
  "files": [
    "factory/bin/flow.sh",
    "factory/config/flow.json",
    "factory/config/flow.schema.json",
    "factory/tests/cases/*stall*"
  ]
}
---

# WO-20261013-a7e6 - The stall policy in flow.sh wakes the seat that owes the next record, retries, then hands the item to the maintenance lane; owner notices capped (K7 part 4 of 4)

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

Split of WO-20261013-70c4 (Roadmap K7) under the owner's size rule of 2026-10-13 03:00Z; the escalation goes to the maintenance worker (owner 01:16Z) instead of the digest.

## Scope

**In**

- factory/bin/flow.sh, factory/config/flow.json and flow.schema.json; case factory/tests/cases/*stall*

**Out - non-goals**

- probes beyond the stall (SPEC-16.F)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* a stall wakes the owing seat and reaches the maintenance lane only after the configured retries; the owner hears at most the cap
- [ ] `AC-H2` *(human)* make lint and make -C factory test pass in Podman

## Test plan

```sh
make lint && make -C factory test, in Podman through the repository targets
```

## Assumptions

1. interim until SPEC-16.F f-stall is active (owner 02:50Z)

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
