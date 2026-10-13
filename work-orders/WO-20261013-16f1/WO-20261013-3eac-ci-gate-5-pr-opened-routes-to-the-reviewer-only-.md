---
{
  "id": "WO-20261013-3eac",
  "slug": "ci-gate-5-pr-opened-routes-to-the-reviewer-only-",
  "title": "CI gate 5: pr.opened routes to the reviewer only; the tester role is retired and its playbook marked retired",
  "type": "chore",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T19:47:04+00:00",
  "parent": "WO-20261013-16f1",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect order 19:50Z (C29 CI gate design approved, owner m-20261013194434026-yz0ob), system loop p0; approved by the architect in the owner place",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261013-3217",
    "WO-20261013-aff2"
  ],
  "blocks": [],
  "files": [
    "factory/config/routes.json",
    "roles/tester.json",
    "playbooks/tester.md",
    "factory/tests/cases/23-no-tester-route.test.sh"
  ]
}
---

# WO-20261013-3eac - CI gate 5: pr.opened routes to the reviewer only; the tester role is retired and its playbook marked retired

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

Design /home/luna/.local/state/coq/coq-jev-herdr-plugin/plans/2026/10/20261013194800-ci-gate-design.md, ticket 5. Input: merge.sh keys on the gate (ticket 3) and main verdicts come from the gate (ticket 4). Output: no tester seat is ever seated; testers keep running until this lands.

## Scope

**In**

- factory/config/routes.json: pr.opened seats the reviewer only
- roles/tester.json and playbooks/tester.md: marked retired
- factory/tests/cases/23-no-tester-route.test.sh

**Out - non-goals**

- deleting the tester role file (kept as retired)

## Degrees of freedom

- [free] How retired is marked in the role schema

## Acceptance criteria

- [ ] `AC-H1` *(human)* pr.opened produces a reviewer seat request and no tester request
- [ ] `AC-H2` *(human)* The tester playbook states it is retired

## Test plan

```sh
bash factory/tests/cases/23-no-tester-route.test.sh
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
