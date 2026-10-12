---
{
  "id": "WO-20261012-b12c",
  "slug": "scheduler-observe-package-and-the-status-subcomm",
  "title": "Scheduler observe package and the status subcommand: JSON log lines per change, the Scheduler gRPC service with Health, Status, Reload, Drain and Retry on the control socket, counters, per SPEC-16.I",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T19:37:41+00:00",
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
    "WO-20261012-d7f4"
  ],
  "blocks": [
    "WO-20261012-fa36"
  ]
}
---

# WO-20261012-b12c - Scheduler observe package and the status subcommand: JSON log lines per change, the Scheduler gRPC service with Health, Status, Reload, Drain and Retry on the control socket, counters, per SPEC-16.I

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

Everything the scheduler decides must be readable in its pane and over its socket, and the supervisor must be able to ask the belt's words from the status subcommand.

## Scope

**In**

- Owns: scheduler/internal/observe/, scheduler/internal/cli/status.go
- package observe: the logger of SPEC-16.I i-log over core events, the Scheduler service server on the control socket fed from core.StatusSnapshot, the belt words for the status flag
- scheduler/internal/cli/status.go: text or JSON, the belt flag, exit codes (SPEC-16.I i-status)
- tests for every case of SPEC-16.I i-tests

**Out - non-goals**

- editing any file outside the directories this ticket owns, in particular scheduler/go.mod, scheduler/internal/core/ and any other ticket's package
- adding a dependency to the module (ask the architect)
- writing a record file directly; records go through the executor's record verb
- a metrics port (there is no port)
- writing any record or page

## Degrees of freedom

- [free] the log field order

## Acceptance criteria

- [ ] `AC-H1` *(human)* every case of SPEC-16.I i-tests passes in Podman
- [ ] `AC-H2` *(human)* ten empty ticks log nothing at info; one routed record logs each transition with the record id (i-t1)
- [ ] `AC-H3` *(human)* status --belt prints the bash runner's belt words and exits as route.sh status would (i-t3)

## Test plan

_Test plan from claude/workflow/templates/test-plan.md, shaped by claude/workflow/schemas/test-plan.schema.json. The tester runs exactly these cases and nothing else._

**Scope under test**

The observe package and the status subcommand.

**Cases**

- `TP-1`
  - intent: Change, not poll. (spec case i-t1)
  - command: `make -C scheduler test PKG='./internal/observe -run TestOneLinePerChange'`
  - expected: exit 0: ten empty ticks at info level write nothing; one routed record writes the listing, plan, job and receipt lines, each carrying the record id
- `TP-2`
  - intent: The answer is the truth. (spec case i-t2)
  - command: `make -C scheduler test PKG='./internal/observe -run TestStatusCounters'`
  - expected: exit 0: after a scripted run the Status answer's counters equal the fake executor's call log and the store's states
- `TP-3`
  - intent: The supervisor can read it. (spec case i-t3)
  - command: `make -C scheduler test PKG='./internal/observe -run TestStatusExitCodes'`
  - expected: exit 0: the subcommand exits 1 on a stopped belt or a failed gate and 0 otherwise; the belt flag prints the bash runner's words
- `TP-4`
  - intent: Prose stays in the record. (spec case i-t4)
  - command: `make -C scheduler test PKG='./internal/observe -run TestNoteNeverWhole'`
  - expected: exit 0: a note of 240 characters with a newline in it appears in no log line beyond one cut line

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
- `2026-10-12` SPEC-16.I 1.1.0 (PR 37): Status gains the runtime field (image, memory, container name, resolved digest) from the config group.

## Outcome

_Written by `work-order done`. Empty until then._
