---
{
  "id": "WO-20261012-be64",
  "slug": "roadmap-l-decision-nodes-for-the-locked-roadmap-",
  "title": "Roadmap L - Decision nodes for the locked roadmap decisions in the design graph, the NATS decision marked deferred and the bus ticket re-scoped",
  "type": "chore",
  "status": "ready",
  "priority": "p2",
  "created": "2026-10-12",
  "updated": "2026-10-13",
  "created_at": "2026-10-12T22:14:00+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "owner locked ROADMAP.md 2026-10-12 (cards C9 to C22) and gave USERGO; Getting My Bearings is the review surface, lavish is prohibited",
    "at": "2026-10-12"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261013-18d6",
    "WO-20261013-223e",
    "WO-20261013-3aea",
    "WO-20261013-4ce5",
    "WO-20261013-7fa3",
    "WO-20261013-b296",
    "WO-20261013-badd",
    "WO-20261013-c17f",
    "WO-20261013-c64d",
    "WO-20261013-e3f6",
    "WO-20261013-fe37"
  ],
  "blocks": [],
  "files": [
    "graph/nodes/DEC-roadmap-c*.json",
    "graph/nodes/DEC-nats-jetstream-grpc.json",
    "graph/INDEX.md",
    "graph/GRAPH.mmd"
  ]
}
---

# WO-20261012-be64 - Roadmap L - Decision nodes for the locked roadmap decisions in the design graph, the NATS decision marked deferred and the bus ticket re-scoped

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

The owner's cards C10 to C22 exist only in ROADMAP.md; the design graph still says the bus is NATS JetStream (card C15).

## Scope

**In**

- graph decision nodes for C10 to C22, the NATS node marked deferred, WO-20261010-539f re-scoped or cancelled

**Out - non-goals**

- graph changes beyond these decisions

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* graph check passes and each card has a node naming its date and answer

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

_Written by `work-order done`. Empty until then._
