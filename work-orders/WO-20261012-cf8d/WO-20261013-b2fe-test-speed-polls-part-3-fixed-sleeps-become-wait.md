---
{
  "id": "WO-20261013-b2fe",
  "slug": "test-speed-polls-part-3-fixed-sleeps-become-wait",
  "title": "Test speed, polls part 3: fixed sleeps become wait_until polls in herdr cases 16-test-pane-per-seat, 24-patrolwatch, 02-audit, 04-bringup-monitors, 12-blueprint-panes",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T15:51:09+00:00",
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
  "depends_on": [
    "WO-20261013-892f"
  ],
  "blocks": [],
  "files": [
    "herdr/tests/cases/16-test-pane-per-seat.test.sh",
    "herdr/tests/cases/24-patrolwatch.test.sh",
    "herdr/tests/cases/02-audit.test.sh",
    "herdr/tests/cases/04-bringup-monitors.test.sh",
    "herdr/tests/cases/12-blueprint-panes.test.sh"
  ]
}
---

# WO-20261013-b2fe - Test speed, polls part 3: fixed sleeps become wait_until polls in herdr cases 16-test-pane-per-seat, 24-patrolwatch, 02-audit, 04-bringup-monitors, 12-blueprint-panes

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

Owner 2026-10-13: test suites cannot be the bottleneck. Every suite runs its cases one after another, every pull request reruns whole suites main already ran, and herdr cases wait on fixed sleeps. Design: $COQ_STATE/plans/2026/10/20261013160000-test-speed-design.md (section d-shape 5)

## Scope

**In**

- every fixed sleep in these cases becomes wait_until on the condition it waited for; a sleep that is the thing under test stays with a comment

**Out - non-goals**

- herdr/tests/lib/world.sh (part 1)
- cases of other parts

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* these cases pass and carry no uncommented fixed sleep; make -C herdr test passes

## Test plan

```sh
make lint && make -C herdr test, in Podman through the repository targets
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
