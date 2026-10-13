---
{
  "id": "WO-20261013-17a1",
  "slug": "close-the-two-stale-tickets-with-no-pull-request",
  "title": "Close the two stale tickets with no pull request, WO-20261010-eaa3 and WO-20261011-38c7, through the work-order tool with the proof found on their branches (K8 part 3 of 5)",
  "type": "feature",
  "status": "ready",
  "priority": "p1",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T03:17:44+00:00",
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
  "blocks": [],
  "files": [
    "work-orders/WO-20261010-da54/WO-20261010-eaa3-*",
    "work-orders/WO-20261010-329d/WO-20261011-38c7-*",
    "work-orders/archive/2026/WO-20261010-eaa3-*",
    "work-orders/archive/2026/WO-20261011-38c7-*"
  ]
}
---

# WO-20261013-17a1 - Close the two stale tickets with no pull request, WO-20261010-eaa3 and WO-20261011-38c7, through the work-order tool with the proof found on their branches (K8 part 3 of 5)

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

Split of WO-20261013-89c7 (Roadmap K8) under the owner's size rule of 2026-10-13 03:00Z.

## Scope

**In**

- each ticket done with evidence when its work is on main, cancelled with the reason otherwise; WO-20261011-23df is carried by pull request 15 and left alone

**Out - non-goals**

- any code change

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* neither ticket is in-progress on main afterwards, and each carries its evidence or its cancel reason
- [ ] `AC-H2` *(human)* make lint passes

## Test plan

```sh
make lint, in Podman through the repository target
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
