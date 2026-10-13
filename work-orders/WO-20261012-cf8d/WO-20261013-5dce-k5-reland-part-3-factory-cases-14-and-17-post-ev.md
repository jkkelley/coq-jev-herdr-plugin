---
{
  "id": "WO-20261013-5dce",
  "slug": "k5-reland-part-3-factory-cases-14-and-17-post-ev",
  "title": "K5 reland, part 3: factory cases 14 and 17 post every gate record with its sha",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T14:36:03+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect orders 2026-10-13: 9c50 split (reviewer max_seats 2 to 4), K5 reland, post-merge as code; lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261013-d1cd"
  ],
  "blocks": [
    "WO-20261013-e9c0"
  ],
  "files": [
    "factory/tests/cases/14-flow-busy.test.sh",
    "factory/tests/cases/17-state-root.test.sh"
  ]
}
---

# WO-20261013-5dce - K5 reland, part 3: factory cases 14 and 17 post every gate record with its sha

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

Same cause as part 1 (32fc429 reverted for breaking the factory suite); these cases post gate records with no sha.

## Scope

**In**

- factory/tests/cases/14-flow-busy and 17-state-root pass --sha on every gate record

**Out - non-goals**

- the writer (the reland part)
- herdr/tests/cases/13-break-glass and 18-watches, which A3 parts WO-20261013-5c06 and WO-20261013-f9f2 own on pull request 89

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* make -C factory test passes with today's writer, and these files post no gate record without --sha

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
