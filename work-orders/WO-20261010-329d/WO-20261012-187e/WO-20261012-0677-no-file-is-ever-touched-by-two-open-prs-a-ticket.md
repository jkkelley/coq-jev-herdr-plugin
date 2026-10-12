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
  "blocks": []
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

- [ ] `AC-H1` *(human)* starting a ticket whose files overlap an open PR's changed files exits non-zero naming the PR and the files
- [ ] `AC-H2` *(human)* a PR whose diff touches a file outside its ticket's files field fails the gate with the path named
- [ ] `AC-H3` *(human)* two PRs cut from the same main and merged in either order produce no conflict in CHANGELOG.md, INDEX.md, READMEs or CONTEXT_STATE.md
- [ ] `AC-H4` *(human)* two PRs adding a SOP get different numbers

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

## Outcome

_Written by `work-order done`. Empty until then._
