---
{
  "id": "WO-20261013-dd11",
  "slug": "test-speed-the-tester-runs-suites-sh-plan-for-it",
  "title": "Test speed: the tester runs suites.sh plan for its pull request instead of whole suites; the full suite runs once on main through verify-main.sh",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T15:50:55+00:00",
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
    "WO-20261013-f1ff"
  ],
  "blocks": [],
  "files": [
    "roles/tester.json",
    "playbooks/tester.md"
  ]
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

**Out - non-goals**

- the map itself (its own ticket)
- the tester's model (WO-20261013-0f18)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* the role and playbook name suites.sh plan, the playbook check reports no drift and make lint passes

## Test plan

```sh
make lint && make -C roles test, in Podman through the repository targets
```

## Assumptions

1. WO-20261013-0f18 (pull request 96) and WO-20261013-73be (pull request 89) also edit the tester role and follow this ticket; their edges are written when those pull requests merge

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
