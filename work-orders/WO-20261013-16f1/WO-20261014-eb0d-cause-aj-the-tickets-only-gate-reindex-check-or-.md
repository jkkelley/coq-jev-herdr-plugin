---
{
  "id": "WO-20261014-eb0d",
  "slug": "cause-aj-the-tickets-only-gate-reindex-check-or-",
  "title": "Cause aj: the tickets-only gate (reindex --check or lint) fails a ready ticket whose files field is empty, so a cut PR with no files is refused at once, not minutes later at start",
  "type": "bug",
  "status": "ready",
  "priority": "p1",
  "created": "2026-10-14",
  "updated": "2026-10-14",
  "created_at": "2026-10-14T00:26:08+00:00",
  "parent": "WO-20261013-16f1",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect order 00:27Z cause aj (5ab0f); approved by the architect in the owner place",
    "at": "2026-10-14"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [],
  "files": [
    ".claude/skills/work-order/scripts/work-order.sh",
    "work-orders/tests/ruled-files.test.sh"
  ]
}
---

# WO-20261014-eb0d - Cause aj: the tickets-only gate (reindex --check or lint) fails a ready ticket whose files field is empty, so a cut PR with no files is refused at once, not minutes later at start

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

Tickets cut with work-order new without a files field passed the tickets-only gate and failed only at start (wo-start: declares no files), minutes later, once per ticket (0b48, a18c, c789, 5e4a, cc5b, 0529 on 2026-10-14). The gate should refuse the cut PR at once.

## Scope

**In**

- work-orders/ index check (bin/aggregates.sh or work-order.sh reindex --check): a ticket with status ready and an empty files field fails with the ticket id
- work-orders/tests/ruled-files.test.sh: a ready ticket with no files fails the check; with files it passes

**Out - non-goals**

- work-order new deriving files from Scope In (separate ticket)

## Degrees of freedom

- [free] [free] Which of lint or reindex --check carries the rule

## Acceptance criteria

- [ ] `AC-H1` *(human)* A ready ticket whose files field is empty fails the tickets-only gate naming the ticket

## Test plan

```sh
bash work-orders/tests/ruled-files.test.sh
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
