---
{
  "id": "WO-20261012-0677",
  "slug": "no-file-is-ever-touched-by-two-open-prs-a-ticket",
  "title": "No file is ever touched by two open PRs: a ticket declares its files, start refuses an overlap with any open PR, and generated aggregates never ride a PR",
  "type": "bug",
  "status": "in-progress",
  "priority": "p0",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T18:08:24+00:00",
  "parent": "WO-20261012-187e",
  "branch": "feat/no-file-is-ever-touched-by-two-open-prs-a-ticket",
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "lavish is prohibited for Claude seats; owner order on the bearings page 2026-10-12 18:07Z: no file ever clashes on a PR",
    "at": "2026-10-12"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [],
  "files": [
    "AGENTS.md",
    ".gitignore",
    "Makefile",
    "bin/changelog.sh",
    "bin/step.sh",
    "bin/mint-id.sh",
    "bin/new-sop.sh",
    "bin/wo-start.sh",
    "factory/bin/claims.sh",
    "factory/bin/gate.sh",
    "factory/config/claims.json",
    "factory/config/claims.schema.json",
    "factory/tests/cases/15-claims.test.sh",
    "factory/tests/cases/16-claims-tools.test.sh",
    "docs/sops/SOP-0006-declare-a-ticket-s-files-start-it-without-a-clash-and-mint-doc-numbers.md"
  ]
}
---

# WO-20261012-0677 - No file is ever touched by two open PRs: a ticket declares its files, start refuses an overlap with any open PR, and generated aggregates never ride a PR

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

Owner 2026-10-12 18:07Z: no file may ever clash on a PR; two agents on one file is forbidden. On 2026-10-12 PRs 25, 28, 29, 30 and 31 all edited herdr/bin/seat.sh, factory/config/routes.json, herdr/config/herdr.json, monitors.json or factory/RUNBOOK.md, PR 31 added a second SOP-0003, and every PR rewrote CHANGELOG.md, CONTEXT_STATE.md and work-orders/INDEX.md, so each merge forced the next PR into a conflict, a main merge and a full re-test.

## Scope

**In**

- a files field on a ticket (paths or globs) set at cut, and work-order start refusing when it overlaps the changed files of any open PR or the files field of any in-progress ticket
- a gate check that fails a PR whose diff touches a path outside its ticket's files field
- CHANGELOG.md, work-orders/INDEX.md, epic READMEs and CONTEXT_STATE.md never in a feature PR diff; they are rendered after merge
- doc ids (SOP, RB numbers) minted by a script so two PRs cannot take the same number

**Out - non-goals**

- splitting shared config files into fragments (a follow-up ticket if the files field shows it is needed)

## Degrees of freedom

- [free] how aggregates reach main (rendered by the merger after merge through make step, a main-only job, or untracked and rendered on read), as long as no feature PR diff contains them
- [free] where the overlap check lives (work-order start wrapper, seat.sh, or route.sh), as long as no ticket can start past it

## Acceptance criteria

- [x] `AC-H1` *(human)* starting a ticket whose files overlap an open PR's changed files exits non-zero naming the PR and the files
  - observed `2026-10-12` factory/tests/cases/15-claims.test.sh and 16-claims-tools.test.sh, run in test pane wD3:pGN: claims.sh start / wo-start.sh against an open PR 31 on herdr/bin/seat.sh exits 3 printing 'PR 31 (feat/scoped) changes herdr/bin/seat.sh, which WO-20261012-aaaa claims as herdr/bin/seat.sh', and work-order.sh is never called; a live in-progress ticket in another worktree is named too. Full factory suite: tests: 21 passed, 0 failed
- [x] `AC-H2` *(human)* a PR whose diff touches a file outside its ticket's files field fails the gate with the path named
  - observed `2026-10-12` same cases: gate.sh pr-files --ticket exits 1 with one line naming 'factory/config/routes.json is outside the files field of WO-20261012-aaaa; CHANGELOG.md is an aggregate (CHANGELOG.md): it is rendered after the merge and never rides a PR'; a clean diff exits 0; and gate.sh pr-files on this very ticket exits 0. Wiring a route row to call it was not done: routes.json is another PR's file
- [x] `AC-H3` *(human)* two PRs cut from the same main and merged in either order produce no conflict in CHANGELOG.md, INDEX.md, READMEs or CONTEXT_STATE.md
  - observed `2026-10-12` case 15-claims AC-H3: two branches cut from one main, each running bin/changelog.sh add and git add -A, merge in both orders with exit 0 and no conflict, CHANGELOG.md rendered locally and not tracked; CHANGELOG.md, CONTEXT_STATE.md, work-orders/INDEX.md and every work-orders README are gitignored (git check-ignore) and removed from the index in 009374d; step.sh no longer commits a checkpoint
- [x] `AC-H4` *(human)* two PRs adding a SOP get different numbers
  - observed `2026-10-12` case 16-claims-tools AC-H4: with SOP-0002 in the tree and SOP-0003 in open PR 31, bin/mint-id.sh sop printed SOP-0004 then SOP-0005; four concurrent mints gave four different numbers; new-sop.sh through the real docs.sh wrote the SOP under the minted id (SOP-0006 in this PR); claims.sh ids exits 3 naming 'SOP-0002 is taken by PR 31 adds docs/sops/SOP-0002-b.md'

## Test plan

```sh
make test
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-12` Retro. Built factory/bin/claims.sh (set, get, start, diff, ids), bin/wo-start.sh, bin/mint-id.sh, bin/new-sop.sh and gate.sh pr-files; the four aggregates are gitignored and removed from the index; step.sh stops committing checkpoints. Surprises: (1) work-order.sh and docs.sh are managed skill copies, so the start check is a wrapper and the SOP number is minted by running docs.sh on a scratch project; a direct work-order.sh start still skips the check, and only the gate catches that PR. (2) routes.json and seat.sh were another PR's, so no route calls gate.sh pr-files yet: a follow-up ticket should add the when row. (3) Every open PR touches the aggregates, so each meets a modify/delete conflict on CHANGELOG.md, CONTEXT_STATE.md or work-orders/INDEX.md once this merges: resolve by accepting the deletion. PR 32 already conflicts with main on .gitignore before this change. (4) Every ready ticket cut before today has no files field; wo-start refuses it until the architect runs claims.sh set. (5) make step lint takes over two minutes, so it runs in the test pane.

## Outcome

_Written by `work-order done`. Empty until then._
