---
{
  "id": "WO-20261012-5d09",
  "slug": "tester-playbook-says-git-is-off-and-the-worktree",
  "title": "Tester playbook says git is off and the worktree is already at the head, so a tester runs its plan through testpane.sh without asking for approval",
  "type": "bug",
  "status": "in-progress",
  "priority": "p0",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T20:00:16+00:00",
  "parent": "WO-20261012-187e",
  "branch": "feat/tester-playbook-says-git-is-off-and-the-worktree",
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect cut, p0: tester stalls on three PRs today",
    "at": "2026-10-12"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": []
}
---

# WO-20261012-5d09 - Tester playbook says git is off and the worktree is already at the head, so a tester runs its plan through testpane.sh without asking for approval

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

Tester seats deny Bash(git *) and Bash(gh *) by design, but playbooks/tester.md tells them to confirm the head sha. A Haiku tester tries git, gets 'Permission ... denied', concludes Bash is off and asks the architect for approval. On 2026-10-12 this stalled PR 25's tester 35 minutes and PR 35 and PR 36 testers twice each.

## Scope

**In**

- playbooks/tester.md: git and gh are denied on purpose; seat.sh puts the worktree at the PR head; Bash is on for make, podman, testpane.sh and event.sh; never ask for approval, run the plan
- a GOOD and NEVER table in the playbook with the exact no-git command sequence: Read the ticket, testpane.sh <pane> <plan>, read the pane, event.sh add

**Out - non-goals**

- roles/tester.json allow and deny lists
- roles/bin/brief.sh (open in PR 17)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [x] `AC-H1` *(human)* playbooks/tester.md names the git and gh deny, the head already checked out, and the exact command sequence
  - observed `2026-10-12` playbooks/tester.md steps 1-4 name the git and gh deny, the head already checked out by seat.sh, and the sequence Read ticket, testpane.sh, herdr pane read, event.sh add; Forbidden has the NEVER and GOOD lines; rendered from roles/tester.json; make lint all ok (exit 0)
- [x] `AC-H2` *(human)* a fresh tester seated on an open PR posts its result with no approval question (observed on the next PR the belt tests)
  - observed `2026-10-12` NOT YET OBSERVED by the worker: needs the next tester the belt seats on an open PR; the architect confirms on that PR's test record

## Test plan

```sh
make lint
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-12` Retro: playbooks/tester.md is rendered from roles/tester.json (render-playbook.sh --check in make lint), so the edit went into must and forbidden there, per the architect ruling on block 4u22h (roles/tester.json only, via jq). The renderer has no table element, so GOOD and NEVER are two forbidden lines. roles/tester.json allow and deny untouched.

## Outcome

_Written by `work-order done`. Empty until then._
