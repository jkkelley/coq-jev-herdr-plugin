---
{
  "id": "WO-20261013-b6f3",
  "slug": "cause-z-a-belt-seated-tester-runs-the-full-suite",
  "title": "Cause z: a belt-seated tester runs the full suites; its playbook runs factory/bin/suites.sh plan on the PR diff and only the commands it prints",
  "type": "bug",
  "status": "in-progress",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T21:59:04+00:00",
  "parent": "WO-20261013-16f1",
  "branch": "feat/cause-z-a-belt-seated-tester-runs-the-full-suite",
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect ruling 22:12Z: belt-seated testers run only the suites the diff needs",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [],
  "files": [
    "roles/tester.json",
    "playbooks/tester.md",
    "roles/tests/tester-plan.test.sh"
  ]
}
---

# WO-20261013-b6f3 - Cause z: a belt-seated tester runs the full suites; its playbook runs factory/bin/suites.sh plan on the PR diff and only the commands it prints

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

The belt-seated tester runs the ticket's whole test plan, so a ten-line PR waits on the full herdr suite (about 25 min; tester d127 on PR 136 was in it at 21:56Z). PR 109 merged factory/bin/suites.sh plan, which prints only the suites a diff needs, but the roles/tester.json steps do not call it.

## Scope

**In**

- roles/tester.json must steps: after reading the ticket, run factory/bin/suites.sh plan on the PR diff and run only the commands it prints (a CASES entry runs only those cases); playbooks/tester.md re-rendered with roles/bin/render-playbook.sh; one case in roles/tests proving the step is present

**Out - non-goals**

- No change to suites.sh, suites.json, seat.sh or route.sh; no new role; the full suites still run on main verify

## Degrees of freedom

- [free] Wording of the step is the worker's; the test case name is free

## Acceptance criteria

- [ ] `AC-H1` *(human)* AC-H1: the rendered tester playbook has a step that runs factory/bin/suites.sh plan on the PR diff and runs only its output. AC-H2: render-playbook.sh roles playbooks --check exits 0. AC-H3: a roles test case fails if the step is removed. AC-H4: make lint and make -C factory test exit 0

## Test plan

```sh
make lint && make -C factory test && bash roles/bin/render-playbook.sh roles playbooks --check
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
