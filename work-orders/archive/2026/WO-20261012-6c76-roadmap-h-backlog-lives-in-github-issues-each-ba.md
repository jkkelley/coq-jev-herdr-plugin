---
{
  "id": "WO-20261012-6c76",
  "slug": "roadmap-h-backlog-lives-in-github-issues-each-ba",
  "title": "Roadmap H - Backlog lives in GitHub issues: each backlog item becomes an issue with a priority label and backlog/ leaves git",
  "type": "chore",
  "status": "done",
  "priority": "p1",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T22:13:38+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": "feat/roadmap-h-backlog-lives-in-github-issues-each-ba",
  "pr": 81,
  "closed": "2026-10-12",
  "approval": {
    "via": "override",
    "reason": "owner locked ROADMAP.md 2026-10-12 (cards C9 to C22) and gave USERGO; Getting My Bearings is the review surface, lavish is prohibited",
    "at": "2026-10-12"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [],
  "files": [
    "backlog/*",
    "bin/backlog.sh",
    "docs/runbooks/backlog.md"
  ]
}
---

# WO-20261012-6c76 - Roadmap H - Backlog lives in GitHub issues: each backlog item becomes an issue with a priority label and backlog/ leaves git

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

Backlog items are files that need a pull request to add (owner card C14).

## Scope

**In**

- every backlog/ item filed as a GitHub issue with title, body and a priority label
- the backlog script files issues; backlog/ removed from git

**Out - non-goals**

- issue triage automation

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [x] `AC-H1` *(human)* the issue count equals the item count, and the critical Pi DNS item keeps its priority
  - observed `2026-10-12` gh issue list --label backlog --state all counts 34 issues, #45 to #78, for the 34 distinct items of 41 read (main 7, the architect's local branch chore/architect-records-20261011 at 6c06ec9 30 live plus 1 done, 3 uncommitted files in the live checkout). 33 open, 1 closed (the done item, #71). Pi DNS item 1arbf is #52 with labels backlog and priority: critical, the only critical one. Filed at 22:40Z from bin/backlog.sh as of 4e1df4b plus the ghr rename landed in 9c35966. A rerun of migrate files 0 and finds 34 already filed. The reviewer checks it with: bin/backlog.sh list --state all
- [x] `AC-H2` *(human)* adding a backlog item creates an issue and changes no file in git
  - observed `2026-10-12` bin/backlog.sh selftest 37 of 37 against a stub gh: 'add: changes no file in git (AC-H2)' and 'migrate changes no file in git' compare git status --porcelain of a scratch checkout, and add creates exactly one issue with labels backlog and priority. Not run against the public repo: the architect ordered no further GitHub writes until the PR merges (2026-10-12 after the migration run). backlog/ is removed from git in 9c35966 (11 files); make lint, make -C factory test (21 passed) and make -C herdr test (25 passed) green in test pane wD3:pNE; gate.sh pr-files exit 0

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

- `2026-10-12` Retro. Built bin/backlog.sh (add, list, move, done, labels, migrate, selftest) and docs/runbooks/backlog.md; removed backlog/. Sources were wider than main: main had 7 items but 27 more lived only on the architect's local branch chore/architect-records-20261011 and in the live checkout, so migrate read both (34 distinct, first copy of an id wins). Real run found a bug the stub could not: the gh wrapper called itself (fixed as ghr, selftest now covers gh on PATH). Deviations: the 34 issues were filed before the PR was tested; the architect said leave them, no GitHub writes until merge. The test lives in the script (selftest) because this ticket's files field has no tests path. Follow-ups outside my files, for the architect: .claude/scripts/backlog.sh (managed scaffold script) would recreate backlog/ if run; AGENTS.md lines 100, 116 and 235 and COMPASS.md line 40 still describe backlog/; roles/architect.json and playbooks/architect.md allow the path backlog/; a Makefile target for backlog selftest; the lines that cite 'backlog disva' style ids now resolve with bin/backlog.sh list --state all.

## Outcome

_Written by `work-order done`. Empty until then._
