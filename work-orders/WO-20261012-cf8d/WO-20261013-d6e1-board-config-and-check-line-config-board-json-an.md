---
{
  "id": "WO-20261013-d6e1",
  "slug": "board-config-and-check-line-config-board-json-an",
  "title": "Board config and check: line/config/board.json and its schema, and board.sh check, which exits 3 naming a missing key or a literal path (SPEC-17 T14; K1 part 2 of 5)",
  "type": "feature",
  "status": "ready",
  "priority": "p1",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T03:17:21+00:00",
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
    "WO-20261013-3a07"
  ],
  "blocks": [
    "WO-20261013-e522"
  ],
  "files": [
    "line/bin/board.sh",
    "line/config/board.json",
    "line/config/board.schema.json",
    "line/tests/cases/board-check*"
  ]
}
---

# WO-20261013-d6e1 - Board config and check: line/config/board.json and its schema, and board.sh check, which exits 3 naming a missing key or a literal path (SPEC-17 T14; K1 part 2 of 5)

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

- line/config/board.json and board.schema.json: state_root variable, lanes (the record schema's addressee roles plus owner), priorities p0 to p3, default_priority, lease_seconds, nudge_seconds, digest_seconds, retention_days, health_file; no literal path
- line/bin/board.sh check, exit codes 0, 2, 3, 4, 6 like queue/bin/queue.sh; case line/tests/cases/board-check.sh (T14)

**Out - non-goals**

- the item verbs (K1 part 3)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* board.sh check exits 3 naming the key on a missing key or a literal path and 0 on the shipped config
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
