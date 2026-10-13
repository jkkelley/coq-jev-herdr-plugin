---
{
  "id": "WO-20261013-bed2",
  "slug": "routes-rows-429-and-500-to-the-orchestrator-lane",
  "title": "Routes rows: 429 and 500 to the orchestrator lane, merged 200 to the merger only, the architect row on merged 200 deleted, and the owner seat read from the ticket (K7 part 2 of 4)",
  "type": "feature",
  "status": "ready",
  "priority": "p1",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T03:29:33+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "owner 2026-10-13 03:00Z (record 57h60) size rule and 02:50Z (lvvtd) SPEC-16 is the engine; lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261013-44aa",
    "WO-20261012-6f13",
    "WO-20261013-b839"
  ],
  "blocks": [
    "WO-20261012-7a46"
  ],
  "files": [
    "factory/config/routes.json",
    "factory/tests/cases/*routes-rows*"
  ]
}
---

# WO-20261013-bed2 - Routes rows: 429 and 500 to the orchestrator lane, merged 200 to the merger only, the architect row on merged 200 deleted, and the owner seat read from the ticket (K7 part 2 of 4)

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

Split of WO-20261013-70c4 (Roadmap K7) under the owner's size rule of 2026-10-13 03:00Z, with SPEC-17 1.0.1's one consumer for merged 200.

## Scope

**In**

- factory/config/routes.json rows as named; case factory/tests/cases/*routes-rows*

**Out - non-goals**

- the row that calls line/bin/merge.sh (a follow-up of WO-20261013-f6ae)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* a scheduler ticket's record routes to its owner seat with no hand forwarding, and routes-lint passes
- [ ] `AC-H2` *(human)* make lint and make -C factory test pass in Podman

## Test plan

```sh
make lint && make -C factory test, in Podman through the repository targets
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
