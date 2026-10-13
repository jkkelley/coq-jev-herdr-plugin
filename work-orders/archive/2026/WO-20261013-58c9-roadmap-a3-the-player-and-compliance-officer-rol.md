---
{
  "id": "WO-20261013-58c9",
  "slug": "roadmap-a3-the-player-and-compliance-officer-rol",
  "title": "Roadmap A3 - The player and compliance-officer roles read records from the state root: one step in each role and its playbook re-rendered",
  "type": "feature",
  "status": "done",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T14:11:35+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": "feat/roadmap-a3-the-player-and-compliance-officer-rol",
  "pr": 149,
  "closed": "2026-10-13",
  "approval": {
    "via": "override",
    "reason": "architect P1 order 2026-10-13: A3 split under the owner size rule (03:00Z); lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261013-5b33"
  ],
  "blocks": [],
  "files": [
    "roles/player.json",
    "roles/compliance-officer.json",
    "playbooks/player.md",
    "playbooks/compliance-officer.md",
    "roles/tests/compliance-officer.test.sh"
  ]
}
---

# WO-20261013-58c9 - Roadmap A3 - The player and compliance-officer roles read records from the state root: one step in each role and its playbook re-rendered

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
- playbooks/player.md and playbooks/compliance-officer.md re-rendered by roles/bin/render-playbook.sh, never by hand
- roles/tests/compliance-officer.test.sh follows the new step if it pins the must list

**Out - non-goals**

- any behaviour change beyond where records are read (Roadmap B, WO-20261012-6f13)
- other roles, which have their own A3 part

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [x] `AC-H1` *(human)* roles/player.json and roles/compliance-officer.json each carry the state-root step, and the playbook check reports no drift
  - observed `2026-10-13` roles/player.json gains must step 5 and roles/compliance-officer.json must step 16 (a '[ ] ' checklist item, before 'end the turn'), each the state-root step word for word; render-playbook.sh roles playbooks --check exit 0; make lint 'roles: schema + playbooks in sync ok'; herdr case 27 'playbooks match the roles (no render drift)' ok; run in test pane wD3:p1J7 through herdr/bin/testpane.sh
- [x] `AC-H2` *(human)* neither role nor playbook names a repository or slot events/ path for reading records; make lint passes
  - observed `2026-10-13` in both roles and both playbooks events/ appears only as events/bin/event.sh (allow.commands, the officer's report step, the new step) and the new step's negation 'a slot's or the checkout's events/ is never read'; the role breadcrumbs name a slot's events/ only as what broke; make lint 'lint: all ok' exit 0; CASES='23 27' make -C herdr test 2 passed, 0 failed (compliance officer 60 passed, 0 failed)

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

- `2026-10-13` Retro: roles/ has no Makefile, so make -C roles test ran as CASES='23 27' make -C herdr test, the repository target that runs roles/tests/compliance-officer.test.sh (case 23) and the render-drift pin (case 27) in Podman. The test pins no must list (it counts at least 8 checklist lines, now 17), so it is unchanged. The officer's step is a '[ ] ' item before 'end the turn', the way the worker's sits before its close-out, so the GOOD examples stay last. Each role gains a breadcrumbs entry (JSON has no comments). Correction to the AC-H2 line: the officer's breadcrumb also names a slot's events/ in a prohibition ('must never take ... as the answer'), never as a path to read. Gotcha: an Edit on roles/player.json fired a formatter hook that reflowed every array; reverted and edited byte-exact with a script. Seen in passing: lint/lint.sh pads labels to 40 characters, so two longer labels glue their verdict ('herdr: layouts against layout.schema.jsonok', 'changelog: entries + CHANGELOG.md renderedok'). Worker step 1 passed by ruling imu40 (start worktree).

## Outcome

_Written by `work-order done`. Empty until then._
