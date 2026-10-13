---
{
  "id": "WO-20261013-1e9f",
  "slug": "the-patrol-saw-eight-line-processes-dead-56-time",
  "title": "The patrol saw eight line processes dead 56 times but only queued them for an architect who was dead, and posts no card on the owner page",
  "type": "bug",
  "status": "cancelled",
  "priority": "p1",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T13:20:42+00:00",
  "parent": "WO-20261013-16f1",
  "branch": null,
  "pr": null,
  "closed": "2026-10-13",
  "approval": {
    "via": "override",
    "reason": "architect P0 order 2026-10-13 (owner m-20261013162710557-e4nos: always a system loop), approved by the architect in the owner place (card C29); lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [],
  "files": [
    "line/patrol-tick.sh",
    "line/tests/cases/patrol-escalate.sh"
  ],
  "superseded_by": "WO-20261013-9617"
}
---

# WO-20261013-1e9f - The patrol saw eight line processes dead 56 times but only queued them for an architect who was dead, and posts no card on the owner page

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

patrol-tick.sh:56-73 finding() posts a note 100 per key every 10 minutes and from the third sighting adds a p2 item to aq.sh (:69), the architect's queue, and prompts the target seat (:72). The process probe at :226-236 raised proc.* findings for eight line processes (route.sh run, route-retry.sh, record-bus, digest.sh, merge-watch.sh, turnwatch.sh, loop.sh watch, unfreeze.sh --watch) 56 times between 03:32Z and 13:00Z, all addressed to $MAINT (sched-worker-1), a seat that was dead, and the aq.sh entry waits for the architect, also dead. Nothing escalates to the only reader who was alive: the owner. Hand-offs end at seats; a finding with no acting seat after three sightings is a failure of the line, not of a seat.

## Scope

**In**

- a finding that reaches its third sighting with no seat record for the target in that span posts one card on the owner page through bearings.sh stable ask, with the finding, the sighting count and what has been tried
- one card per key per hour at most, cleared when the finding clears
- the card text follows the owner prose rule: a few short lines, the state, then the one decision

**Out - non-goals**

- restarting the processes (the supervisor and the orchestrator own that)

## Degrees of freedom

- [free] card wording, as long as it names the process and says how long it has been down

## Acceptance criteria

- [ ] `AC-H1` *(human)* in a test world with the target seat dead, a process finding seen three times produces exactly one bearings card and a record naming it
- [ ] `AC-H2` *(human)* a finding handled by a live seat between sightings posts no card

## Test plan

```sh
podman run --rm -v $PWD:/repo -w /repo <digest-pinned image> bash line/tests/patrol-escalate.test.sh
```

## Assumptions

1. line/patrol-tick.sh exists after Roadmap I (WO-20261012-90ce); the bearings card helper is the one watchdog.sh already uses

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

Cancelled `2026-10-13` - nothing shipped.

- reason: architect ruling ykne9: re-cut after the patrol move, at line/bin/patrol-tick.sh with a runnable plan; amend refuses an approved ticket
- superseded by: `WO-20261013-9617`

No branch, no PR and no merge commit exist for this work order.

