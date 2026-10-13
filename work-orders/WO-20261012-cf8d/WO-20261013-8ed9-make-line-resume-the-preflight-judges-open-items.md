---
{
  "id": "WO-20261013-8ed9",
  "slug": "make-line-resume-the-preflight-judges-open-items",
  "title": "make line-resume: the preflight judges open items by rule, the system comes up B1 to B10 in order and stops at the first FAILED, seats one at a time, line.resumed 100, flags removed last (SPEC-17 T09; K4 part 3 of 4)",
  "type": "feature",
  "status": "ready",
  "priority": "p1",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T03:29:22+00:00",
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
    "WO-20261013-ced5",
    "WO-20261012-7a46"
  ],
  "blocks": [],
  "files": [
    "Makefile",
    "line/bin/line-resume.sh",
    "line/tests/cases/line-resume*"
  ]
}
---

# WO-20261013-8ed9 - make line-resume: the preflight judges open items by rule, the system comes up B1 to B10 in order and stops at the first FAILED, seats one at a time, line.resumed 100, flags removed last (SPEC-17 T09; K4 part 3 of 4)

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

- Makefile target line-resume calling line/bin/line-resume.sh: preflight (consumer gone, sha superseded or result present are done with the reason), bring-up in order with a 500 record at the first FAILED, merger first and worker last
- case line/tests/cases/line-resume.sh

**Out - non-goals**

- the supervisor (K4 part 4)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* after a halt, line-resume marks a stale item done with its reason, starts the system in order and routes live records once; a FAILED node stops it with a 500 and nothing below starts
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
