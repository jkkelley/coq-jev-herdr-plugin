---
{
  "id": "WO-20261012-6e43",
  "slug": "scheduler-policy-package-the-policies-table-with",
  "title": "Scheduler policy package: the policies table with the break glass refusal, open escalations, the default as a record then a wake, limits from the log, and the break glass rows, per SPEC-16.E",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T19:37:27+00:00",
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
    "WO-20261012-32fe"
  ],
  "blocks": [
    "WO-20261012-1ccf"
  ]
}
---

# WO-20261012-6e43 - Scheduler policy package: the policies table with the break glass refusal, open escalations, the default as a record then a wake, limits from the log, and the break glass rows, per SPEC-16.E

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

An unanswered escalation must get its default on time as a record first and a wake second, bounded per ticket, and a break glass must be routed and never decided.

## Scope

**In**

- Owns: scheduler/internal/policy/
- package policy: the table loader and checks (break glass refused, unique ids), open escalations over the record index, the apply plan (record job then prompt job with the printed-id token), limits, and the plan of the break glass rows (SPEC-16.E)
- tests for every case of SPEC-16.E e-tests

**Out - non-goals**

- editing any file outside the directories this ticket owns, in particular scheduler/go.mod, scheduler/internal/core/ and any other ticket's package
- adding a dependency to the module (ask the architect)
- writing a record file directly; records go through the executor's record verb
- reading the owner's page or granting anything
- the sweep (health's housekeeping)

## Degrees of freedom

- [free] how the record index is queried, as long as policies never list the log themselves

## Acceptance criteria

- [ ] `AC-H1` *(human)* every case of SPEC-16.E e-tests passes in Podman
- [ ] `AC-H2` *(human)* a table with a break.glass match is refused at load and on reload (e-t1)
- [ ] `AC-H3` *(human)* the default's record precedes its wake in every plan (e-t3)

## Test plan

_Test plan from claude/workflow/templates/test-plan.md, shaped by claude/workflow/schemas/test-plan.schema.json. The tester runs exactly these cases and nothing else._

**Scope under test**

The policy package.

**Cases**

- `TP-1`
  - intent: The line cannot grant itself a break glass. (spec case e-t1)
  - command: `make -C scheduler test PKG='./internal/policy -run TestLoadRefusesBreakGlassRow'`
  - expected: exit 0: a table with a break.glass match is refused with exit 3 at load, and a duplicate id likewise
- `TP-2`
  - intent: Answered means a later record of an answering kind. (spec case e-t2)
  - command: `make -C scheduler test PKG='./internal/policy -run TestOpenUntilAnswered'`
  - expected: exit 0: a blocked 423 is open, closed by a later ticket.cut on the ticket, not closed by an earlier one or another ticket's
- `TP-3`
  - intent: Record first, wake second. (spec case e-t3)
  - command: `make -C scheduler test PKG='./internal/policy -run TestDefaultRecordThenWake'`
  - expected: exit 0: past the deadline one record job and one prompt job after it are created; the prompt's argument carries the writer's printed id
- `TP-4`
  - intent: The limit comes from the log. (spec case e-t4)
  - command: `make -C scheduler test PKG='./internal/policy -run TestLimitPerTicket'`
  - expected: exit 0: with one default already in the log a second escalation of the same ticket and row is left waiting
- `TP-5`
  - intent: The seat that asked is the seat that is woken. (spec case e-t5)
  - command: `make -C scheduler test PKG='./internal/policy -run TestSourceSeat'`
  - expected: exit 0: to source resolves the escalation's seat and its role from the labels; a role name resolves that role's seat on the ticket
- `TP-6`
  - intent: Routed, never decided. (spec case e-t6)
  - command: `make -C scheduler test PKG='./internal/policy -run TestBreakGlassRoutes'`
  - expected: exit 0: the replay fixtures for the six break glass rows and the policy.applied row yield the plans the routing spec names, and a 200 yields the break-glass verb with exit 3 final

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
