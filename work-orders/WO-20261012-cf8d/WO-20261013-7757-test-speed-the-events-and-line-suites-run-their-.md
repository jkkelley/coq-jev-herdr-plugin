---
{
  "id": "WO-20261013-7757",
  "slug": "test-speed-the-events-and-line-suites-run-their-",
  "title": "Test speed: the events and line suites run their cases through bin/test-cases.sh",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T15:55:02+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect P0 order 2026-10-13 (owner p0c28), design approved on card C29; re-cut for runnable plans and NN- case names; lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261013-0bc0"
  ],
  "blocks": [],
  "files": [
    "events/tests/run.sh",
    "line/tests/run.sh"
  ]
}
---

# WO-20261013-7757 - Test speed: the events and line suites run their cases through bin/test-cases.sh

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

Owner 2026-10-13: test suites cannot be the bottleneck. Every suite runs its cases one after another, every pull request reruns whole suites main already ran, and herdr cases wait on fixed sleeps. Design: $COQ_STATE/plans/2026/10/20261013160000-test-speed-design.md (section d-shape 3); split from WO-20261013-0bc0 so each ticket stays at five files.

## Scope

**In**

- events/tests/run.sh and line/tests/run.sh call bin/test-cases.sh inside their container

**Out - non-goals**

- the runner and its config (WO-20261013-0bc0)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* both suites give the same verdict with JOBS=1 and with the default

## Test plan

```sh
make lint && bash events/tests/run.sh && make -C line test, in Podman (events/tests/run.sh re-execs itself in Podman)
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
