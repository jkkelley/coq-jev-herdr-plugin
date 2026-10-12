---
{
  "id": "WO-20261012-3cb1",
  "slug": "test-pane-runs-in-the-seat-s-worktree-testpane-s",
  "title": "Test pane runs in the seat's worktree: testpane.sh wraps every command as a subshell that cds to the seat's worktree first, so no tester or worker result comes from the main checkout",
  "type": "bug",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T19:57:54+00:00",
  "parent": "WO-20261012-187e",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect cut, p0: void test results on four PRs today; owner order 2026-10-12: architect and owner are not gates",
    "at": "2026-10-12"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": []
}
---

# WO-20261012-3cb1 - Test pane runs in the seat's worktree: testpane.sh wraps every command as a subshell that cds to the seat's worktree first, so no tester or worker result comes from the main checkout

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

Test panes open with cwd at the main checkout, and testpane.sh runs '( command )' there, so make test or make lint checks the architect's records branch instead of the PR head. It voided results on PR 31, PR 35, PR 36 and PR 37 on 2026-10-12 (backlog srzhu), each costing a full re-run, and a stale main-checkout run held PR 36's tester 18 minutes.

## Scope

**In**

- herdr/bin/testpane.sh runs '( cd <seat worktree> && command )' with the worktree from the seat's environment (COQ_WORKTREE or the seat record), refusing with exit 3 when the worktree is unset or missing
- a herdr test case proving a command sent through testpane.sh runs in the seat's worktree while the pane's own shell keeps its cwd

**Out - non-goals**

- herdr/bin/seat.sh and herdr/tests/lib/world.sh (open in other PRs)

## Degrees of freedom

- [free] where testpane.sh reads the worktree from (COQ_WORKTREE or the seat record), as long as a seat cannot run outside its own worktree by accident

## Acceptance criteria

- [ ] `AC-H1` *(human)* a command sent through testpane.sh prints the seat's worktree from pwd, never the main checkout
- [ ] `AC-H2` *(human)* the pane's own shell cwd is unchanged after the command, so seat.sh --down still leaves the pane alive (WO-20261011-36d7 holds)

## Test plan

```sh
make -C herdr test
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
