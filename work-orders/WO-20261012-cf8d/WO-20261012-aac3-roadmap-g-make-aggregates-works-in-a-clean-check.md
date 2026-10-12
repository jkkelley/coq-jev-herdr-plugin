---
{
  "id": "WO-20261012-aac3",
  "slug": "roadmap-g-make-aggregates-works-in-a-clean-check",
  "title": "Roadmap G - make aggregates works in a clean checkout, without the gitignored work-order skill copy it calls today",
  "type": "bug",
  "status": "ready",
  "priority": "p1",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T22:13:29+00:00",
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

- [ ] `AC-H1` *(human)* in a git worktree add with no .claude directory, make aggregates exits 0 or exits 4 naming the missing tool and how to get it

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
