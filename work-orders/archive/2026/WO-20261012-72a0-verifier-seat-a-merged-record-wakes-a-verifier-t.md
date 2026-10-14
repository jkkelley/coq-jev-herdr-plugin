---
{
  "id": "WO-20261012-72a0",
  "slug": "verifier-seat-a-merged-record-wakes-a-verifier-t",
  "title": "Verifier seat: a merged record wakes a verifier that checks the merge on main against the ticket's criteria and posts verified or rejected, so no merge waits on the architect",
  "type": "feature",
  "status": "cancelled",
  "priority": "p0",
  "created": "2026-10-12",
  "updated": "2026-10-13",
  "created_at": "2026-10-12T14:04:48+00:00",
  "parent": "WO-20261012-187e",
  "branch": null,
  "pr": null,
  "closed": "2026-10-13",
  "approval": {
    "via": "override",
    "reason": "lavish is prohibited for Claude seats; owner order 2026-10-12: get the factory working without the architect or owner as a gate",
    "at": "2026-10-12"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [],
  "superseded_by": "WO-20261013-aff2"
}
---

# WO-20261012-72a0 - Verifier seat: a merged record wakes a verifier that checks the merge on main against the ticket's criteria and posts verified or rejected, so no merge waits on the architect

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

routes.json sends merged 200 to the architect with verify, and verified 201 to an interface agent that is not seated, so every merge needed the architect by hand and flow.json escalated each one.

## Scope

**In**

- a verifier role and playbook, routes.json merged row to it
- verified routes to the monitor until the interface agent is seated

**Out - non-goals**

- the interface agent itself

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* a merged record on a test repo produces verified 201 from the verifier seat naming the main sha, with no architect action
- [ ] `AC-H2` *(human)* grep routes.json finds no to architect row

## Test plan

```sh
make -C factory test
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

Cancelled `2026-10-13` - nothing shipped.

- reason: Duplicate audit F3, ruled 2026-10-13T23:55Z: verify after a merge has one owner, CI gate 4 (WO-20261013-aff2). A verifier seat is the wrong shape under the owner rule that no agent is a gate; no roles/verifier.json exists. verify-main.sh stays the interim path until WO-20261013-aff2 lands.
- superseded by: `WO-20261013-aff2`

No branch, no PR and no merge commit exist for this work order.

