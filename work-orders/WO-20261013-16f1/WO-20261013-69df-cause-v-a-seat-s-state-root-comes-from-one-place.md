---
{
  "id": "WO-20261013-69df",
  "slug": "cause-v-a-seat-s-state-root-comes-from-one-place",
  "title": "Cause v: a seat's state root comes from one place (COQ_STATE or the XDG state root), never from the checkout it was seated from; seat.sh refuses a seat whose records tree is not the canonical one",
  "type": "bug",
  "status": "in-progress",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T20:12:12+00:00",
  "parent": "WO-20261013-16f1",
  "branch": "feat/cause-v-a-seat-s-state-root-comes-from-one-place",
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
    "herdr/bin/seat.sh",
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

- [x] `AC-H1` *(human)* A seat started from any worktree posts its records into the canonical records tree
  - observed `2026-10-13` herdr/tests/cases/36-seat-canonical-state-root.test.sh in the test pane (wD3:p1FA): a seat started from a second git worktree named verify-fba7551, COQ_STATE unset and COQ_REPO inherited, puts seat.up 100 and a post from its own event.sh under the canonical records tree, none under a root named after the checkout, and its pane environment line carries COQ_REPO of the canonical repository. A mutant that restores the old sl_canonical_repo reproduces the incident (records under verify-fba7551/records). Full herdr suite: 32 passed, 0 failed; make -C herdr lint clean.
- [x] `AC-H2` *(human)* A seat whose resolved tree differs is refused with exit 3 and no records written elsewhere
  - observed `2026-10-13` Same case: a resolver that names its own checkout (the stale kind) is refused by seat.sh with exit 3, the message names the canonical records tree and the tree the seat would have used, no record is written to either tree and no agent is started. A checkout with no bin/state-root.sh has nothing to judge and is let through with a log line, because the suite's stub treehouse slots are empty clones and a seat there cannot write anywhere.

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

- `2026-10-13` Retro. Cause: seat.sh exported COQ_REPO=$SL_REPO and bin/state-root.sh names the root after COQ_REPO basename, so a seat run from a worktree or from another seat posted to a root named after that checkout (live roots verify-fba7551, start-WO-20261013-496d and start-case12-fix exist). Fix: seat-lib.sh sl_canonical_repo reads the repository from the git common directory, sl_record posts to the canonical state root, seat.sh exports the canonical repository (plus the caller COQ_STATE when set) and state_root_gate refuses a seat whose own resolver disagrees. First gate refused a worktree with no resolver and failed five treehouse cases (08 10 16 32 33), whose stub slots are empty clones; narrowed to let those through. Scope: the files field named only seat-lib.sh and case 36, but the ticket scope and the export line need seat.sh; widened with claims.sh set (no open PR touched seat.sh). Step 1 of the worker playbook (treehouse lease holder equals the ticket) cannot hold for a seat started by start-tickets.sh in a cache worktree, which the brief named; worked in COQ_WORKTREE as told. Left alone: the three stray roots under ~/.local/state/coq (their owners decide), and a seat already running keeps its old COQ_REPO until it is seated again.

## Outcome

_Written by `work-order done`. Empty until then._
