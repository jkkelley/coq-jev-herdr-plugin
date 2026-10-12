---
{
  "id": "WO-20261012-fa36",
  "slug": "scheduler-cut-over-shadow-mode-and-its-decision-",
  "title": "Scheduler cut-over: shadow mode and its decision files, the parity report and subcommand, going active with the belt panes released and the ledger adopted, rollback, the grid slots and the belt status command, per SPEC-16.J",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T19:37:53+00:00",
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
    "WO-20261012-1ccf",
    "WO-20261012-b12c",
    "WO-20261012-df2b"
  ],
  "blocks": [
    "WO-20261012-1635"
  ]
}
---

# WO-20261012-fa36 - Scheduler cut-over: shadow mode and its decision files, the parity report and subcommand, going active with the belt panes released and the ledger adopted, rollback, the grid slots and the belt status command, per SPEC-16.J

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

The scheduler replaces the bash belt behind a flag; shadow must decide without acting, parity must prove the decisions match, and going active must adopt the belt's ledger so nothing routes twice.

## Scope

**In**

- Owns: scheduler/internal/cutover/, scheduler/internal/cli/parity.go, scheduler/host/bin/cutover.sh, herdr/config/monitors.json, herdr/config/herdr.json
- package cutover: the mode gate on the job runner, decision files, the parity report over the bash ledger and receipts (SPEC-16.J)
- the parity subcommand
- scheduler/host/bin/cutover.sh performing the steps of j-active and j-rollback through the monitors script
- herdr/config/monitors.json: the executor and scheduler slots, the three belt slots and the two watches released; herdr/config/herdr.json belt.status pointing at the scheduler's status with the belt flag

**Out - non-goals**

- editing any file outside the directories this ticket owns, in particular scheduler/go.mod, scheduler/internal/core/ and any other ticket's package
- adding a dependency to the module (ask the architect)
- writing a record file directly; records go through the executor's record verb
- deleting the bash scripts (a later ticket)
- starting before pull requests touching herdr/config have merged

## Degrees of freedom

- [free] the order of the two herdr config edits relative to the cutover script

## Acceptance criteria

- [ ] `AC-H1` *(human)* cases j-t1 to j-t4 pass in Podman
- [ ] `AC-H2` *(human)* the parity report over a fixture bash state directory exits 0 on agreement and 1 naming each mismatch
- [ ] `AC-H3` *(human)* after cutover.sh on a scratch session no belt pane runs and status says active with the gate passed

## Test plan

_Test plan from claude/workflow/templates/test-plan.md, shaped by claude/workflow/schemas/test-plan.schema.json. The tester runs exactly these cases and nothing else._

**Scope under test**

The cut-over package, the parity subcommand, the cutover script and the two herdr config edits.

**Cases**

- `TP-1`
  - intent: Shadow decides, never acts. (spec case j-t1)
  - command: `make -C scheduler test PKG='./internal/cutover -run TestShadowSendsNoMutatingVerb'`
  - expected: exit 0: over the replay fixtures in shadow the fake executor saw only observation verbs and one decision file exists per record
- `TP-2`
  - intent: The report reads both sides. (spec case j-t2)
  - command: `make -C scheduler test PKG='./internal/cutover -run TestParityAgainstBashLedger'`
  - expected: exit 0: a fixture bash state directory with receipts yields zero mismatches for agreeing decisions and names each disagreeing one with both sides
- `TP-3`
  - intent: The runbook can gate on it. (spec case j-t3)
  - command: `make -C scheduler test PKG='./internal/cutover -run TestParityExitCodes'`
  - expected: exit 0: below the minimum records or with a mismatch the report exits 1, otherwise 0
- `TP-4`
  - intent: Nothing twice, nothing skipped. (spec case j-t4)
  - command: `make -C scheduler test PKG='./internal/cutover -run TestAdoptLedger'`
  - expected: exit 0: started active on a bash state directory the scheduler routes nothing already ledgered and routes the first unrouted record

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
1. Start only when no open pull request touches herdr/config/monitors.json or herdr/config/herdr.json.

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-12` Test plan rewritten by sched-architect: every go test case now runs as make -C scheduler test PKG='<package> -run <Test>' (the skeleton's Podman target, network off); a bare go command fails on the host (test.failed onb71 on WO-20261012-48ab). The lint ticket's negative case runs inside the lint image.
- `2026-10-12` Ownership: under scheduler/host this ticket owns only the new file scheduler/host/bin/cutover.sh; every other host file is WO-20261012-df2b's and is merged before this ticket may start (depends_on).

## Outcome

_Written by `work-order done`. Empty until then._
