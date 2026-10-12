---
{
  "id": "WO-20261012-5826",
  "slug": "go-scheduler-design-one-xml-spec-per-domain-unde",
  "title": "Go scheduler design: one XML spec per domain under specs/scheduler, each at most 1000 lines, plus the build tickets cut for four Opus workers",
  "type": "feature",
  "status": "in-progress",
  "priority": "p0",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T18:35:51+00:00",
  "parent": "WO-20261012-ea33",
  "branch": "feat/go-scheduler-design-one-xml-spec-per-domain-unde",
  "pr": null,
  "closed": null,
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

- [ ] `AC-H1` *(human)* every specs/scheduler/*.xml parses and is at most 1000 lines
- [ ] `AC-H2` *(human)* every row of factory/config/routes.json and every status code is owned by exactly one domain spec
- [ ] `AC-H3` *(human)* the build tickets list disjoint files

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

## Outcome

_Written by `work-order done`. Empty until then._
