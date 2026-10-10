---
{
  "id": "WO-20261010-090c",
  "slug": "sitrep-site-go-server-websocket-owner-channel-wi",
  "title": "SITREP site: Go server, websocket owner channel, wireframe viewer, link to the factory dashboard",
  "type": "feature",
  "status": "draft",
  "priority": "p0",
  "created": "2026-10-10",
  "updated": "2026-10-10",
  "created_at": "2026-10-10T19:25:21+00:00",
  "parent": "WO-20261010-98ea",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": null,
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261010-7c55"
  ],
  "blocks": [
    "WO-20261010-c180"
  ]
}
---

# WO-20261010-090c - SITREP site: Go server, websocket owner channel, wireframe viewer, link to the factory dashboard

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

The owner wants to talk to the interface agent and review wireframes from one local page, not the terminal

## Scope

**In**

- cmd/sitrep Go binary serving the page, a websocket channel with schema JSON frames, a wireframe viewer, tiers from config, labelled pane, Makefile, Podman suite from new-podman-suite.sh

**Out - non-goals**

- the factory dashboard itself
- cluster deploy (Helm later)

## Degrees of freedom

- [free] Go web framework choice (stdlib or one framework already used in rime)

## Acceptance criteria

- [ ] `AC-H1` *(human)* owner sends a message from the page and the interface agent's reply appears without reload
- [ ] `AC-H2` *(human)* wireframe viewer shows the frames from the wireframes ticket
- [ ] `AC-H3` *(human)* suite green; make serve TIER=uat works from a slot

## Test plan

```sh
make -C cmd/sitrep test
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
