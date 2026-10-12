---
{
  "id": "WO-20261012-2a12",
  "slug": "break-glass-live-proof-the-owner-s-first-real-gr",
  "title": "Break glass live proof: the owner's first real grant through the interface card flips a live seat to bypass permissions, runs one action, and restores it",
  "type": "test",
  "status": "draft",
  "priority": "p2",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T12:18:44+00:00",
  "parent": "WO-20261010-329d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": null,
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261011-e618"
  ],
  "blocks": []
}
---

# WO-20261012-2a12 - Break glass live proof: the owner's first real grant through the interface card flips a live seat to bypass permissions, runs one action, and restores it

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

PR 22 (WO-20261011-4562) lands the break glass mechanism proven by suites with a stub owner answer; the live halves of its AC-H1 (a real Claude Code seat re-reads its settings and runs the one action) and AC-H3 (the owner's Grant and Refuse card with its 200 or 423 answer) cannot be observed until the interface agent owns the bearings card (WO-20261011-e618). Owner decision 2026-10-12: land PR 22, prove the live halves here.

## Scope

**In**

- apply the held interface card patch 9907813 from origin/backup/4562-before-rebuild onto the interface agent
- one owner-authorised break glass on a live seat, observed end to end

**Out - non-goals**

- changing the break glass mechanism, its one-use rule or its records
- any second action under the same grant

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* the owner grants one break glass on the bearings card; the named live seat runs in bypassPermissions, runs exactly the one action, and seat.sh --check is clean after the restore within ttl
- [ ] `AC-H2` *(human)* a Refuse on the card is recorded 423 and the seat's settings stay byte for byte the role's
- [ ] `AC-H3` *(human)* the board shows that break glass as one line moving asked, granted, in effect, done, restored

## Test plan

```sh
a live run on a real seat, observed by the owner and the tester; records break.glass 100, 200, 201, 204 in events/
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
