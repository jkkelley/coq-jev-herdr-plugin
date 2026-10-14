---
{
  "id": "WO-20261013-74b6",
  "slug": "test-speed-every-case-prints-its-wall-time-and-f",
  "title": "Test speed: every case prints its wall time and fails over its budget, from config/tests.json",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-14",
  "created_at": "2026-10-13T15:51:01+00:00",
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
    "WO-20261013-0bc0",
    "WO-20261013-249e"
  ],
  "blocks": [],
  "files": [
    "bin/test-cases.sh",
    "config/tests.json",
    "config/tests.schema.json",
    "factory/tests/cases/20-runner-budget.test.sh"
  ]
}
---

# WO-20261013-74b6 - Test speed: every case prints its wall time and fails over its budget, from config/tests.json

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

Owner 2026-10-13: test suites cannot be the bottleneck. Every suite runs its cases one after another, every pull request reruns whole suites main already ran, and herdr cases wait on fixed sleeps. Design: $COQ_STATE/plans/2026/10/20261013160000-test-speed-design.md (section d-shape 4)

## Scope

**In**

- bin/test-cases.sh prints -- <case>: pass <seconds>s and fails a case over its budget; config/tests.json and tests.schema.json gain the default budget and per-suite overrides, each with a reason
- factory/tests/cases/20-runner-budget.test.sh: a stub case over budget fails with its name and time

**Out - non-goals**

- making any case faster (the poll tickets)
- the jobs value (WO-20261013-0bc0)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* every case line carries its time, a case over budget turns the suite red naming it, and make lint passes

## Test plan

```sh
make lint && make -C factory test, in Podman through the repository targets
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
