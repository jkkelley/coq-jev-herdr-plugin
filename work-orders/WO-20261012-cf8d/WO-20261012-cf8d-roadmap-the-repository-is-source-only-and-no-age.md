---
{
  "id": "WO-20261012-cf8d",
  "slug": "roadmap-the-repository-is-source-only-and-no-age",
  "title": "Roadmap: the repository is source only and no agent is a gate",
  "type": "chore",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T22:13:09+00:00",
  "parent": null,
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "owner locked ROADMAP.md 2026-10-12 (cards C9 to C22) and gave USERGO; Getting My Bearings is the review surface, lavish is prohibited",
    "at": "2026-10-12"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": []
}
---

# WO-20261012-cf8d - Roadmap: the repository is source only and no agent is a gate

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

On 2026-10-12 the line flooded the architect and stopped: the repository was the message bus, the architect was the gate for carries, verifies, conflicts and records, and halting was not a command. ROADMAP.md, locked by the owner, is the fix; this epic holds its work items.

## Scope

**In**

- the lettered work items of ROADMAP.md as child tickets

**Out - non-goals**

- the big loop design, which ROADMAP.md names as the next design after phase 5

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* every child ticket is done and ROADMAP.md phases 2 and 3 meet their done-when lines

## Test plan

```sh
make lint && make -C factory test && make -C herdr test, all in Podman through the repository targets
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
