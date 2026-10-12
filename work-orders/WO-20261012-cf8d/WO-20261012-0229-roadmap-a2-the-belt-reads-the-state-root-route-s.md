---
{
  "id": "WO-20261012-0229",
  "slug": "roadmap-a2-the-belt-reads-the-state-root-route-s",
  "title": "Roadmap A2 - The belt reads the state root: route.sh, flow.sh, gate.sh and policy.sh read records and keep their ledger and belt files under the state root",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T22:13:17+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "owner locked ROADMAP.md 2026-10-12 (cards C9 to C22) and gave USERGO; Getting My Bearings is the review surface, lavish is prohibited",
    "at": "2026-10-12"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261012-7e13"
  ],
  "blocks": [
    "WO-20261012-541a",
    "WO-20261012-da1e"
  ],
  "files": [
    "factory/bin/*",
    "factory/config/*",
    "factory/schema/*",
    "factory/tests/*",
    "factory/RUNBOOK.md"
  ]
}
---

# WO-20261012-0229 - Roadmap A2 - The belt reads the state root: route.sh, flow.sh, gate.sh and policy.sh read records and keep their ledger and belt files under the state root

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

The belt reads ${repo}/events and keeps factory/state in the checkout, so every worktree sees a different log and records must be copied between slots (ROADMAP.md rules 1 and the one-state-root rule).

## Scope

**In**

- factory configs name records and state through the state root resolver, not ${repo}/events or ${repo}/factory/state
- the routed ledger, belt file and since boundary move to <state>/ledger and <state>/run

**Out - non-goals**

- routing changes beyond the paths (D)
- seats and reports (A3)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* route.sh once with COQ_STATE set routes a record written there and writes its ledger entry under <state>/ledger/routed
- [ ] `AC-H2` *(human)* gate.sh and flow.sh find records under the state root in the factory test world
- [ ] `AC-H3` *(human)* make -C factory test passes with the test world pointing COQ_STATE at a temp dir

## Test plan

```sh
make lint && make -C factory test && make -C herdr test, all in Podman through the repository targets
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
