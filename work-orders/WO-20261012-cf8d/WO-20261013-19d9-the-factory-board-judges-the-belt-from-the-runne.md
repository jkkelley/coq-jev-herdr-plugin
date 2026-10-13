---
{
  "id": "WO-20261013-19d9",
  "slug": "the-factory-board-judges-the-belt-from-the-runne",
  "title": "The factory board judges the belt from the runner's real belt file against belt_max_age_seconds, and the stale belt_state input is dropped (K8 part 4 of 5)",
  "type": "feature",
  "status": "ready",
  "priority": "p1",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T03:17:47+00:00",
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
  "depends_on": [
    "WO-20261013-e537"
  ],
  "blocks": [
    "WO-20261013-f15d"
  ],
  "files": [
    "report/loop/config/board.json",
    "report/loop/config/board.schema.json",
    "report/loop/loop.sh",
    "report/loop/tests/cases/08-belt.test.sh"
  ]
}
---

# WO-20261013-19d9 - The factory board judges the belt from the runner's real belt file against belt_max_age_seconds, and the stale belt_state input is dropped (K8 part 4 of 5)

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

Split of WO-20261013-89c7 (Roadmap K8) under the owner's size rule of 2026-10-13 03:00Z.

## Scope

**In**

- report/loop/config/board.json and its schema: the belt file through the repository's state variable (runner state_dir plus belt, written by route.sh belt_touch); belt_state removed
- loop.sh reads it; case report/loop/tests/cases/08-belt.test.sh

**Out - non-goals**

- factory/ files (A2 holds them)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* with a fresh belt file the board says the belt is fresh, and stopped once the file is older than belt_max_age_seconds
- [ ] `AC-H2` *(human)* make lint and make -C report/loop test pass in Podman

## Test plan

```sh
make lint && make -C report/loop test, in Podman through the repository targets
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
