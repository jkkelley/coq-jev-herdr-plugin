---
{
  "id": "WO-20261013-9cc9",
  "slug": "cause-m-part-2-the-route-ignore-rows-for-note-an",
  "title": "Cause m part 2: the route ignore rows for note and verified match on kind alone, any code, with a factory case",
  "type": "bug",
  "status": "in-progress",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T22:06:20+00:00",
  "parent": "WO-20261013-16f1",
  "branch": "feat/cause-m-part-2-the-route-ignore-rows-for-note-an",
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect ruling 22:08Z route failures",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [],
  "files": [
    "factory/config/routes.json",
    "factory/tests/cases/23-ignore-by-kind.test.sh"
  ]
}
---

# WO-20261013-9cc9 - Cause m part 2: the route ignore rows for note and verified match on kind alone, any code, with a factory case

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

factory/config/routes.json ignore rows match note only at codes 100 and 300 and verified only at 201, while orchestrators post note 200, 409 and 422 and verified 200. 25 of 28 route-runner failures since 21:30Z are 'no route for note 200/409/422' (architect ruling 22:08Z, 51 failures per 30 min).

## Scope

**In**

- factory/config/routes.json: the ignore rows for kind note and kind verified match on kind alone, any code; one factory case proving a note at 200, 409 and 422 and a verified at 200 route to ignore and write no 500

**Out - non-goals**

- No other route row changes; no change to route.sh; every other kind keeps its code match

## Degrees of freedom

- [free] The row form is the worker's if the routes schema allows kind-only match

## Acceptance criteria

- [ ] `AC-H1` *(human)* AC-H1: note at any code and verified at any code route to ignore. AC-H2: a factory case proves note 200, 409, 422 and verified 200 write no route failure. AC-H3: make lint and make -C factory test exit 0

## Test plan

```sh
make lint && make -C factory test
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
