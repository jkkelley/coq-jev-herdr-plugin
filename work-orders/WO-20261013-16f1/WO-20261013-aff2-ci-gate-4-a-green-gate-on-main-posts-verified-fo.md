---
{
  "id": "WO-20261013-aff2",
  "slug": "ci-gate-4-a-green-gate-on-main-posts-verified-fo",
  "title": "CI gate 4: a green gate on main posts verified for every merge since the last verified sha, a red one posts rejected and sets the merge hold",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T19:46:58+00:00",
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
    "WO-20261013-ab25"
  ],
  "blocks": [
    "WO-20261013-3eac"
  ],
  "files": [
    "ci/bin/main-gate.sh",
    "ci/tests/cases/04-main-gate.test.sh"
  ]
}
---

# WO-20261013-aff2 - CI gate 4: a green gate on main posts verified for every merge since the last verified sha, a red one posts rejected and sets the merge hold

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

Design /home/luna/.local/state/coq/coq-jev-herdr-plugin/plans/2026/10/20261013194800-ci-gate-design.md, ticket 4. Input: the gate runs on push to main (ticket 2). Output: verified 200 or rejected 422 records for the range, replacing the verify-main seat runs.

## Scope

**In**

- ci/bin/main-gate.sh: from the gate result on a main sha, post verified per PR in the range since the last verified sha, or rejected naming the failing suite and set the hold; retry 3 times then report
- ci/tests/cases/04-main-gate.test.sh

**Out - non-goals**

- removing line/bin/verify-main.sh (a follow-up)

## Degrees of freedom

- [free] Where the last verified sha is kept (outside the repo)

## Acceptance criteria

- [ ] `AC-H1` *(human)* A green main sha posts one verified per merged PR since the last verified sha
- [ ] `AC-H2` *(human)* A red one posts rejected with the failing suite and the hold

## Test plan

```sh
bash ci/tests/cases/04-main-gate.test.sh
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
