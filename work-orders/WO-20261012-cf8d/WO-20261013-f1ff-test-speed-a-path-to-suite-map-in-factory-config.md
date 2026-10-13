---
{
  "id": "WO-20261013-f1ff",
  "slug": "test-speed-a-path-to-suite-map-in-factory-config",
  "title": "Test speed: a path-to-suite map in factory config and factory/bin/suites.sh print the suites a pull request's changed files touch; a tickets-only pull request runs lint and reindex only",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T15:50:53+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect P0 order 2026-10-13 (owner p0c28); design approved on card C29 with two conditions; lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [
    "WO-20261013-dd11"
  ],
  "files": [
    "factory/config/suites.json",
    "factory/config/suites.schema.json",
    "factory/bin/suites.sh",
    "factory/tests/cases/suites-map.test.sh"
  ]
}
---

# WO-20261013-f1ff - Test speed: a path-to-suite map in factory config and factory/bin/suites.sh print the suites a pull request's changed files touch; a tickets-only pull request runs lint and reindex only

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

Owner 2026-10-13: test suites cannot be the bottleneck. Every suite runs its cases one after another, every pull request reruns whole suites main already ran, and herdr cases wait on fixed sleeps. Design: $COQ_STATE/plans/2026/10/20261013160000-test-speed-design.md (section d-shape 1). Condition 1 of the architect's approval (card C29): a path maps to every suite that exercises it, not only the suite under it; 32fc429 changed events/bin and broke the factory suite, which a per-directory map would not have run (ruling b99ta, record 7c3dq).

## Scope

**In**

- factory/config/suites.json and suites.schema.json: rows of path pattern to every make target whose suite exercises that path, not only the suite under it: events/bin and events/schema map to the events, factory and herdr suites; bin/state-root.sh and config/ to every suite that sources them; a tickets-only set (work-orders/, changelog/) maps to make lint and work-order.sh reindex --check; a path with no row means the full set
- factory/bin/suites.sh plan --base B --head H prints one command per line; full prints the full set; exit codes per section d-codes
- factory/tests/cases/suites-map.test.sh asserts the cross-suite rows: a change to events/bin/event.sh plans events, factory and herdr

**Out - non-goals**

- the tester's role (WO-20261013-dd11)
- running the suites (verify-main.sh, WO-20261013-9bdd)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* a change to events/bin/event.sh or events/schema plans the events, factory and herdr suites, and the test fails if one is dropped
- [ ] `AC-H2` *(human)* a tickets-only diff plans lint and reindex only; an unmapped path plans the full set; a missing key exits 3

## Test plan

```sh
make lint && make -C factory test, in Podman through the repository targets
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
