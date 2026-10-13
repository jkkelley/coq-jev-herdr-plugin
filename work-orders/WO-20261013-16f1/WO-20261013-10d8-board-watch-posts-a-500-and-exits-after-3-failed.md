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

- [x] `AC-H1` *(human)* A watch whose collect fails 3 passes in a row posts one 500 record and exits non-zero. One failed pass followed by a pass posts nothing. The patrol flags data.json older than 2 minutes within one tick. Tests cover both.
  - observed `2026-10-13` report/loop/tests/cases/18-watch-ladder.test.sh: 30 assertions pass from the test pane; the same case fails 16 assertions against the old loop.sh (exit 124 wanted 4). 3 failed passes in a row post one 500 to the architect and exit 4 (also under --iterations 0); fail,pass,fail,fail posts nothing; fail,fail,pass,fail,fail,fail posts one on pass 6. loop.sh age flags data.json 200s old (limit 120s, 119s is fresh), pages the orchestrator once per stale spell, re-arms when fresh; monitors.json slot 4.2.2 boardage runs it every 60s. make lint ok, report/loop suite 20 passed, herdr case 24-patrolwatch passes with the new slot.

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

- `2026-10-13` Correction to the AC-H1 evidence: the new case fails 22 assertions against the old loop.sh, not 16 (counted from the red run output); the 16 is a miscount, everything else in the evidence stands.
- `2026-10-13` Retro: the AC says flag data.json older than 2 minutes; kept literal. Known cost: data.json only moves when the floor moves, so a line idle over 2 minutes pages too (the live line moves it every few seconds in practice). The patrol check lives as loop.sh age plus monitors.json slot 4.2.2 boardage rather than in patrolwatch.sh (not in the ticket files, and that tick is a prompt skipped while the officer is busy). The test uses a stub sleep on PATH to change the world between passes, so loop.sh gained no test seam.

## Outcome

_Written by `work-order done`. Empty until then._
