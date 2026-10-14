---
{
  "id": "WO-20261014-9803",
  "slug": "cause-w-part-2-line-bin-reap-containers-sh-remov",
  "title": "Cause w, part 2: line/bin/reap-containers.sh removes coq.run containers older than the suite budget, logs each removal, retries 3 times then reports",
  "type": "bug",
  "status": "ready",
  "priority": "p1",
  "created": "2026-10-14",
  "updated": "2026-10-14",
  "created_at": "2026-10-14T00:06:25+00:00",
  "parent": "WO-20261013-16f1",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "duplicate audit split 2026-10-13T23:55Z: the reaper half of WO-20261013-249e, ruled by the architect",
    "at": "2026-10-14"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261013-249e"
  ],
  "blocks": [],
  "files": [
    "line/bin/reap-containers.sh",
    "line/tests/cases/reap-containers.test.sh"
  ]
}
---

# WO-20261014-9803 - Cause w, part 2: line/bin/reap-containers.sh removes coq.run containers older than the suite budget, logs each removal, retries 3 times then reports

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

Split from WO-20261013-249e by the duplicate audit (2026-10-13T23:55Z), which declared 11 files and broke the a-few-files size rule. Four test containers from the 03:32Z crash were still Up 17 hours at 20:19Z, holding slot mounts and memory, and nothing removes a container whose runner died. WO-20261013-249e labels every test container with coq.run=<suite>:<epoch> and --rm; this ticket is the reaper that uses the label.

## Scope

**In**

- line/bin/reap-containers.sh: remove coq.run containers older than the suite budget from config, log each removal, retry 3 times then report
- line/tests/cases/reap-containers.test.sh: a labelled container past its budget is removed, a younger one and an unlabelled one are kept

**Out - non-goals**

- labelling the containers and the --rm flag (WO-20261013-249e)
- containers of other tools: no coq.run label are never touched

## Degrees of freedom

- [free] where the budget table lives, as long as it is config and not a literal in the script (factory/config/suites.json budget field is one place)

## Acceptance criteria

- [ ] `AC-H1` *(human)* the reaper removes only labelled containers past budget

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
