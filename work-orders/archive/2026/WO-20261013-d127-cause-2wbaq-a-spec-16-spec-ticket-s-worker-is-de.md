---
{
  "id": "WO-20261013-d127",
  "slug": "cause-2wbaq-a-spec-16-spec-ticket-s-worker-is-de",
  "title": "Cause 2wbaq: a SPEC-16 spec ticket's worker is denied specs/ and graph/; a spec-author role (the worker on claude-opus-5-5 with specs/ and graph/ writable, roles/ still denied, three seats) and seat.sh picks it when every file of the ticket is under specs/ or graph/",
  "type": "bug",
  "status": "done",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T16:41:50+00:00",
  "parent": "WO-20261013-16f1",
  "branch": "feat/cause-2wbaq-a-spec-16-spec-ticket-s-worker-is-de",
  "pr": 136,
  "closed": "2026-10-13",
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
    "WO-20261013-496d",
    "WO-20261013-e880"
  ],
  "files": [
    "roles/spec-author.json",
    "playbooks/spec-author.md",
    "roles/schema/role.schema.json",
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

- [x] `AC-H1` *(human)* a SPEC-16 per-file ticket seats spec-author on claude-opus-5-5 and its worker can write specs/ and graph/ but not roles/; the playbook check in lint reports no drift; the case passes
  - observed `2026-10-13` herdr case 35 in Podman (state root test-output/2026/10/20261013200845-d127-herdr-cases.log): seat.sh --ticket T --role spec-author on a ticket whose every file is under specs/ and graph/ seats worker-wo-20261013-35a1 as spec-author, claude started with --model claude-opus-5-5, settings deny no edit under specs/, graph/ or roles/ (roles/ writable per architect ruling 19:55Z); a mixed ticket worker still denies all three; tests: 3 passed, 0 failed with cases 01 and 26. make lint: all ok, roles: schema + playbooks in sync (no drift). The automatic pick from the ticket files is the follow-up after WO-20261013-a0e2 (see the scope-split note).

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

- `2026-10-13` Rework of PR 136 (review finding: AC-H1 and Scope promise the seat.sh pick but the PR deferred it and cut no follow-up). The pick cannot land in this PR: WO-20261013-a0e2 - Cause f: the belt cannot seat the tester and reviewer for a tickets pull request, because the ticket's branch is null; seat.sh takes the head branch from the pull request (PR 135, still open) edits the same herdr/bin/seat.sh and no file is touched by two open PRs. The follow-up is now cut as WO-20261013-e880 - Cause 2wbaq, part 2: seat.sh seats a ticket's worker as spec-author when every file of the ticket is under specs/, graph/, roles/ or playbooks/ (depends_on WO-20261013-a0e2 and this ticket; files herdr/bin/seat.sh and herdr/tests/cases/35-spec-author-role.test.sh; draft, awaiting the architect's approve). Scope In bullet 2 (seat.sh) and the AC-H1 clause 'a SPEC-16 per-file ticket seats spec-author' are met here only for the explicit seat.sh --role spec-author; the automatic pick is delivered by WO-20261013-e880.
- `2026-10-13` Retro: the role is a jq derivation of roles/worker.json, so its shape cannot drift from the worker; case 35 pins the fence by the rendered settings, not by the playbook text. Change next time: claims.sh start must see tickets live in treehouse slots (cause posted to the architect); a harness Edit on a tracked JSON file reflowed the whole schema through a formatter hook, so JSON edits go through sed or jq.
- `2026-10-13` Bootstrap spec-author seat architect-you-are-the-spec-df73 (architect fence allows roles/), after worker-wo-20261013-d127 was denied roles/ (record 20261013T194359Z-423-kihec). Architect ruling 19:55Z applied: spec-author is the role for specs/, graph/ and roles/ changes, so its deny.paths is empty. Label worker-${ticket}, so route.sh seat_of, flow.sh and the patrol reach the seat (breadcrumb in roles/spec-author.json). Scope split: WO-20261013-a0e2 is live in slot 3 with an uncommitted edit to the same herdr/bin/seat.sh block, started 13 s after this ticket because claims.sh start cannot see treehouse slots, and no file is touched by two open PRs. So herdr/bin/seat.sh left this ticket files and the automatic pick is a follow-up after WO-20261013-a0e2 merges: seat.sh seats --role worker as spec-author when every file of the ticket is under specs/, graph/, roles/ or playbooks/ (playbooks/ because a role change re-renders its playbook), and case 35 gains the pick assertions. roles/schema/role.schema.json joined the files for the name enum. Until the pick lands, seat a spec ticket with seat.sh --ticket T --role spec-author.

## Outcome

_Written by `work-order done`. Empty until then._
