---
{
  "id": "WO-20261013-ee5c",
  "slug": "cause-s-the-patrol-counts-a-line-process-by-its-",
  "title": "Cause s: the patrol counts a line process by its exact argv0 script, not by any command line that names the script, so route-retry.sh and merge-watch.sh no longer show two instances",
  "type": "bug",
  "status": "ready",
  "priority": "p1",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T20:07:59+00:00",
  "parent": "WO-20261013-16f1",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect order 20:20Z: patrol process count must match the exact process; approved by the architect in the owner place",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261013-1258"
  ],
  "blocks": [],
  "files": [
    "line/bin/patrol-tick.sh",
    "line/tests/cases/patrol-process-count.test.sh"
  ]
}
---

# WO-20261013-ee5c - Cause s: the patrol counts a line process by its exact argv0 script, not by any command line that names the script, so route-retry.sh and merge-watch.sh no longer show two instances

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

At 20:04Z the patrol reported route-retry.sh and merge-watch.sh with 2 top-level instances each. The second match was a seat.sh command whose --task text named the script. The process count matches the whole command line (pgrep -f style), so any argument that names a script is counted. False findings cost an orchestrator turn each.

## Scope

**In**

- line/bin/patrol-tick.sh (landing via WO-20261013-1258): count a process only when its argv0 or the script argument right after the interpreter is the script path
- line/tests/cases/patrol-process-count.test.sh: a process whose argument text names the script is not counted; two real instances are

**Out - non-goals**

- the patrol's other checks

## Degrees of freedom

- [free] How argv is read (/proc/PID/cmdline split on NUL, or ps -o args with the first two words)

## Acceptance criteria

- [ ] `AC-H1` *(human)* A seat.sh command whose --task text names route-retry.sh adds no instance
- [ ] `AC-H2` *(human)* Two real route-retry.sh processes are still reported

## Test plan

```sh
bash line/tests/cases/patrol-process-count.test.sh
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
