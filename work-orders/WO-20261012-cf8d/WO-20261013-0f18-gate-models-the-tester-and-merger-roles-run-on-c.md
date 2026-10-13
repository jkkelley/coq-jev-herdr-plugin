---
{
  "id": "WO-20261013-0f18",
  "slug": "gate-models-the-tester-and-merger-roles-run-on-c",
  "title": "Gate models: the tester and merger roles run on claude-sonnet-5-5 instead of claude-haiku-5-5, playbooks re-rendered and pinned by a test",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T14:35:52+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect orders 2026-10-13, re-cut on review yv8xi; lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [],
  "files": [
    "roles/tester.json",
    "roles/merger.json",
    "playbooks/tester.md",
    "playbooks/merger.md",
    "herdr/tests/cases/27-gate-models.test.sh"
  ]
}
---

# WO-20261013-0f18 - Gate models: the tester and merger roles run on claude-sonnet-5-5 instead of claude-haiku-5-5, playbooks re-rendered and pinned by a test

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

Haiku testers and mergers misread test plans and gate records on 2026-10-12 and 2026-10-13; the owner moved both to Sonnet. Split from WO-20261013-9c50 under the size rule.

## Scope

**In**

- roles/tester.json and roles/merger.json model.claude is claude-sonnet-5-5; playbooks/tester.md and playbooks/merger.md re-rendered by roles/bin/render-playbook.sh
- herdr/tests/cases/27-gate-models.test.sh pins both models and fails on haiku (roles/ has no suite of its own; the herdr suite runs role tests, as 23-compliance-officer does)

**Out - non-goals**

- the reviewer's seat count (WO-20261013-dd47)
- the merger's duties (WO-20261013-f6ae and its follow-up)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* both roles name claude-sonnet-5-5, the playbook check in lint reports no drift and the case fails on haiku

## Test plan

```sh
make lint && make -C herdr test, in Podman through the repository targets (lint runs the playbook drift check)
```

## Assumptions

1. WO-20261013-73be (pull request 89) and WO-20261013-dd11 (pull request 98) also edit the tester role; the order is written as edges once those pull requests merge, until then claims.sh start keeps them apart

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
