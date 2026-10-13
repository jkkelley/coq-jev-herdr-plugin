---
{
  "id": "WO-20261013-0bc0",
  "slug": "test-speed-one-shared-case-runner-bin-test-cases",
  "title": "Test speed: one shared case runner, bin/test-cases.sh, runs each suite's cases in parallel, buffers each case's output and prints it whole in name order",
  "type": "feature",
  "status": "in-progress",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T15:50:58+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": "feat/test-speed-one-shared-case-runner-bin-test-cases",
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect P0 order 2026-10-13 (owner p0c28); design approved on card C29 with two conditions; lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [
    "WO-20261013-7757",
    "WO-20261013-74b6"
  ],
  "files": [
    "bin/test-cases.sh",
    "config/tests.json",
    "config/tests.schema.json",
    "herdr/tests/run.sh",
    "factory/tests/run.sh"
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

Owner 2026-10-13: test suites cannot be the bottleneck. Every suite runs its cases one after another, every pull request reruns whole suites main already ran, and herdr cases wait on fixed sleeps. Design: $COQ_STATE/plans/2026/10/20261013160000-test-speed-design.md (section d-shape 3). Condition 2 of the architect's approval (card C29): herdr died at 31.8G on 2026-10-13, so parallel herdr servers are capped: JOBS defaults to min(cores, 4) and is a config value.

## Scope

**In**

- bin/test-cases.sh CASE_DIR: runs every *.test.sh with JOBS at a time, honours CASES as today, prints each case's buffered output whole in name order and the one summary line tests: N passed, M failed
- config/tests.json and tests.schema.json: jobs, default min(cores, 4), a per-suite override, a breadcrumb naming the 31.8G herdr death; JOBS in the environment wins for one run
- herdr/tests/run.sh and factory/tests/run.sh call it inside their container; herdr keeps its teardown check after all cases

**Out - non-goals**

- events/tests/run.sh and line/tests/run.sh (their own ticket)
- wall time and budgets (WO-20261013-74b6)
- the cases themselves

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* with no JOBS set the runner uses min(cores, 4) from config/tests.json, and never more herdr servers than that
- [ ] `AC-H2` *(human)* herdr and factory give the same verdict with JOBS=1 and with the default, and herdr leaves no scratch session

## Test plan

```sh
make lint && make -C factory test && make -C herdr test, in Podman through the repository targets
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
