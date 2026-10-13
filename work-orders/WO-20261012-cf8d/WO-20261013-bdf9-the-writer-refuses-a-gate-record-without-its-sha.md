---
{
  "id": "WO-20261013-bdf9",
  "slug": "the-writer-refuses-a-gate-record-without-its-sha",
  "title": "The writer refuses a gate record without its sha: event.sh add exits 3 naming --sha for pr.opened, test.passed, test.failed, review.passed, review.changes, merged, merge.conflict, verified and rejected, and writes nothing (K5 part 1 of 2)",
  "type": "feature",
  "status": "ready",
  "priority": "p1",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T03:17:32+00:00",
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
  "depends_on": [],
  "blocks": [
    "WO-20261013-e782"
  ],
  "files": [
    "events/bin/event.sh",
    "events/tests/cases/04-gate-sha.test.sh"
  ]
}
---

# WO-20261013-bdf9 - The writer refuses a gate record without its sha: event.sh add exits 3 naming --sha for pr.opened, test.passed, test.failed, review.passed, review.changes, merged, merge.conflict, verified and rejected, and writes nothing (K5 part 1 of 2)

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

- events/bin/event.sh add: the nine gate kinds require --sha; exit 3 naming the flag
- case events/tests/cases/04-gate-sha.test.sh

**Out - non-goals**

- the code map in the schema (K5 part 2)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* a test.passed without --sha exits 3 naming the flag and writes nothing; with --sha it is written
- [ ] `AC-H2` *(human)* make lint and make -C events test pass in Podman

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
