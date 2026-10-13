---
{
  "id": "WO-20261012-541a",
  "slug": "roadmap-a3-seats-reports-and-bearings-read-the-s",
  "title": "Roadmap A3 - Seats, reports and bearings read the state root: seat.sh, the watches, the roles and playbooks, the loop board and the sitrep read records from the one state root",
  "type": "feature",
  "status": "cancelled",
  "priority": "p0",
  "created": "2026-10-12",
  "updated": "2026-10-13",
  "created_at": "2026-10-12T22:13:20+00:00",
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
    "WO-20261012-0229"
  ],
  "blocks": [],
  "files": [
    "herdr/bin/*",
    "herdr/config/*",
    "herdr/layouts/*",
    "herdr/tests/*",
    "roles/*",
    "playbooks/*",
    "report/loop/*",
    "tools/bearings/config/sitrep.json",
    "tools/bearings/scripts/sitrep-build.mjs"
  ],
  "superseded_by": "WO-20261013-496d"
}
---

# WO-20261012-541a - Roadmap A3 - Seats, reports and bearings read the state root: seat.sh, the watches, the roles and playbooks, the loop board and the sitrep read records from the one state root

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

Seats search their own slot's events/ and miss records (the merger did on 2026-10-12 22:05Z), and the board and sitrep read the repository events/.

## Scope

**In**

- herdr scripts, roles, playbooks, report/loop and the bearings sitrep build resolve records through the state root
- every playbook names the state root as the only place records are read and written

**Out - non-goals**

- seat behaviour changes beyond paths (B)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* a seat started in a treehouse slot posts a record that lands in the state root, not in the slot
- [ ] `AC-H2` *(human)* loop.sh view and the sitrep build show a record written to the state root
- [ ] `AC-H3` *(human)* make -C herdr test and make -C report/loop test pass with COQ_STATE at a temp dir

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

- reason: superseded under the size rule (owner 03:00Z, architect P1 order): split into ten parts with explicit files, five readers and five role pairs; this one claimed whole directories
- superseded by: `WO-20261013-496d`

No branch, no PR and no merge commit exist for this work order.

