---
{
  "id": "WO-20261013-fd7d",
  "slug": "make-line-halt-and-line-drain-the-halt-and-drain",
  "title": "make line-halt and line-drain: the halt and drain flags in the state root's run directory with reason and time, line.halted 503 to the owner lane, bearings stable never touched (K4 part 1 of 4)",
  "type": "feature",
  "status": "ready",
  "priority": "p1",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T03:29:15+00:00",
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
    "WO-20261013-f268",
    "WO-20261013-f298",
    "WO-20261012-41a3"
  ],
  "blocks": [
    "WO-20261013-ced5",
    "WO-20261013-8e0c"
  ],
  "files": [
    "Makefile",
    "line/bin/line-halt.sh",
    "line/bin/line-drain.sh",
    "line/tests/cases/line-halt*"
  ]
}
---

# WO-20261013-fd7d - make line-halt and line-drain: the halt and drain flags in the state root's run directory with reason and time, line.halted 503 to the owner lane, bearings stable never touched (K4 part 1 of 4)

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

Split of WO-20261013-f52a (Roadmap K4 - halt, drain, resume and line-check) under the owner's size rule of 2026-10-13 03:00Z.

## Scope

**In**

- Makefile targets line-halt and line-drain calling line/bin/line-halt.sh and line/bin/line-drain.sh; halt stops the runner and watches and keeps every seat up; drain stops new dequeues
- case line/tests/cases/line-halt.sh (T08 without the supervisor)

**Out - non-goals**

- resume and check (later parts)
- the supervisor (K4 part 4)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* in the test world line-halt leaves no belt or watch process, every seat up and 503 on the owner lane; line-drain stops new dequeues and in-flight items finish
- [ ] `AC-H2` *(human)* make lint and make -C line test pass in Podman

## Test plan

```sh
make lint && make -C line test, in Podman through the repository targets
```

## Assumptions

1. interim until the scheduler is active: SPEC-16.F reads the same flags (f-halt, f-drain, f-recovery) at cut-over (owner 02:50Z)

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
