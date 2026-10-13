---
{
  "id": "WO-20261013-5b33",
  "slug": "compliance-officer-role-a-read-only-haiku-seat-t",
  "title": "Compliance officer role: a read-only Haiku seat that reads every agent's screen, the architect's included, and reports each stuck, refused, idle or rule-breaking agent to the system as a schema-checked record",
  "type": "feature",
  "status": "in-progress",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T01:05:15+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": "feat/compliance-officer-role-a-read-only-haiku-seat-t",
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "owner order on Getting My Bearings 2026-10-13 01:03Z; lavish is prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [],
  "files": [
    "roles/compliance-officer.json",
    "playbooks/compliance-officer.md",
    "roles/schema/compliance-report.schema.json",
    "roles/tests/*"
  ]
}
---

# WO-20261013-5b33 - Compliance officer role: a read-only Haiku seat that reads every agent's screen, the architect's included, and reports each stuck, refused, idle or rule-breaking agent to the system as a schema-checked record

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

Owner 2026-10-13 01:01Z to 01:03Z: two testers sat up to 40 minutes on a refused git command and nobody noticed. 'have an haiku agent with specific RO only instructions that they're to be a tattle tale, have them do it and report to the system'; 'create that tattle tale agent with a schema too, i want it re-used and i want it fucking ratting out all you fucks'; 'its like my little compliance officer'. Interim: the monitor seat was briefed and herdr/bin/turnwatch.sh runs with COQ_HERDR_CONFIG pointing watches.architect_agent at it.

## Scope

**In**

- roles/compliance-officer.json, valid against roles/schema/role.schema.json: runtime claude, model claude-haiku-5-5, read_only true, allow only herdr pane read and list, herdr agent list and get, and events/bin/event.sh add; deny Write, Edit, Agent, git, gh, and herdr agent prompt (it reports, it never nudges or fixes); wakes on a seat turn ending and on a timed patrol
- playbooks/compliance-officer.md rendered from the role as the other playbooks are, with the exact judgement list: waiting on a question or menu, a refused or denied tool, a stopped error, idle while it owes a record its playbook names, the same step looped, a broken AGENTS.md law seen on screen (a background job, a Monitor tool under an agent, a hand edit outside its files, prose or a question to the owner outside a card); every agent is watched, the architect and the orchestrator included
- roles/schema/compliance-report.schema.json: the report record (seat, ticket, pane, finding code from a closed list, what was seen in one line, evidence lines, first seen and last seen UTC) and a finding-code map (code, meaning, who acts); one report per seat per finding, never repeated
- a test that the role and the report schema validate, the playbook is in sync, and a sample report validates while one with an unknown finding code fails

**Out - non-goals**

- wiring the watch into bringup and the orchestrator acting on reports (Roadmap K, SPEC-17 K2 and K3)
- any power to change, nudge or stop a seat

## Degrees of freedom

- [free] the finding-code names, as long as the list is closed, each maps to who acts, and 'architect broke a law' is one of them

## Acceptance criteria

- [x] `AC-H1` *(human)* roles/compliance-officer.json validates and make lint's roles step passes with the playbook in sync
  - observed `2026-10-13` make lint in Podman from the test pane: 'roles: schema + playbooks in sync ok', 'lint: all ok'; roles/tests/compliance-officer.test.sh: 'role validates against role.schema.json' and 'playbook in sync with the role (render --check)' ok
- [x] `AC-H2` *(human)* the report schema accepts a sample report and rejects an unknown finding code, shown by a test
  - observed `2026-10-13` roles/tests/compliance-officer.test.sh, 60 passed 0 failed: 'sample report validates' ok; 'unknown finding code fails', 'wrong who-acts for a finding fails', 'missing evidence fails', 'an extra field fails' all refused; each refusal first checks the variant file parses
- [x] `AC-H3` *(human)* the playbook names every agent as watched, the architect included, and forbids any write, nudge or fix
  - observed `2026-10-13` playbooks/compliance-officer.md: 'the architect and the orchestrator are in the list and are read like any other', Forbidden opens 'any write, edit or file change', 'any nudge', 'any fix'; deny list holds Write, Edit, NotebookEdit, Agent, Task, git *, gh *, herdr agent prompt, herdr pane run, send-text, send-keys, close; tests assert each
- [x] `AC-H4` *(human)* make lint and make -C herdr test pass in Podman
  - observed `2026-10-13` from the test pane: make lint 'lint: all ok'; make -C herdr test 'tests: 27 passed, 0 failed' including 23-compliance-officer and 24-patrolwatch (three ticks, three '> PATROL' prompts heard); EXIT=0 for both

## Test plan

```sh
make lint && make -C herdr test, in Podman through the repository targets
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-13` Retro. Went well: the role file as data carried the checklist and the GOOD/NEVER lines without touching the renderer, which the worker fence denies. Went badly: steps are capped at 240 characters so the 13 GOOD examples render as numbered steps beside the checklist; a renderer extension with an examples section would read better and is the architect's file. First slot I picked, 4.1.4, does not exist in the 3-wide grid and broke case 17-pane-health; caught by running the subset before the full suite. A herdr stub echoes a prompt twice (tty echo plus the stub's own line), so case 24 counts '^> PATROL' lines. Tick waits: patrolwatch skips a tick while the officer is busy, so a hung officer is silent until the supervisor's alive check.
- `2026-10-13` Files beyond the ticket's list, all needed by the above: roles/schema/role.schema.json (name enum gains compliance-officer, or lint rejects the role), herdr/bin/patrolwatch.sh, herdr/config/herdr.json and herdr.schema.json (patrol_seconds, compliance_agent), herdr/config/monitors.json (slot 4.2.1; 4.1.4 does not exist in the 3-wide grid and broke case 17-pane-health), herdr/tests/cases/23-compliance-officer.test.sh and 24-patrolwatch.test.sh. No open PR touches any of them. Left for Roadmap K: the orchestrator and the maintenance worker acting on reports, and a maintenance-worker role (none exists yet, so acts=maintenance-worker is a lane name only); the officer cannot read prior reports to dedupe (the ticket's allow list has no event.sh list), so one report per key rests on its own context and the consumer dropping a repeated key.
- `2026-10-13` Scope added by the architect, owner question 'isn't the tattle tale on some kind of 1 min loop?': the officer patrols on a 1-minute tick driven by the system, reads every agent's screen each tick, and checks each line process of the restart runbook runs exactly once; a hung seat or dead process is reported within one tick; findings go to the orchestrator lane, process findings to the maintenance worker. Done: herdr/bin/patrolwatch.sh (watches.patrol_seconds 60, watches.compliance_agent, reserved slot 4.2.1 in monitors.json), finding codes CO-HUNG, CO-PROC-DEAD, CO-PROC-DUPLICATE, playbook tick and checklist and GOOD/NEVER for all 13 codes, herdr case 24 for the tick.
- `2026-10-13` Scope added by the architect, owner order 01:05Z: the playbook carries a checklist for every patrol, names every script and command the officer uses (herdr/bin/turnwatch.sh with COQ_HERDR_CONFIG pointing watches.architect_agent at it) and gives a GOOD and a NEVER example for every finding code. Owner quotes: 'checklist, the scripts you use, etc, everything', 'use GOOD and NEVER for examples'. Done: the role file holds them as data and the playbook is rendered from it.

## Outcome

_Written by `work-order done`. Empty until then._
