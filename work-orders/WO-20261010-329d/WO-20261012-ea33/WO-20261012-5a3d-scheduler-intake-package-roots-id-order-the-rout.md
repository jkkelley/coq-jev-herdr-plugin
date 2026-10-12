---
{
  "id": "WO-20261012-5a3d",
  "slug": "scheduler-intake-package-roots-id-order-the-rout",
  "title": "Scheduler intake package: roots, id order, the routed ledger with claim before act, the first-start boundary, interrupted claims and the reader, per SPEC-16.A",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T19:37:03+00:00",
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
    "WO-20261012-48ab"
  ],
  "blocks": [
    "WO-20261012-1ccf",
    "WO-20261012-379f"
  ]
}
---

# WO-20261012-5a3d - Scheduler intake package: roots, id order, the routed ledger with claim before act, the first-start boundary, interrupted claims and the reader, per SPEC-16.A

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

Every record must reach routing exactly once across roots, restarts and the cut-over; the bash runner's ledger is the contract to keep byte for byte.

## Scope

**In**

- Owns: scheduler/internal/intake/
- package intake implementing core.Source (file source over the configured roots) and core.Ledger with the bash runner's words, the boundary, Interrupted and the reader of SPEC-16.A
- tests for every case of SPEC-16.A a-tests with the testkit

**Out - non-goals**

- editing any file outside the directories this ticket owns, in particular scheduler/go.mod, scheduler/internal/core/ and any other ticket's package
- adding a dependency to the module (ask the architect)
- writing a record file directly; records go through the executor's record verb
- routing, jobs or any side effect
- a bus source (later)

## Degrees of freedom

- [free] internal file layout and helper names inside the package

## Acceptance criteria

- [ ] `AC-H1` *(human)* every case of SPEC-16.A a-tests passes in Podman
- [ ] `AC-H2` *(human)* the ledger words and layout equal factory/bin/route.sh's (case a-t4)
- [ ] `AC-H3` *(human)* the package imports core and testkit only, plus the standard library

## Test plan

_Test plan from claude/workflow/templates/test-plan.md, shaped by claude/workflow/schemas/test-plan.schema.json. The tester runs exactly these cases and nothing else._

**Scope under test**

The intake package.

**Cases**

- `TP-1`
  - intent: A record copied from a slot root into the checkout root is still one record. (spec case a-t1)
  - command: `make -C scheduler test PKG='./internal/intake -run TestListOrdersAcrossRoots'`
  - expected: exit 0: refs from two roots come back in id order, a duplicate id appears once with the first root
- `TP-2`
  - intent: A restart on an old log wakes nobody. (spec case a-t2)
  - command: `make -C scheduler test PKG='./internal/intake -run TestBoundary'`
  - expected: exit 0: a record below the boundary is never listed; since=start lists the whole log
- `TP-3`
  - intent: Exactly-once is the claim. (spec case a-t3)
  - command: `make -C scheduler test PKG='./internal/intake -run TestClaimOnce'`
  - expected: exit 0: two concurrent Claim calls on one id return true once; the ledger file holds claimed and a UTC
- `TP-4`
  - intent: Cut-over adopts the ledger unchanged. (spec case a-t4)
  - command: `make -C scheduler test PKG='./internal/intake -run TestLedgerWordsMatchBash'`
  - expected: exit 0: every word the bash runner writes is produced byte for byte by the Go ledger
- `TP-5`
  - intent: A bad file is named once and never again. (spec case a-t5)
  - command: `make -C scheduler test PKG='./internal/intake -run TestUnreadable'`
  - expected: exit 0: a file that does not parse is ledgered unreadable and yields one record job for a 500 note
- `TP-6`
  - intent: A crash between claim and job write is reported, not repeated. (spec case a-t6)
  - command: `make -C scheduler test PKG='./internal/intake -run TestInterruptedAtStart'`
  - expected: exit 0: a claimed entry with no job files becomes interrupted with one 500 note; one with job files is left for the job store
- `TP-7`
  - intent: A receipt never receipts itself. (spec case a-t7)
  - command: `make -C scheduler test PKG='./internal/intake -run TestOwnSeat'`
  - expected: exit 0: a record whose seat is in runner_seats is ledgered own and never handed to routing

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
