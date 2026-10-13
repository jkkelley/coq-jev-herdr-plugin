---
{
  "id": "WO-20261012-aac3",
  "slug": "roadmap-g-make-aggregates-works-in-a-clean-check",
  "title": "Roadmap G - make aggregates works in a clean checkout, without the gitignored work-order skill copy it calls today",
  "type": "bug",
  "status": "done",
  "priority": "p1",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T22:13:29+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": "feat/roadmap-g-make-aggregates-works-in-a-clean-check",
  "pr": 79,
  "closed": "2026-10-12",
  "approval": {
    "via": "override",
    "reason": "owner locked ROADMAP.md 2026-10-12 (cards C9 to C22) and gave USERGO; Getting My Bearings is the review surface, lavish is prohibited",
    "at": "2026-10-12"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [
    "WO-20261012-41a3",
    "WO-20261012-e970"
  ],
  "files": [
    "Makefile",
    "bin/aggregates.sh"
  ]
}
---

# WO-20261012-aac3 - Roadmap G - make aggregates works in a clean checkout, without the gitignored work-order skill copy it calls today

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

Makefile:43 runs .claude/skills/work-order/scripts/work-order.sh reindex, a gitignored copy, so make aggregates exits 127 in a fresh clone or worktree (found verifying PR 36 on main, record k5ygl).

## Scope

**In**

- make aggregates renders INDEX and the READMEs with no .claude/skills present, or says exactly what to install

**Out - non-goals**

- changing what the aggregates contain

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [x] `AC-H1` *(human)* in a git worktree add with no .claude directory, make aggregates exits 0 or exits 4 naming the missing tool and how to get it
  - observed `2026-10-12` Clean detached git worktree of HEAD (no .claude/skills), run in test pane wD3:pN8: before, make aggregates died 'work-order.sh: No such file or directory' (Error 127). After: make aggregates exit 0, 'rebuilt work-orders/INDEX.md and every child README' via the ~/.claude machine copy; with CLAUDE_HOME=/nonexistent, bin/aggregates.sh exit 4 and make prints 'Error 4', naming work-order.sh, the three paths looked at, jkkelley/dotfiles claude/skills/work-order, skill-sync and WORK_ORDER_SH; WORK_ORDER_SH override exit 0; bad arg exit 2. make lint exit 0; make -C factory test 21 passed 0 failed.

## Test plan

```sh
make lint && make -C factory test && make -C herdr test, all in Podman through the repository targets
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-12` Retro: found work-order.sh in project then machine copy, exit 4 otherwise; make shows Error 4 but exits 2 (GNU make), recorded in the BREADCRUMB. make -C herdr test: 24 passed, 1 failed (17-resume-checkpoint), not caused by this ticket: the worktree has no CONTEXT_STATE.md (gitignored, .gitignore:113) and case 17 expects the world copy to hold a checkpoint; e36e (#40) fixed only checkpoint.sh. Needs its own ticket (herdr/tests/cases/17-resume-checkpoint.test.sh, outside this ticket's files).

## Outcome

_Written by `work-order done`. Empty until then._
