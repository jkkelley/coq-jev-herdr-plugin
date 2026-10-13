---
{
  "id": "WO-20261013-44b3",
  "slug": "roadmap-a3-the-reviewer-and-worker-roles-read-re",
  "title": "Roadmap A3 - The reviewer and worker roles read records from the state root: one step in each role and its playbook re-rendered",
  "type": "feature",
  "status": "done",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T14:11:27+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": "feat/roadmap-a3-the-reviewer-and-worker-roles-read-re",
  "pr": 118,
  "closed": "2026-10-13",
  "approval": {
    "via": "override",
    "reason": "architect P1 order 2026-10-13: A3 split under the owner size rule (03:00Z); lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [],
  "files": [
    "roles/reviewer.json",
    "roles/worker.json",
    "playbooks/reviewer.md",
    "playbooks/worker.md"
  ]
}
---

# WO-20261013-44b3 - Roadmap A3 - The reviewer and worker roles read records from the state root: one step in each role and its playbook re-rendered

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

Seats searched their own slot's events/ and missed records (the merger on 2026-10-12 22:05Z). Since A1 (WO-20261012-7e13) and A2 (WO-20261012-0229) the writer and the belt use the one state root through bin/state-root.sh, but no playbook says so, and a seat still reads a path its role names. Split from WO-20261012-541a under the size rule.

## Scope

**In**

- the role's must list gains one step: records are read and written only through events/bin/event.sh, which resolves the state root (bin/state-root.sh tree records); a slot's or the checkout's events/ is never read
- playbooks/reviewer.md and playbooks/worker.md re-rendered by roles/bin/render-playbook.sh, never by hand

**Out - non-goals**

- any behaviour change beyond where records are read (Roadmap B, WO-20261012-6f13)
- other roles, which have their own A3 part

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [x] `AC-H1` *(human)* roles/reviewer.json and roles/worker.json each carry the state-root step, and the playbook check reports no drift
  - observed `2026-10-13` roles/worker.json and roles/reviewer.json each carry the state-root step as a must entry; playbooks/worker.md (step 5) and playbooks/reviewer.md (step 5) re-rendered by roles/bin/render-playbook.sh; render-playbook.sh roles playbooks --check exits 0 (render-rc=0), run in test pane wD3:p16Y
- [x] `AC-H2` *(human)* neither role nor playbook names a repository or slot events/ path for reading records; make lint passes
  - observed `2026-10-13` the four files name only events/bin/event.sh (the writer) and the new step's 'is never read' clause, no records read path; make lint ok (lint-rc=0, 'roles: schema + playbooks in sync ok'), run in test pane wD3:p16Y

## Test plan

```sh
make lint && make -C roles test, in Podman through the repository targets; roles/bin/render-playbook.sh roles playbooks --check exits 0
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-13` Retro: copied the 73be wording verbatim for the merger and tester. In the worker the step goes before the close-out step because that one ends in 'stop'. The test plan names make -C roles test, but roles/ has no Makefile (make: No rule to make target 'test'), so lint's roles check and render-playbook.sh --check were the proof. Worth a system ticket if roles is meant to have a test target.

## Outcome

_Written by `work-order done`. Empty until then._
