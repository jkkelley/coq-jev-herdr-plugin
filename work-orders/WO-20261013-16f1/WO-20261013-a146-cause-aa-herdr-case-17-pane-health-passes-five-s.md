---
{
  "id": "WO-20261013-a146",
  "slug": "cause-aa-herdr-case-17-pane-health-passes-five-s",
  "title": "Cause aa: herdr case 17-pane-health passes five suite runs in a row, in suite order, and an order dependence is fixed forward",
  "type": "bug",
  "status": "in-progress",
  "priority": "p1",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T22:02:53+00:00",
  "parent": "WO-20261013-16f1",
  "branch": "feat/cause-aa-herdr-case-17-pane-health-passes-five-s",
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect ruling 22:03Z",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [],
  "files": [
    "herdr/tests/cases/17-pane-health.test.sh"
  ]
}
---

# WO-20261013-a146 - Cause aa: herdr case 17-pane-health passes five suite runs in a row, in suite order, and an order dependence is fixed forward

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

Main 85e91d3 failed herdr case 17-pane-health once in suite order (a repeat inside 15 minutes wrote a second 500, got 2, want 1) and passed alone and on the f31bf7d rerun. It is a timing or ordering signature until proven otherwise (architect ruling 22:08Z).

## Scope

**In**

- Run the herdr suite five times in a row in suite order at main; if case 17 fails, find the order dependence (state or timing shared with the cases before it, or the polls changes of PRs 138, 139 and 140) and fix it forward; keep the proof in the ticket evidence

**Out - non-goals**

- No revert, no edit to the polls PRs unless the fix needs it, no change outside the herdr test world and herdr/bin

## Degrees of freedom

- [free] The fix shape is the worker's

## Acceptance criteria

- [x] `AC-H1` *(human)* AC-H1: five consecutive full herdr suite runs show case 17-pane-health pass. AC-H2: any order dependence found is fixed in the case or its helper with a breadcrumb comment. AC-H3: make lint and make -C herdr test exit 0
  - observed `2026-10-13` AC-H1: five consecutive full herdr suite runs at the fix, each 'tests: 32 passed, 0 failed' with '17-pane-health: pass' (logs fix-1..5.log in the seat scratchpad; five baseline runs at main also passed, so the flake needs load). AC-H2: cause was the 500 text carrying monitors.sh fg_process (bash/clear/jq/sleep by instant), which sl_report_500 dedups on exactly; herdr/bin/bringup.sh now records 'runs a job'; case 17 pins it with an assert that failed before the fix (got 'runs sleep') and passes after; breadcrumbs in both files. AC-H3: make lint rc=0 and make -C herdr lint clean before each of the five make -C herdr test runs, all rc=0.

## Test plan

```sh
make lint && make -C herdr test, five times
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-13` Retro: five idle-host baseline suite runs at main all passed, so the case 17 flake only shows under load. Fixed the cause (volatile process name in the 500 text defeating sl_report_500's exact-text dedup) in herdr/bin/bringup.sh rather than loosening the test, and added a deterministic assert. Ticket files list named only the case; bringup.sh is herdr/bin, inside the ticket's allowed scope. Treehouse lease check in worker step 1 did not apply: this seat's worktree is a git worktree under ~/.cache/coq, not a treehouse slot.

## Outcome

_Written by `work-order done`. Empty until then._
