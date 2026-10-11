---
{
  "id": "WO-20261011-7b8f",
  "slug": "pr-12-and-the-foundation-branch-go-through-the-l",
  "title": "PR 12 and the foundation branch go through the line: a reviewer seat passes SPEC-00 and SPEC-01 for the P0 gate",
  "type": "feature",
  "status": "draft",
  "priority": "p0",
  "created": "2026-10-11",
  "updated": "2026-10-11",
  "created_at": "2026-10-11T14:39:43+00:00",
  "parent": "WO-20261010-329d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": null,
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261011-fa78"
  ],
  "blocks": []
}
---

# WO-20261011-7b8f - PR 12 and the foundation branch go through the line: a reviewer seat passes SPEC-00 and SPEC-01 for the P0 gate

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

PR 12 waits held, and the P0 gate needs a reviewer to pass SPEC-00 and SPEC-01, which sit unreviewed on a branch 139 files off main

## Scope

**In**

- WO-20261011-3d78 (PR 12) through the line
- WO-20261010-fbad: a worker rebases feat/p0-foundation on main, opens its PR, the reviewer seat records a review naming SPEC-00 and SPEC-01, the merger merges
- graph INDEX regenerated on main; the P0 gate row for specs flips to passed on the board

**Out - non-goals**

- spikes
- new specs

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* 3d78 merged by the merger seat with test, review and merged records
- [ ] `AC-H2` *(human)* fbad PR opened by a worker seat, review.passed record names SPEC-00 and SPEC-01, merged by the merger seat
- [ ] `AC-H3` *(human)* make lint green on main after both merges and graph/INDEX.md regenerated
- [ ] `AC-H4` *(human)* the board shows both lines done and the P0 gate row for specs reads passed

## Test plan

```sh
make lint graph/bin/graph.sh check events/bin/event.sh list --ticket WO-20261010-fbad
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
