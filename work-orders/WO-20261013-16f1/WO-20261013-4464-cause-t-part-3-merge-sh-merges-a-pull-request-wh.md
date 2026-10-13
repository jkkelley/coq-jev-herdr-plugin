---
{
  "id": "WO-20261013-4464",
  "slug": "cause-t-part-3-merge-sh-merges-a-pull-request-wh",
  "title": "Cause t, part 3: merge.sh merges a pull request whatever its fence verdict; it refuses one that gate.sh pr-fence holds and posts the hold to the orchestrator lane",
  "type": "bug",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T20:02:21+00:00",
  "parent": "WO-20261013-16f1",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect ruling 2026-10-13 20:12Z (causes t and u); lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261013-2298",
    "WO-20261013-6463"
  ],
  "blocks": [],
  "files": [
    "line/bin/merge.sh",
    "line/tests/cases/merge-fence.sh"
  ]
}
---

# WO-20261013-4464 - Cause t, part 3: merge.sh merges a pull request whatever its fence verdict; it refuses one that gate.sh pr-fence holds and posts the hold to the orchestrator lane

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

A gate verb nobody runs is not a control. The merger is the last step before main, so merge.sh is where the fence verdict must stop a merge (cause t, ruling 20:12Z 2026-10-13).

## Scope

**In**

- line/bin/merge.sh runs gate.sh pr-fence for the ticket before it merges; on exit 1 it does not merge and posts one hold record with the fenced paths to the orchestrator lane; on exit 4 it retries up to 3 times, then posts a 500
- line/tests/cases/merge-fence.sh: a held fence leaves the pull request unmerged with one record, a clean fence merges

**Out - non-goals**

- the verb itself (part 2)
- the merge hold file (cause l) and the newest-gate rule (cause m), which this follows

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* the case passes and fails when the call is removed; make lint and make -C line test pass

## Test plan

```sh
make lint && make -C line test, in Podman through the repository targets
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-13` WO-20261013-3217 (CI gate 3, pull request 130) also edits line/bin/merge.sh; the depends_on edge is written once pull request 130 merges; until then claims.sh start keeps the two apart. Whichever lands second keeps the fence refusal.

## Outcome

_Written by `work-order done`. Empty until then._
