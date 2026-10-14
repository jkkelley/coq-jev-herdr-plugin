---
{
  "id": "WO-20261013-8e0c",
  "slug": "the-supervisor-keeps-only-bearings-stable-alive-",
  "title": "The supervisor keeps only bearings stable alive while the halt flag exists, and the runbook says how the owner's USERHALT and USERGO reach the line commands (K4 part 4 of 4)",
  "type": "feature",
  "status": "ready",
  "priority": "p1",
  "created": "2026-10-13",
  "updated": "2026-10-14",
  "created_at": "2026-10-13T03:29:26+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "owner 2026-10-13 03:00Z (record 57h60) size rule and 02:50Z (lvvtd) SPEC-16 is the engine; lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261013-fd7d"
  ],
  "blocks": [
    "WO-20261013-77c0"
  ],
  "files": [
    "herdr/bin/supervisor.sh",
    "herdr/tests/cases/*supervisor*",
    "docs/runbooks/line-halt-resume.md"
  ]
}
---

# WO-20261013-8e0c - The supervisor keeps only bearings stable alive while the halt flag exists, and the runbook says how the owner's USERHALT and USERGO reach the line commands (K4 part 4 of 4)

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

Split of WO-20261013-f52a (Roadmap K4) under the owner's size rule of 2026-10-13 03:00Z.

## Scope

**In**

- herdr/bin/supervisor.sh: with the halt flag present it repairs only bearings stable
- herdr/tests/cases supervisor case for the halt; docs/runbooks/line-halt-resume.md

**Out - non-goals**

- the make targets (K4 parts 1 to 3)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* a supervisor tick under the halt flag repairs only bearings stable
- [ ] `AC-H2` *(human)* make lint and make -C herdr test pass in Podman

## Test plan

```sh
make lint && make -C herdr test, in Podman through the repository targets
```

## Assumptions

1. interim until the scheduler is active: SPEC-16.F reads the same flags (f-halt, f-drain, f-recovery) at cut-over (owner 02:50Z)

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-14` Duplicate audit ruling 2026-10-13T23:55Z (F16): first on herdr/bin/supervisor.sh; WO-20261013-77c0 depends on this ticket.

## Outcome

_Written by `work-order done`. Empty until then._
