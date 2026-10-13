---
{
  "id": "WO-20261013-f298",
  "slug": "roadmap-k5-the-writer-refuses-a-gate-record-with",
  "title": "Roadmap K5 - The writer refuses a gate record without its sha and any code outside the SPEC-17 status code map, and the schema gains the halt, drain and resume kinds (after A1)",
  "type": "feature",
  "status": "done",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T00:57:35+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": "feat/roadmap-k5-the-writer-refuses-a-gate-record-with",
  "pr": 145,
  "closed": "2026-10-13",
  "approval": {
    "via": "override",
    "reason": "owner accepted SPEC-17 on card C25; lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261012-7e13"
  ],
  "blocks": [],
  "files": [
    "events/bin/event.sh",
    "events/schema/event.schema.json",
    "events/tests/*"
  ]
}
---

# WO-20261013-f298 - Roadmap K5 - The writer refuses a gate record without its sha and any code outside the SPEC-17 status code map, and the schema gains the halt, drain and resume kinds (after A1)

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

On 2026-10-12 a tester's test.passed carried no sha and the reviewer's pass was held until a re-seat by hand; a code nobody maps routes nowhere (SPEC-17 s-inventory H11). SPEC-17 s-codes is the map; the writer still accepts both.

## Scope

**In**

- events/bin/event.sh add exits 3 naming the flag when a record of kind pr.opened, test.passed, test.failed, review.passed, review.changes, merged, merge.conflict, verified or rejected carries no --sha
- the writer exits 3 naming the code when it is not in SPEC-17 s-codes; the schema's code set is the map; kinds line.halted, line.draining and line.resumed added
- cases in events/tests for each refusal and for every accepted code; existing records still validate

**Out - non-goals**

- routing (K7)
- the board (K1)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [x] `AC-H1` *(human)* a test.passed without --sha exits 3 naming the flag and writes nothing
  - observed `2026-10-13` events/tests/cases/04-refusals.test.sh: each of the nine gate kinds without --sha exits 3 with 'event: --sha is required on a <kind> record' and the record count stays 0; the suite passes in pane wD3:p1FS (events 4 passed, 0 failed)
- [x] `AC-H2` *(human)* a record with a code outside the map exits 3 naming the code; every code of the map is accepted
  - observed `2026-10-13` 04-refusals.test.sh: all 13 codes of the SPEC-17 s-codes map are accepted and validate; 15 codes outside it (101, 150, 199, 450, 501 and others) exit 3 naming the code with nothing written; the schema enum equals the spec's s-codes list
- [x] `AC-H3` *(human)* make lint passes with the schema change and events check still validates every existing record
  - observed `2026-10-13` make lint: lint all ok; make -C factory test 25 passed, make -C line test 13 passed, make -C herdr test 31 passed. events check passes every record but one that is invalid under the pre-change schema too (20261013134301-review-changes-pr-92-wo-20261013-b221.json, 7 observations against maxItems 5), not caused by this change

## Test plan

```sh
make lint && make -C events test, in Podman through the repository targets (A1 provides the events test target)
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-13` Retro: K5 landed as PR 90 and was reverted (PR 95) because 16 factory cases post bare gate records and codes outside the map. Reland keeps the writer strict and puts the difference in the fixture, factory/tests/lib/world.sh event-fixture.sh, with a breadcrumb. Open for the architect: roles/compliance-officer.json and playbooks/compliance-officer.md report code 450, which the writer now refuses (SPEC-17 puts seat findings at 500); one live record (20261013134301-review-changes-pr-92-wo-20261013-b221.json) has 7 observations over the schema max of 5 and fails events check on main already.

## Outcome

_Written by `work-order done`. Empty until then._
