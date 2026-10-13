---
{
  "id": "WO-20261013-f52a",
  "slug": "roadmap-k4-halt-drain-resume-and-line-check-make",
  "title": "Roadmap K4 - Halt, drain, resume and line-check: make line-halt, line-drain, line-resume and line-check with the flags in the state root's run directory, the preflight by rule, the bring-up checklist, USERHALT and USERGO, and a supervisor that keeps only bearings stable alive while halted (widens item C)",
  "type": "feature",
  "status": "cancelled",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T00:57:32+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": null,
  "pr": null,
  "closed": "2026-10-13",
  "approval": {
    "via": "override",
    "reason": "owner accepted SPEC-17 on card C25; lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261013-ba44",
    "WO-20261012-7a46"
  ],
  "blocks": [],
  "files": [
    "Makefile",
    "herdr/bin/supervisor.sh",
    "herdr/tests/cases/*supervisor*",
    "docs/runbooks/line-halt-resume.md",
    "line/bin/line-halt.sh",
    "line/bin/line-drain.sh",
    "line/bin/line-resume.sh",
    "line/bin/line-check.sh",
    "line/tests/cases/line-*.sh"
  ],
  "superseded_by": "WO-20261013-fd7d"
}
---

# WO-20261013-f52a - Roadmap K4 - Halt, drain, resume and line-check: make line-halt, line-drain, line-resume and line-check with the flags in the state root's run directory, the preflight by rule, the bring-up checklist, USERHALT and USERGO, and a supervisor that keeps only bearings stable alive while halted (widens item C)

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

Halting on 2026-10-12 meant hunting process ids by hand and restarting needed a hand-written runbook; card C24 added the drain. SPEC-17 s-halt and s-bringup define four commands and the bring-up checklist B1 to B10; roadmap item C (WO-20261012-e970) covered halt and resume only and is superseded by this ticket.

## Scope

**In**

- make line-halt: writes the halt flag with reason and time, stops the runner, stall watch, policy watch and health watch and releases their slots, interrupts every seat's turn and keeps every seat up, posts line.halted 503 to the owner lane and the record, never touches bearings stable
- make line-drain: the drain flag; no new ticket dequeues, items in flight finish, the health line says draining
- make line-resume: the preflight (open items judged by rule: consumer gone, sha superseded or result present are done with the reason; ledger and board agree), the bring-up DAG B1 to B10 in order stopping at the first FAILED with a 500 record, seats one at a time merger first worker last, fifteen minutes counting architect nudges, line.resumed 100, flags removed last
- make line-check: B1 to B8 read-only, one line per node ok or FAILED, exit 1 on any FAILED
- herdr/bin/supervisor.sh repairs only bearings stable while the halt flag exists; docs/runbooks/line-halt-resume.md says how the owner's USERHALT and USERGO reach the commands
- cases T08, T09 and T13 of SPEC-17 s-tests as line/tests/cases/line-*.sh and the supervisor case in herdr/tests

**Out - non-goals**

- new monitoring
- the health checks (K2)
- the board (K1)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* in the test world line-halt leaves no belt or watch process, bearings stable still running, every seat up, 503 on the owner lane, and a supervisor tick repairs only bearings (T08)
- [ ] `AC-H2` *(human)* line-resume after a halt marks a stale item done with its reason, starts the system in order and routes live records once; a FAILED node stops it with a 500 and nothing below starts (T09)
- [ ] `AC-H3` *(human)* line-check prints one line per node and exits 1 on any FAILED without writing (T13)

## Test plan

```sh
make lint && make -C factory test && make -C herdr test && make -C line test, all in Podman through the repository targets
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

Cancelled `2026-10-13` - nothing shipped.

- reason: owner 03:00Z size rule: split into WO-20261013-fd7d, WO-20261013-ced5, WO-20261013-8ed9, WO-20261013-8e0c
- superseded by: `WO-20261013-fd7d`

No branch, no PR and no merge commit exist for this work order.

