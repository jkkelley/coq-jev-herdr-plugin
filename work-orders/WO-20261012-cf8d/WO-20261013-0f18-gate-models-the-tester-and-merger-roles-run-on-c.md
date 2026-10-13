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
    "reason": "architect orders 2026-10-13: 9c50 split (reviewer max_seats 2 to 4), K5 reland, post-merge as code; lavish prohibited for Claude seats",
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
    "roles/tests/gate-models.test.sh"
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
- roles/tests/gate-models.test.sh pins both models

**Out - non-goals**

- the reviewer's seat count (its own part)
- the merger's duties (WO-20261013-f6ae and its follow-up)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* both roles name claude-sonnet-5-5, the playbook check reports no drift and the test fails on haiku; make lint passes

## Test plan

```sh
make lint && make -C roles test, in Podman through the repository targets; roles/bin/render-playbook.sh roles playbooks --check exits 0
```

## Assumptions

1. WO-20261013-73be (A3, merger and tester roles read the state root, on pull request 89) also edits these four files; this part goes first and 73be follows it; the depends_on edge is written on 73be once pull request 89 merges, until then claims.sh start keeps the two apart

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
