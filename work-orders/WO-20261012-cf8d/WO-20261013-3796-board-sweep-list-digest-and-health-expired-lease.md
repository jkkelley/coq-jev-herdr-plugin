---
{
  "id": "WO-20261013-3796",
  "slug": "board-sweep-list-digest-and-health-expired-lease",
  "title": "Board sweep, list, digest and health: expired leases return to open, one nudge per digest window per lane, twenty queued nudges collapse into one pull, and the health file is written (SPEC-17 T02, T03; K1 part 4 of 5)",
  "type": "feature",
  "status": "ready",
  "priority": "p1",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T03:17:26+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "owner 2026-10-13 03:00Z (record 57h60): one concern, at most 5 files, under about 300 lines; lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261013-e522"
  ],
  "blocks": [
    "WO-20261013-f15d"
  ],
  "files": [
    "line/bin/board.sh",
    "line/tests/cases/board-digest*"
  ]
}
---

# WO-20261013-3796 - Board sweep, list, digest and health: expired leases return to open, one nudge per digest window per lane, twenty queued nudges collapse into one pull, and the health file is written (SPEC-17 T02, T03; K1 part 4 of 5)

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

Split of WO-20261013-f268 (Roadmap K1 - Board) under the owner's size rule of 2026-10-13 03:00Z.

## Scope

**In**

- board.sh sweep, list, digest, health
- cases line/tests/cases/board-digest.sh (T02, T03)

**Out - non-goals**

- routing into the board (K7 parts)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* fifty records posted to the architect lane give at most one nudge within digest_seconds, and twenty queued nudges to one seat collapse into one pull with nothing lost
- [ ] `AC-H2` *(human)* make lint and make -C line test pass in Podman

## Test plan

```sh
make lint && make -C line test, in Podman through the repository targets
```

## Assumptions

1. SPEC-16 does this job once the scheduler is active (owner 02:50Z, record lvvtd); this part is the interim

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
