---
{
  "id": "WO-20261010-6a3b",
  "slug": "spike-11-scratch-herdr-session-harness-in-podman",
  "title": "Spike 11: scratch herdr session harness in Podman",
  "type": "feature",
  "status": "cancelled",
  "priority": "p1",
  "created": "2026-10-10",
  "updated": "2026-10-10",
  "created_at": "2026-10-10T19:24:20+00:00",
  "parent": "WO-20261010-da54",
  "branch": null,
  "pr": null,
  "closed": "2026-10-10",
  "approval": {
    "via": "override",
    "reason": "architect: sure of it; owner 2026-10-10 UTC: approval is the architect's job, Lavish is prohibited for this project",
    "at": "2026-10-10"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [
    "WO-20261010-8777"
  ],
  "superseded_by": "WO-20261010-8777"
}
---

# WO-20261010-6a3b - Spike 11: scratch herdr session harness in Podman

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

Every herdr test needs isolation from the live session

## Scope

**In**

- start herdr server --session t-<id> headless in a container, create workspace, tab, pane, assert labels, tear down

**Out - non-goals**

- production code; any Steam client automation

## Degrees of freedom

- [free] container base image

## Acceptance criteria

- [ ] `AC-H1` *(human)* harness runs under make test with --network=none and leaves no session behind
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

Cancelled `2026-10-10` - nothing shipped.

- reason: answered by herdr/tests/run.sh: the suite runs the real herdr binary headless in Podman with a stub claude, one scratch session per case, torn down and asserted gone
- superseded by: `WO-20261010-8777`

No branch, no PR and no merge commit exist for this work order.

