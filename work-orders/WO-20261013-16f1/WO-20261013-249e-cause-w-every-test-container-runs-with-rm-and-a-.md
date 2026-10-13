---
{
  "id": "WO-20261013-249e",
  "slug": "cause-w-every-test-container-runs-with-rm-and-a-",
  "title": "Cause w: every test container runs with --rm and a coq.run label, and a reaper removes coq.run containers older than the suite budget",
  "type": "bug",
  "status": "ready",
  "priority": "p1",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T20:19:47+00:00",
  "parent": "WO-20261013-16f1",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect orders 20:31Z (cause w stale containers, cause x claims blind to slots); approved by the architect in the owner place",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [],
  "files": [
    "bin/test-cases.sh",
    "line/bin/reap-containers.sh",
    "line/tests/cases/reap-containers.test.sh"
  ]
}
---

# WO-20261013-249e - Cause w: every test container runs with --rm and a coq.run label, and a reaper removes coq.run containers older than the suite budget

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

Four test containers from the 03:32Z crash (coq-herdr-test 929c91e2b026 and 29c1f543ac4b, coq-factory-test ba65e0cc1e3a, a coq-lint one) were still Up 17 hours at 20:19Z, holding slot mounts and memory. Nothing removes a container whose runner died.

## Scope

**In**

- bin/test-cases.sh and the suite runners: podman run with --rm and --label coq.run=<suite>:<epoch>
- line/bin/reap-containers.sh: remove coq.run containers older than the suite budget from config, log each removal, retry 3 times then report
- line/tests/cases/reap-containers.test.sh: a labelled container past its budget is removed, a younger one and an unlabelled one are kept

**Out - non-goals**

- containers of other tools (no coq.run label are never touched)

## Degrees of freedom

- [free] Where the budget table lives (factory/config/suites.json budget field)

## Acceptance criteria

- [ ] `AC-H1` *(human)* Every test container carries --rm and a coq.run label
- [ ] `AC-H2` *(human)* The reaper removes only labelled containers past budget

## Test plan

```sh
bash line/tests/cases/reap-containers.test.sh
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
