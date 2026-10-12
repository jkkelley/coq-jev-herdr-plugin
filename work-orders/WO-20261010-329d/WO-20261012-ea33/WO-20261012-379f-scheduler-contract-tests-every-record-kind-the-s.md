---
{
  "id": "WO-20261012-379f",
  "slug": "scheduler-contract-tests-every-record-kind-the-s",
  "title": "Scheduler contract tests: every record kind the scheduler emits through the real event writer and its check, every verb against the real scripts' usage, the bash ledger against the Go ledger, per SPEC-16.K",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T19:37:45+00:00",
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
    "WO-20261012-d7f4",
    "WO-20261012-5a3d",
    "WO-20261012-8d87"
  ],
  "blocks": []
}
---

# WO-20261012-379f - Scheduler contract tests: every record kind the scheduler emits through the real event writer and its check, every verb against the real scripts' usage, the bash ledger against the Go ledger, per SPEC-16.K

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

A schema change in the log or a changed exit class in a host script must fail a test before it fails the line.

## Scope

**In**

- Owns: scheduler/tests/contract/
- scheduler/tests/contract with a make contract target's script and cases per SPEC-16.K k-contract: the writer check over every emitted kind, the scripts' usage runs, the ledger comparison over a fixture log
- the cases run inside the test image with bash, jq and the repository mounted read-only

**Out - non-goals**

- editing any file outside the directories this ticket owns, in particular scheduler/go.mod, scheduler/internal/core/ and any other ticket's package
- adding a dependency to the module (ask the architect)
- writing a record file directly; records go through the executor's record verb
- editing any host script
- the Makefile outside the contract target's recipe line

## Degrees of freedom

- [free] case file naming

## Acceptance criteria

- [ ] `AC-H1` *(human)* case k-t4 passes in Podman
- [ ] `AC-H2` *(human)* every kind in the verb table's record allowlist is exercised
- [ ] `AC-H3` *(human)* the ledger comparison reports zero differences over the fixture log

## Test plan

_Test plan from claude/workflow/templates/test-plan.md, shaped by claude/workflow/schemas/test-plan.schema.json. The tester runs exactly these cases and nothing else._

**Scope under test**

The contract test suite.

**Cases**

- `TP-1`
  - intent: The scripts and the scheduler agree. (spec case k-t4)
  - command: `make -C scheduler contract`
  - expected: exit 0: every emitted record kind passes the writer's check; every verb runs against the real scripts' usage

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
1. The Makefile's contract target line is added by this ticket; the skeleton leaves a placeholder comment for it.

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-12` Test plan rewritten by sched-architect: every go test case now runs as make -C scheduler test PKG='<package> -run <Test>' (the skeleton's Podman target, network off); a bare go command fails on the host (test.failed onb71 on WO-20261012-48ab). The lint ticket's negative case runs inside the lint image.

## Outcome

_Written by `work-order done`. Empty until then._
