---
{
  "id": "WO-20261013-9c50",
  "slug": "capacity-and-gate-models-max-agents-8-to-16-in-t",
  "title": "Capacity and gate models: max_agents 8 to 16 in the herdr config, the tester and merger roles on claude-sonnet-5-5 instead of claude-haiku-5-5 with their playbooks re-rendered, and a test that pins both",
  "type": "chore",
  "status": "cancelled",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T02:23:51+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": null,
  "pr": null,
  "closed": "2026-10-13",
  "approval": {
    "via": "override",
    "reason": "owner card C27 (record gxmaw), all four levers; lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [],
  "files": [
    "herdr/config/herdr.json",
    "roles/tester.json",
    "roles/merger.json",
    "playbooks/tester.md",
    "playbooks/merger.md",
    "herdr/tests/cases/*capacity*"
  ],
  "superseded_by": "WO-20261013-a1c6"
}
---

# WO-20261013-9c50 - Capacity and gate models: max_agents 8 to 16 in the herdr config, the tester and merger roles on claude-sonnet-5-5 instead of claude-haiku-5-5 with their playbooks re-rendered, and a test that pins both

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

Card C27 (record gxmaw, 2026-10-13): four tickets at once need workers, testers, a reviewer, a merger and the fixed seats, and the cap of eight kept refusing seats (a reviewer at 23:23Z and a merger at 23:31Z on 2026-10-12, the line idle seventeen minutes); the Haiku testers and merger sat forty minutes thinking Bash was off, searched the whole disk and said OK to everything (owner 01:01Z and 01:40Z). The owner pulled both levers: the cap to sixteen, the tester and merger on Sonnet.

## Scope

**In**

- herdr/config/herdr.json: max_agents 16 (herdr.schema.json allows up to 32); a breadcrumb comment is impossible in JSON, so the reason lives in the test case's header
- roles/tester.json and roles/merger.json: model.claude claude-sonnet-5-5, architect_may_override kept; playbooks/tester.md and playbooks/merger.md re-rendered by roles/bin/render-playbook.sh, never by hand
- one herdr test case herdr/tests/cases/*capacity* that reads the shipped config and roles and pins max_agents 16, the two models, and that the schema still validates; its header carries the breadcrumb: what broke, why these values, what it costs (more live agents per host)

**Out - non-goals**

- the reviewer's and the worker's models
- the loop budgets and per-loop caps, which the SPEC-17 1.1.0 design ticket owns
- any restart or re-seat of a live seat

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* herdr/config/herdr.json validates against its schema with max_agents 16 and make lint passes in Podman
- [ ] `AC-H2` *(human)* both roles say claude-sonnet-5-5 and render-playbook --check passes with the re-rendered playbooks
- [ ] `AC-H3` *(human)* the new herdr case pins all three values and make -C herdr test passes in Podman

## Test plan

```sh
make lint && make -C herdr test, in Podman through the repository targets
```

## Assumptions

1. pull request 86 (WO-20261013-5b33, the compliance officer) holds herdr/config/herdr.json today; this ticket starts when it merges unless the architect folds the one-key change into that pull request; no other open pull request holds these files (checked 2026-10-13 02:15Z)

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

Cancelled `2026-10-13` - nothing shipped.

- reason: split under the size rule into three parts: max_agents, gate models, reviewer seats (architect ruling: reviewer max_seats 2 to 4)
- superseded by: `WO-20261013-a1c6`

No branch, no PR and no merge commit exist for this work order.

