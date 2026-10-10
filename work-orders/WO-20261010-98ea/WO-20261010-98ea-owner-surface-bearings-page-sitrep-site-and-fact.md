---
{
  "id": "WO-20261010-98ea",
  "slug": "owner-surface-bearings-page-sitrep-site-and-fact",
  "title": "Owner surface: bearings page, SITREP site and factory dashboard",
  "type": "feature",
  "status": "draft",
  "priority": "p1",
  "created": "2026-10-10",
  "updated": "2026-10-10",
  "created_at": "2026-10-10T18:17:38+00:00",
  "parent": null,
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": null,
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": []
}
---

# WO-20261010-98ea - Owner surface: bearings page, SITREP site and factory dashboard

## Problem

The owner decides and talks to the system from a page, never the terminal. Today the page tool is a stale copy in the home directory with no tests, no tiers and hardcoded behaviour, and there is no SITREP site or factory dashboard at all.

## Scope

**In**

- bearings vendored into this repo with tiers, tests and an upgrade path
- SITREP client/server with a websocket owner channel and wireframe viewer
- factory dashboard reachable from the SITREP

**Out - non-goals**

- the game, the player seat, the Qud adapter
- the Go control plane itself, only the dashboard that reads it

## Acceptance criteria


- [ ] `AC-H1` *(human)* every child ticket is done and the owner has confirmed each surface from a wireframe shown in the SITREP

## Test plan

```sh
each child carries its own podman test plan; the epic closes on children
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
