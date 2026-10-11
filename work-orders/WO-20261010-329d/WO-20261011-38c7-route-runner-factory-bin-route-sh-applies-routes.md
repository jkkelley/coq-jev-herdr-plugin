---
{
  "id": "WO-20261011-38c7",
  "slug": "route-runner-factory-bin-route-sh-applies-routes",
  "title": "Route runner: factory/bin/route.sh applies routes.json to every new record and nothing else",
  "type": "feature",
  "status": "draft",
  "priority": "p0",
  "created": "2026-10-11",
  "updated": "2026-10-11",
  "created_at": "2026-10-11T14:39:37+00:00",
  "parent": "WO-20261010-329d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": null,
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [
    "WO-20261011-5355"
  ]
}
---

# WO-20261011-38c7 - Route runner: factory/bin/route.sh applies routes.json to every new record and nothing else

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

routes.json, queue.sh and event.sh exist but no process reads a record and performs its route, so every wake, enqueue and escalation is a human typing herdr commands and the belt is stopped

## Scope

**In**

- factory/bin/route.sh: watches events/ for records after a cursor, matches each against factory/config/routes.json top to bottom, performs the first row: wake (herdr agent prompt to the target seat's pane with the record id and its playbook path), enqueue (queue/bin/queue.sh enqueue), escalate (events/bin/event.sh add with code 423), notify_owner (one line to the interface agent)
- one record.routed 300 per action; a record matching no row becomes a 500 to the monitor; the belt state file under factory/state is touched every tick
- tests with fixture records and a stubbed herdr; RUNBOOK.md; graph nodes CMP-route-runner and RUN-route-runner with defined_in

**Out - non-goals**

- any branch on kind, code or note outside applying routes.json (hard cap: new behaviour is a routes.json row, never runner code)
- NATS JetStream and gRPC (WO-20261010-539f)
- seat bring-up (B3) and bringup ordering (B4)

## Degrees of freedom

- [free] the cursor file format, as long as a restart never routes a record twice
- [free] the poll interval, as long as it is between 5 and 30 seconds and read from config
- [free] the wake prompt text, as long as it carries only the record id and the playbook path

## Acceptance criteria

- [ ] `AC-H1` *(human)* a fixture pr.opened 100 record makes the runner wake the tester seat (the herdr stub logs the call) and write record.routed 300
- [ ] `AC-H2` *(human)* a fixture record matching no row produces a 500 record addressed to the monitor
- [ ] `AC-H3` *(human)* a fixture test.failed 422 with attempt 3 produces an escalation record with code 423 to the architect
- [ ] `AC-H4` *(human)* stop and restart the runner over the same events dir: nothing is routed twice
- [ ] `AC-H5` *(human)* add a new row to routes.json for a new kind, no runner code change: the runner performs it
- [ ] `AC-H6` *(human)* the belt state file is fresher than 60 seconds while running and goes stale within 60 seconds of a stop
- [ ] `AC-H7` *(human)* RUNBOOK.md lets a fresh reader run the runner against another repo's events dir and routes file; CMP-route-runner carries defined_in RUN-route-runner

## Test plan

```sh
make -C factory test # lint image, --network=none, herdr stubbed; cases: wake, 500, escalate, restart idempotence, new row, belt state make lint
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
