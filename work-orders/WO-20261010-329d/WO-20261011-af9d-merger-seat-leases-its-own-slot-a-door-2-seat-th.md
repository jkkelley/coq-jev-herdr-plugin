---
{
  "id": "WO-20261011-af9d",
  "slug": "merger-seat-leases-its-own-slot-a-door-2-seat-th",
  "title": "Merger seat leases its own slot: a door 2 seat that runs git gets a treehouse worktree held by its own name, so cleanup never checks out main in a PR's slot",
  "type": "bug",
  "status": "draft",
  "priority": "p0",
  "created": "2026-10-11",
  "updated": "2026-10-11",
  "created_at": "2026-10-11T15:33:02+00:00",
  "parent": "WO-20261010-329d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": null,
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": []
}
---

# WO-20261011-af9d - Merger seat leases its own slot: a door 2 seat that runs git gets a treehouse worktree held by its own name, so cleanup never checks out main in a PR's slot

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

The merger came up through door 1 on PR 12's ticket and shares that ticket's treehouse slot with the tester and reviewer. work-order.sh cleanup runs git checkout main in its cwd, so a merger cleaning up PR 13 from PR 12's slot would pull that worktree off PR 12's branch under the tester, and seat.sh --down on the lease owner refuses while other seats are in the slot. On 2026-10-11 the architect told the merger to skip cleanup and ran it by hand (WO-20261011-23df note).

## Scope

**In**

- seat.sh door 2 (--role R --task) leases a treehouse slot held by the seat name when the role allows git, and checks out main there
- roles/merger.json and playbooks/merger.md: the merger comes up once through door 2 and serves every PR from its own slot
- SOP-0001 updated: the merger is never brought up on a PR's ticket

**Out - non-goals**

- sharing rules for tester and reviewer on one ticket (they stay on the ticket's lease)

## Degrees of freedom

- [free] the lease holder string, as long as treehouse status lists it under the seat name

## Acceptance criteria

- [ ] `AC-H1` *(human)* seat.sh --role merger --task text leases a slot held by merger and checks out main in it; a herdr/tests case asserts it
- [ ] `AC-H2` *(human)* work-order.sh cleanup run by the merger seat changes no other slot's branch, shown on one real PR
- [ ] `AC-H3` *(human)* SOP-0001 and the merger playbook name the door 2 bring-up and RUN-role-seats-on-a-pr is updated

## Test plan

```sh
CASES=12 bash herdr/tests/run.sh in the labelled test pane
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
