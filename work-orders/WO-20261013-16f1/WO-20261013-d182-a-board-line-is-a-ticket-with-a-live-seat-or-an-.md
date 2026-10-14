---
{
  "id": "WO-20261013-d182",
  "slug": "a-board-line-is-a-ticket-with-a-live-seat-or-an-",
  "title": "A board line is a ticket with a live seat or an open PR; in-progress with neither shows under stale (cause ae)",
  "type": "bug",
  "status": "ready",
  "priority": "p1",
  "created": "2026-10-13",
  "updated": "2026-10-14",
  "created_at": "2026-10-13T22:52:32+00:00",
  "parent": "WO-20261013-16f1",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "owner via architect 22:55Z: board shows 17 lines, stale counted",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261013-10d8"
  ],
  "blocks": [],
  "files": [
    "report/loop/loop.sh",
    "report/loop/schema/loop.schema.json",
    "report/loop/lib/stale.sh",
    "report/loop/tests/cases/19-stale-split.test.sh"
  ]
}
---

# WO-20261013-d182 - A board line is a ticket with a live seat or an open PR; in-progress with neither shows under stale (cause ae)

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

report/loop collect counts every ticket file marked in-progress as a line. On 2026-10-13 the board showed 17 lines, 5 stale with no branch or PR (5fa8, b221, c17f, f268, fe37) and some merged but never archived. The owner cannot read the factory from it.

## Scope

**In**

- collect lists in-progress tickets with a live seat or an open PR as lines; in-progress with neither go to a separate stale list, shown on the page and not counted in the line total. Fixture and case cover it.

**Out - non-goals**

- Sweeping the stale tickets (separate task), the page layout beyond a stale section.

## Degrees of freedom

- [free] The schema may gain a stale key; keep validate's existing stale check consistent.

## Acceptance criteria

- [ ] `AC-H1` *(human)* A fixture with one live ticket and one in-progress ticket without seat or PR yields one line and one stale entry; page shows both under distinct headings; lint and the report/loop suite pass.

## Test plan

```sh
report/loop/tests case for the stale split via suites.sh plan.
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
