---
{
  "id": "WO-20261012-41a3",
  "slug": "roadmap-f-changelog-rendered-from-merged-pull-re",
  "title": "Roadmap F - Changelog rendered from merged pull request titles at release: make step writes no entry and changelog/ leaves git",
  "type": "chore",
  "status": "ready",
  "priority": "p1",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T22:13:33+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "owner locked ROADMAP.md 2026-10-12 (cards C9 to C22) and gave USERGO; Getting My Bearings is the review surface, lavish is prohibited",
    "at": "2026-10-12"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261012-99d6",
    "WO-20261012-aac3"
  ],
  "blocks": [],
  "files": [
    "bin/step.sh",
    "bin/changelog.sh",
    "changelog/*",
    "Makefile",
    ".gitignore"
  ]
}
---

# WO-20261012-41a3 - Roadmap F - Changelog rendered from merged pull request titles at release: make step writes no entry and changelog/ leaves git

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

make step writes one changelog file per step, 186 on main, and each rides a pull request (owner card C13).

## Scope

**In**

- bin/changelog.sh render builds CHANGELOG.md from merged pull request titles through gh
- make step writes no changelog entry; changelog/ is removed from git and gitignored

**Out - non-goals**

- release tagging

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* make step on a branch adds no file under changelog/
- [ ] `AC-H2` *(human)* bin/changelog.sh render lists the last merged pull request titles in order

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
