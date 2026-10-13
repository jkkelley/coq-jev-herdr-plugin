---
{
  "id": "WO-20261013-f1ff",
  "slug": "test-speed-a-path-to-suite-map-in-factory-config",
  "title": "Test speed: a path-to-suite map in factory config and factory/bin/suites.sh print the suites a pull request's changed files touch; a tickets-only pull request runs lint and reindex only",
  "type": "feature",
  "status": "done",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T15:50:53+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": "feat/test-speed-a-path-to-suite-map-in-factory-config",
  "pr": 109,
  "closed": "2026-10-13",
  "approval": {
    "via": "override",
    "reason": "architect P0 order 2026-10-13 (owner p0c28), design approved on card C29; re-cut for runnable plans and NN- case names; lavish prohibited for Claude seats",
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
    "factory/tests/cases/19-suites-map.test.sh"
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

- factory/config/suites.json and suites.schema.json: rows of path pattern to every suite command that exercises that path, not only the suite under it: events/bin and events/schema map to the events, factory and herdr suites; bin/state-root.sh and config/ to every suite that sources them; a tickets-only set (work-orders/, changelog/) maps to make lint and work-order.sh reindex --check; a path with no row means the full set; every command named exists (events runs as bash events/tests/run.sh, which has no Makefile)
- factory/bin/suites.sh plan --base B --head H prints one command per line; full prints the full set; exit codes per section d-codes
- factory/tests/cases/19-suites-map.test.sh asserts the cross-suite rows: a change to events/bin/event.sh plans events, factory and herdr

**Out - non-goals**

- the tester's role (WO-20261013-dd11)
- running the suites (verify-main.sh, WO-20261013-9bdd)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [x] `AC-H1` *(human)* a change to events/bin/event.sh or events/schema plans the events, factory and herdr suites, and the test fails if one is dropped
  - observed `2026-10-13` factory/tests/cases/19-suites-map.test.sh (51 checks, make -C factory test CASES=19, tests: 1 passed 0 failed): events/bin/event.sh and events/schema plan events, factory, herdr (and line, whose merge.sh calls event.sh); a copy of the map with herdr dropped from the events/bin row plans no herdr, which the case asserts, so dropping it fails the case
- [x] `AC-H2` *(human)* a tickets-only diff plans lint and reindex only; an unmapped path plans the full set; a missing key exits 3
  - observed `2026-10-13` same case: a diff of work-orders/ and changelog/ files plans exactly 'make lint' then 'work-order.sh reindex --check' with nothing on stderr; Jenkinsfile (no row) and Jenkinsfile among mapped paths plan the full set of 11 commands and stderr names the path; each of commands, always, full and rows removed exits 3 naming the key; make lint passes (lint: all ok) incl. suites.json against suites.schema.json

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

- `2026-10-13` Retro: reading what each suite copies found two things the ticket text did not name: line's merge.sh calls event.sh and state-root.sh (line joins the events rows), and scheduler/host/tests/run.sh is a suite make -C scheduler test never runs (new suite scheduler-host, caught by the case that lists suites on disk). Rows union, a path no row matches plans the full set. Not done, outside the files field: factory/RUNBOOK.md does not yet describe suites.sh (the tester ticket WO-20261013-dd11 reads it).

## Outcome

_Written by `work-order done`. Empty until then._
