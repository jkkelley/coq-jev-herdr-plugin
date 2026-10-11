---
{
  "id": "WO-20261011-9639",
  "slug": "worker-role-closes-its-own-ticket-roles-worker-j",
  "title": "Worker role closes its own ticket: roles/worker.json allows work-order.sh submit and done",
  "type": "bug",
  "status": "draft",
  "priority": "p0",
  "created": "2026-10-11",
  "updated": "2026-10-11",
  "created_at": "2026-10-11T14:39:36+00:00",
  "parent": "WO-20261010-329d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": null,
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [
    "WO-20261011-fa78"
  ]
}
---

# WO-20261011-9639 - Worker role closes its own ticket: roles/worker.json allows work-order.sh submit and done

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

roles/worker.json allows work-order.sh note and evidence but not submit or done, so every ticket reaches its PR still in progress and the architect closes it from main by hand, playing reviewer and merger (c077, 36d7, 4c5e)

## Scope

**In**

- roles/worker.json allow.commands gains work-order.sh submit and work-order.sh done
- playbooks/worker.md re-rendered from the role
- SPEC-02 draft note if it lists the verbs

**Out - non-goals**

- reviewer and merger seats
- the route runner

## Degrees of freedom

- [free] the exact allow pattern, as long as roles/schema validates it and the rendered playbook shows both verbs

## Acceptance criteria

- [ ] `AC-H1` *(human)* roles/worker.json allows submit and done, validates against roles/schema, and playbooks/worker.md shows both verbs
- [ ] `AC-H2` *(human)* a worker seat runs work-order.sh submit then done on its own branch and both succeed (proved on this ticket's own branch or a fixture ticket)
- [ ] `AC-H3` *(human)* the breadcrumb at the allow line names this ticket and the three by-hand close-outs it ends

## Test plan

```sh
make lint grep -c 'work-order.sh submit\|work-order.sh done' roles/worker.json playbooks/worker.md
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
