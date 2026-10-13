---
{
  "id": "WO-20261013-4309",
  "slug": "the-ticket-queue-s-items-live-under-the-state-ro",
  "title": "The ticket queue's items live under the state root: items_dir in queue/config/queue.json moves under the state root and the queue schema allows it (K1 part 5 of 5)",
  "type": "feature",
  "status": "ready",
  "priority": "p1",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T03:17:29+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "owner 2026-10-13 03:00Z (record 57h60): one concern, at most 5 files, under about 300 lines; lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [],
  "files": [
    "queue/config/queue.json",
    "queue/config/queue.schema.json"
  ]
}
---

# WO-20261013-4309 - The ticket queue's items live under the state root: items_dir in queue/config/queue.json moves under the state root and the queue schema allows it (K1 part 5 of 5)

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

Split of WO-20261013-f268 (Roadmap K1 - Board) under the owner's size rule of 2026-10-13 03:00Z: runtime data never in git.

## Scope

**In**

- queue/config/queue.json items_dir under the state root variable; queue/config/queue.schema.json accepts it

**Out - non-goals**

- the board (K1 parts 2 to 4)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* queue/bin/queue.sh lists and pulls items from the state root and nothing is written in the checkout
- [ ] `AC-H2` *(human)* make lint passes

## Test plan

```sh
make lint, in Podman through the repository target
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
