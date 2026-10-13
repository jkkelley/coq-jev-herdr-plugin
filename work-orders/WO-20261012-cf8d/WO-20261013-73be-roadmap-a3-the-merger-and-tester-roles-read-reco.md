---
{
  "id": "WO-20261013-73be",
  "slug": "roadmap-a3-the-merger-and-tester-roles-read-reco",
  "title": "Roadmap A3 - The merger and tester roles read records from the state root: one step in each role and its playbook re-rendered",
  "type": "feature",
  "status": "in-progress",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T14:11:24+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": "feat/roadmap-a3-the-merger-and-tester-roles-read-reco",
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect P1 order 2026-10-13: A3 split under the owner size rule (03:00Z); lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [
    "WO-20261012-6f13"
  ],
  "files": [
    "roles/merger.json",
    "roles/tester.json",
    "playbooks/merger.md",
    "playbooks/tester.md"
  ]
}
---

# WO-20261013-73be - Roadmap A3 - The merger and tester roles read records from the state root: one step in each role and its playbook re-rendered

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
- playbooks/merger.md and playbooks/tester.md re-rendered by roles/bin/render-playbook.sh, never by hand

**Out - non-goals**

- any behaviour change beyond where records are read (Roadmap B, WO-20261012-6f13)
- other roles, which have their own A3 part

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [x] `AC-H1` *(human)* roles/merger.json and roles/tester.json each carry the state-root step, and the playbook check reports no drift
  - observed `2026-10-13` roles/merger.json and roles/tester.json each carry the state-root step as their last must entry; roles/bin/render-playbook.sh roles playbooks --check exits 0 (no drift), run in test pane
- [x] `AC-H2` *(human)* neither role nor playbook names a repository or slot events/ path for reading records; make lint passes
  - observed `2026-10-13` grep of the four files finds only events/bin/event.sh (the writer) and the new step's 'never read' clause; no records read path; make lint ok (LINT_RC=0), roles tests 60 passed 0 failed

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

- `2026-10-13` Retro: the ticket's test plan names make -C roles test, which has no Makefile; ran make lint, roles/tests/compliance-officer.test.sh and render-playbook.sh --check in the test pane instead.

## Outcome

_Written by `work-order done`. Empty until then._
