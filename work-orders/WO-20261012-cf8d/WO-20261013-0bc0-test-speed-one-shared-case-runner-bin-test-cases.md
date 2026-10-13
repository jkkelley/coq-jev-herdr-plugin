---
{
  "id": "WO-20261013-0bc0",
  "slug": "test-speed-one-shared-case-runner-bin-test-cases",
  "title": "Test speed: one shared case runner, bin/test-cases.sh, runs each suite's cases in parallel, buffers each case's output and prints it whole in name order",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T15:50:58+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect P0 order 2026-10-13 (owner m-20261013154808303-p0c28: test suites cannot be the bottleneck); lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [
    "WO-20261013-74b6"
  ],
  "files": [
    "bin/test-cases.sh",
    "herdr/tests/run.sh",
    "factory/tests/run.sh",
    "events/tests/run.sh",
    "line/tests/run.sh"
  ]
}
---

# WO-20261013-0bc0 - Test speed: one shared case runner, bin/test-cases.sh, runs each suite's cases in parallel, buffers each case's output and prints it whole in name order

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

Owner 2026-10-13: test suites cannot be the bottleneck. Every suite runs its cases one after another, every pull request reruns whole suites main already ran, and herdr cases wait on fixed sleeps. Design: $COQ_STATE/plans/2026/10/20261013160000-test-speed-design.md (section d-shape 3)

## Scope

**In**

- bin/test-cases.sh CASE_DIR: runs every *.test.sh with JOBS at a time (default the core count), honours CASES as today, prints each case's buffered output whole in name order and the one summary line tests: N passed, M failed
- herdr/tests/run.sh, factory/tests/run.sh, events/tests/run.sh and line/tests/run.sh call it inside their container; herdr keeps its teardown check after all cases

**Out - non-goals**

- wall time and budgets (its own ticket)
- the cases themselves

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* each suite gives the same verdict as before with JOBS=1 and with the default, and herdr leaves no scratch session

## Test plan

```sh
make lint && make -C factory test && make -C herdr test && make -C events test && make -C line test, in Podman through the repository targets
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
