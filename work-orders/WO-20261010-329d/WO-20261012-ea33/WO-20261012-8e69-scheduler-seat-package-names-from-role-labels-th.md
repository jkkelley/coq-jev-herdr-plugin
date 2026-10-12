---
{
  "id": "WO-20261012-8e69",
  "slug": "scheduler-seat-package-names-from-role-labels-th",
  "title": "Scheduler seat package: names from role labels, the observer with three signals, cap holds, bring-up and down through the executor, the shared seat and absent wakes, per SPEC-16.C",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T19:37:19+00:00",
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
    "WO-20261012-d7f4"
  ],
  "blocks": [
    "WO-20261012-3c7a",
    "WO-20261012-1ccf"
  ]
}
---

# WO-20261012-8e69 - Scheduler seat package: names from role labels, the observer with three signals, cap holds, bring-up and down through the executor, the shared seat and absent wakes, per SPEC-16.C

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

A seat bring-up past its cap or a down of a busy shared seat must be held, not refused; the bash runner wrote a 500 and lost the wake in both cases.

## Scope

**In**

- Owns: scheduler/internal/seat/
- package seat: seat names and the reverse lookup, core.SeatObserver over the agent list and pane read verbs with the configured patterns, the hold rules for cap, shared and absent, and the exit classes of seat-up and seat-down (SPEC-16.C)
- tests for every case of SPEC-16.C c-tests

**Out - non-goals**

- editing any file outside the directories this ticket owns, in particular scheduler/go.mod, scheduler/internal/core/ and any other ticket's package
- adding a dependency to the module (ask the architect)
- writing a record file directly; records go through the executor's record verb
- starting an agent itself
- re-seating a dead seat (the supervisor's)

## Degrees of freedom

- [free] how statuses are cached between ticks

## Acceptance criteria

- [ ] `AC-H1` *(human)* every case of SPEC-16.C c-tests passes in Podman
- [ ] `AC-H2` *(human)* seat names equal factory/bin/route.sh seat_of for every role file in roles/
- [ ] `AC-H3` *(human)* no Run leaves the package while a job is held

## Test plan

_Test plan from claude/workflow/templates/test-plan.md, shaped by claude/workflow/schemas/test-plan.schema.json. The tester runs exactly these cases and nothing else._

**Scope under test**

The seat package.

**Cases**

- `TP-1`
  - intent: Names are the seat script's names. (spec case c-t1)
  - command: `make -C scheduler test PKG='./internal/seat -run TestSeatNameFromLabel'`
  - expected: exit 0: tester on a ticket yields the label with the ticket lowercased; the merger yields merger; a label with a leftover variable errors
- `TP-2`
  - intent: Three signals, one status. (spec case c-t2)
  - command: `make -C scheduler test PKG='./internal/seat -run TestObserveStatuses'`
  - expected: exit 0: from a scripted agent list and pane reads the observer yields absent, busy by herdr, busy by footer, idle, and unknown when the verb fails
- `TP-3`
  - intent: Hold, never refuse. (spec case c-t3)
  - command: `make -C scheduler test PKG='./internal/seat -run TestCapHolds'`
  - expected: exit 0: a seat-up for a role at its cap is held with reason cap, released oldest first when a seat goes absent, and the fake executor saw no call while held
- `TP-4`
  - intent: Refusals that can clear are retried. (spec case c-t4)
  - command: `make -C scheduler test PKG='./internal/seat -run TestUpExitClasses'`
  - expected: exit 0: exit 3 and 4 and a timeout schedule a retry, exit 2 is dead at once, exit 0 is done
- `TP-5`
  - intent: The shared seat is not pulled from under a ticket. (spec case c-t5)
  - command: `make -C scheduler test PKG='./internal/seat -run TestSharedDownWaitsForIdle'`
  - expected: exit 0: a down of the merger is held while it is busy or confirming and runs on the first idle tick
- `TP-6`
  - intent: A wake waits for the supervisor. (spec case c-t6)
  - command: `make -C scheduler test PKG='./internal/seat -run TestAbsentWake'`
  - expected: exit 0: a prompt to an absent seat is held, runs when the seat appears, and is dead with one 500 after the absent wait

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
