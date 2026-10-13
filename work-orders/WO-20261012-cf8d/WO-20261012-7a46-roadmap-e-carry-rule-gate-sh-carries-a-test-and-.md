---
{
  "id": "WO-20261012-7a46",
  "slug": "roadmap-e-carry-rule-gate-sh-carries-a-test-and-",
  "title": "Roadmap E - Carry rule: gate.sh carries a test and review when a pull request's own files equal the tested commit",
  "type": "feature",
  "status": "ready",
  "priority": "p1",
  "created": "2026-10-12",
  "updated": "2026-10-13",
  "created_at": "2026-10-12T22:13:51+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "owner locked ROADMAP.md 2026-10-12 (cards C9 to C22) and gave USERGO; Getting My Bearings is the review surface, lavish is prohibited",
    "at": "2026-10-12"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261013-bed2",
    "WO-20261013-2298"
  ],
  "blocks": [
    "WO-20261012-e970",
    "WO-20261013-f52a",
    "WO-20261013-8ed9"
  ],
  "files": [
    "factory/bin/gate.sh",
    "factory/tests/cases/*gate-carry*"
  ]
}
---

# WO-20261012-7a46 - Roadmap E - Carry rule: gate.sh carries a test and review when a pull request's own files equal the tested commit

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

Every main merge into a branch made the architect compare files by hand and post carried results (2026-10-12).

## Scope

**In**

- gate.sh compares the PR's own files at the head with the tested sha and posts the carried result as the gate

**Out - non-goals**

- carrying when any own file changed

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* a head that differs from the tested sha only by a main merge carries test and review with no architect record
- [ ] `AC-H2` *(human)* a head with one own file changed does not carry

## Test plan

```sh
make lint && make -C factory test && make -C herdr test, all in Podman through the repository targets
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
