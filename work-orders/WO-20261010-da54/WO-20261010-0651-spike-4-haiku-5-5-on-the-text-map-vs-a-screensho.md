---
{
  "id": "WO-20261010-0651",
  "slug": "spike-4-haiku-5-5-on-the-text-map-vs-a-screensho",
  "title": "Spike 4: Haiku 5.5 on the text map vs a screenshot",
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
  "depends_on": [
    "WO-20261010-d58d"
  ],
  "blocks": [
    "WO-20261010-cc10"
  ]
}
---

# WO-20261010-0651 - Spike 4: Haiku 5.5 on the text map vs a screenshot

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

Text state is expected to beat pixels; unproven for Qud

## Scope

**In**

- 20 fixed scenarios, same prompt, text-only vs screenshot vs both, tokens and successes counted

**Out - non-goals**

- production code; any Steam client automation

## Degrees of freedom

- [free] scenario set, as long as it is committed

## Acceptance criteria

- [ ] `AC-H1` *(human)* text-only matches or beats vision at under 3K tokens per turn
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
