---
{
  "id": "WO-20261013-70c4",
  "slug": "roadmap-k7-routes-and-lint-one-row-per-record-ki",
  "title": "Roadmap K7 - Routes and lint: one row per record kind and attempt, the owner seat read from the ticket, the router posts to the board and nudges with the lane, 429 and 500 rows to the orchestrator lane, merged 200 to the merger and the orchestrator, the stall policy, the architect digest and counter, and lint that every code of the SPEC-17 map has a row (widens item D)",
  "type": "feature",
  "status": "cancelled",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T00:57:40+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": null,
  "pr": null,
  "closed": "2026-10-13",
  "approval": {
    "via": "override",
    "reason": "owner accepted SPEC-17 on card C25; lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261013-f268",
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
  "superseded_by": "WO-20261013-44aa"
}
---

# WO-20261013-70c4 - Roadmap K7 - Routes and lint: one row per record kind and attempt, the owner seat read from the ticket, the router posts to the board and nudges with the lane, 429 and 500 rows to the orchestrator lane, merged 200 to the merger and the orchestrator, the stall policy, the architect digest and counter, and lint that every code of the SPEC-17 map has a row (widens item D)

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

Routes went to seats that do not exist (762 route failures by 2026-10-12), stalls escalated to the owner every 90 seconds, and the architect got a copy of everything. SPEC-17 s-lanes, s-architect and s-config name the rows and the digest; roadmap item D (WO-20261012-da1e) is superseded by this ticket.

## Scope

**In**

- lint fails a record kind with no routes row, a kind with two rows for one attempt, and a code of SPEC-17 s-codes with no row (T15); routes name the ticket's owner seat, never a built name
- factory/bin/route.sh posts each routed record to its lane through line/bin/board.sh post and nudges the idle consumer with the lane and the count; the wake line that carried the record id is retired
- routes rows: 429 refused and 500 seat findings to the orchestrator lane; merged 200 to the merger for the verify and to the orchestrator for the cleanup as one item; the architect row on merged 200 deleted
- the architect digest: one batched nudge of items addressed to the architect and not yet answered, every digest_seconds, the resume notice first after a compaction; an architect nudge counter per hour by kind on the health line
- the stall policy in factory/bin/flow.sh: wake the seat that owes the next record, retry, then escalate to the digest; owner notices capped

**Out - non-goals**

- the carry rule (E)
- the board script (K1)
- the health checks (K2)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* a test pushes 50 records through the router and the architect gets at most one nudge
- [ ] `AC-H2` *(human)* a stall wakes the owing seat and reaches the owner only after the configured retries
- [ ] `AC-H3` *(human)* a scheduler ticket's record routes to its owner seat with no hand forwarding
- [ ] `AC-H4` *(human)* lint fails a routes table where a code of the map has no row or a kind has two rows for one attempt, naming it (T15)

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

- reason: owner 03:00Z size rule: split into WO-20261013-44aa, WO-20261013-bed2, WO-20261013-04b8, WO-20261013-a7e6; the architect digest dropped for the 02:41Z delivery model
- superseded by: `WO-20261013-44aa`

No branch, no PR and no merge commit exist for this work order.

