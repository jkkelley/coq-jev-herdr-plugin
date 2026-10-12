---
{
  "id": "WO-20261012-3cb1",
  "slug": "test-pane-runs-in-the-seat-s-worktree-testpane-s",
  "title": "Test pane runs in the seat's worktree: testpane.sh wraps every command as a subshell that cds to the seat's worktree first, so no tester or worker result comes from the main checkout",
  "type": "bug",
  "status": "in-progress",
  "priority": "p0",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T19:57:54+00:00",
  "parent": "WO-20261012-187e",
  "branch": "feat/test-pane-runs-in-the-seat-s-worktree-testpane-s",
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

- [x] `AC-H1` *(human)* a command sent through testpane.sh prints the seat's worktree from pwd, never the main checkout
  - observed `2026-10-12` Through herdr/bin/testpane.sh in the live test pane wD3:pHZ, pwd printed /home/luna/.treehouse/coq-jev-herdr-plugin-f314e6/7/coq-jev-herdr-plugin, the seat's worktree; herdr case 22 (real headless herdr) reads pwd as the worktree path, spaces included, and case 07 asserts the command reaches herdr as ( cd <worktree> && ... ). Full suite: tests: 24 passed, 0 failed.
- [x] `AC-H2` *(human)* the pane's own shell cwd is unchanged after the command, so seat.sh --down still leaves the pane alive (WO-20261011-36d7 holds)
  - observed `2026-10-12` Case 22 reads the pane shell cwd from herdr process-info before and after a passing and a failing command and it is unchanged; case 09 (cd and exit inside the command) still passes, and case 16 shows the test pane shell stays in the checkout, so seat.sh --down still leaves the pane alive.

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

- `2026-10-12` Retro: the first run of the new wrapper was its own proof - pwd in wD3:pHZ printed the slot, not the records checkout. Cases 07, 09 and 16 each needed COQ_WORKTREE once the wrapper refuses without it; bash =~ treats a backslash-escaped space as a bare space, so a printf %q path in a regex needs its backslashes doubled. Cost to know: a seat without COQ_WORKTREE is now refused; seat.sh already exports it. Out of scope and untouched: seat.sh and tests/lib/world.sh.

## Outcome

_Written by `work-order done`. Empty until then._
