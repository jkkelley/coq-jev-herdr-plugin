---
{
  "id": "WO-20261011-fa78",
  "slug": "first-ticket-through-the-line-pr-11-closes-with-",
  "title": "First ticket through the line: PR 11 closes with a seat at every station and no by-hand record",
  "type": "feature",
  "status": "draft",
  "priority": "p0",
  "created": "2026-10-11",
  "updated": "2026-10-11",
  "created_at": "2026-10-11T14:39:42+00:00",
  "parent": "WO-20261010-329d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": null,
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261011-9639",
    "WO-20261011-23df"
  ],
  "blocks": [
    "WO-20261011-7b8f"
  ]
}
---

# WO-20261011-fa78 - First ticket through the line: PR 11 closes with a seat at every station and no by-hand record

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

No ticket has ever been closed by the loop; the last three were merged by the architect from main

## Scope

**In**

- WO-20261011-dc0d runs the line: its worker runs submit and done (B1), tester, reviewer and merger seats write their records (B3), cleanup by the merger
- every manual touch is listed in the retro note; anything that blocked the line becomes a ticket
- the board shows the dc0d line with zero by-hand stations

**Out - non-goals**

- new features
- PR 12 and the foundation branch (B7)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* dc0d reaches done on its own branch by its worker seat
- [ ] `AC-H2` *(human)* test, review and merged records for dc0d come from three seats that are not the architect
- [ ] `AC-H3` *(human)* the merger ran work-order.sh cleanup and released slot 1
- [ ] `AC-H4` *(human)* the board line for dc0d shows no by-hand station
- [ ] `AC-H5` *(human)* the retro note lists every manual touch, and each one has a ticket or a routes.json row

## Test plan

```sh
events/bin/event.sh list --ticket WO-20261011-dc0d gh pr view 11 --json state,mergedBy
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-11` Owner law 2026-10-11 15:34Z (graph DEC-system-runs-the-loop, on REQ-north-star): the system runs the loop, not agents. Notification sound, automated, deterministic; cleanup done by the system; no idle agents; greens visible from records. Every hand step in SOP-0001 (wake by prompt, down after record, salvage, cleanup) must be owned by the belt when this lands.

## Outcome

_Written by `work-order done`. Empty until then._
