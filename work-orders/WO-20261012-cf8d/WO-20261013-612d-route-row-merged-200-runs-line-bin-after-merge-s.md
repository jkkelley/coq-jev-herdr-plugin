---
{
  "id": "WO-20261013-612d",
  "slug": "route-row-merged-200-runs-line-bin-after-merge-s",
  "title": "Route row: merged 200 runs line/bin/after-merge.sh instead of waking the architect to verify",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T14:36:14+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect orders 2026-10-13, re-cut on review yv8xi; lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261013-48f2"
  ],
  "blocks": [],
  "files": [
    "factory/config/routes.json",
    "factory/bin/route.sh",
    "factory/tests/cases/18-route-after-merge.test.sh"
  ]
}
---

# WO-20261013-612d - Route row: merged 200 runs line/bin/after-merge.sh instead of waking the architect to verify

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

routes.json routes merged 200 to a wake of the architect with verify and downs the merger; owner order 2026-10-13 makes the after-merge script the handler. Review yv8xi: code 450 (compliance report) has no row, so the reland of the code map would route it nowhere.

## Scope

**In**

- factory/config/routes.json: the merged 200 row runs after-merge.sh with the record id; route.sh gains the run action if the rows ticket has not added it
- factory/config/routes.json: a 450 row sends the compliance report to the orchestrator lane, which acts on conduct reports (SPEC-17 O9)
- factory/tests/cases/18-route-after-merge.test.sh covers both rows

**Out - non-goals**

- after-merge.sh itself
- other rows (WO-20261013-bed2)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* a merged 200 in the factory test world runs after-merge.sh once with the record id and wakes no architect; a 450 reaches the orchestrator; make lint passes

## Test plan

```sh
make lint && make -C factory test, in Podman through the repository targets
```

## Assumptions

1. WO-20261013-44aa, WO-20261013-bed2 and WO-20261013-04b8 (pull request 89) hold routes.schema.json, routes.json and route.sh; this row follows them, and the edges are written once pull request 89 merges

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
