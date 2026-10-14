---
{
  "id": "WO-20261014-539a",
  "slug": "cause-ay-scheduler-testkit-world-copies-events-b",
  "title": "Cause ay: scheduler testkit world copies events/bin/event.sh without bin/state-root.sh and config/state.json, so make -C scheduler test fails on main",
  "type": "bug",
  "status": "done",
  "priority": "p0",
  "created": "2026-10-14",
  "updated": "2026-10-14",
  "created_at": "2026-10-14T01:43:20+00:00",
  "parent": "WO-20261013-16f1",
  "branch": "feat/cause-ay-scheduler-testkit-world-copies-events-b",
  "pr": 181,
  "closed": "2026-10-14",
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

- [x] `AC-H1` *(human)* worldFiles carries bin/state-root.sh and config/state.json with a breadcrumb; make -C scheduler test passes in the pod
  - observed `2026-10-14` make -C scheduler test green in pod from pane wD3:p1VW: ok cmd/scheduler, internal/core, internal/testkit (before: 2 testkit cases failed, exit 4 bin/state-root.sh missing); make -C scheduler lint and make lint green; worldFiles carries bin/state-root.sh and config/state.json with a breadcrumb (scheduler/internal/testkit/world.go:18-35)

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

- `2026-10-14` Retro: the ticket named world.go only, but once the writer could run, two more drifts in testkit_test.go surfaced: the writer prints the state-root file path (not an id) and writes under HOME, and gate kind test.failed needs --sha since WO-20261013-f298. Fixed in the same PR: test sets COQ_STATE to the world state dir and reads the printed path, builderSpecs test.failed gets SHA abc1234, World.CheckRecords sets COQ_STATE. Files touched beyond the ticket list: scheduler/internal/testkit/testkit_test.go. Cause class: a testkit copy of a script drifts when the script gains a dependency; world.go errors name a missing file but not a missing sourced file.

## Outcome

_Written by `work-order done`. Empty until then._
