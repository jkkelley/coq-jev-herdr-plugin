---
{
  "id": "WO-20261013-a1c6",
  "slug": "capacity-herdr-max-agents-goes-from-8-to-16-pinn",
  "title": "Capacity: herdr max_agents goes from 8 to 16, pinned by a herdr test case",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-14",
  "created_at": "2026-10-13T14:35:49+00:00",
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
    "WO-20261013-7af7"
  ],
  "blocks": [
    "WO-20261013-dd47"
  ],
  "files": [
    "herdr/config/herdr.json",
    "herdr/tests/cases/25-max-agents.test.sh"
  ]
}
---

# WO-20261013-a1c6 - Capacity: herdr max_agents goes from 8 to 16, pinned by a herdr test case

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

The line seats more than eight agents at once (testers, reviewers, a merger and workers per loop) and herdr refuses the ninth. Split from WO-20261013-9c50 under the size rule.

## Scope

**In**

- herdr/config/herdr.json max_agents 16 with a breadcrumb in the nearest commented file naming this ticket
- herdr/tests/cases/25-max-agents.test.sh pins the value and fails on 8

**Out - non-goals**

- role models and seat counts (the other two parts of WO-20261013-9c50)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* the case passes at 16 and fails at 8; make -C herdr test and make lint pass

## Test plan

```sh
make lint && make -C herdr test, in Podman through the repository targets
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
