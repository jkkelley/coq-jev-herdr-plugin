---
{
  "id": "WO-20261012-da1e",
  "slug": "roadmap-d-one-consumer-per-record-kind-the-owner",
  "title": "Roadmap D - One consumer per record kind, the owner seat from the ticket, the architect digest, the stall policy and a flood test",
  "type": "feature",
  "status": "cancelled",
  "priority": "p0",
  "created": "2026-10-12",
  "updated": "2026-10-13",
  "created_at": "2026-10-12T22:13:47+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": null,
  "pr": null,
  "closed": "2026-10-13",
  "approval": {
    "via": "override",
    "reason": "owner locked ROADMAP.md 2026-10-12 (cards C9 to C22) and gave USERGO; Getting My Bearings is the review surface, lavish is prohibited",
    "at": "2026-10-12"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261012-6f13",
    "WO-20261012-0229"
  ],
  "blocks": [],
  "files": [
    "factory/config/routes.json",
    "factory/config/routes.schema.json",
    "factory/bin/route.sh",
    "factory/bin/flow.sh",
    "factory/config/flow.json",
    "factory/config/flow.schema.json",
    "factory/bin/digest.sh",
    "factory/tests/cases/*"
  ],
  "superseded_by": "WO-20261013-70c4"
}
---

# WO-20261012-da1e - Roadmap D - One consumer per record kind, the owner seat from the ticket, the architect digest, the stall policy and a flood test

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

Routes went to seats that do not exist (762 route failures by 2026-10-12), stalls escalated to the owner every 90 seconds, and the architect got a copy of everything.

## Scope

**In**

- lint fails a record kind with no routes row; routes name the ticket's owner seat
- the architect digest: one batched prompt of items addressed to the architect and not yet answered; the resume notice first after a compaction
- the stall policy: wake the seat that owes the next record, retry, then escalate; owner notices capped
- an architect prompt counter per hour by kind

**Out - non-goals**

- the carry rule (E)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* a test pushes 50 records through the router and the architect gets at most one prompt
- [ ] `AC-H2` *(human)* a stall wakes the owing seat and reaches the owner only after the configured retries
- [ ] `AC-H3` *(human)* a scheduler ticket's record routes to its owner seat with no hand forwarding

## Test plan

```sh
make lint && make -C factory test && make -C herdr test, all in Podman through the repository targets
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

Cancelled `2026-10-13` - nothing shipped.

- reason: superseded by WO-20261013-70c4: Roadmap K7 widens item D with the board post and the rows of SPEC-17 s-config
- superseded by: `WO-20261013-70c4`

No branch, no PR and no merge commit exist for this work order.

