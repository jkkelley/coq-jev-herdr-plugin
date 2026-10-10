---
{
  "id": "WO-20261010-c180",
  "slug": "factory-dashboard-live-view-of-the-queue-seats-r",
  "title": "Factory dashboard: live view of the queue, seats, records and leases, Factorio feel",
  "type": "feature",
  "status": "draft",
  "priority": "p1",
  "created": "2026-10-10",
  "updated": "2026-10-10",
  "created_at": "2026-10-10T19:25:22+00:00",
  "parent": "WO-20261010-98ea",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": null,
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261010-090c"
  ],
  "blocks": []
}
---

# WO-20261010-c180 - Factory dashboard: live view of the queue, seats, records and leases, Factorio feel

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

The owner needs to see where work is without reading logs

## Scope

**In**

- a page fed by the control plane and the event log: queue columns, seat tiles with status and pct, record stream, lease map; linked from the SITREP

**Out - non-goals**

- control plane changes

## Degrees of freedom

- [free] charting library

## Acceptance criteria

- [ ] `AC-H1` *(human)* every seat, lease and queue item visible within 2 s of its change
- [ ] `AC-H2` *(human)* built to the confirmed wireframe (checksum in evidence)

## Test plan

```sh
make -C cmd/sitrep test
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
