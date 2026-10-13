---
{
  "id": "WO-20261013-e537",
  "slug": "loop-sh-validate-fails-an-in-progress-ticket-on-",
  "title": "loop.sh validate fails an in-progress ticket on main that has no branch on origin and no open pull request, naming it (K8 part 2 of 5)",
  "type": "feature",
  "status": "ready",
  "priority": "p1",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T03:17:41+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "owner 2026-10-13 03:00Z (record 57h60): one concern, at most 5 files, under about 300 lines; lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261013-1e65"
  ],
  "blocks": [
    "WO-20261013-19d9"
  ],
  "files": [
    "report/loop/loop.sh",
    "report/loop/tests/cases/07-stale-ticket.test.sh"
  ]
}
---

# WO-20261013-e537 - loop.sh validate fails an in-progress ticket on main that has no branch on origin and no open pull request, naming it (K8 part 2 of 5)

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

Split of WO-20261013-89c7 (Roadmap K8) under the owner's size rule of 2026-10-13 03:00Z.

## Scope

**In**

- loop.sh validate exits 3 naming the ticket; report/loop's test target carries the case report/loop/tests/cases/07-stale-ticket.test.sh

**Out - non-goals**

- wiring the check into lint/lint.sh (a one-line follow-up when that file is free)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* validate exits 3 naming a fixture ticket that is in-progress with no branch and no pull request, and 0 once it is closed
- [ ] `AC-H2` *(human)* make lint and make -C report/loop test pass in Podman

## Test plan

```sh
make lint && make -C report/loop test, in Podman through the repository targets
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
