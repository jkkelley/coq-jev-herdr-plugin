---
{
  "id": "WO-20261013-dd47",
  "slug": "gate-capacity-the-reviewer-role-s-max-seats-goes",
  "title": "Gate capacity: the reviewer role's max_seats goes from 2 to 4, playbook re-rendered",
  "type": "feature",
  "status": "cancelled",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T14:35:55+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": null,
  "pr": null,
  "closed": "2026-10-13",
  "approval": {
    "via": "override",
    "reason": "architect orders 2026-10-13, re-cut on review yv8xi; lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261013-a1c6"
  ],
  "blocks": [],
  "files": [
    "roles/reviewer.json",
    "playbooks/reviewer.md",
    "herdr/tests/cases/28-reviewer-seats.test.sh"
  ],
  "superseded_by": "WO-20261013-5f41"
}
---

# WO-20261013-dd47 - Gate capacity: the reviewer role's max_seats goes from 2 to 4, playbook re-rendered

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

Two reviewer seats queue the review of every open pull request behind each other; the architect ruled 2026-10-13 that the reviewer gets four seats. Split from WO-20261013-9c50 under the size rule.

## Scope

**In**

- roles/reviewer.json max_seats 4; playbooks/reviewer.md re-rendered by roles/bin/render-playbook.sh
- herdr/tests/cases/28-reviewer-seats.test.sh pins max_seats 4 and fails on 2

**Out - non-goals**

- role models (WO-20261013-0f18)
- herdr max_agents (WO-20261013-a1c6)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* the role says 4, the case fails on 2 and the playbook check in lint reports no drift

## Test plan

```sh
make lint && make -C herdr test, in Podman through the repository targets (lint runs the playbook drift check)
```

## Assumptions

1. WO-20261013-44b3 (pull request 89) also edits these files; the edge is written once pull request 89 merges

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

Cancelled `2026-10-13` - nothing shipped.

- reason: architect ruling (b) 2026-10-13: pull request 99 already sets reviewer max_seats 4 (plus worker 6, orchestrator 2); rescoped to the cap test only
- superseded by: `WO-20261013-5f41`

No branch, no PR and no merge commit exist for this work order.

