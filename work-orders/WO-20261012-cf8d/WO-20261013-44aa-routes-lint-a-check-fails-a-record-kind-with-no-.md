---
{
  "id": "WO-20261013-44aa",
  "slug": "routes-lint-a-check-fails-a-record-kind-with-no-",
  "title": "Routes lint: a check fails a record kind with no routes row, a kind with two rows for one attempt and a SPEC-17 code with no row, naming it (SPEC-17 T15; K7 part 1 of 4)",
  "type": "feature",
  "status": "ready",
  "priority": "p1",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T03:29:29+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "owner 2026-10-13 03:00Z (record 57h60) size rule and 02:50Z (lvvtd) SPEC-16 is the engine; lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261012-0229"
  ],
  "blocks": [
    "WO-20261013-bed2"
  ],
  "files": [
    "factory/bin/routes-lint.sh",
    "factory/config/routes.schema.json",
    "factory/tests/cases/*routes-lint*"
  ]
}
---

# WO-20261013-44aa - Routes lint: a check fails a record kind with no routes row, a kind with two rows for one attempt and a SPEC-17 code with no row, naming it (SPEC-17 T15; K7 part 1 of 4)

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

Split of WO-20261013-70c4 (Roadmap K7 - routes and lint) under the owner's size rule of 2026-10-13 03:00Z; routes rows are SPEC-16.B's data and stay.

## Scope

**In**

- factory/bin/routes-lint.sh and factory/config/routes.schema.json; case factory/tests/cases/*routes-lint*

**Out - non-goals**

- the rows themselves (K7 part 2)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* the check names the kind or code on each failure and passes on the shipped table once the rows land
- [ ] `AC-H2` *(human)* make lint and make -C factory test pass in Podman

## Test plan

```sh
make lint && make -C factory test, in Podman through the repository targets
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
