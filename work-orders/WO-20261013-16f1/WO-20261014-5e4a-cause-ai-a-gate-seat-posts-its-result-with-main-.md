---
{
  "id": "WO-20261014-5e4a",
  "slug": "cause-ai-a-gate-seat-posts-its-result-with-main-",
  "title": "Cause ai: a gate seat posts its result with main's event.sh (the checkout's writer, which has K5's sha check), never the copy in the PR worktree, which can predate K5",
  "type": "bug",
  "status": "ready",
  "priority": "p1",
  "created": "2026-10-14",
  "updated": "2026-10-14",
  "created_at": "2026-10-14T00:08:58+00:00",
  "parent": "WO-20261013-16f1",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect order 00:07Z cause ai (record ci2os); approved by the architect in the owner place",
    "at": "2026-10-14"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": []
}
---

# WO-20261014-5e4a - Cause ai: a gate seat posts its result with main's event.sh (the checkout's writer, which has K5's sha check), never the copy in the PR worktree, which can predate K5

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

test.passed 20261013T233958Z-201-xhya3 for PR 156 (seat tester-wo-20261013-8573) carries pr null and sha null, so merge.sh cannot match head f41666d. Checked: the seat's worktree was treehouse slot 7 on the PR 156 branch, which was cut before the K5 reland (PR 145) landed on main; that copy of events/bin/event.sh accepts a gate record without --sha. Main's writer refuses it. So the actual path is the PR worktree's older writer.

## Scope

**In**

- roles/bin/brief.sh and playbooks/tester.md and playbooks/reviewer.md: the brief tells a gate seat to post with $COQ_REPO/events/bin/event.sh (main's checkout), not events/bin/event.sh of its worktree
- roles/tests/gate-writer-path.test.sh: the printed tester and reviewer briefs name the main writer path

**Out - non-goals**

- the writer's own sha check (WO-20261013-f298, merged)

## Degrees of freedom

- [free] [free] Whether the path is an env var or a literal in the brief

## Acceptance criteria

- [ ] `AC-H1` *(human)* A tester or reviewer brief names the main checkout's event.sh for posting

## Test plan

```sh
bash roles/tests/gate-writer-path.test.sh
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
