---
{
  "id": "WO-20261012-3c7a",
  "slug": "scheduler-health-package-the-belt-heartbeat-from",
  "title": "Scheduler health package: the belt heartbeat from the tick loop, two-signal stalls, latches, executor health, the halt flag, drain, recovery at start and housekeeping, per SPEC-16.F",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T19:37:32+00:00",
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
    "WO-20261012-9790",
    "WO-20261012-8e69"
  ],
  "blocks": [
    "WO-20261012-1ccf"
  ]
}
---

# WO-20261012-3c7a - Scheduler health package: the belt heartbeat from the tick loop, two-signal stalls, latches, executor health, the halt flag, drain, recovery at start and housekeeping, per SPEC-16.F

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

A tester mid-suite must never read as a stalled line and a long bring-up never as a stopped belt; every verdict is said once and the supervisor keeps the repairing.

## Scope

**In**

- Owns: scheduler/internal/health/
- package health: the belt writer, the stall judge over gates, records and seat statuses, core.Latches over files, the executor health latch, the halt check, drain, the start gate order and the housekeeping job source (SPEC-16.F)
- tests for every case of SPEC-16.F f-tests

**Out - non-goals**

- editing any file outside the directories this ticket owns, in particular scheduler/go.mod, scheduler/internal/core/ and any other ticket's package
- adding a dependency to the module (ask the architect)
- writing a record file directly; records go through the executor's record verb
- seating anything
- writing a record directly (notes are record jobs)

## Degrees of freedom

- [free] the file names of latches, as long as they are the names f-latch-names lists

## Acceptance criteria

- [ ] `AC-H1` *(human)* every case of SPEC-16.F f-tests passes in Podman
- [ ] `AC-H2` *(human)* the belt file's age never passes one poll interval while a Run blocks (f-t1)
- [ ] `AC-H3` *(human)* an overdue gate with a busy seat yields no note; with an absent or long-idle seat exactly one (f-t2, f-t3)

## Test plan

_Test plan from claude/workflow/templates/test-plan.md, shaped by claude/workflow/schemas/test-plan.schema.json. The tester runs exactly these cases and nothing else._

**Scope under test**

The health package.

**Cases**

- `TP-1`
  - intent: A long action is not a dead belt. (spec case f-t1)
  - command: `make -C scheduler test PKG='./internal/health -run TestBeltTouchedWhileJobRuns'`
  - expected: exit 0: with a Run that blocks for three ticks the belt file's age never passes one poll interval
- `TP-2`
  - intent: Two signals. (spec case f-t2)
  - command: `make -C scheduler test PKG='./internal/health -run TestStallNeedsIdleSeat'`
  - expected: exit 0: an overdue gate with a busy seat yields nothing; with the seat idle past the threshold it yields one 500 note; with the seat absent likewise
- `TP-3`
  - intent: Said once. (spec case f-t3)
  - command: `make -C scheduler test PKG='./internal/health -run TestStallLatchedOnce'`
  - expected: exit 0: the same stall over ten ticks yields one note; an answer drops the latch; a later stall of the same gate is noted again
- `TP-4`
  - intent: A dead executor costs no attempts. (spec case f-t4)
  - command: `make -C scheduler test PKG='./internal/health -run TestExecutorDownHoldsJobs'`
  - expected: exit 0: with Health failing no Run is attempted, job attempts do not rise, one note is written; when Health returns jobs run
- `TP-5`
  - intent: Halt means halt. (spec case f-t5)
  - command: `make -C scheduler test PKG='./internal/health -run TestHaltFlag'`
  - expected: exit 0: with the flag present the belt is touched, status says halted, nothing is listed or run; after removal the tick resumes
- `TP-6`
  - intent: Nothing is lost at shutdown. (spec case f-t6)
  - command: `make -C scheduler test PKG='./internal/health -run TestDrainLeavesRunning'`
  - expected: exit 0: a drain with a job still running after the drain seconds exits 0 and leaves the job running in the store
- `TP-7`
  - intent: A period runs once. (spec case f-t7)
  - command: `make -C scheduler test PKG='./internal/health -run TestHousekeepingOncePerPeriod'`
  - expected: exit 0: ten ticks inside one period create one sweep job per housekeeping row
- `TP-8`
  - intent: A stall is visible in time. (spec case f-t8)
  - command: `make -C scheduler test PKG='./internal/health -run TestVisibleBoundRefused'`
  - expected: exit 0: a configuration whose poll plus smallest deadline passes the bound is refused at start naming both keys

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
