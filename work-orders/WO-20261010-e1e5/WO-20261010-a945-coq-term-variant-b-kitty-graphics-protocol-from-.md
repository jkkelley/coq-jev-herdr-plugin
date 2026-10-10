---
{
  "id": "WO-20261010-a945",
  "slug": "coq-term-variant-b-kitty-graphics-protocol-from-",
  "title": "coq-term variant B: Kitty graphics protocol from inside the pane",
  "type": "feature",
  "status": "draft",
  "priority": "p1",
  "created": "2026-10-10",
  "updated": "2026-10-10",
  "created_at": "2026-10-10T19:25:26+00:00",
  "parent": "WO-20261010-e1e5",
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

# WO-20261010-a945 - coq-term variant B: Kitty graphics protocol from inside the pane

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

A second render backend for comparison and for terminals without socket graphics

## Scope

**In**

- Rust program emitting Kitty graphics escapes from inside its pane, same protocol as variant A

**Out - non-goals**

- socket backend

## Degrees of freedom

- [free] crate choices

## Acceptance criteria

- [ ] `AC-H1` *(human)* renders the spike test pattern at 10 fps in the owner's terminal or records 422 with the terminal name

## Test plan

```sh
make -C terminals/kitty test
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
