---
{
  "id": "WO-20261013-a0e2",
  "slug": "cause-f-the-belt-cannot-seat-the-tester-and-revi",
  "title": "Cause f: the belt cannot seat the tester and reviewer for a tickets pull request, because the ticket's branch is null; seat.sh takes the head branch from the pull request",
  "type": "bug",
  "status": "in-progress",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T16:37:15+00:00",
  "parent": "WO-20261013-16f1",
  "branch": "feat/cause-f-the-belt-cannot-seat-the-tester-and-revi",
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect P0 order 2026-10-13 (owner m-20261013162710557-e4nos: always a system loop), approved by the architect in the owner place (card C29); lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [
    "WO-20261013-0bda"
  ],
  "files": [
    "herdr/bin/seat.sh",
    "herdr/tests/cases/32-seat-gate-tickets-pr.test.sh"
  ]
}
---

# WO-20261013-a0e2 - Cause f: the belt cannot seat the tester and reviewer for a tickets pull request, because the ticket's branch is null; seat.sh takes the head branch from the pull request

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

Cause f (record b5yad, roadmap progress 2026-10-13 15:58Z): a tickets-only pull request is opened under an epic whose branch is null, so seat.sh refuses the tester and reviewer and the orchestrator seats them by hand with --worktree. PRs 89, 96 and 98 sat in rework while the line starved of build seats. P0.

## Scope

**In**

- herdr/bin/seat.sh: when the ticket's branch is null and the record names a pull request, the branch is that pull request's head ref from gh, fetched into the seat's worktree; a breadcrumb names this cause
- herdr/tests/cases/32-seat-gate-tickets-pr.test.sh: a tester seated for a pull request whose ticket has branch null gets the head branch

**Out - non-goals**

- seat.sh taking a started ticket's branch from origin (Roadmap B, WO-20261012-6f13)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [x] `AC-H1` *(human)* a pr.opened on a tickets-only pull request seats its tester with no hand step, and the case fails without the fix
  - observed `2026-10-13` herdr/tests/cases/32-seat-gate-tickets-pr.test.sh passes from test pane wD3:p1A2 (make -C herdr test, 27 of 28 cases, the one failure is 12-blueprint-panes, a known main break fixed by PR 113): a tester and a reviewer are seated by seat.sh --ticket with no --worktree for a ticket whose branch is null, the slot is on the open pull request's head and tracks origin. With herdr/bin/seat.sh reverted, the same case fails 11 assertions (exit 3 'has no branch yet'). Case 08 still passes; make lint passes.

## Test plan

```sh
make lint && make -C herdr test, in Podman through the repository targets
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-13` Retro: seat.sh is not told the PR by route.sh, so it looks the PR up itself from gh by title prefix (every PR is titled '<WO-id> - ...'); route.sh --pr and frontmatter pr were rejected (breadcrumb in seat.sh). Added herdr/tests/stubs/gh because the suite container has no gh; it returns every PR and leaves the filtering to seat.sh. Case 12-blueprint-panes fails on this base, not caused here.

## Outcome

_Written by `work-order done`. Empty until then._
