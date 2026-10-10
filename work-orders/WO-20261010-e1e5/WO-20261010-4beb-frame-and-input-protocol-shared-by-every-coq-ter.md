---
{
  "id": "WO-20261010-4beb",
  "slug": "frame-and-input-protocol-shared-by-every-coq-ter",
  "title": "Frame and input protocol shared by every coq-term variant and game host",
  "type": "feature",
  "status": "draft",
  "priority": "p1",
  "created": "2026-10-10",
  "updated": "2026-10-10",
  "created_at": "2026-10-10T19:25:25+00:00",
  "parent": "WO-20261010-e1e5",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": null,
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [
    "WO-20261010-a945",
    "WO-20261010-d08d"
  ]
}
---

# WO-20261010-4beb - Frame and input protocol shared by every coq-term variant and game host

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

Variants and hosts must interoperate without prose: one schema for frames in and keys out

## Scope

**In**

- proto/coqterm/v1: Frame (png or rgba, size, seq, utc), Input (key, modifiers, seq), Trace (line, utc); JSON schema mirror for scripts

**Out - non-goals**

- a variant implementation

## Degrees of freedom

- [free] field naming within proto style

## Acceptance criteria

- [ ] `AC-H1` *(human)* make lint validates the schemas; a Go and a Rust stub round-trip one frame and one input

## Test plan

```sh
make -C proto test
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
