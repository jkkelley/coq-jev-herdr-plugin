---
{
  "id": "WO-20261013-48f2",
  "slug": "post-merge-cleanup-is-code-line-bin-after-merge-",
  "title": "Post-merge cleanup is code: line/bin/after-merge.sh cleans the branches, downs the ticket's seats and returns their slots, restores the checkout's ticket copies, starts verify-main.sh in an unowned pane and posts one record",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T14:36:12+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect orders 2026-10-13: 9c50 split (reviewer max_seats 2 to 4), K5 reland, post-merge as code; lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261013-9bdd"
  ],
  "blocks": [
    "WO-20261013-612d"
  ],
  "files": [
    "line/bin/after-merge.sh",
    "line/tests/cases/after-merge.sh"
  ]
}
---

# WO-20261013-48f2 - Post-merge cleanup is code: line/bin/after-merge.sh cleans the branches, downs the ticket's seats and returns their slots, restores the checkout's ticket copies, starts verify-main.sh in an unowned pane and posts one record

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

After every merge the orchestrator cleaned branches, downed seats, returned slots and restored ticket copies by hand (SPEC-17 s-inventory). Owner order 2026-10-13: post-merge cleanup is code, run by the belt on merged 200.

## Scope

**In**

- line/bin/after-merge.sh --record ID: work-order.sh cleanup (local and remote branches), herdr/bin/seat.sh down for every seat of the ticket with its slot returned, the checkout's ticket copies restored from main, verify-main.sh started in a herdr pane no seat owns, one record; each step 3 tries, then a 500 to the orchestrator lane
- line/tests/cases/after-merge.sh against a fake herdr, gh and git

**Out - non-goals**

- the route row that runs it (its own part)
- line/bin/merge.sh and its test (WO-20261013-f6ae)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* a merged 200 in the test world leaves no branch, no seat and no held slot for the ticket, starts verify-main once and posts one record; a step that fails three times posts one 500

## Test plan

```sh
make lint && make -C line test, in Podman through the repository targets
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
