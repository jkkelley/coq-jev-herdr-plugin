---
{
  "id": "WO-20261012-5826",
  "slug": "go-scheduler-design-one-xml-spec-per-domain-unde",
  "title": "Go scheduler design: one XML spec per domain under specs/scheduler, each at most 1000 lines, plus the build tickets cut for four Opus workers",
  "type": "feature",
  "status": "done",
  "priority": "p0",
  "created": "2026-10-12",
  "updated": "2026-10-13",
  "created_at": "2026-10-12T18:35:51+00:00",
  "parent": "WO-20261012-ea33",
  "branch": "feat/go-scheduler-design-one-xml-spec-per-domain-unde",
  "pr": 89,
  "closed": "2026-10-13",
  "approval": {
    "via": "override",
    "reason": "lavish is prohibited for Claude seats; owner order on the bearings page 2026-10-12 18:34Z, CRITICAL: Go scheduler, Fable architect team",
    "at": "2026-10-12"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": []
}
---

# WO-20261012-5826 - Go scheduler design: one XML spec per domain under specs/scheduler, each at most 1000 lines, plus the build tickets cut for four Opus workers

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

The scheduler needs a complete design before code: domains, contracts, schemas, status codes, failure and retry rules, and the DAG it schedules.

## Scope

**In**

- specs/scheduler/<domain>.xml for each domain the architect identifies (for example records intake, routing table, seat lifecycle, retries and backoff, policies and deadlines, health and supervision, config and schema, Podman runtime, observability, cut-over), each at most 1000 lines, generic and portable
- a mermaid blueprint of the scheduler and its place in the factory DAG
- build tickets cut with work-order.sh under the epic, each with disjoint files so no two open PRs share a file

**Out - non-goals**

- writing Go code (the workers build)

## Degrees of freedom

- [free] the domain split, as long as each spec stays at most 1000 lines and every route, record kind and status code in factory/config and events/schema is covered by exactly one domain

## Acceptance criteria

- [x] `AC-H1` *(human)* every specs/scheduler/*.xml parses and is at most 1000 lines
  - observed `2026-10-12` podman run --rm --network=none --userns=keep-id -v $PWD:/repo:ro,Z localhost/coq-lint:1 bash /repo/specs/scheduler/bin/check.sh check --repo /repo on commit 40825f5: ok for all 12 files (SPEC-16 overview 261 lines, A 116, B 124, C 108, D 162, E 100, F 132, G 111, H 131, I 73, J 93, K 85), each validated by xmllint against specs/scheduler/schema/scheduler-spec.xsd, every element under 240 characters, every source attribute resolving to a file, spec anchor or graph node, no forbidden pattern; lint/lint.sh in the same image: lint all ok.
- [x] `AC-H2` *(human)* every row of factory/config/routes.json and every status code is owned by exactly one domain spec
  - observed `2026-10-12` The same check prints 'ownership ok: 27 routes rows and 12 status codes each owned once': rows declared with owns-route in SPEC-16.B (12 SDLC and ignore rows), SPEC-16.D (6 attempt and escalation rows), SPEC-16.E (6 break glass rows and policy.applied), SPEC-16.F (seat.down 500 and code_gte 500); codes with owns-code in A (100), B (200, 201, 300, 409), C (429), D (422, 423), E (204, 400), F (412, 500). While D and E still failed the schema the check exited 3 naming every row and code owned by 0 specs, so a gap or a double fails the set.
- [x] `AC-H3` *(human)* the build tickets list disjoint files
  - observed `2026-10-12` 18 build tickets cut under WO-20261012-ea33 (48ab e27e 8d87 df2b 5a3d 32fe 9790 d7f4 8e69 7a9a 6e43 3c7a 1ccf b12c 379f 0113 fa36 1635), each opening its In list with an Owns line; a pairwise check of the 39 owned paths over 153 ticket pairs finds no shared path between any two tickets that can be open at once. The one nested path, scheduler/host/bin/cutover.sh under the host ticket's directory, belongs to the cut-over ticket, which depends on the host ticket, and both carry a note fixing it.

## Test plan

```sh
make lint
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-12` Retro: design only, as ordered. 12 specs under specs/scheduler with their own schema (every element with words cites a source), a check script that proves AC-H1 and AC-H2 mechanically in the lint image, 16 graph nodes, 18 build tickets in 4 waves with test plans rendered from the specs' case elements. Lessons: graph.sh add splits a source on ':' and truncates the UTC; make lint does not scan specs/scheduler until the lint ticket lands; make lint from this seat runs over 120 s, so it runs in the background. Cost: CHANGELOG.md and graph/INDEX.md ride the PR as generated aggregates.

## Outcome

_Written by `work-order done`. Empty until then._
