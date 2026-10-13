---
{
  "id": "WO-20261013-a91a",
  "slug": "orchestrator-role-and-playbook-the-seat-rules-on",
  "title": "Orchestrator role and playbook: the seat rules on the findings the code raises; the line duties O1 to O7 are named as the scheduler's, with the interim command for each (K3 shrunk to a shim)",
  "type": "feature",
  "status": "ready",
  "priority": "p1",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T03:29:11+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "owner 2026-10-13 03:00Z (record 57h60) size rule and 02:50Z (lvvtd) SPEC-16 is the engine; lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [],
  "files": [
    "roles/orchestrator.json",
    "playbooks/orchestrator.md"
  ]
}
---

# WO-20261013-a91a - Orchestrator role and playbook: the seat rules on the findings the code raises; the line duties O1 to O7 are named as the scheduler's, with the interim command for each (K3 shrunk to a shim)

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

WO-20261013-14f9 (Roadmap K3 - Orchestrator seat) would build line/bin/orchestrate.sh, whose duties are SPEC-16 B, C, D and F (owner 02:50Z: not new bash). The size rule of 03:00Z and the shim flag shrink it to the role and its playbook.

## Scope

**In**

- roles/orchestrator.json: purpose is rulings on findings and acting through existing commands; the must list names O1 to O7 with the SPEC-16 section that owns each and the interim command (seat.sh --down, work-order cleanup, gh) until the scheduler is active
- playbooks/orchestrator.md re-rendered by roles/bin/render-playbook.sh, never by hand

**Out - non-goals**

- line/bin/orchestrate.sh (superseded by SPEC-16 B, C, D and F)
- rulings for the owner

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* the role validates against roles/schema/role.schema.json and the playbook passes render-playbook --check
- [ ] `AC-H2` *(human)* make lint passes

## Test plan

```sh
make lint, in Podman through the repository target
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
