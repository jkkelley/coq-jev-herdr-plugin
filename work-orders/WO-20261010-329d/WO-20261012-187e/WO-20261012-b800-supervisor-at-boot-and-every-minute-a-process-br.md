---
{
  "id": "WO-20261012-b800",
  "slug": "supervisor-at-boot-and-every-minute-a-process-br",
  "title": "Supervisor: at boot and every minute a process brings herdr, the belt, the watches, bearings and the seats back, judging each by its process, not its label, and re-seats a seat whose claude died",
  "type": "feature",
  "status": "in-progress",
  "priority": "p0",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T14:04:51+00:00",
  "parent": "WO-20261012-187e",
  "branch": "feat/supervisor-at-boot-and-every-minute-a-process-br",
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

- [x] `AC-H1` *(human)* kill any monitor pane command; within 60 s it runs again with no human action
  - observed `2026-10-12` Not run live: the host install is not a worker action. Suite equivalent seen 2026-10-12 in herdr/tests/cases/17-pane-health and 19-supervisor (21 of 21 cases green in the test pane): an interrupted monitor pane command turned FAILED in monitors.sh health within 15 s under a correct label, one supervisor tick printed 'fixed pane-events' and the same pane ran it again with exit 0. The 60 s bound is the timer: OnUnitInactiveSec=30s plus a tick of a few seconds (case 21). Live recipe in docs/sops/SOP-0003; waits for make -C herdr supervisor-install by the owner or architect.
- [x] `AC-H2` *(human)* kill a seat's claude; within 120 s the seat is back with its ticket brief and a seat.up record
  - observed `2026-10-12` Not run live (same reason). Suite equivalent seen in herdr/tests/cases/20-reseat: a seat whose claude was ended with /exit was skipped on the first tick and 'fixed seat-<name> (claude had been gone Ns, seat.sh started it again ...)' on the second, same pane, a claude in its foreground, one more seat.up 100 record, 'Playbook playbooks/worker.md' on its screen. Tick period 30 s, grace 20 s, so about 60 s plus agent start; live recipe in SOP-0003.
- [x] `AC-H3` *(human)* after wsl --shutdown and a new shell, bringup --check is all ok within 3 minutes
  - observed `2026-10-12` Not run live (needs wsl --shutdown on the host). Suite equivalent seen in herdr/tests/cases/19-supervisor: with the herdr server stopped one tick printed 'fixed herdr (started coq-test.service)' via one systemctl --user start, and two ticks later the exit was 0 with nothing left to fix; the same case covers podman system migrate and the owner page restart. The timer starts 20 s after the user manager (lingering is on for this user). Live recipe in SOP-0003.

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

- `2026-10-12` Retro. Went well: the repo already owned each repair (bringup, belt, bearings, seat rerun), so the supervisor is a short orchestrator and the new surface is process-based health plus the re-seat rule; every step landed with a case in a headless scratch herdr. Went badly: bringup stopped at the first failing pane and called label-correct dead panes ok (fixed: monitors.sh health); the interim watchers lived in ~/.cache with the month typed in. Not done and why: the three human criteria were not run live - installing units and wsl --shutdown are host actions a worker may not take; suite equivalents are in the evidence. Left for the architect or owner: make -C herdr supervisor-install from the main checkout, then release the interim record-watch pane (slot 2.3.2) so recwatch does not double-prompt; WO-20261012-da52 owns removing record-bus.sh from 2.3.3. Design choices: re-seat is a seat.sh rerun (keeps the lease), 2 sightings 20 s apart, 3 per 30 min cap; bearings restart honours a stop that was meant; a tab 4 'monitors 4 - watches' keeps the watches off glass (2.3.1) and the bus slots.

## Outcome

_Written by `work-order done`. Empty until then._
