---
{
  "id": "WO-20261013-e880",
  "slug": "cause-2wbaq-part-2-seat-sh-seats-a-ticket-s-work",
  "title": "Cause 2wbaq, part 2: seat.sh seats a ticket's worker as spec-author when every file of the ticket is under specs/, graph/, roles/ or playbooks/",
  "type": "bug",
  "status": "draft",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-14",
  "created_at": "2026-10-13T20:58:19+00:00",
  "parent": "WO-20261013-16f1",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": null,
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261013-a0e2",
    "WO-20261013-d127",
    "WO-20261013-d0dd"
  ],
  "blocks": [
    "WO-20261012-6f13"
  ],
  "files": [
    "herdr/bin/seat.sh",
    "herdr/tests/cases/35-spec-author-role.test.sh"
  ]
}
---

# WO-20261013-e880 - Cause 2wbaq, part 2: seat.sh seats a ticket's worker as spec-author when every file of the ticket is under specs/, graph/, roles/ or playbooks/

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

WO-20261013-d127 added the spec-author role but left the automatic pick out of its pull request, because WO-20261013-a0e2 edits the same herdr/bin/seat.sh block and no file is touched by two open PRs. Until the pick lands a spec ticket is seated only by hand with seat.sh --ticket T --role spec-author, so AC-H1 of WO-20261013-d127 (a SPEC-16 per-file ticket seats spec-author) holds only for the manual flag.

## Scope

**In**

- herdr/bin/seat.sh: when the role is worker and the ticket's files field is non-empty and every file is under specs/, graph/, roles/ or playbooks/ (playbooks/ because a role change re-renders its playbook), the seat is spec-author, else worker; an explicit --role always wins; a breadcrumb names cause 2wbaq
- herdr/tests/cases/35-spec-author-role.test.sh: pick assertions - an all-spec ticket seated with no --role is spec-author on claude-opus-5-5, a mixed ticket and a ticket with no files stay worker

**Out - non-goals**

- the spec-author role itself, its playbook and the schema enum (WO-20261013-d127, already merged by then)
- any other role's permissions

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* a ticket whose every file is under specs/, graph/, roles/ or playbooks/ is seated by seat.sh with no --role flag as spec-author on claude-opus-5-5, a mixed ticket is seated as worker, and the case fails without the pick

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
