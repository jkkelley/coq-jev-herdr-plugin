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

- [ ] `AC-H1` *(human)* a test.passed without --sha exits 3 naming the flag and writes nothing
- [ ] `AC-H2` *(human)* a record with a code outside the map exits 3 naming the code; every code of the map is accepted
- [ ] `AC-H3` *(human)* make lint passes with the schema change and events check still validates every existing record

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

## Outcome

_Written by `work-order done`. Empty until then._
