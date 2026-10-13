---
{
  "id": "WO-20261013-5f41",
  "slug": "role-caps-pinned-herdr-case-28-asserts-the-seat-",
  "title": "Role caps pinned: herdr case 28 asserts the seat caps pull request 99 sets (worker 6, reviewer 4, orchestrator 2)",
  "type": "test",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T16:54:06+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect ruling (b) 2026-10-13 on the dd47 and pull request 99 overlap; lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [],
  "files": [
    "herdr/tests/cases/28-role-caps.test.sh"
  ]
}
---

# WO-20261013-5f41 - Role caps pinned: herdr case 28 asserts the seat caps pull request 99 sets (worker 6, reviewer 4, orchestrator 2)

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

Pull request 99 (owner message m-20261013161912217-3d6g0, 15 seats available and agents idle) raised the worker, reviewer and orchestrator seat caps with no test, so a later role edit can silently drop them back. Rescoped from WO-20261013-dd47, whose cap change pull request 99 already makes (architect ruling (b), 2026-10-13).

## Scope

**In**

- herdr/tests/cases/28-role-caps.test.sh reads roles/worker.json, roles/reviewer.json and roles/orchestrator.json and asserts max_seats 6, 4 and 2, each failing on the old value (4, 2 and 1)

**Out - non-goals**

- the cap values themselves (pull request 99)
- role models (WO-20261013-0f18)
- herdr max_agents (WO-20261013-a1c6)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* the case passes on main after pull request 99 merges and fails when any one cap is set back to its old value; make lint and make -C herdr test pass

## Test plan

```sh
make lint && make -C herdr test, in Podman through the repository targets
```

## Assumptions

1. Start only after pull request 99 merges: until then main holds the old caps and the case fails. Pull request 99 has no work-order id, so the edge cannot be a depends_on and is held here; the orchestrator starts this ticket on that merge.

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
