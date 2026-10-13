---
{
  "id": "WO-20261013-f9f2",
  "slug": "roadmap-a3-recwatch-reads-the-records-tree-of-th",
  "title": "Roadmap A3 - recwatch reads the records tree of the state root instead of the checkout's and every slot's events/",
  "type": "feature",
  "status": "done",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T14:11:17+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": "feat/roadmap-a3-recwatch-reads-the-records-tree-of-th",
  "pr": 107,
  "closed": "2026-10-13",
  "approval": {
    "via": "override",
    "reason": "architect P1 order 2026-10-13: A3 split under the owner size rule (03:00Z); lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [
    "WO-20261012-99d6"
  ],
  "files": [
    "herdr/bin/recwatch.sh",
    "herdr/tests/cases/18-watches.test.sh"
  ]
}
---

# WO-20261013-f9f2 - Roadmap A3 - recwatch reads the records tree of the state root instead of the checkout's and every slot's events/

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

herdr/bin/recwatch.sh lists events/ under the checkout and under every treehouse slot and de-duplicates copies by file name; since A1 every record is written once to the state root, so the slot scan reads copies and misses nothing only by luck. Split from WO-20261012-541a.

## Scope

**In**

- recwatch.sh polls the one records tree from bin/state-root.sh tree records; the slot scan and the cross-root de-duplication go; the breadcrumb is updated
- herdr/tests/cases/18-watches.test.sh: a record written to COQ_STATE/records is announced once; a file under a slot's events/ is not

**Out - non-goals**

- replacing recwatch with the herdr board delivery model (WO-20261013-bf48 and its parts)
- herdr/tests/lib/world.sh

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [x] `AC-H1` *(human)* the watch announces a new gate record from the state root once and ignores a slot's events/
  - observed `2026-10-13` herdr case 18-watches: a pr.opened written to COQ_STATE/records is announced 'REC state ...' and appears exactly once in the recwatch pane; files under the checkout's events/ and a leased slot's events/ are not announced, while a later state-root record is
- [x] `AC-H2` *(human)* make -C herdr test passes; make lint passes
  - observed `2026-10-13` make lint passed; make -C herdr test: 26 passed, 1 failed, the one being 12-blueprint-panes ('dev serves a built page'), which fails identically on unmodified origin/main (checked in the test pane), so not caused by this change; 18-watches passes

## Test plan

```sh
make lint && make -C herdr test, in Podman through the repository targets
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-13` retro: Case 18 took the old checkout/slot records by file name; since A1 they live in the state root. Pre-existing failure on main: herdr case 12-blueprint-panes 'dev serves a built page' (no page promoted) is outside this ticket's files and needs its own ticket.

## Outcome

_Written by `work-order done`. Empty until then._
