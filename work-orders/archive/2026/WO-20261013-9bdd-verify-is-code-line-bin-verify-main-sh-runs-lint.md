---
{
  "id": "WO-20261013-9bdd",
  "slug": "verify-is-code-line-bin-verify-main-sh-runs-lint",
  "title": "Verify is code: line/bin/verify-main.sh runs lint and the factory, herdr, events and scheduler suites on a clean worktree at the new main sha and posts verified 200 per pull request or rejected 422",
  "type": "feature",
  "status": "done",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T14:36:09+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": "feat/verify-is-code-line-bin-verify-main-sh-runs-lint",
  "pr": 112,
  "closed": "2026-10-13",
  "approval": {
    "via": "override",
    "reason": "architect orders 2026-10-13: 9c50 split (reviewer max_seats 2 to 4), K5 reland, post-merge as code; lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [
    "WO-20261013-48f2"
  ],
  "files": [
    "line/bin/verify-main.sh",
    "line/tests/cases/verify-main.sh"
  ]
}
---

# WO-20261013-9bdd - Verify is code: line/bin/verify-main.sh runs lint and the factory, herdr, events and scheduler suites on a clean worktree at the new main sha and posts verified 200 per pull request or rejected 422

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

After a merge the verify on main is orchestrator hand work and was skipped or carried by hand on 2026-10-12 and 2026-10-13. Owner order 2026-10-13: post-merge verify is code, not a seat.

## Scope

**In**

- line/bin/verify-main.sh --sha SHA --pr N...: a clean detached worktree at SHA outside the repository, make lint and make -C factory, herdr, events and scheduler test in Podman, one verified 200 per pull request or one rejected 422 naming the failing suite and its log under the state root's logs tree; a rejected main writes the merge hold (cause j) that merge.sh reads; the worktree is removed after; 3 tries on io, then a 500 to the orchestrator
- line/tests/cases/verify-main.sh with stub suites: a green run posts verified per pull request, a red one posts rejected and the hold

**Out - non-goals**

- starting it (the after-merge part)
- merging (WO-20261013-f6ae, line/bin/merge.sh)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [x] `AC-H1` *(human)* a green stub run posts one verified 200 per pull request, a red one posts rejected 422 and the hold file exists; no file is left in the repository
  - observed `2026-10-13` line/tests/cases/verify-main.sh, run in test pane wD3:p155 through line/tests/run.sh: green stub run exit 0 and one verified 200 per pull request (2 PRs, 2 records, sha and ticket set); red stub run exit 3, one rejected 422 with the failing suite and its log, merge-hold.json under the state root run tree, no verified; git status clean and one worktree entry after every run. tests: 6 passed, 0 failed; make lint: all ok

## Test plan

```sh
make lint && make -C line test, in Podman through the repository targets
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-13` Retro: the case file name verify-main.sh comes from the ticket; suites are overridable through VERIFY_SUITES so the stubs need no config file or schema. Open items for others: routes.json has verified 201 only (this posts 200 as ordered), merge.sh does not read the hold yet (WO-20261013-2d35), and the line suite itself is not in the default suite list because the ticket lists lint, factory, herdr, events and scheduler only.

## Outcome

_Written by `work-order done`. Empty until then._
