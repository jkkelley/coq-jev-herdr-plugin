---
{
  "id": "WO-20261012-da52",
  "slug": "record-bus-every-slot-s-new-records-reach-the-ch",
  "title": "Record bus: every slot's new records reach the checkout events/ within ten seconds, so the belt routes seat records with no copy by hand",
  "type": "feature",
  "status": "in-progress",
  "priority": "p0",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T14:04:46+00:00",
  "parent": "WO-20261012-187e",
  "branch": "feat/record-bus-every-slot-s-new-records-reach-the-ch",
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "lavish is prohibited for Claude seats; owner order 2026-10-12: get the factory working without the architect or owner as a gate",
    "at": "2026-10-12"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": []
}
---

# WO-20261012-da52 - Record bus: every slot's new records reach the checkout events/ within ten seconds, so the belt routes seat records with no copy by hand

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

Seats write records into their slot's events/, route.sh watches only the checkout's, so the architect copied every gate record by hand; an interim bus runs from ~/.cache/coq-watch/record-bus.sh in monitor slot 2.3.3.

## Scope

**In**

- factory/bin/bus.sh run, a reserved monitor slot in monitors.json, started by bringup
- slots discovered from treehouse config, never a typed path

**Out - non-goals**

- changing the record schema

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* a record written in any slot appears in the checkout events/ within 10 s, byte identical, once
- [ ] `AC-H2` *(human)* the interim ~/.cache record-bus.sh is removed and grep finds no ~/.cache path in herdr/ or factory/

## Test plan

```sh
make -C factory test
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
