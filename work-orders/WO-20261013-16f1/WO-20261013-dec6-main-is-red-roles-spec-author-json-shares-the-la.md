---
{
  "id": "WO-20261013-dec6",
  "slug": "main-is-red-roles-spec-author-json-shares-the-la",
  "title": "Main is red: roles/spec-author.json shares the label worker-${ticket} with the worker, so policy.sh answers --to spec-author and case 12-policy fails (cause ag)",
  "type": "bug",
  "status": "in-progress",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T23:36:03+00:00",
  "parent": "WO-20261013-16f1",
  "branch": "feat/main-is-red-roles-spec-author-json-shares-the-la",
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect ruling 23:33Z: fix forward on red main",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [],
  "files": [
    "roles/spec-author.json",
    "herdr/tests/cases/35-spec-author-role.test.sh",
    "roles/tests/label-unique.test.sh"
  ]
}
---

# WO-20261013-dec6 - Main is red: roles/spec-author.json shares the label worker-${ticket} with the worker, so policy.sh answers --to spec-author and case 12-policy fails (cause ag)

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

Verify of main at 2789efa and 96fc609 failed make -C factory test, case 12-policy, deterministically since PR 136 (e82fcb2; passes at b87afe2). roles/spec-author.json line 37 has label worker-${ticket}, equal to roles/worker.json. factory/bin/policy.sh role_of_seat (line 90) walks roles/*.json alphabetically and returns spec-author for a worker seat; events/bin/event.sh refuses --to spec-author, so the policy.applied default is never written. Merge hold is set.

## Scope

**In**

- Give roles/spec-author.json a distinct label (for example spec-author-${ticket}); a roles test that no two roles share a label; case 35 updated if it names the label. Roles files are fenced, so a spec-author seat does it.

**Out - non-goals**

- Changing role_of_seat, the writer's --to list, or any other role.

## Degrees of freedom

- [free] If a distinct label breaks seat naming, make role_of_seat skip roles the writer cannot address, and say why.

## Acceptance criteria

- [ ] `AC-H1` *(human)* Case 12-policy passes in the container (bash factory/tests/run.sh --case 12-policy). A test fails when two roles share a label. Lint and the factory and herdr suites pass. The merge hold clears on a green verify.

## Test plan

```sh
bash factory/tests/run.sh --case 12-policy before (red) and after (green); roles test.
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
