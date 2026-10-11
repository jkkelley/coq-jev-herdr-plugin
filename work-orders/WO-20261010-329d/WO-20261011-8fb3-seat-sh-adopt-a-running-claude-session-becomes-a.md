---
{
  "id": "WO-20261011-8fb3",
  "slug": "seat-sh-adopt-a-running-claude-session-becomes-a",
  "title": "seat.sh adopt: a running claude session becomes a seat in place, keeping its context, under the role's label, settings and record",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-11",
  "updated": "2026-10-11",
  "created_at": "2026-10-11T18:42:54+00:00",
  "parent": "WO-20261010-329d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "Claude seat; Lavish is prohibited for Claude seats by the owner hard rule; owner order 18:38Z get the system operational",
    "at": "2026-10-11"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": []
}
---

# WO-20261011-8fb3 - seat.sh adopt: a running claude session becomes a seat in place, keeping its context, under the role's label, settings and record

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

The owner ordered the architect session to become the interface agent with all its context (DEC-architect-becomes-interface-agent). seat.sh can only start a fresh claude, so a context transfer today means a new model with none of the day in it.

## Scope

**In**

- seat.sh --adopt --role R --pane P --session ID [--worktree DIR]: writes seat.json for the role's seat name with the live session id, relabels the pane with the role label, writes the role settings.json for the next restart, exports nothing it cannot, records seat.up 100 with kind adopt in the note, and starts no agent
- seat.sh --check reads an adopted seat like any other; --down on an adopted seat retires the record and relabels but never kills the pane
- a --resume ID flag on the normal start path so a seat can also be re-started from a session transcript in a fresh pane
- runbook section and suite cases

**Out - non-goals**

- changing the live session's permission mode or model (the owner does that in the pane); the settings file applies at the next start

## Degrees of freedom

- [free] the adopt note wording, as long as it names the session id and the pane

## Acceptance criteria

- [ ] `AC-H1` *(human)* seat.sh --adopt on a live pane writes seat.json and the label, records seat.up, and seat.sh --check reports the seat ok with the agent running
- [ ] `AC-H2` *(human)* seat.sh --down on the adopted seat leaves the pane and its agent alive and records seat.down
- [ ] `AC-H3` *(human)* seat.sh --ticket X --role R --resume ID starts claude with --resume ID in the stub harness
- [ ] `AC-H4` *(human)* make -C herdr test and make lint green

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
