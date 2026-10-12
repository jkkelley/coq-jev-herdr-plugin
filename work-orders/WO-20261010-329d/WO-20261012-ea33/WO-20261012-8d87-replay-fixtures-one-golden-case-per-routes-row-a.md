---
{
  "id": "WO-20261012-8d87",
  "slug": "replay-fixtures-one-golden-case-per-routes-row-a",
  "title": "Replay fixtures: one golden case per routes row and per policies row under scheduler/testdata/replay, derived from the factory suite's cases, synthetic, with a schema and a check script",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T19:36:56+00:00",
  "parent": "WO-20261012-ea33",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect: lavish is prohibited for Claude seats; cut from SPEC-16 by the scheduler architect with disjoint files and a generated test plan; owner order on the bearings page 2026-10-12 18:34Z, CRITICAL",
    "at": "2026-10-12"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [
    "WO-20261012-32fe",
    "WO-20261012-379f"
  ]
}
---

# WO-20261012-8d87 - Replay fixtures: one golden case per routes row and per policies row under scheduler/testdata/replay, derived from the factory suite's cases, synthetic, with a schema and a check script

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

The engine proves the bash belt's behaviour before its own by replaying golden cases; without fixtures for every row a row can ship untested, which is how the belt's false alarms went unseen.

## Scope

**In**

- Owns: scheduler/testdata/
- scheduler/testdata/replay/<case>/ for every routes row and every policies row, in the layout of SPEC-16.K k-replay: records in order, a context file, an expected file with verdict, row index and jobs (verb, args, after)
- scheduler/testdata/replay.schema.json for the expected and context files, and scheduler/testdata/README.md describing the layout
- scheduler/testdata/bin/check.sh (bash, jq, python3): every case validates, every routes row index and policies row id is covered, every verb of SPEC-16.H h-verbs appears in some expected job, no forbidden pattern
- the expected jobs carry the exact wake lines and receipt notes of SPEC-16.B b-plan-text and b-receipt-shape

**Out - non-goals**

- editing any file outside the directories this ticket owns, in particular scheduler/go.mod, scheduler/internal/core/ and any other ticket's package
- adding a dependency to the module (ask the architect)
- writing a record file directly; records go through the executor's record verb
- Go code that runs the fixtures (the engine ticket)
- real ids from the live log

## Degrees of freedom

- [free] case names and the number of records per case, as long as every row has at least one case

## Acceptance criteria

- [ ] `AC-H1` *(human)* bash scheduler/testdata/bin/check.sh exits 0 and prints the rows and verbs covered
- [ ] `AC-H2` *(human)* removing any one case directory makes the check fail naming the uncovered row
- [ ] `AC-H3` *(human)* no fixture line matches the forbidden patterns of specs/scheduler/config/check.json
- [ ] `AC-H4` *(human)* for the wake, no-route, escalate, break glass, seat down and policy default cases the expected jobs match the calls the factory suite's corresponding case asserts

## Test plan

_Test plan from claude/workflow/templates/test-plan.md, shaped by claude/workflow/schemas/test-plan.schema.json. The tester runs exactly these cases and nothing else._

**Scope under test**

The golden replay fixtures and their check.

**Cases**

- `TP-1`
  - intent: the acceptance criterion this command proves, as the ticket states it
  - command: `bash scheduler/testdata/bin/check.sh`
  - expected: exit 0: every routes row, policies row and verb covered; every case valid
- `TP-2`
  - intent: the acceptance criterion this command proves, as the ticket states it
  - command: `rm -r /tmp/fx && cp -r scheduler/testdata /tmp/fx && rm -r /tmp/fx/replay/$(ls /tmp/fx/replay | head -1) && bash /tmp/fx/bin/check.sh; test $? -eq 3`
  - expected: exit 0: the check fails naming the uncovered row

**Isolation**

- runtime: podman
- image: `localhost/coq-lint@sha256:d2f6ded8d64627b8e7c02552431a4205431312d2570f1562313d8d26dc815077` (coq-lint:1, the repository lint image)

**Out of scope - CI covers**

- CI runs make -C scheduler test over the whole module on every change under scheduler/
- make lint on the repository validates every config file against its schema

## Assumptions

1. Worker seat: runtime claude, model claude-opus-5-5, effort high (the architect's pick for this epic).
1. The scheduler specs live under specs/scheduler/ on branch feat/go-scheduler-design-one-xml-spec-per-domain-unde until its pull request lands on main; until then read them with git show origin/<that branch>:specs/scheduler/<file>.
1. factory/tests/cases/*.test.sh and factory/config/routes.json are the oracle; read them, never edit them.

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
