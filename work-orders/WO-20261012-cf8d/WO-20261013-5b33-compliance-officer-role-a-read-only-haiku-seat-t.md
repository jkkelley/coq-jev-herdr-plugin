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

- [ ] `AC-H1` *(human)* roles/compliance-officer.json validates and make lint's roles step passes with the playbook in sync
- [ ] `AC-H2` *(human)* the report schema accepts a sample report and rejects an unknown finding code, shown by a test
- [ ] `AC-H3` *(human)* the playbook names every agent as watched, the architect included, and forbids any write, nudge or fix
- [ ] `AC-H4` *(human)* make lint and make -C herdr test pass in Podman

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

## Outcome

_Written by `work-order done`. Empty until then._
