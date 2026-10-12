---
{
  "id": "WO-20261012-e36e",
  "slug": "case-17-resume-checkpoint-passes-in-a-clean-chec",
  "title": "Case 17-resume-checkpoint passes in a clean checkout: the test brings its own checkpoint.sh instead of needing the gitignored skill copy",
  "type": "bug",
  "status": "in-progress",
  "priority": "p0",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T19:47:42+00:00",
  "parent": "WO-20261012-265d",
  "branch": "feat/case-17-resume-checkpoint-passes-in-a-clean-chec",
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect cut on a failed verify of PR 30 on main; owner order 2026-10-12: architect and owner are not gates",
    "at": "2026-10-12"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": []
}
---

# WO-20261012-e36e - Case 17-resume-checkpoint passes in a clean checkout: the test brings its own checkpoint.sh instead of needing the gitignored skill copy

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

herdr case 17-resume-checkpoint calls $REPO/.claude/skills/context-compaction/scripts/checkpoint.sh, a gitignored copy that skill-sync installs. Seat slots have it, so PR 30 passed its gates; a clean worktree (verify on main, CI, any fresh clone) does not, so make -C herdr test fails 22/1 on main 372f9aa and on every PR's clean run since (PR 25, PR 34 verify).

## Scope

**In**

- herdr/tests/cases/17-resume-checkpoint.test.sh supplies checkpoint.sh to its world (a fixture under herdr/tests/fixtures or COQ_CHECKPOINT_SH), so the case passes with no .claude/skills present

**Out - non-goals**

- changing herdr/bin/resume-checkpoint.sh behaviour
- herdr/tests/lib/world.sh (open in PR 25)

## Degrees of freedom

- [free] how the case provides checkpoint.sh (a vendored fixture copy, or a minimal stub that implements read --top N), as long as it needs nothing outside the repo's tracked files

## Acceptance criteria

- [x] `AC-H1` *(human)* make -C herdr test passes in a fresh git worktree of the branch with no .claude/skills directory
  - observed `2026-10-12` make -C herdr test in a fresh git worktree of branch HEAD ec12a04 (no .claude/skills directory, checked with test ! -e), run in test pane wD3:pHS: 23 passed, 0 failed, exit 0. On unmodified HEAD the same clean worktree fails 17-resume-checkpoint with 'checkpoint.sh was not found'.
- [x] `AC-H2` *(human)* the case still proves AC-H1 to AC-H3 of WO-20261012-8fb2 against the real resume-checkpoint.sh
  - observed `2026-10-12` 17-resume-checkpoint still runs the real herdr/bin/resume-checkpoint.sh unmodified through every assertion of AC-H1 to AC-H3 of WO-20261012-8fb2 (top checkpoint verbatim, live-seat pick, one-line failures, compact-only wiring in both settings files); only checkpoint.sh is a tracked fixture at herdr/tests/fixtures/checkpoint.sh. Read the case log: 0 FAIL lines.

## Test plan

```sh
git worktree add --detach /tmp/x HEAD && make -C /tmp/x/herdr test
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-12` Retro: the case called a gitignored skill copy (.gitignore:91), so seat slots passed and every clean tree failed. Fix: tracked read-only fixture (the real cmd_read awk) installed in the case's throwaway world at the path the hook falls back to; herdr/Makefile lint now shellchecks tests/fixtures. Cost: the fixture must follow the skill's read format. Reproduced the failure first on unmodified HEAD in a clean worktree.

## Outcome

_Written by `work-order done`. Empty until then._
