---
{
  "id": "WO-20261013-4dc2",
  "slug": "cause-r-a-tickets-only-pull-request-is-gated-by-",
  "title": "Cause r: a tickets-only pull request is gated by a script, not a tester seat; line/bin/gate-tickets.sh runs lint and reindex --check on the head at pr.opened and posts test.passed or test.failed with the sha",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T19:14:48+00:00",
  "parent": "WO-20261013-16f1",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect P0 order 19:16Z, system loop: tickets-only gate as a script; approved by the architect in the owner place",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [],
  "files": [
    "line/bin/gate-tickets.sh",
    "line/tests/cases/gate-tickets.test.sh"
  ]
}
---

# WO-20261013-4dc2 - Cause r: a tickets-only pull request is gated by a script, not a tester seat; line/bin/gate-tickets.sh runs lint and reindex --check on the head at pr.opened and posts test.passed or test.failed with the sha

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

Testers are the bottleneck (8 PRs awaiting test at 19:16Z, cap 4). A tickets-only PR needs only lint, reindex and reindex --check, about a minute, yet it takes a tester seat of about 3 minutes to bring up.

## Scope

**In**

- line/bin/gate-tickets.sh: given --pr N, detect that the PR head touches only work-orders/ files, check the head out in a clean worktree, run make lint and work-order.sh reindex --check, retry 3 times, then post test.passed 201 or test.failed with --pr and the head sha through events/bin/event.sh
- line/tests/cases/ case for gate-tickets.sh: a tickets-only PR passes, a PR touching code is refused with exit 2 and no record, a bad reindex posts test.failed

**Out - non-goals**

- wiring the script to the pr.opened route (a follow-up ticket for factory/bin/route.sh, after WO-20261013-439d)

## Degrees of freedom

- [free] Whether the line tests dir already has a runner to reuse

## Acceptance criteria

- [ ] `AC-H1` *(human)* gate-tickets.sh --pr N on a tickets-only head posts test.passed with the sha within 2 minutes and without a seat
- [ ] `AC-H2` *(human)* A non-tickets PR is refused, exit 2

## Test plan

```sh
line suite case with a scratch repo and a stub gh and event.sh; assert records and exit codes
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
