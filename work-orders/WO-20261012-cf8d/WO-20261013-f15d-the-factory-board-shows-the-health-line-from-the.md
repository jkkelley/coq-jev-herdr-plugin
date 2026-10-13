---
{
  "id": "WO-20261013-f15d",
  "slug": "the-factory-board-shows-the-health-line-from-the",
  "title": "The factory board shows the health line from the board's health file when present, so the owner's question has one answer (K8 part 5 of 5)",
  "type": "feature",
  "status": "ready",
  "priority": "p1",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T03:17:50+00:00",
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
    "WO-20261013-19d9",
    "WO-20261013-3796"
  ],
  "blocks": [],
  "files": [
    "report/loop/loop.sh",
    "report/loop/lib/collect.jq",
    "report/loop/tests/cases/09-health-line.test.sh"
  ]
}
---

# WO-20261013-f15d - The factory board shows the health line from the board's health file when present, so the owner's question has one answer (K8 part 5 of 5)

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

- loop.sh and lib/collect.jq read the health file named in line/config/board.json when it exists; case report/loop/tests/cases/09-health-line.test.sh

**Out - non-goals**

- writing the health file (K1 part 4)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* the board view shows the health file's state and lanes within one refresh, and nothing when the file is absent
- [ ] `AC-H2` *(human)* make lint and make -C report/loop test pass in Podman

## Test plan

```sh
make lint && make -C report/loop test, in Podman through the repository targets
```

## Assumptions

1. SPEC-16.I's status answer replaces the health file once the scheduler is active (owner 02:50Z)

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
