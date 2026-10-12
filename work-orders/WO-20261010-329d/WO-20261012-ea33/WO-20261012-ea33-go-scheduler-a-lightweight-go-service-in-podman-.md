---
{
  "id": "WO-20261012-ea33",
  "slug": "go-scheduler-a-lightweight-go-service-in-podman-",
  "title": "Go scheduler: a lightweight Go service in Podman on WSL schedules the small loop and the software factory DAG, designed by a Fable architect and built by four Opus workers",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T18:35:49+00:00",
  "parent": "WO-20261010-329d",
  "branch": null,
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

# WO-20261012-ea33 - Go scheduler: a lightweight Go service in Podman on WSL schedules the small loop and the software factory DAG, designed by a Fable architect and built by four Opus workers

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

The line is scheduled by bash watchers and loops (route.sh, flow.sh, policy.sh, interim scripts in a user cache) that lose wakes, retry nothing, false-alarm on stalls and need the architect by hand. Owner 2026-10-12 18:34Z, CRITICAL: build a lightweight Go scheduler, run it in Podman on WSL, spec every domain in its own XML spec of at most 1000 lines, and put it into the small loop and the factory DAG.

## Scope

**In**

- scheduler/ (Go module, Containerfile, tests) and specs/scheduler/*.xml, one spec per domain
- a Fable architect seat in its own herdr workspace that designs and routes only, and four Opus worker seats it routes tickets to
- cut-over plan from route.sh, flow.sh and policy.sh to the scheduler, behind a flag

**Out - non-goals**

- editing any file outside scheduler/ and specs/scheduler/ while another open PR touches it (owner rule 2026-10-12 18:07Z)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* every child is done and verified on main
- [ ] `AC-H2` *(human)* the scheduler runs in Podman on WSL and routes a real pr.opened to a tester with no bash watcher

## Test plan

```sh
make -C scheduler test
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
