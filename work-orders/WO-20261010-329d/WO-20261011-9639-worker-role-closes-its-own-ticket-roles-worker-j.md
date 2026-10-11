---
{
  "id": "WO-20261011-9639",
  "slug": "worker-role-closes-its-own-ticket-roles-worker-j",
  "title": "Worker role closes its own ticket: roles/worker.json allows work-order.sh submit and done",
  "type": "bug",
  "status": "in-progress",
  "priority": "p0",
  "created": "2026-10-11",
  "updated": "2026-10-11",
  "created_at": "2026-10-11T14:39:36+00:00",
  "parent": "WO-20261010-329d",
  "branch": "feat/worker-role-closes-its-own-ticket-roles-worker-j",
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "Claude seat; Lavish is prohibited for Claude seats by the owner hard rule, decisions recorded in the ticket note",
    "at": "2026-10-11"
  },
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

- [x] `AC-H1` *(human)* roles/worker.json allows submit and done, validates against roles/schema, and playbooks/worker.md shows both verbs
  - observed `2026-10-11` jsonschema.validate passes for every roles/*.json against roles/schema/role.schema.json; render-playbook.sh --check prints render-ok; grep counts submit 3 times in roles/worker.json and 2 in playbooks/worker.md
- [ ] `AC-H2` *(human)* a worker seat runs work-order.sh submit then done on its own branch and both succeed (proved on this ticket's own branch or a fixture ticket)
- [x] `AC-H3` *(human)* the breadcrumb at the allow line names this ticket and the three by-hand close-outs it ends
  - observed `2026-10-11` roles/worker.json breadcrumbs[0] opens with 2026-10-11 WO-20261011-9639 and names WO-20261011-c077, WO-20261011-36d7 and WO-20261011-4c5e; role.schema.json describes the field

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

- `2026-10-11` Retro: JSON role files had no place for a breadcrumb, so the schema gained an optional breadcrumbs array instead of a comment in a neighbouring file. The must line hit the 240 char cap on the first try and was shortened. Worker seats already up (616c, 38c7) run under the old settings; bypassPermissions means the deny list, not the allow list, fences them, so they can close out; their playbook copy is old until their branches rebase.

## Outcome

_Written by `work-order done`. Empty until then._
