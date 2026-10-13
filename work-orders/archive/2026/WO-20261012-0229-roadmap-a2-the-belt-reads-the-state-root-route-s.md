---
{
  "id": "WO-20261012-0229",
  "slug": "roadmap-a2-the-belt-reads-the-state-root-route-s",
  "title": "Roadmap A2 - The belt reads the state root: route.sh, flow.sh, gate.sh and policy.sh read records and keep their ledger and belt files under the state root",
  "type": "feature",
  "status": "done",
  "priority": "p0",
  "created": "2026-10-12",
  "updated": "2026-10-13",
  "created_at": "2026-10-12T22:13:17+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": "feat/roadmap-a2-the-belt-reads-the-state-root-route-s",
  "pr": 88,
  "closed": "2026-10-13",
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

- [x] `AC-H1` *(human)* route.sh once with COQ_STATE set routes a record written there and writes its ledger entry under <state>/ledger/routed
  - observed `2026-10-13` factory/tests/cases/17-state-root.test.sh: route.sh once with COQ_STATE set and no --state routed a pr.opened written there (tester woken with its id); the ledger entry <state>/ledger/routed/<record file name> read 'done seat'; belt and since landed in <state>/run; nothing in factory/state or the checkout events/. make -C factory test: 22 passed, 0 failed.
- [x] `AC-H2` *(human)* gate.sh and flow.sh find records under the state root in the factory test world
  - observed `2026-10-13` 17-state-root.test.sh: gate.sh when head_current --id finds a record by its id field under the state root with no --events (exit 0, unknown id exit 4); flow.sh once --from-start notes a stalled test.passed 201 read from the state root and latches it in <state>/run/flow. 12-gate and 13-gate-route cases pass on records in the state root.
- [x] `AC-H3` *(human)* make -C factory test passes with the test world pointing COQ_STATE at a temp dir
  - observed `2026-10-13` make lint: all ok. make -C factory test: 22 passed, 0 failed with the world exporting COQ_STATE=$W/state (factory/tests/lib/world.sh, no event move shim). make -C herdr test: 25 passed, 0 failed after the one-line BELT path change in herdr/tests/cases/13-recover-belt.test.sh. All run in test pane wD3:pQX.

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

- `2026-10-13` Retro: the belt (route.sh, flow.sh, policy.sh, gate.sh) now resolves records, ledger, belt, since and latches through bin/state-root.sh via a new factory/bin/paths.sh and a ${tree:NAME} placeholder in the configs; --state DIR is the state root. Ledger is keyed on the record file name, routing still in id order, gate.sh finds a record by its id field. Forced outside the declared files: herdr/tests/cases/13-recover-belt.test.sh BELT path (one line; no open PR touches it). Not done, belongs to A3: report/loop board.json belt_state still names factory/state/runner.json, and .gitignore still lists factory/state/. Since the orchestrator's ruling 4sryn, every record is posted with the checkout writer until this merges. The world no longer moves records into events/; its event.sh wrapper only prints the id.

## Outcome

_Written by `work-order done`. Empty until then._
