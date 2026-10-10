---
{
  "id": "WO-20261010-84f1",
  "slug": "monitoring-monitor-seat-tab-group-notifications-",
  "title": "Monitoring: monitor seat, tab group, notifications, status-change wakeups",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-10",
  "updated": "2026-10-10",
  "created_at": "2026-10-10T19:25:31+00:00",
  "parent": null,
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

# WO-20261010-84f1 - Monitoring: monitor seat, tab group, notifications, status-change wakeups

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

The system must come up before any agent and wake seats on status change (DEC-system-before-agents, REQ-status-change-wakeups)

## Scope

**In**

- monitor role implementation on herdr events and the event log, monitors tab group, herdr notifications for owner-level codes, queue sweep

**Out - non-goals**

- the dashboard page

## Degrees of freedom

- [free] tick interval within config bounds

## Acceptance criteria

- [ ] `AC-H1` *(human)* a seat blocked on a lease is woken within one tick of its release in the scratch harness
- [ ] `AC-H2` *(human)* a 423 reaching the owner raises exactly one herdr notification

## Test plan

```sh
make -C herdr test
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
