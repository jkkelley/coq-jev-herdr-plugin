---
{
  "id": "WO-20261013-1e65",
  "slug": "the-factory-board-reads-live-ticket-state-loop-s",
  "title": "The factory board reads live ticket state: loop.sh collect takes the open pull requests and the ticket branches on origin, so a started ticket shows live with its branch, pull request and latest gate record (K8 part 1 of 5)",
  "type": "feature",
  "status": "ready",
  "priority": "p1",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T03:17:38+00:00",
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
  "depends_on": [],
  "blocks": [
    "WO-20261013-e537"
  ],
  "files": [
    "report/loop/loop.sh",
    "report/loop/lib/collect.jq",
    "report/loop/tests/cases/06-live.test.sh",
    "report/loop/tests/fixtures/live/*"
  ]
}
---

# WO-20261013-1e65 - The factory board reads live ticket state: loop.sh collect takes the open pull requests and the ticket branches on origin, so a started ticket shows live with its branch, pull request and latest gate record (K8 part 1 of 5)

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

Split of WO-20261013-89c7 (Roadmap K8 - the factory board shows the live line) under the owner's size rule of 2026-10-13 03:00Z.

## Scope

**In**

- report/loop/loop.sh collect and lib/collect.jq read open pull requests (number, head, title) and origin ticket branches; inside the test image they come from fixtures
- case report/loop/tests/cases/06-live.test.sh with fixtures under report/loop/tests/fixtures/live/

**Out - non-goals**

- the stale-ticket check (K8 part 2)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* a ticket started in the fixture shows live with its branch and pull request, and a ticket with an open pull request shows the same
- [ ] `AC-H2` *(human)* make lint and make -C report/loop test pass in Podman

## Test plan

```sh
make lint && make -C report/loop test, in Podman through the repository targets
```

## Assumptions

1. gh and git answer on the host; the test image uses fixtures

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
