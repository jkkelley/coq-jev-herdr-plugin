---
{
  "id": "WO-20261013-9617",
  "slug": "the-patrol-saw-eight-line-processes-dead-56-time",
  "title": "The patrol saw eight line processes dead 56 times but only queued them for an architect who was dead, and posts no card on the owner page (re-cut at line/bin/patrol-tick.sh)",
  "type": "bug",
  "status": "ready",
  "priority": "p1",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T17:54:20+00:00",
  "parent": "WO-20261013-16f1",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect ruling ykne9 2026-10-13 (Roadmap I split one ticket per script); lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261013-1258"
  ],
  "blocks": [],
  "files": [
    "line/bin/patrol-tick.sh",
    "line/tests/cases/patrol-escalate.sh"
  ]
}
---

# WO-20261013-9617 - The patrol saw eight line processes dead 56 times but only queued them for an architect who was dead, and posts no card on the owner page (re-cut at line/bin/patrol-tick.sh)

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

patrol-tick.sh:56-73 finding() posts a note 100 per key every 10 minutes and from the third sighting adds a p2 item to aq.sh (:69), the architect's queue, and prompts the target seat (:72). The process probe at :226-236 raised proc.* findings for eight line processes 56 times between 03:32Z and 13:00Z, all addressed to a dead seat, and the aq.sh entry waited for the architect, also dead. Nothing escalated to the owner. Re-cut of WO-20261013-1e9f, whose files named line/patrol-tick.sh, a path the Roadmap I move never creates.

## Scope

**In**

- a finding that reaches its third sighting with no seat record for the target in that span posts one card on the owner page through bearings.sh stable ask, with the finding, the sighting count and what has been tried
- one card per key per hour at most, cleared when the finding clears; the card text follows the owner prose rule
- line/tests/cases/patrol-escalate.sh proves both criteria with a stub bearings.sh and a dead target seat

**Out - non-goals**

- restarting the processes (the supervisor and the orchestrator own that)
- the move of the script (its own ticket, which this follows)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* with the target seat dead, a process finding seen three times produces exactly one card and a record naming it
- [ ] `AC-H2` *(human)* a finding handled by a live seat between sightings posts no card; make lint and make -C line test pass

## Test plan

```sh
make lint && make -C line test, in Podman through the repository targets
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
