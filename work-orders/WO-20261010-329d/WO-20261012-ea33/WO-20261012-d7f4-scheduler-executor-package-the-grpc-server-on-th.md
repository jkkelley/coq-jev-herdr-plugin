---
{
  "id": "WO-20261012-d7f4",
  "slug": "scheduler-executor-package-the-grpc-server-on-th",
  "title": "Scheduler executor package: the gRPC server on the host with the verb table, refusals, timeouts and tails, the client the scheduler dials, and the exec subcommand, per SPEC-16.H",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T19:37:15+00:00",
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
    "WO-20261012-e27e"
  ],
  "blocks": [
    "WO-20261012-8e69",
    "WO-20261012-1ccf",
    "WO-20261012-b12c",
    "WO-20261012-379f"
  ]
}
---

# WO-20261012-d7f4 - Scheduler executor package: the gRPC server on the host with the verb table, refusals, timeouts and tails, the client the scheduler dials, and the exec subcommand, per SPEC-16.H

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

The executor is the scheduler's only way to change the world; it must run exactly the verb table, refuse everything else, and answer with a verdict the jobs domain can classify.

## Scope

**In**

- Owns: scheduler/internal/executor/, scheduler/internal/cli/exec.go
- package executor: the Executor service server (SPEC-16.H h-executor, h-verbs, h-proto), the verb runner binding positions and host variables, the record flag allowlist, the environment unset, the log line per Run, and the gRPC client implementing core.Executor
- scheduler/internal/cli/exec.go registering the exec subcommand
- tests for h-t3, h-t4 and h-t5 with stub scripts on the path, over a real unix socket

**Out - non-goals**

- editing any file outside the directories this ticket owns, in particular scheduler/go.mod, scheduler/internal/core/ and any other ticket's package
- adding a dependency to the module (ask the architect)
- writing a record file directly; records go through the executor's record verb
- the Scheduler service (observe ticket)
- any decision about which verb to run

## Degrees of freedom

- [free] the concurrency primitive for bounded parallel runs

## Acceptance criteria

- [ ] `AC-H1` *(human)* cases h-t3, h-t4 and h-t5 pass in Podman
- [ ] `AC-H2` *(human)* every verb of scheduler/config/executor.json runs against a stub and binds its positions; the record verb forces the configured seat and refuses a flag outside the allowed set
- [ ] `AC-H3` *(human)* the socket is mode 0600 and no TCP listener exists

## Test plan

_Test plan from claude/workflow/templates/test-plan.md, shaped by claude/workflow/schemas/test-plan.schema.json. The tester runs exactly these cases and nothing else._

**Scope under test**

The executor package and the exec subcommand.

**Cases**

- `TP-1`
  - intent: The fence holds. (spec case h-t3)
  - command: `make -C scheduler test PKG='./internal/executor -run TestRefusals'`
  - expected: exit 0: an unknown verb, a newline argument, a disallowed record flag and a wrong argument count each come back refused with a reason and no child process
- `TP-2`
  - intent: Every verb has a case. (spec case h-t4)
  - command: `make -C scheduler test PKG='./internal/executor -run TestRunVerbsAgainstStubs'`
  - expected: exit 0: every verb in the table runs against stub scripts on the path, binds its positions, forces the seat on record, times out when told, and returns tails of the configured length
- `TP-3`
  - intent: One executor, private socket. (spec case h-t5)
  - command: `make -C scheduler test PKG='./internal/executor -run TestSocketMode'`
  - expected: exit 0: the socket is created with mode 0600 and a second listener on the same path is refused

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
