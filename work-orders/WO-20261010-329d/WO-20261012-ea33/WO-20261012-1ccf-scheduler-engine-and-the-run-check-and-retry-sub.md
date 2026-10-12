---
{
  "id": "WO-20261012-1ccf",
  "slug": "scheduler-engine-and-the-run-check-and-retry-sub",
  "title": "Scheduler engine and the run, check and retry subcommands: the tick loop composing intake, routing, jobs, seats, policies and health, the replay suite over the fixtures, per SPEC-16 and SPEC-16.K",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T19:37:36+00:00",
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
  "depends_on": [
    "WO-20261012-5a3d",
    "WO-20261012-32fe",
    "WO-20261012-9790",
    "WO-20261012-d7f4",
    "WO-20261012-8e69",
    "WO-20261012-7a9a",
    "WO-20261012-6e43",
    "WO-20261012-3c7a"
  ],
  "blocks": [
    "WO-20261012-fa36"
  ]
}
---

# WO-20261012-1ccf - Scheduler engine and the run, check and retry subcommands: the tick loop composing intake, routing, jobs, seats, policies and health, the replay suite over the fixtures, per SPEC-16 and SPEC-16.K

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

The domains are proven apart; the engine ties them into one loop that never blocks on a job, and the replay suite proves the whole against the golden fixtures row by row.

## Scope

**In**

- Owns: scheduler/internal/engine/, scheduler/internal/cli/run.go, scheduler/internal/cli/check.go, scheduler/internal/cli/retry.go
- package engine: the tick loop of SPEC-16 sh-loop wiring the real implementations, the escalation count, the record index shared with policies, mode gating per SPEC-16.J j-mode, the start order of SPEC-16.F f-recovery
- the run, check and retry subcommands (SPEC-16.H h-cli)
- the replay suite of SPEC-16.K k-replay and the coverage test k-t3

**Out - non-goals**

- editing any file outside the directories this ticket owns, in particular scheduler/go.mod, scheduler/internal/core/ and any other ticket's package
- adding a dependency to the module (ask the architect)
- writing a record file directly; records go through the executor's record verb
- the Scheduler service and status (observe ticket)
- the parity report (cut-over ticket)

## Degrees of freedom

- [free] goroutine layout of the loop, as long as a tick never waits on a Run

## Acceptance criteria

- [ ] `AC-H1` *(human)* cases k-t2 and k-t3 pass in Podman over every fixture
- [ ] `AC-H2` *(human)* make -C scheduler build produces a binary whose run subcommand starts, passes the gate against a fake executor in the test, and ticks
- [ ] `AC-H3` *(human)* the engine package imports every domain package and core; no domain package imports the engine

## Test plan

_Test plan from claude/workflow/templates/test-plan.md, shaped by claude/workflow/schemas/test-plan.schema.json. The tester runs exactly these cases and nothing else._

**Scope under test**

The engine and three subcommands.

**Cases**

- `TP-1`
  - intent: Golden. (spec case k-t2)
  - command: `make -C scheduler test PKG='./internal/engine -run TestReplay'`
  - expected: exit 0: every fixture's expected file equals the engine's plans and the fake executor's calls
- `TP-2`
  - intent: No row untested. (spec case k-t3)
  - command: `make -C scheduler test PKG='./internal/engine -run TestReplayCoversEveryRow'`
  - expected: exit 0: every routes row index appears as a chosen row in some fixture; a row with none fails naming it

**Isolation**

- runtime: podman
- image: `docker.io/library/golang@sha256:116d58cbd88c1297624acc6e967a060012422bacf9930927e23fb719189c6f36` (golang:1.26-bookworm, pulled 2026-08)

**Out of scope - CI covers**

- CI runs make -C scheduler test over the whole module on every change under scheduler/
- make lint on the repository validates every config file against its schema

## Assumptions

1. Worker seat: runtime claude, model claude-opus-5-5, effort high (the architect's pick for this epic).
1. The scheduler specs live under specs/scheduler/ on branch feat/go-scheduler-design-one-xml-spec-per-domain-unde until its pull request lands on main; until then read them with git show origin/<that branch>:specs/scheduler/<file>.
1. Go builds and tests run only in Podman through make -C scheduler targets; nothing runs on the host.

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-12` Test plan rewritten by sched-architect: every go test case now runs as make -C scheduler test PKG='<package> -run <Test>' (the skeleton's Podman target, network off); a bare go command fails on the host (test.failed onb71 on WO-20261012-48ab). The lint ticket's negative case runs inside the lint image.

## Outcome

_Written by `work-order done`. Empty until then._
