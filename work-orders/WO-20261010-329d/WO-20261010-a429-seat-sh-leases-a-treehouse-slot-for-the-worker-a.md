---
{
  "id": "WO-20261010-a429",
  "slug": "seat-sh-leases-a-treehouse-slot-for-the-worker-a",
  "title": "seat.sh leases a treehouse slot for the worker and the worker playbook names the real lease tool",
  "type": "feature",
  "status": "in-progress",
  "priority": "p2",
  "created": "2026-10-10",
  "updated": "2026-10-11",
  "created_at": "2026-10-10T22:29:51+00:00",
  "parent": "WO-20261010-329d",
  "branch": "feat/seat-sh-leases-a-treehouse-slot-for-the-worker-a",
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

# WO-20261010-a429 - seat.sh leases a treehouse slot for the worker and the worker playbook names the real lease tool

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

AGENTS.md (Where your workspace comes from) allows one source of worktrees, the treehouse pool, and forbids a hand-rolled git worktree add. seat.sh takes --worktree and the architect hand-rolled /home/luna/worktrees/<ticket> for WO-20261010-c274 and WO-20261010-8fa8. playbooks/worker.md step 1 tells the worker to stop when the slot lease is not its own and names slot.sh, which does not exist, so the 8fa8 worker sat at step 1 from 21:47 to 22:2x UTC until the architect answered by hand.

## Scope

**In**

- seat.sh --ticket acquires a treehouse slot for the ticket (treehouse get or the hydration-prompt lease path) and passes it as the worktree; --worktree stays only for the Podman suite
- playbooks/worker.md step 1 names the real lease check (treehouse status keyed by ticket id) and roles/worker.json allows it
- retire.sh returns the slot

**Out - non-goals**

- any change to treehouse itself

## Degrees of freedom

- [free] the seat record carries the lease path as worktree only, or as worktree plus a lease field, as long as the breadcrumb at the write site says which and why

## Acceptance criteria

- [ ] `AC-H1` *(human)* seat.sh --ticket X --role worker with no --worktree starts the seat in a treehouse slot leased to X, and treehouse status shows the lease
- [ ] `AC-H2` *(human)* a worker at step 1 finds its lease without asking the architect
- [ ] `AC-H3` *(human)* seat.sh --down for a ticket seat returns the slot and treehouse status no longer lists the ticket
- [ ] `AC-H4` *(human)* a seat started with --worktree leases nothing and returns nothing, so the Podman suite keeps running against a plain directory

## Test plan

```sh
make -C herdr test from the labelled test pane with a stub treehouse on PATH in the world, then make lint
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-11` Decision 2026-10-11 UTC (architect, fixed): lease with treehouse get --lease --lease-holder <ticket> --no-fetch --json, the holder is the ticket id so treehouse status is keyed by it; release in seat.sh --down with treehouse return <worktree> --if-lease-holder <ticket> --force after retire.sh and the tab close; worker step 1 reads treehouse status --json for its ticket on its worktree and roles/worker.json allows treehouse status *, get and return stay with seat.sh; the suite stubs treehouse in herdr/tests/stubs (get --lease makes a directory under the world and records the holder, status --json lists it, return removes it), on PATH from world_up like the compaction-guard stub, proved by a new case 08. Why: AGENTS.md names the pool as the one worktree source and treehouse get --lease is its non-interactive verb; a worker never acquires because the slot is the seat's, not the agent's.

## Outcome

_Written by `work-order done`. Empty until then._
