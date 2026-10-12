---
{
  "id": "WO-20261012-7a9a",
  "slug": "scheduler-job-package-the-durable-store-idempote",
  "title": "Scheduler job package: the durable store, idempotency keys and unknown-outcome discovery, states and order, backoff, dead letter, wake confirmation and the quiet window, per SPEC-16.D",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T19:37:23+00:00",
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
    "WO-20261012-9790"
  ],
  "blocks": [
    "WO-20261012-1ccf"
  ]
}
---

# WO-20261012-7a9a - Scheduler job package: the durable store, idempotency keys and unknown-outcome discovery, states and order, backoff, dead letter, wake confirmation and the quiet window, per SPEC-16.D

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

The bash belt lost wakes and retried nothing; every side effect must be a durable, idempotent, retried and confirmed job, dead-lettered with one note.

## Scope

**In**

- Owns: scheduler/internal/job/
- package job: core.JobStore over one file per job, the runner with bounded in-flight Runs and per-seat serialisation, classification of verdicts, backoff, After order, discovery, confirmation and the quiet hold (SPEC-16.D)
- tests for every case of SPEC-16.D d-tests

**Out - non-goals**

- editing any file outside the directories this ticket owns, in particular scheduler/go.mod, scheduler/internal/core/ and any other ticket's package
- adding a dependency to the module (ask the architect)
- writing a record file directly; records go through the executor's record verb
- deciding which jobs exist (routing, policies, health decide)
- raising a seat's attempt

## Degrees of freedom

- [free] the in-memory index structure

## Acceptance criteria

- [ ] `AC-H1` *(human)* every case of SPEC-16.D d-tests passes in Podman
- [ ] `AC-H2` *(human)* a prompt or record job whose Run timed out is never re-sent before discovery (d-t8)
- [ ] `AC-H3` *(human)* exactly one dead-letter note per dead job and none for a dead note job (d-t9)

## Test plan

_Test plan from claude/workflow/templates/test-plan.md, shaped by claude/workflow/schemas/test-plan.schema.json. The tester runs exactly these cases and nothing else._

**Scope under test**

The job package.

**Cases**

- `TP-1`
  - intent: Idempotent by key. (spec case d-t1)
  - command: `make -C scheduler test PKG='./internal/job -run TestKeyDedupes'`
  - expected: exit 0: putting the same spec twice yields one file; a plan replayed after a simulated restart creates nothing
- `TP-2`
  - intent: Pure arithmetic. (spec case d-t2)
  - command: `make -C scheduler test PKG='./internal/job -run TestBackoffArithmetic'`
  - expected: exit 0: delays for attempts 1 to 5 equal base, base times factor, and so on, capped, with zero jitter
- `TP-3`
  - intent: Every verdict has one class. (spec case d-t3)
  - command: `make -C scheduler test PKG='./internal/job -run TestClassify'`
  - expected: exit 0: exit 0 done, a final exit done with the code kept, refused dead, other exit retry, timeout discovery
- `TP-4`
  - intent: Order is data. (spec case d-t4)
  - command: `make -C scheduler test PKG='./internal/job -run TestOrderAfter'`
  - expected: exit 0: the down runs after a dead primary, the receipt never runs after a dead primary and is dead with reason after
- `TP-5`
  - intent: A record confirms. (spec case d-t5)
  - command: `make -C scheduler test PKG='./internal/job -run TestWakeConfirmedByRecord'`
  - expected: exit 0: a prompt is confirming after exit 0 and done when the seat's record on the ticket lands inside the window
- `TP-6`
  - intent: A lost wake is found. (spec case d-t6)
  - command: `make -C scheduler test PKG='./internal/job -run TestWakeResentThenDead'`
  - expected: exit 0: no signal inside the window re-sends the same line, and after the maximum the job is dead with one 500 note
- `TP-7`
  - intent: The quiet window is honoured. (spec case d-t7)
  - command: `make -C scheduler test PKG='./internal/job -run TestQuietInbox'`
  - expected: exit 0: with the quiet verb answering quiet the inbox verb is called once with the line and no prompt runs; when it answers not quiet the job enters confirming
- `TP-8`
  - intent: Never a blind double. (spec case d-t8)
  - command: `make -C scheduler test PKG='./internal/job -run TestUnknownOutcomeDiscovery'`
  - expected: exit 0: a timed-out record job is done when intake shows the record, and retried when it does not; a timed-out prompt is confirming when the seat is busy
- `TP-9`
  - intent: One note, never a flood. (spec case d-t9)
  - command: `make -C scheduler test PKG='./internal/job -run TestDeadNoteOnce'`
  - expected: exit 0: a dead primary writes the failure note once and the ledger word failed; a dead note job writes nothing

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
