---
{
  "id": "WO-20261012-6c76",
  "slug": "roadmap-h-backlog-lives-in-github-issues-each-ba",
  "title": "Roadmap H - Backlog lives in GitHub issues: each backlog item becomes an issue with a priority label and backlog/ leaves git",
  "type": "chore",
  "status": "in-progress",
  "priority": "p1",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T22:13:38+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": "feat/roadmap-h-backlog-lives-in-github-issues-each-ba",
  "pr": null,
  "closed": null,
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

- [ ] `AC-H1` *(human)* the issue count equals the item count, and the critical Pi DNS item keeps its priority
- [ ] `AC-H2` *(human)* adding a backlog item creates an issue and changes no file in git

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

## Outcome

_Written by `work-order done`. Empty until then._
