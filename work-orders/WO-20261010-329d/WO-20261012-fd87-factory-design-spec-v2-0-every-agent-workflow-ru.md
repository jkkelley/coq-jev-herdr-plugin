---
{
  "id": "WO-20261012-fd87",
  "slug": "factory-design-spec-v2-0-every-agent-workflow-ru",
  "title": "Factory design spec v2.0: every agent, workflow, runbook, SOP, schema and status code of the small loop and the software factory, generic and portable",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T17:59:06+00:00",
  "parent": "WO-20261010-329d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "lavish is prohibited for Claude seats; owner answered card C7 on the bearings page 2026-10-12 17:58Z: yes, v2.0 now, side agent asap",
    "at": "2026-10-12"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": []
}
---

# WO-20261012-fd87 - Factory design spec v2.0: every agent, workflow, runbook, SOP, schema and status code of the small loop and the software factory, generic and portable

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

specs/exports/factory-spec.xml v1.1.0 (303 rules, sections S1 to S6) predates the 2026-10-12 merges (belt seats the line, standing policies, supervisor, SITREP, break glass) and holds rules only, not the full agents, workflows and procedures. The owner needs a complete, portable spec for work (card C7, 2026-10-12 17:58Z: yes, v2.0 now).

## Scope

**In**

- specs/exports/factory-spec.xml v2.0.0 rebuilt from origin/main: sections S1 small loop, S2 big loop, S3 herdr, S4 a2a, S5 determinism, S6 port notes, plus S7 agents (every role file in full: model, effort, permissions, inputs, outputs, records, wakes_on, playbook steps), S8 workflows (every routes.json row as an edge, with mermaid in a CDATA block), S9 runbooks and SOPs (every RUNBOOK.md and docs/sops step list, in order), S10 schemas and status codes (record, role, routes, status code table)
- a generic copy rule: no hostnames, no /home paths, no keys, no owner PII, no ticket ids as requirements; each element under 240 chars; every rule cites its source file
- a lint or test that parses the XML, checks the 240-char limit and greps for /home/, localhost keys and email addresses

**Out - non-goals**

- changing any code, role, playbook or runbook the spec describes
- open PRs not yet on main

## Degrees of freedom

- [free] element names inside each new section, as long as S1 to S6 keep v1.1.0 ids where the rule still holds
- [free] where the check lives, as long as make lint or make test runs it

## Acceptance criteria

- [ ] `AC-H1` *(human)* factory-spec.xml version 2.0.0 parses with xmllint and has sections S1 to S10
- [ ] `AC-H2` *(human)* every file under roles/*.json, playbooks/*.md, factory/config/routes.json, docs/sops/*.md and every RUNBOOK.md is cited by at least one element
- [ ] `AC-H3` *(human)* the check finds no /home/ path, no bearings key, no email address and no element over 240 chars
- [ ] `AC-H4` *(human)* the owner reads it on the page and accepts it (human)

## Test plan

```sh
make lint && make test
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
