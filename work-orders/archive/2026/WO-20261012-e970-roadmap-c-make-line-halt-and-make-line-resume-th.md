---
{
  "id": "WO-20261012-e970",
  "slug": "roadmap-c-make-line-halt-and-make-line-resume-th",
  "title": "Roadmap C - make line-halt and make line-resume: the halt flag the supervisor honours, USERHALT, and bearings stable always left running",
  "type": "feature",
  "status": "cancelled",
  "priority": "p1",
  "created": "2026-10-12",
  "updated": "2026-10-13",
  "created_at": "2026-10-12T22:13:55+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": null,
  "pr": null,
  "closed": "2026-10-13",
  "approval": {
    "via": "override",
    "reason": "owner locked ROADMAP.md 2026-10-12 (cards C9 to C22) and gave USERGO; Getting My Bearings is the review surface, lavish is prohibited",
    "at": "2026-10-12"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261012-7a46",
    "WO-20261012-aac3"
  ],
  "blocks": [],
  "files": [
    "Makefile",
    "herdr/bin/line.sh",
    "herdr/bin/supervisor.sh",
    "herdr/tests/cases/*",
    "docs/runbooks/line-halt-resume.md"
  ],
  "superseded_by": "WO-20261013-f52a"
}
---

# WO-20261012-e970 - Roadmap C - make line-halt and make line-resume: the halt flag the supervisor honours, USERHALT, and bearings stable always left running

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

Halting on 2026-10-12 meant hunting process ids by hand, and restarting needed a hand-written runbook.

## Scope

**In**

- make line-halt stops the belt, watches and loops, interrupts every seat's turn, writes the halt flag and a record, and never stops bearings stable
- make line-resume runs the preflight (stale pending records marked done), starts each component once, wakes seats one at a time
- the supervisor honours the halt flag and while halted keeps only bearings stable alive; then it is installed

**Out - non-goals**

- new monitoring

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* in the herdr test world line-halt leaves no belt or watch process and bearings stable still running
- [ ] `AC-H2` *(human)* line-resume after a halt routes the live records once and marks stale ones done

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

Cancelled `2026-10-13` - nothing shipped.

- reason: superseded by WO-20261013-f52a: Roadmap K4 widens item C with drain and line-check per SPEC-17 s-build
- superseded by: `WO-20261013-f52a`

No branch, no PR and no merge commit exist for this work order.

