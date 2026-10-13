---
{
  "id": "WO-20261013-14f9",
  "slug": "roadmap-k3-orchestrator-seat-the-fixed-seat-runs",
  "title": "Roadmap K3 - Orchestrator seat: the fixed seat runs the line by rule, re-routes refused seats, downs finished seats, cleans up after a merge from the checkout, owns the verify on main and holds capacity, with its playbook rendered from the role",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T00:57:30+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "owner accepted SPEC-17 on card C25; lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261013-ba44"
  ],
  "blocks": [],
  "files": [
    "roles/orchestrator.json",
    "playbooks/orchestrator.md",
    "line/bin/orchestrate.sh",
    "line/tests/cases/orchestrate-*.sh"
  ]
}
---

# WO-20261013-14f9 - Roadmap K3 - Orchestrator seat: the fixed seat runs the line by rule, re-routes refused seats, downs finished seats, cleans up after a merge from the checkout, owns the verify on main and holds capacity, with its playbook rendered from the role

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

Line operations were the architect's by hand on 2026-10-12: ledger entries cleared, seats downed, cleanups run, verifies carried (SPEC-17 s-inventory H03, H04, H09, H10, H12, H18). SPEC-17 s-orchestrator gives them to the orchestrator seat as rules O1 to O7; the role still says it routes records by the decision table.

## Scope

**In**

- roles/orchestrator.json: purpose widened to running the line, the must list carries O1 to O7, allowed commands gain line/bin/board.sh and line/bin/orchestrate.sh; playbooks/orchestrator.md re-rendered by roles/bin/render-playbook.sh, never by hand
- line/bin/orchestrate.sh: the duties as commands the seat runs, each three attempts then a record: down-order (O1), down-idle (O2), cleanup from the checkout never from a slot (O3), ensure-verify re-seats the merger when merged 200 has no verify within the stall deadline (O4), hold-capacity (O5), release-stale (O6), reroute (O7)
- cases T10 to T12 of SPEC-17 s-tests as line/tests/cases/orchestrate-*.sh

**Out - non-goals**

- routes rows (K7)
- the health checks (K2)
- rulings of any kind, break glass, a word to the owner

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* a merged 200 with no verified within the stall deadline re-seats the merger and the architect lane stays empty (T10)
- [ ] `AC-H2` *(human)* after close the branch, the worktree and the slot are gone, and a cleanup that fails three times is one open item on the orchestrator lane and one line on the health line (T11)
- [ ] `AC-H3` *(human)* a second 423 on one ticket becomes one owner-lane item and its answer record marks it done (T12); roles lint and playbook sync pass

## Test plan

```sh
make lint && make -C line test, in Podman through the repository targets
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
