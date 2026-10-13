---
{
  "id": "WO-20261013-ced5",
  "slug": "make-line-check-the-bring-up-checklist-b1-to-b8-",
  "title": "make line-check: the bring-up checklist B1 to B8 read-only, one line per node ok or FAILED, exit 1 on any FAILED (SPEC-17 T13; K4 part 2 of 4)",
  "type": "feature",
  "status": "ready",
  "priority": "p1",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T03:29:18+00:00",
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
    "WO-20261013-fd7d",
    "WO-20261012-41a3"
  ],
  "blocks": [
    "WO-20261013-8ed9"
  ],
  "files": [
    "Makefile",
    "line/bin/line-check.sh",
    "line/tests/cases/line-check*"
  ]
}
---

# WO-20261013-ced5 - make line-check: the bring-up checklist B1 to B8 read-only, one line per node ok or FAILED, exit 1 on any FAILED (SPEC-17 T13; K4 part 2 of 4)

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

Split of WO-20261013-f52a (Roadmap K4) under the owner's size rule of 2026-10-13 03:00Z.

## Scope

**In**

- Makefile target line-check calling line/bin/line-check.sh; nothing is written
- case line/tests/cases/line-check.sh

**Out - non-goals**

- starting anything (K4 part 3)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* line-check prints one line per node and exits 1 on any FAILED without writing
- [ ] `AC-H2` *(human)* make lint and make -C line test pass in Podman

## Test plan

```sh
make lint && make -C line test, in Podman through the repository targets
```

## Assumptions

1. interim until the scheduler is active: SPEC-16.F reads the same flags (f-halt, f-drain, f-recovery) at cut-over (owner 02:50Z)

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
