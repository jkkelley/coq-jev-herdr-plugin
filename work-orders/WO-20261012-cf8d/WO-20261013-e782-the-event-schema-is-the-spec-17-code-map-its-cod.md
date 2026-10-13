---
{
  "id": "WO-20261013-e782",
  "slug": "the-event-schema-is-the-spec-17-code-map-its-cod",
  "title": "The event schema is the SPEC-17 code map: its code set is the map, it gains the kinds line.halted, line.draining and line.resumed, and the writer exits 3 naming a code outside the map (K5 part 2 of 2)",
  "type": "feature",
  "status": "ready",
  "priority": "p1",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T03:17:35+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "owner 2026-10-13 03:00Z (record 57h60): one concern, at most 5 files, under about 300 lines; lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261013-bdf9"
  ],
  "blocks": [],
  "files": [
    "events/schema/event.schema.json",
    "events/bin/event.sh",
    "events/tests/cases/05-code-map.test.sh"
  ]
}
---

# WO-20261013-e782 - The event schema is the SPEC-17 code map: its code set is the map, it gains the kinds line.halted, line.draining and line.resumed, and the writer exits 3 naming a code outside the map (K5 part 2 of 2)

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

Split of WO-20261013-f298 (Roadmap K5 - writer refusals) under the owner's size rule of 2026-10-13 03:00Z.

## Scope

**In**

- events/schema/event.schema.json: code enum from SPEC-17 s-codes; kinds line.halted, line.draining, line.resumed
- event.sh names the refused code; case events/tests/cases/05-code-map.test.sh

**Out - non-goals**

- routing (K7 parts)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* a code outside the map exits 3 naming it; every code of the map is accepted
- [ ] `AC-H2` *(human)* every existing record still validates and make lint and make -C events test pass in Podman

## Test plan

```sh
make lint && make -C events test, in Podman through the repository targets
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
