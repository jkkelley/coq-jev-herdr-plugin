---
{
  "id": "WO-20261013-0529",
  "slug": "cause-z-follow-up-2-a-herdr-case-runs-roles-test",
  "title": "Cause z follow-up 2: a herdr case runs roles/tests/tester-plan.test.sh, so the tester-plan check runs in the herdr suite and is not a test nobody calls",
  "type": "bug",
  "status": "ready",
  "priority": "p1",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T23:16:06+00:00",
  "parent": "WO-20261013-16f1",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect order 23:15Z (174aa): cause z follow-ups; approved by the architect in the owner place",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [],
  "files": [
    "herdr/tests/cases/38-tester-plan-runs.test.sh"
  ]
}
---

# WO-20261013-0529 - Cause z follow-up 2: a herdr case runs roles/tests/tester-plan.test.sh, so the tester-plan check runs in the herdr suite and is not a test nobody calls

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

WO-20261013-b6f3 adds roles/tests/tester-plan.test.sh, but no suite calls it, so a regression in the tester plan goes unseen.

## Scope

**In**

- herdr/tests/cases/38-tester-plan-runs.test.sh: runs roles/tests/tester-plan.test.sh and fails when it fails

**Out - non-goals**

- the content of tester-plan.test.sh

## Degrees of freedom

- [free] [free] Case number

## Acceptance criteria

- [ ] `AC-H1` *(human)* herdr suite fails when roles/tests/tester-plan.test.sh fails

## Test plan

```sh
bash herdr/tests/cases/38-tester-plan-runs.test.sh
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
