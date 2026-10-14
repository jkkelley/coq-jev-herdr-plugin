---
{
  "id": "WO-20261014-539a",
  "slug": "cause-ay-scheduler-testkit-world-copies-events-b",
  "title": "Cause ay: scheduler testkit world copies events/bin/event.sh without bin/state-root.sh and config/state.json, so make -C scheduler test fails on main",
  "type": "bug",
  "status": "in-progress",
  "priority": "p0",
  "created": "2026-10-14",
  "updated": "2026-10-14",
  "created_at": "2026-10-14T01:43:20+00:00",
  "parent": "WO-20261013-16f1",
  "branch": "feat/cause-ay-scheduler-testkit-world-copies-events-b",
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "Architect ruling 20261014014251",
    "at": "2026-10-14"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [],
  "files": [
    "scheduler/internal/testkit/world.go"
  ]
}
---

# WO-20261014-539a - Cause ay: scheduler testkit world copies events/bin/event.sh without bin/state-root.sh and config/state.json, so make -C scheduler test fails on main

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

scheduler/internal/testkit/world.go worldFiles (line 22) copies events/bin/event.sh but event.sh line 40 sources ../bin/state-root.sh and needs config/state.json; the World's event writer exits 4 and 2 testkit cases fail. Main is red on make -C scheduler test (architect ruling 20261014014251).

## Scope

**In**

- scheduler/internal/testkit/world.go: add bin/state-root.sh and config/state.json to worldFiles, with a breadcrumb comment

**Out - non-goals**

- make -C scheduler test green; main verified

## Degrees of freedom

- [free] Any way of copying the two files into the world.

## Acceptance criteria

- [ ] `AC-H1` *(human)* worldFiles carries bin/state-root.sh and config/state.json with a breadcrumb; make -C scheduler test passes in the pod

## Test plan

```sh
make -C scheduler test; make lint
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
