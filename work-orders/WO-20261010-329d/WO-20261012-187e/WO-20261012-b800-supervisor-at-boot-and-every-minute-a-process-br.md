---
{
  "id": "WO-20261012-b800",
  "slug": "supervisor-at-boot-and-every-minute-a-process-br",
  "title": "Supervisor: at boot and every minute a process brings herdr, the belt, the watches, bearings and the seats back, judging each by its process, not its label, and re-seats a seat whose claude died",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T14:04:51+00:00",
  "parent": "WO-20261012-187e",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "lavish is prohibited for Claude seats; owner order 2026-10-12: get the factory working without the architect or owner as a gate",
    "at": "2026-10-12"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": []
}
---

# WO-20261012-b800 - Supervisor: at boot and every minute a process brings herdr, the belt, the watches, bearings and the seats back, judging each by its process, not its label, and re-seats a seat whose claude died

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

Three outages on 2026-10-12 (herdr restart, WSL reboot, suspend) each needed the architect to restart bearings, six dead monitor panes that bringup.sh --check called ok, hung commands, and two seats whose claude crashed with a Bun segfault.

## Scope

**In**

- a supervisor started at WSL boot running bringup.sh --apply on a timer
- process-based health for every reserved pane (backlog m2jhs) and the watches (60l24)
- a seat whose pane has no claude process is downed and re-seated with its ticket

**Out - non-goals**

- restarting a seat that is merely idle

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* kill any monitor pane command; within 60 s it runs again with no human action
- [ ] `AC-H2` *(human)* kill a seat's claude; within 120 s the seat is back with its ticket brief and a seat.up record
- [ ] `AC-H3` *(human)* after wsl --shutdown and a new shell, bringup --check is all ok within 3 minutes

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
