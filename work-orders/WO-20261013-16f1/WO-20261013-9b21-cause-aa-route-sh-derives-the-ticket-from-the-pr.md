---
{
  "id": "WO-20261013-9b21",
  "slug": "cause-aa-route-sh-derives-the-ticket-from-the-pr",
  "title": "Cause aa: route.sh derives the ticket from the PR head branch when a record has a pr but no ticket; a PR carrying two tickets uses the first",
  "type": "bug",
  "status": "in-progress",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T22:06:26+00:00",
  "parent": "WO-20261013-16f1",
  "branch": "feat/cause-aa-route-sh-derives-the-ticket-from-the-pr",
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect ruling 22:08Z route failures",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [],
  "files": [
    "factory/bin/route.sh",
    "factory/tests/cases/24-route-ticket-from-branch.test.sh"
  ]
}
---

# WO-20261013-9b21 - Cause aa: route.sh derives the ticket from the PR head branch when a record has a pr but no ticket; a PR carrying two tickets uses the first

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

A gate record with ticket null cannot be routed: records 20261013T213137Z-201-6p9av and 20261013T214216Z-422-2tk0m (PR 137) failed with 'seat needs a ticket' in factory/bin/route.sh act_primary (architect ruling 22:08Z).

## Scope

**In**

- factory/bin/route.sh: when a record carries a pr and no ticket, derive the ticket from the PR's head branch or its ticket-bearing title, one gh call at most, and use the first ticket when a PR carries two; one factory case

**Out - non-goals**

- No change to seat.sh, routes.json or record schema; a record with a ticket is routed as today

## Degrees of freedom

- [free] How the ticket is read from the branch (gh pr view or the branch name map) is the worker's

## Acceptance criteria

- [x] `AC-H1` *(human)* AC-H1: a test.passed with pr 137 and no ticket routes with the first ticket of that PR. AC-H2: a record that has a ticket is unchanged. AC-H3: make lint and make -C factory test exit 0
  - observed `2026-10-13` factory case 24: test.passed 201 with pr 137 and no ticket seated reviewer for the PR's first ticket WO-20261013-249e (receipt carries it, no 500); a record with a ticket made no gh call and kept its own ticket; case fails 9 checks without the route.sh change; make lint and make -C factory test exit 0, 26 passed 0 failed

## Test plan

```sh
make lint && make -C factory test
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-13` retro: the head branch of a worker PR is feat/<slug> and rarely carries an id, so the title is the usual source of the ticket; ticket_of_pr reads branch then title, first id wins. Worktree start-WO-20261013-9b21 is not a treehouse slot, so the worker.md step 1 lease check could not pass; proceeded on the architect's brief.

## Outcome

_Written by `work-order done`. Empty until then._
