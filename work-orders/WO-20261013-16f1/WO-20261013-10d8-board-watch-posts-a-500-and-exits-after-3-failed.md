---
{
  "id": "WO-20261013-10d8",
  "slug": "board-watch-posts-a-500-and-exits-after-3-failed",
  "title": "Board watch posts a 500 and exits after 3 failed passes, and the patrol checks the board page age (cause ad)",
  "type": "bug",
  "status": "in-progress",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T22:49:18+00:00",
  "parent": "WO-20261013-16f1",
  "branch": "feat/board-watch-posts-a-500-and-exits-after-3-failed",
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "owner P0 22:50Z via architect: board froze 6h, watch failed silently",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [],
  "files": [
    "report/loop/loop.sh",
    "report/loop/tests/cases/18-watch-ladder.test.sh",
    "herdr/config/monitors.json"
  ]
}
---

# WO-20261013-10d8 - Board watch posts a 500 and exits after 3 failed passes, and the patrol checks the board page age (cause ad)

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

report/loop/loop.sh cmd_watch (line 316) logs 'pass N failed' and loops forever. On 2026-10-13 the board froze at 16:24Z with 3200+ failed passes ('cannot read the event records', line 241) and nobody was told for 6 hours; the owner saw it. Violates the ladder rule: retry 3 times, then report, never fail silently.

## Scope

**In**

- cmd_watch counts consecutive failed passes; at 3 it posts a 500 record to the architect naming the last error and exits non-zero; a passing pass resets the count. The patrol (system monitor) checks report/loop/out/data.json age under 2 minutes and pages the orchestrator when older. A herdr case proves both.

**Out - non-goals**

- Changing what collect reads, the render, or the page. The monitor pane supervision beyond the 3-fail exit.

## Degrees of freedom

- [free] The patrol check may live in an existing monitor script; choose the smallest place.

## Acceptance criteria

- [ ] `AC-H1` *(human)* A watch whose collect fails 3 passes in a row posts one 500 record and exits non-zero. One failed pass followed by a pass posts nothing. The patrol flags data.json older than 2 minutes within one tick. Tests cover both.

## Test plan

```sh
bash report/loop/tests (watch with a failing --root and --iterations) plus the patrol case via suites.sh plan.
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
