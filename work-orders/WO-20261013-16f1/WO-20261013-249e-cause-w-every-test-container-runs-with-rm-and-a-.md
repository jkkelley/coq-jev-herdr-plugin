---
{
  "id": "WO-20261013-249e",
  "slug": "cause-w-every-test-container-runs-with-rm-and-a-",
  "title": "Cause w: every test container runs with --rm and a coq.run label, and a reaper removes coq.run containers older than the suite budget",
  "type": "bug",
  "status": "ready",
  "priority": "p1",
  "created": "2026-10-13",
  "updated": "2026-10-14",
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
  "depends_on": [
    "WO-20261013-0bc0",
    "WO-20261012-41a3"
  ],
  "blocks": [
    "WO-20261013-fd7d",
    "WO-20261013-74b6",
    "WO-20261013-7757",
    "WO-20261014-9803"
  ],
  "files": [
    "bin/test-cases.sh",
    "events/tests/run.sh",
    "factory/tests/run.sh",
    "herdr/tests/run.sh",
    "line/tests/run.sh",
    "report/loop/tests/run.sh",
    "scheduler/host/tests/run.sh",
    "tools/bearings/tests/run-tests.sh",
    "Makefile"
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

- bin/test-cases.sh (WO-20261013-0bc0 - Test speed: one shared case runner, merged and done) and the podman run sites of the suite runners: events/tests/run.sh, factory/tests/run.sh, herdr/tests/run.sh, line/tests/run.sh, report/loop/tests/run.sh, scheduler/host/tests/run.sh, tools/bearings/tests/run-tests.sh and the lint run in Makefile: podman run with --rm and --label coq.run=<suite>:<epoch>
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

- `2026-10-14` Duplicate audit ruling 2026-10-13T23:55Z (F13): split. This ticket keeps only the labels and --rm change: podman run with --rm and --label coq.run=<suite>:<epoch> at the run sites in bin/test-cases.sh, the seven suite runners and the lint run in Makefile; AC-H1 only. The reaper line/bin/reap-containers.sh and line/tests/cases/reap-containers.test.sh with AC-H2 move to a ticket of their own that depends on this one. Order on the shared runner files and Makefile: WO-20261013-9040, WO-20261012-41a3, this ticket, then WO-20261013-74b6, WO-20261013-7757 and WO-20261013-fd7d.

## Outcome

_Written by `work-order done`. Empty until then._
