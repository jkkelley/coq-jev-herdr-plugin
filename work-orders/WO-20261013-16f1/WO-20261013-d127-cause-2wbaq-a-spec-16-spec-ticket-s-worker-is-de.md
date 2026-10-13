---
{
  "id": "WO-20261013-d127",
  "slug": "cause-2wbaq-a-spec-16-spec-ticket-s-worker-is-de",
  "title": "Cause 2wbaq: a SPEC-16 spec ticket's worker is denied specs/ and graph/; a spec-author role (the worker on claude-opus-5-5 with specs/ and graph/ writable, roles/ still denied, three seats) and seat.sh picks it when every file of the ticket is under specs/ or graph/",
  "type": "bug",
  "status": "in-progress",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T16:41:50+00:00",
  "parent": "WO-20261013-16f1",
  "branch": "feat/cause-2wbaq-a-spec-16-spec-ticket-s-worker-is-de",
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect ruling 2026-10-13 on cause 2wbaq (card C29); lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261013-7af7"
  ],
  "blocks": [
    "WO-20261013-496d"
  ],
  "files": [
    "roles/spec-author.json",
    "playbooks/spec-author.md",
    "herdr/bin/seat.sh",
    "herdr/tests/cases/35-spec-author-role.test.sh"
  ]
}
---

# WO-20261013-d127 - Cause 2wbaq: a SPEC-16 spec ticket's worker is denied specs/ and graph/; a spec-author role (the worker on claude-opus-5-5 with specs/ and graph/ writable, roles/ still denied, three seats) and seat.sh picks it when every file of the ticket is under specs/ or graph/

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

Cause 2wbaq (record 20261013T163817Z-423-2wbaq): the worker role denies writes to specs/ and graph/, so a worker seated on a SPEC-16 per-file ticket is blocked and escalates 423. Spec authoring also needs the stronger model; the architect ruled the role 2026-10-13.

## Scope

**In**

- roles/spec-author.json: the worker role with model.claude claude-opus-5-5, the deny of specs/ and graph/ removed and roles/ still denied, max_seats 3; playbooks/spec-author.md rendered by roles/bin/render-playbook.sh
- herdr/bin/seat.sh seats a ticket's worker as spec-author when every file in the ticket's files field is under specs/ or graph/, else worker; a breadcrumb names this cause
- herdr/tests/cases/35-spec-author-role.test.sh: a ticket whose files are all under specs/ and graph/ seats spec-author; a mixed ticket seats worker

**Out - non-goals**

- any other role's permissions
- herdr max_agents (WO-20261013-a1c6)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* a SPEC-16 per-file ticket seats spec-author on claude-opus-5-5 and its worker can write specs/ and graph/ but not roles/; the playbook check in lint reports no drift; the case passes

## Test plan

```sh
make lint && make -C herdr test, in Podman through the repository targets (lint runs the playbook drift check)
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
