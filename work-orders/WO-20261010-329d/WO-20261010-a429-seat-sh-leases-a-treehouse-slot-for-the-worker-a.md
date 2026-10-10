---
{
  "id": "WO-20261010-a429",
  "slug": "seat-sh-leases-a-treehouse-slot-for-the-worker-a",
  "title": "seat.sh leases a treehouse slot for the worker and the worker playbook names the real lease tool",
  "type": "feature",
  "status": "draft",
  "priority": "p2",
  "created": "2026-10-10",
  "updated": "2026-10-10",
  "created_at": "2026-10-10T22:29:51+00:00",
  "parent": "WO-20261010-329d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": null,
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

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* seat.sh --ticket X --role worker with no --worktree starts the seat in a treehouse slot leased to X, and treehouse status shows the lease
- [ ] `AC-H2` *(human)* a worker at step 1 finds its lease without asking the architect
- [ ] `AC-H3` *(human)* retire.sh returns the slot and treehouse status no longer lists the ticket

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

## Outcome

_Written by `work-order done`. Empty until then._
