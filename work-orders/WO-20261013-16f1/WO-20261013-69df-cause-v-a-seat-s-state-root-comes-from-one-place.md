---
{
  "id": "WO-20261013-69df",
  "slug": "cause-v-a-seat-s-state-root-comes-from-one-place",
  "title": "Cause v: a seat's state root comes from one place (COQ_STATE or the XDG state root), never from the checkout it was seated from; seat.sh refuses a seat whose records tree is not the canonical one",
  "type": "bug",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T20:12:12+00:00",
  "parent": "WO-20261013-16f1",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect order 20:23Z cause v, system slot p0; approved by the architect in the owner place",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [],
  "files": [
    "herdr/bin/seat-lib.sh",
    "herdr/tests/cases/36-seat-canonical-state-root.test.sh"
  ]
}
---

# WO-20261013-69df - Cause v: a seat's state root comes from one place (COQ_STATE or the XDG state root), never from the checkout it was seated from; seat.sh refuses a seat whose records tree is not the canonical one

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

At 20:03Z three Sonnet testers were seated by seat.sh run from the verify-fba7551 worktree. Their records (test.passed for PR 127, 128, 112) landed in ~/.local/state/coq/verify-fba7551/records, not ~/.local/state/coq/coq-jev-herdr-plugin/records, so the merger never saw them. The state root is derived from the checkout path. The orchestrator copied the records by hand, which is a defect.

## Scope

**In**

- herdr/bin/seat.sh and herdr/bin/seat-lib.sh: resolve the records tree from COQ_STATE or the XDG state root only; at seat start, refuse (exit 3) if the resolved records tree is not the canonical one, naming both paths
- herdr/tests/cases/36-seat-canonical-state-root.test.sh: a seat started from a second worktree gets the canonical records tree, or is refused

**Out - non-goals**

- the treehouse-slot case (WO-20261013-496d, merged) and the lease logic

## Degrees of freedom

- [free] Where the canonical root is read (seat-lib.sh helper or bin/state-root.sh)

## Acceptance criteria

- [ ] `AC-H1` *(human)* A seat started from any worktree posts its records into the canonical records tree
- [ ] `AC-H2` *(human)* A seat whose resolved tree differs is refused with exit 3 and no records written elsewhere

## Test plan

```sh
bash herdr/tests/cases/36-seat-canonical-state-root.test.sh
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
