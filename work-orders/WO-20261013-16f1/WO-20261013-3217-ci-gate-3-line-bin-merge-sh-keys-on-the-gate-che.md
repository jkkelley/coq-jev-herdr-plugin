---
{
  "id": "WO-20261013-3217",
  "slug": "ci-gate-3-line-bin-merge-sh-keys-on-the-gate-che",
  "title": "CI gate 3: line/bin/merge.sh keys on the gate check of the head sha plus review.passed, not on a test.passed record",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T19:46:51+00:00",
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
    "line/bin/merge.sh",
    "line/tests/cases/merge-gate-check.test.sh"
  ]
}
---

# WO-20261013-3217 - CI gate 3: line/bin/merge.sh keys on the gate check of the head sha plus review.passed, not on a test.passed record

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

Design /home/luna/.local/state/coq/coq-jev-herdr-plugin/plans/2026/10/20261013194800-ci-gate-design.md, ticket 3. Input: the gate check exists (ticket 2). Output: the merger merges on gate success of the head sha and review.passed. Note: WO-20261013-2d35 also names merge.sh; run after it.

## Scope

**In**

- line/bin/merge.sh: read the gate check for the head sha with gh, merge only on success, hold on failure or cancelled
- line/tests/cases/merge-gate-check.test.sh

**Out - non-goals**

- routes (ticket 5)

## Degrees of freedom

- [free] How the check is read (gh api or gh pr checks)

## Acceptance criteria

- [ ] `AC-H1` *(human)* merge.sh --pr N refuses with exit 3 when the gate check of the head sha is not success
- [ ] `AC-H2` *(human)* With gate success and review.passed it merges

## Test plan

```sh
bash line/tests/cases/merge-gate-check.test.sh
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
