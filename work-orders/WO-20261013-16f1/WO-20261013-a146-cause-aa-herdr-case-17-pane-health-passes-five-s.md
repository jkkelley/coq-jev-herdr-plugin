---
{
  "id": "WO-20261013-a146",
  "slug": "cause-aa-herdr-case-17-pane-health-passes-five-s",
  "title": "Cause aa: herdr case 17-pane-health passes five suite runs in a row, in suite order, and an order dependence is fixed forward",
  "type": "bug",
  "status": "ready",
  "priority": "p1",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T22:02:53+00:00",
  "parent": "WO-20261013-16f1",
  "branch": null,
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

- [ ] `AC-H1` *(human)* AC-H1: five consecutive full herdr suite runs show case 17-pane-health pass. AC-H2: any order dependence found is fixed in the case or its helper with a breadcrumb comment. AC-H3: make lint and make -C herdr test exit 0

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

## Outcome

_Written by `work-order done`. Empty until then._
