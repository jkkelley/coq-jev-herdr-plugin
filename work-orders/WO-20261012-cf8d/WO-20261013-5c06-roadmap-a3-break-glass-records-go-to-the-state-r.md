---
{
  "id": "WO-20261013-5c06",
  "slug": "roadmap-a3-break-glass-records-go-to-the-state-r",
  "title": "Roadmap A3 - Break glass records go to the state root: the grant file stores the records tree, not the slot's events/",
  "type": "feature",
  "status": "in-progress",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T14:11:14+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": "feat/roadmap-a3-break-glass-records-go-to-the-state-r",
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect P1 order 2026-10-13: A3 split under the owner size rule (03:00Z); lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [
    "WO-20261012-99d6"
  ],
  "files": [
    "herdr/bin/break-glass-lib.sh",
    "herdr/bin/break-glass-guard.sh",
    "herdr/tests/cases/13-break-glass.test.sh"
  ]
}
---

# WO-20261013-5c06 - Roadmap A3 - Break glass records go to the state root: the grant file stores the records tree, not the slot's events/

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

herdr/bin/break-glass-lib.sh writes events_root as COQ_EVENTS_ROOT or the slot's events/ into the grant file, and herdr/bin/break-glass-guard.sh posts the closing break.glass 201 with it, so the closing record lands in a slot when the seat runs in one. Split from WO-20261012-541a.

## Scope

**In**

- break-glass-lib.sh stores the records tree from bin/state-root.sh tree records in the grant file; break-glass-guard.sh posts with that tree; a breadcrumb at each line
- herdr/tests/cases/13-break-glass.test.sh: the grant and the closing record are both under COQ_STATE/records

**Out - non-goals**

- the break glass rules themselves (owner-only, one action)
- herdr/tests/lib/world.sh

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* a break glass grant and its closing 201 are found under the state root and none under a slot's events/
- [ ] `AC-H2` *(human)* make -C herdr test passes; make lint passes

## Test plan

```sh
make lint && make -C herdr test, in Podman through the repository targets
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
