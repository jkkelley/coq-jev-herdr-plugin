---
{
  "id": "WO-20261013-6463",
  "slug": "cause-m-merge-sh-held-a-pull-request-on-an-older",
  "title": "Cause m: merge.sh held a pull request on an older sha-less test.passed; it judges the newest test.passed and review.passed per head",
  "type": "bug",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T16:37:33+00:00",
  "parent": "WO-20261013-16f1",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect P0 order 2026-10-13 (owner m-20261013162710557-e4nos: always a system loop), approved by the architect in the owner place (card C29); lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261013-2d35"
  ],
  "blocks": [],
  "files": [
    "line/bin/merge.sh",
    "line/tests/cases/merge-newest-gate.sh"
  ]
}
---

# WO-20261013-6463 - Cause m: merge.sh held a pull request on an older sha-less test.passed; it judges the newest test.passed and review.passed per head

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

Cause m (record e6qh2): merge.sh held PR 97 on co8nr, an older test.passed with no sha, though idyn5 with the sha was on the head.

## Scope

**In**

- line/bin/merge.sh reads only gate records whose sha is the pull request's head and takes the newest of each kind; a sha-less record is ignored
- line/tests/cases/merge-newest-gate.sh

**Out - non-goals**

- the writer refusing sha-less gates (WO-20261013-e9c0)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* an older sha-less test.passed beside a newer one with the head sha merges; a failed newest blocks

## Test plan

```sh
make lint && make -C line test, in Podman through the repository targets
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
