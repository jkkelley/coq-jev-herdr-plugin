---
{
  "id": "WO-20261013-f298",
  "slug": "roadmap-k5-the-writer-refuses-a-gate-record-with",
  "title": "Roadmap K5 - The writer refuses a gate record without its sha and any code outside the SPEC-17 status code map, and the schema gains the halt, drain and resume kinds (after A1)",
  "type": "feature",
  "status": "in-progress",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T00:57:35+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": "feat/roadmap-k5-the-writer-refuses-a-gate-record-with",
  "pr": null,
  "closed": null,
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
  - observed `2026-10-13` events/tests/cases/04-refusals.test.sh: all nine gate kinds without --sha exit 3 with 'event: --sha is required on a <kind> record', and no record is written; suite 'tests: 4 passed, 0 failed'
- [x] `AC-H2` *(human)* a record with a code outside the map exits 3 naming the code; every code of the map is accepted
  - observed `2026-10-13` 04-refusals: codes 101,150,199,202,203,301,401,410,424,450,499,501,502,504,599 exit 3 naming the code, nothing written; all 13 codes of SPEC-17 s-codes accepted; schema enum compared with the spec text; line.halted/draining/resumed validate
- [x] `AC-H3` *(human)* make lint passes with the schema change and events check still validates every existing record
  - observed `2026-10-13` make lint: 'lint: all ok' with 'events: every file valid ok'; events/bin/event.sh check passes in 03-read ('events ok: 12 files')

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

- `2026-10-13` Retro. Cost for the architect to rule on: factory/tests and herdr/tests post gate kinds with no --sha and codes 150/250 (07-other-repo, others), so 01-wake, 02-no-route, 03-escalate, 04-restart, 05-new-row, 07, 08-ignore, 09, 10-sha, 11-down fail on the new refusal; those files belong to PR 88 (A2) so not touched here, fix after A2 merges. roles/compliance-officer.json reports code 450, outside the map (s-codes puts seat findings at 500). Existing state-root records: 150/450 uses were test fixtures only; 03-read fixture moved to code 100.

## Outcome

_Written by `work-order done`. Empty until then._
