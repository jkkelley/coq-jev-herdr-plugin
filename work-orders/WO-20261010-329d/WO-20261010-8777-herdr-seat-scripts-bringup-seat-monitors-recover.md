---
{
  "id": "WO-20261010-8777",
  "slug": "herdr-seat-scripts-bringup-seat-monitors-recover",
  "title": "herdr seat scripts: bringup, seat, monitors, recover, retire, ported from bearings-v2",
  "type": "feature",
  "status": "in-progress",
  "priority": "p0",
  "created": "2026-10-10",
  "updated": "2026-10-10",
  "created_at": "2026-10-10T19:24:16+00:00",
  "parent": "WO-20261010-329d",
  "branch": "feat/herdr-seat-scripts-bringup-seat-monitors-recover",
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
    "WO-20261010-6a3b"
  ],
  "blocks": [
    "WO-20261010-c6e9",
    "WO-20261010-84f1"
  ]
}
---

# WO-20261010-8777 - herdr seat scripts: bringup, seat, monitors, recover, retire, ported from bearings-v2

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

SPEC-04 defines the seat lifecycle but no script in this repo implements it; bearings-v2 bin/ has the proven versions

## Scope

**In**

- herdr/bin/{bringup,seat,monitors,recover,retire}.sh and herdr/config/{leases,exemptions}.json reading roles/*.json
- a scratch herdr session suite (tests/) that brings a stub seat up and down

**Out - non-goals**

- layouts (wireframe gate first)
- the control plane

## Degrees of freedom

- [free] internal function names; keeping bash or moving one verb to Go

## Acceptance criteria

- [ ] `AC-H1` *(human)* seat.sh --ticket X --role worker in a scratch session creates tab, panes and labels per SPEC-04 and seat.sh --check passes
- [ ] `AC-H2` *(human)* seat.sh --audit records 500 for a hand-started agent in the scratch session
- [ ] `AC-H3` *(human)* suite runs in Podman from a labelled pane and reports N passed, 0 failed

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

- `2026-10-10` step 2: monitors.sh, bringup.sh, monitors config, case 04 (suite in the labelled test pane), lint of herdr/layouts, bearings wait forwards wakes into the seat; remaining work delegated to worker seats
- `2026-10-10` seat.sh, retire.sh, seat-lib.sh, config, layouts and the Podman suite (3 cases, real headless herdr + stub claude) landed; make -C herdr test green

## Outcome

_Written by `work-order done`. Empty until then._
