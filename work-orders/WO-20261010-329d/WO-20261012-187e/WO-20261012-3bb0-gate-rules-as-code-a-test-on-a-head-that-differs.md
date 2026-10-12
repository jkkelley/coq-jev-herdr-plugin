---
{
  "id": "WO-20261012-3bb0",
  "slug": "gate-rules-as-code-a-test-on-a-head-that-differs",
  "title": "Gate rules as code: a test on a head that differs only by records counts, a head that moves re-wakes the tester, and a PR conflicting with main gets main merged by its worker, all from routes and the merger's checks",
  "type": "feature",
  "status": "in-progress",
  "priority": "p0",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T14:04:49+00:00",
  "parent": "WO-20261012-187e",
  "branch": "feat/gate-rules-as-code-a-test-on-a-head-that-differs",
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "lavish is prohibited for Claude seats; owner order 2026-10-12: get the factory working without the architect or owner as a gate",
    "at": "2026-10-12"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": []
}
---

# WO-20261012-3bb0 - Gate rules as code: a test on a head that differs only by records counts, a head that moves re-wakes the tester, and a PR conflicting with main gets main merged by its worker, all from routes and the merger's checks

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

The architect judged by hand that a test on efc1cd2 covered 43c22b4 (one record file apart), told testers to wait for moved heads, and woke workers to merge main on conflict; none of it is written down, so it stops when the architect does.

## Scope

**In**

- merger check: tree equality outside events/ counts as the same sha
- pr.opened on a PR whose tester has a run in flight supersedes it
- merge.conflict routes to the worker with merge main

**Out - non-goals**

- generated-file conflicts (WO-20261011-5064)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* the merger merges when test and review name shas whose trees differ only under events/, and holds when any other path differs
- [ ] `AC-H2` *(human)* a second pr.opened makes the tester drop the older head and post nothing for it

## Test plan

```sh
make -C factory test
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-12` Add to scope at start: flow-watch stall rule (90s after a gate trigger with no next record) fired three false alarms on 2026-10-12 (ch471, 0ui6q-class, 06gu1) while the seat was mid-task; judge a stall by the seat's process/turn state, not a fixed timer.

## Outcome

_Written by `work-order done`. Empty until then._
