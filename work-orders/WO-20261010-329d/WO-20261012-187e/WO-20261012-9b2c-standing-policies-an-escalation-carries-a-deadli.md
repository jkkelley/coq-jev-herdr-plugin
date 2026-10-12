---
{
  "id": "WO-20261012-9b2c",
  "slug": "standing-policies-an-escalation-carries-a-deadli",
  "title": "Standing policies: an escalation carries a deadline and a default drawn from the owner's locked decisions, so the line takes the default when nobody answers instead of waiting",
  "type": "feature",
  "status": "in-progress",
  "priority": "p0",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T14:04:52+00:00",
  "parent": "WO-20261012-187e",
  "branch": "feat/standing-policies-an-escalation-carries-a-deadli",
  "pr": null,
  "closed": null,
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

# WO-20261012-9b2c - Standing policies: an escalation carries a deadline and a default drawn from the owner's locked decisions, so the line takes the default when nobody answers instead of waiting

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

Escalations route to the owner with no deadline and no default; the PR 22 criteria split waited hours for an answer that the owner's locked decisions already implied (land PRs, no dead code).

## Scope

**In**

- policy table in config mapping escalation kinds to a default action and a deadline
- the monitor applies the default at the deadline and records it

**Out - non-goals**

- break glass, which stays owner-only every time

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [x] `AC-H1` *(human)* an escalation with a policy and no owner answer by its deadline produces the default action and a record naming the policy
  - observed `2026-10-12` 2026-10-12 15:31Z, factory case 12-policy in the test pane (factory/tests/cases/12-policy.test.sh, section AC-H1): a blocked 423 from worker-wo-20261012-aaaa backdated 2000 s with no answer on the ticket produced one policy.applied 200 record from policy-watch to worker with policy=POL-blocked-land-it and answer=<the blocked record id>, note 'default POL-blocked-land-it: Owner default: land the PR...', and one herdr call 'agent prompt worker-wo-20261012-aaaa record <that id> playbook .../worker.md'. A second and third tick wrote nothing. Suite: factory 16 passed 0 failed, make lint all ok.
- [x] `AC-H2` *(human)* an escalation with no policy still waits for the owner
  - observed `2026-10-12` 2026-10-12 15:31Z, factory case 12-policy, section AC-H2: test.failed 422 attempt 3, review.changes 422 attempt 3, an escalated 423 and a break.glass 300, each backdated 86400 s with no policy row, produced 0 policy.applied records, 0 herdr calls and 0 500 notes after policy.sh once; policy.sh status printed nothing and exited 0. A table row matching break.glass exits 3 at start ('matches break.glass; the owner authorises every break glass by hand'). Same run, same suite result.

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

- `2026-10-12` Retro 2026-10-12 UTC. Built factory/bin/policy.sh (once, run, status) over factory/config/policies.json, in monitors slot 2.3.2 policy. A default is a policy.applied 200 record (new event kind, new fields policy and answer) and then a herdr prompt with the line route.sh sends; limit_per_ticket is counted from the log; break.glass is refused by schema and at start. Decisions: the clock lives in a new script and the route runner is untouched (it has no clock); the wake is done by policy.sh because a routes row has one fixed role and the seat to wake is the one that asked. What this does NOT prove: the stub herdr only, no live pane run of policy.sh run, and the herdr suite beyond cases 04, 05 and 13 was left to CI. Findings for the architect: (1) only one row ships, POL-blocked-land-it (blocked 423, 1800 s). graph/nodes holds no decision for 'land PRs, no dead code', and graph/ is outside a worker's paths, so the row cites DEC-local-fast-ci-full, the nearest locked node; the architect should add the node and the rows for the escalations it wants covered. (2) test.failed and review.changes at attempt 3 are deliberately uncovered: no locked decision says what to do after three failures. (3) The epic's AC-H2 (no routes.json row names the architect or owner except uncovered escalations) is not met by this ticket: routes.json still escalates blocked 423 to the architect and the owner, and policy.sh only adds the default behind them. (4) factory/RUNBOOK.md routes table lacks the break.glass rows from WO-20261011-4562; left as found. (5) A worker's event.sh writes under its own worktree events/, and the first record of this ticket was written through the main checkout's script so the runner could see it.

## Outcome

_Written by `work-order done`. Empty until then._
