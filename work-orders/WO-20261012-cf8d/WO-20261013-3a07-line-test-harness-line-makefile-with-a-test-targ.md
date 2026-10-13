---
{
  "id": "WO-20261013-3a07",
  "slug": "line-test-harness-line-makefile-with-a-test-targ",
  "title": "Line test harness: line/Makefile with a test target that runs line/tests/run.sh in Podman like herdr/tests, a shared test library and one smoke case (K1 part 1 of 5)",
  "type": "feature",
  "status": "ready",
  "priority": "p1",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T03:17:18+00:00",
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
  "blocks": [
    "WO-20261013-d6e1"
  ],
  "files": [
    "line/Makefile",
    "line/tests/run.sh",
    "line/tests/lib/*",
    "line/tests/cases/harness-*"
  ]
}
---

# WO-20261013-3a07 - Line test harness: line/Makefile with a test target that runs line/tests/run.sh in Podman like herdr/tests, a shared test library and one smoke case (K1 part 1 of 5)

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

Split of WO-20261013-f268 (Roadmap K1 - Board) under the owner's size rule of 2026-10-13 03:00Z. The board parts and the merge script need a line test target first.

## Scope

**In**

- line/Makefile test target, line/tests/run.sh and line/tests/lib/world.sh, modelled on herdr/tests and events/tests
- one smoke case, line/tests/cases/harness-smoke.sh

**Out - non-goals**

- the board itself (K1 parts 2 to 4)
- moving old scripts into line/ (roadmap item I)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* make -C line test runs every line/tests/cases/*.sh in Podman and passes with the smoke case
- [ ] `AC-H2` *(human)* make lint passes

## Test plan

```sh
make lint && make -C line test, in Podman through the repository targets
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
