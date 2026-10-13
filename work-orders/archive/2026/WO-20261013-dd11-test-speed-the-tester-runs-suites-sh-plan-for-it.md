---
{
  "id": "WO-20261013-dd11",
  "slug": "test-speed-the-tester-runs-suites-sh-plan-for-it",
  "title": "Test speed: the tester runs suites.sh plan for its pull request instead of whole suites; the full suite runs once on main through verify-main.sh",
  "type": "feature",
  "status": "cancelled",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T15:50:55+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": null,
  "pr": null,
  "closed": "2026-10-13",
  "approval": {
    "via": "override",
    "reason": "architect P0 order 2026-10-13 (owner p0c28), design approved on card C29; re-cut for runnable plans and NN- case names; lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261013-f1ff"
  ],
  "blocks": [],
  "files": [
    "roles/tester.json",
    "playbooks/tester.md",
    "herdr/tests/cases/29-tester-runs-plan.test.sh"
  ],
  "superseded_by": "WO-20261013-b6f3"
}
---

# WO-20261013-dd11 - Test speed: the tester runs suites.sh plan for its pull request instead of whole suites; the full suite runs once on main through verify-main.sh

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

Owner 2026-10-13: test suites cannot be the bottleneck. Every suite runs its cases one after another, every pull request reruns whole suites main already ran, and herdr cases wait on fixed sleeps. Design: $COQ_STATE/plans/2026/10/20261013160000-test-speed-design.md (section d-shape 2)

## Scope

**In**

- roles/tester.json: the step that runs the ticket's test plan runs factory/bin/suites.sh plan for the pull request's base and head, plus any case the plan names by hand; the full set is verify-main's on main, never per pull request; playbooks/tester.md re-rendered
- herdr/tests/cases/29-tester-runs-plan.test.sh asserts the role and playbook name suites.sh plan (roles/ has no suite of its own; the herdr suite runs role tests)

**Out - non-goals**

- the map itself (WO-20261013-f1ff)
- the tester's model (WO-20261013-0f18)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* the role and playbook name suites.sh plan, the case fails without it, and the playbook check in lint reports no drift

## Test plan

```sh
make lint && make -C herdr test, in Podman through the repository targets
```

## Assumptions

1. WO-20261013-0f18 (pull request 96) and WO-20261013-73be (pull request 89) also edit the tester role and follow this ticket; their edges are written when those pull requests merge

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

Cancelled `2026-10-13` - nothing shipped.

- reason: superseded by WO-20261013-b6f3 (architect 23:15Z)
- superseded by: `WO-20261013-b6f3`

No branch, no PR and no merge commit exist for this work order.

