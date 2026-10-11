---
{
  "id": "WO-20261011-c077",
  "slug": "seat-sh-checks-out-the-ticket-branch-in-the-slot",
  "title": "seat.sh checks out the ticket branch in the slot it leases, so a worker starts on its branch without the architect touching the slot",
  "type": "feature",
  "status": "in-progress",
  "priority": "p2",
  "created": "2026-10-11",
  "updated": "2026-10-11",
  "created_at": "2026-10-11T03:28:09+00:00",
  "parent": "WO-20261010-329d",
  "branch": "feat/seat-sh-checks-out-the-ticket-branch-in-the-slot",
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "Claude seat; Lavish is prohibited for Claude seats by the owner hard rule, decisions recorded in the ticket note",
    "at": "2026-10-11"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": []
}
---

# WO-20261011-c077 - seat.sh checks out the ticket branch in the slot it leases, so a worker starts on its branch without the architect touching the slot

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

WO-20261010-a429 made seat.sh lease a treehouse slot for a ticket seat, but the slot comes up detached at origin/main while work-order start has already created feat/<slug> in the main checkout. The worker role allows git add, commit and push only, so the architect pre-leased the slot for WO-20261010-2d04 and ran git checkout there by hand before seating; seat.sh then reused the lease with owned false, which means --down will not return it either. Every ticket seat will need this until seat.sh does it.

## Scope

**In**

- seat.sh door 1 reads the ticket's branch from the ticket frontmatter (work-order start stamps it) and, after leasing, runs git fetch origin and git checkout <branch> in the slot (creating a tracking branch when only origin has it); it refuses with exit 3 when the ticket has no branch yet
- a Podman case with the stub treehouse proves the slot is on the ticket branch after seat up and that a ticket without a branch is refused before any lease

**Out - non-goals**

- any change to work-order.sh
- the worker's permissions

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* seat.sh --ticket X --role worker with no --worktree leaves the slot on X's feat branch, tracking origin
- [ ] `AC-H2` *(human)* a ticket whose frontmatter has branch null is refused with exit 3 and no lease is taken

## Test plan

```sh
make -C herdr test from the labelled test pane, then make lint
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-11` Worker: seat.sh reads the ticket frontmatter branch before any lease (null refuses, exit 3, nothing leased) and slot_to_branch fetches origin and checks the slot out on it, tracking origin; a fresh lease that cannot reach the branch is returned once (lease_abandon no longer returns twice, found by the new case). Stub treehouse clones a bare origin when TREEHOUSE_STUB_ORIGIN is set. Case 08 extended; make -C herdr test: 8 passed 0 failed, make lint rc 0, both from the labelled test pane. AC-H1 and AC-H2 are human: the architect confirms the live seat-up on the next ticket seat.

## Outcome

_Written by `work-order done`. Empty until then._
