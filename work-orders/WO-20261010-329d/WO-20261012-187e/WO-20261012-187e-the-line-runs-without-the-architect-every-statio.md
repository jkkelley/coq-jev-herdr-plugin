---
{
  "id": "WO-20261012-187e",
  "slug": "the-line-runs-without-the-architect-every-statio",
  "title": "The line runs without the architect: every station is a seat or a rule, so a dead architect or an absent owner never stops a ticket moving",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T14:04:45+00:00",
  "parent": "WO-20261010-329d",
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

# WO-20261012-187e - The line runs without the architect: every station is a seat or a rule, so a dead architect or an absent owner never stops a ticket moving

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

On 2026-10-12 the line sat idle from 13:16Z to 13:53Z because the architect session crashed: every gate record waited for the architect to copy it into the checkout, wake the next seat, judge a sha, or seat a station. Owner: the system must live on without us, like Factorio.

## Scope

**In**

_none_

**Out - non-goals**

- replacing herdr, treehouse or claude itself
- removing the owner's one-time break glass authority

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* with the architect pane closed for one full ticket, a pr.opened reaches merged and verified with no human or architect action, observed in events/
- [ ] `AC-H2` *(human)* every row of routes.json names a role seat as its target, none names the architect or the owner except escalations that no policy covers

## Test plan

_none recorded - Rule 14 says this runs in a container_

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
