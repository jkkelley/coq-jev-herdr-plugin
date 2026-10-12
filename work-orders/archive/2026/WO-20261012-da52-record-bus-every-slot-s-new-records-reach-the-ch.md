---
{
  "id": "WO-20261012-da52",
  "slug": "record-bus-every-slot-s-new-records-reach-the-ch",
  "title": "Record bus: every slot's new records reach the checkout events/ within ten seconds, so the belt routes seat records with no copy by hand",
  "type": "feature",
  "status": "done",
  "priority": "p0",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T14:04:46+00:00",
  "parent": "WO-20261012-187e",
  "branch": "feat/record-bus-every-slot-s-new-records-reach-the-ch",
  "pr": 25,
  "closed": "2026-10-12",
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

- [x] `AC-H1` *(human)* a record written in any slot appears in the checkout events/ within 10 s, byte identical, once
  - observed `2026-10-12` make -C factory test case 12-bus: a record written by event.sh in slot 1, 2 and a later slot 3 appears in the checkout events/ at the same path, cmp byte identical, one file after three more ticks; run mode delivered in 4 s against the 10 s limit; route.sh once then seated the tester for a bus-copied pr.opened 100 with no copy by hand
- [x] `AC-H2` *(human)* the interim ~/.cache record-bus.sh is removed and grep finds no ~/.cache path in herdr/ or factory/
  - observed `2026-10-12` grep for the user cache path finds nothing in herdr/ or factory/ (case 12 greps both). NOT DONE by this seat: deleting the interim record-bus.sh under the user cache directory and stopping its loop in monitor slot 2.3.3, because the file is outside the worker's allowed paths; the architect or owner removes it, then bringup takes slot 2.3.3 for bus.sh

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

- `2026-10-12` Retro: bus.sh reads slots from treehouse status --json run in the repo, copies once through a ledger under factory/state/bus/copied, tmp then rename. The interim loop's skip-if-in-checkout rule let a record the architect removed come back, which is why the ledger exists. A record a seat commits and merges also arrives untracked in the checkout, so git pull there can refuse until the records commit takes it (breadcrumb in bus.sh). herdr case 04 and 05 counts moved from ten to eleven nodes for the new bus pane. Left to the architect or owner: delete the interim record-bus.sh in the user cache directory and stop its loop in slot 2.3.3 before bringup can take the slot.

## Outcome

_Written by `work-order done`. Empty until then._
