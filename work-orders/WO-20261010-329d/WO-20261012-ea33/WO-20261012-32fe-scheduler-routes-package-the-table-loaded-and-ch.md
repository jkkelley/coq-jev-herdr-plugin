---
{
  "id": "WO-20261012-32fe",
  "slug": "scheduler-routes-package-the-table-loaded-and-ch",
  "title": "Scheduler routes package: the table loaded and checked, the first-row match, the plan with ordered job specs, the wake line and the receipt shape, per SPEC-16.B",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T19:37:07+00:00",
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
    "WO-20261012-48ab",
    "WO-20261012-8d87"
  ],
  "blocks": [
    "WO-20261012-6e43",
    "WO-20261012-1ccf"
  ]
}
---

# WO-20261012-32fe - Scheduler routes package: the table loaded and checked, the first-row match, the plan with ordered job specs, the wake line and the receipt shape, per SPEC-16.B

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

Routing is the table; the Go match must choose the row the bash runner chooses for every record, and the plan must carry the exact wake line and receipt the seats and the board already read.

## Scope

**In**

- Owns: scheduler/internal/routes/
- package routes implementing core.Table (load, checks, Version) and Plan(record, table, escalations) per SPEC-16.B, every action of b-actions as job specs with After edges
- tests for every case of SPEC-16.B b-tests, the replay fixtures as input where the case says so

**Out - non-goals**

- editing any file outside the directories this ticket owns, in particular scheduler/go.mod, scheduler/internal/core/ and any other ticket's package
- adding a dependency to the module (ask the architect)
- writing a record file directly; records go through the executor's record verb
- performing a job
- the escalation count's computation over records (the engine passes it)

## Degrees of freedom

- [free] internal representation of the match predicate, as long as it is a pure function

## Acceptance criteria

- [ ] `AC-H1` *(human)* every case of SPEC-16.B b-tests passes in Podman
- [ ] `AC-H2` *(human)* for every replay fixture the chosen row index equals the expected one (b-t1)
- [ ] `AC-H3` *(human)* the wake line and the receipt note equal the fixtures character for character (b-t3, b-t5)

## Test plan

_Test plan from claude/workflow/templates/test-plan.md, shaped by claude/workflow/schemas/test-plan.schema.json. The tester runs exactly these cases and nothing else._

**Scope under test**

The routes package.

**Cases**

- `TP-1`
  - intent: The match is the bash runner's match. (spec case b-t1)
  - command: `make -C scheduler test PKG='./internal/routes -run TestMatchFirstRowWins'`
  - expected: exit 0: for every replay record the chosen row index equals the fixture's expected index
- `TP-2`
  - intent: Order is data on the jobs. (spec case b-t2)
  - command: `make -C scheduler test PKG='./internal/routes -run TestPlanJobsInOrder'`
  - expected: exit 0: a seat row yields seat-up, prompt, down, receipt with After edges in that order
- `TP-3`
  - intent: Nothing but the line reaches a prompt. (spec case b-t3)
  - command: `make -C scheduler test PKG='./internal/routes -run TestWakeLine'`
  - expected: exit 0: the wake line equals the fixture's line character for character, pr and sha included for with pr rows
- `TP-4`
  - intent: Typed text is fenced. (spec case b-t4)
  - command: `make -C scheduler test PKG='./internal/routes -run TestMalformedExtras'`
  - expected: exit 0: a bad pr or sha yields a plan failure naming the record and no prompt job
- `TP-5`
  - intent: The board sees no change. (spec case b-t5)
  - command: `make -C scheduler test PKG='./internal/routes -run TestReceiptShape'`
  - expected: exit 0: the receipt's note, to, ticket and evidence equal the bash runner's for the same record
- `TP-6`
  - intent: A bad table never loads. (spec case b-t6)
  - command: `make -C scheduler test PKG='./internal/routes -run TestLoadRefusesBadTable'`
  - expected: exit 0: a row with an unknown do or a wake row without to is refused naming the row index and key
- `TP-7`
  - intent: A first 423 and a second 423 are told apart. (spec case b-t7)
  - command: `make -C scheduler test PKG='./internal/routes -run TestEscalationsCount'`
  - expected: exit 0: escalated records by a runner seat before the record count, later ones and other seats do not

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
