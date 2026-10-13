---
{
  "id": "WO-20261010-eaa3",
  "slug": "spike-1-native-linux-qud-runs-in-wsl2-under-xvfb",
  "title": "Spike 1: native Linux Qud runs in WSL2 under Xvfb or WSLg",
  "type": "feature",
  "status": "cancelled",
  "priority": "p0",
  "created": "2026-10-10",
  "updated": "2026-10-13",
  "created_at": "2026-10-10T19:24:17+00:00",
  "parent": "WO-20261010-da54",
  "branch": "feat/spike-1-native-linux-qud-runs-in-wsl2-under-xvfb",
  "pr": null,
  "closed": "2026-10-13",
  "approval": {
    "via": "override",
    "reason": "architect: sure of it; owner 2026-10-10 UTC: approval is the architect's job, Lavish is prohibited for this project",
    "at": "2026-10-10"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [
    "WO-20261010-d58d"
  ],
  "superseded_by": null
}
---

# WO-20261010-eaa3 - Spike 1: native Linux Qud runs in WSL2 under Xvfb or WSLg

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

Unknown whether the DRM-free Linux build runs here without a GPU

## Scope

**In**

- unzip the owner-provided GOG or itch Linux build; run under WSLg, then Xvfb :99 with LIBGL_ALWAYS_SOFTWARE=1; capture a frame

**Out - non-goals**

- production code; any Steam client automation

## Degrees of freedom

- [free] renderer flags tried, display number

## Acceptance criteria

- [ ] `AC-H1` *(human)* a non-black title screen PNG captured under Xvfb
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

Cancelled `2026-10-13` - nothing shipped.

- reason: Closed by WO-20261013-89c7 (Roadmap K8): no pull request was ever opened and its branch on origin carries no commit beyond main and no captured title screen or result record, so neither criterion has proof; Qud runs natively under WSLg today, so the spike is superseded.

No branch, no PR and no merge commit exist for this work order.

