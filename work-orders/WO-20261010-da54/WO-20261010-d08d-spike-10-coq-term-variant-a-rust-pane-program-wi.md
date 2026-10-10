---
{
  "id": "WO-20261010-d08d",
  "slug": "spike-10-coq-term-variant-a-rust-pane-program-wi",
  "title": "Spike 10: coq-term variant A, Rust pane program with the pane.graphics.set backend",
  "type": "feature",
  "status": "draft",
  "priority": "p0",
  "created": "2026-10-10",
  "updated": "2026-10-10",
  "created_at": "2026-10-10T19:24:20+00:00",
  "parent": "WO-20261010-da54",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": null,
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261010-4beb"
  ],
  "blocks": []
}
---

# WO-20261010-d08d - Spike 10: coq-term variant A, Rust pane program with the pane.graphics.set backend

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

Spike 5 proved the socket image path; a program that streams frames into a pane at a usable rate is unproven

## Scope

**In**

- Rust binary: reads frames (PNG or raw RGBA) from a source, pushes them with pane.graphics.set at a target fps, forwards keys to a sink; measure fps and latency

**Out - non-goals**

- production code; any Steam client automation

## Degrees of freedom

- [free] crate choices; frame source for the spike (a test pattern or Xvfb capture)

## Acceptance criteria

- [ ] `AC-H1` *(human)* 10 fps at 640x400 in the owner's terminal with under 150 ms glass-to-glass; input round trip measured
- [ ] `AC-H2` *(human)* result recorded with events/bin/event.sh (201 pass or 422 fail) and a graph node with evidence paths

## Test plan

```sh
podman run --rm --network=none ... per spike; pass/fail signal recorded with events/bin/event.sh add --kind test --code 201|422 --evidence <path>
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
