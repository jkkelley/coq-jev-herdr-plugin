---
{
  "id": "WO-20261012-1635",
  "slug": "scheduler-end-to-end-acceptance-in-a-scratch-her",
  "title": "Scheduler end-to-end acceptance: in a scratch herdr session with a stub agent a pr.opened routes to a seated tester with no bash watcher, then the same on the live session for one real pull request",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T19:37:58+00:00",
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
    "WO-20261012-fa36"
  ],
  "blocks": []
}
---

# WO-20261012-1635 - Scheduler end-to-end acceptance: in a scratch herdr session with a stub agent a pr.opened routes to a seated tester with no bash watcher, then the same on the live session for one real pull request

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

The epic's acceptance is a real pr.opened routed to a tester with no bash watcher; it must be rehearsed in a scratch session before the live session sees it.

## Scope

**In**

- Owns: scheduler/tests/e2e/
- scheduler/tests/e2e with the make e2e target's script and cases per SPEC-16.J j-accept over the herdr scratch harness of SPEC-04 s-testing: executor pane, scheduler container, stub agent, one pr.opened, the seated tester, the receipt and ledger word, the down after test.passed
- a written observation of the live run as a note on this ticket, with the record ids

**Out - non-goals**

- editing any file outside the directories this ticket owns, in particular scheduler/go.mod, scheduler/internal/core/ and any other ticket's package
- adding a dependency to the module (ask the architect)
- writing a record file directly; records go through the executor's record verb
- changing the scheduler's code to pass (a failure is a 423 with evidence)

## Degrees of freedom

- [free] the stub agent's behaviour, as long as it answers the brief and writes test.passed

## Acceptance criteria

- [ ] `AC-H1` *(human)* case j-t5 passes
- [ ] `AC-H2` *(human)* on the live session one real pull request's pr.opened is routed by the scheduler with the belt panes released, observed in status and both panes, recorded as a note with the record ids

## Test plan

_Test plan from claude/workflow/templates/test-plan.md, shaped by claude/workflow/schemas/test-plan.schema.json. The tester runs exactly these cases and nothing else._

**Scope under test**

The end-to-end acceptance.

**Cases**

- `TP-1`
  - intent: The acceptance, rehearsed. (spec case j-t5)
  - command: `make -C scheduler e2e`
  - expected: tests: N passed, 0 failed: in the scratch herdr session a pr.opened routes to a seated stub tester with no bash pane present

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
1. The Makefile's e2e target line is added by this ticket.

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-12` Test plan rewritten by sched-architect: every go test case now runs as make -C scheduler test PKG='<package> -run <Test>' (the skeleton's Podman target, network off); a bare go command fails on the host (test.failed onb71 on WO-20261012-48ab). The lint ticket's negative case runs inside the lint image.

## Outcome

_Written by `work-order done`. Empty until then._
