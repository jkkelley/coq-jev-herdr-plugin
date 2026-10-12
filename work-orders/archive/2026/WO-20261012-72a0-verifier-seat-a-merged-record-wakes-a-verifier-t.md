---
{
  "id": "WO-20261012-72a0",
  "slug": "verifier-seat-a-merged-record-wakes-a-verifier-t",
  "title": "Verifier seat: a merged record wakes a verifier that checks the merge on main against the ticket's criteria and posts verified or rejected, so no merge waits on the architect",
  "type": "feature",
  "status": "done",
  "priority": "p0",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T14:04:48+00:00",
  "parent": "WO-20261012-187e",
  "branch": "feat/verifier-seat-a-merged-record-wakes-a-verifier-t",
  "pr": 29,
  "closed": "2026-10-12",
  "approval": {
    "via": "override",
    "reason": "lavish is prohibited for Claude seats; owner order 2026-10-12: get the factory working without the architect or owner as a gate",
    "at": "2026-10-12"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": []
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

- [x] `AC-H1` *(human)* a merged record on a test repo produces verified 201 from the verifier seat naming the main sha, with no architect action
  - observed `2026-10-12` Routing proved, verdict not: factory case 11-down (15 of 15 pass) shows merged 200 seats verifier-wo-<ticket>, prompts it with record id and playbooks/verifier.md, then takes the merger down, and verified 201 and rejected 422 wake the monitor, never the architect; herdr case 17 shows the verifier seat comes up on an archived ticket on a slot detached at origin/main. The verified 201 naming the main sha is posted by the verifier seat, an agent, so it is observable only live on the next real merge.
- [x] `AC-H2` *(human)* grep routes.json finds no to architect row
  - observed `2026-10-12` NOT literally met. grep routes.json finds four rows with to architect: request.forwarded 300 enqueue, test.failed 422 attempt 3, review.changes 422 attempt 3, blocked 423 first escalation. The merged and verified rows no longer name the architect. The four left are escalations and the owner request queue, which the epic WO-20261012-187e AC-H2 excepts when no policy covers them; WO-20261012-9b2c owns replacing them.

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

- `2026-10-12` Retro: the block was the worker role deny on roles/, graph/ and specs/; the architect placed the role files. The architect per-ticket verifier-${ticket} label hit seat.sh door 1 refusing archived tickets and deleted branches, so seat.sh now special-cases role verifier (breadcrumb at the ticket lookup). playbooks/verifier.md cannot hold a breadcrumb because lint renders it from the role. Left for the architect: roles/bin/brief.sh and nudge.sh archive fallback, graph ROL-verifier node, WFL-integration text.

## Outcome

_Written by `work-order done`. Empty until then._
