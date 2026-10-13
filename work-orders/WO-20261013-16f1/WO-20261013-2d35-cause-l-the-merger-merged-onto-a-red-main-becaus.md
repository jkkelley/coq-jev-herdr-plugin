---
{
  "id": "WO-20261013-2d35",
  "slug": "cause-l-the-merger-merged-onto-a-red-main-becaus",
  "title": "Cause l: the merger merged onto a red main because the hold lived in prose; merge.sh refuses while the merge hold file exists (cause j's hold)",
  "type": "bug",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T16:37:29+00:00",
  "parent": "WO-20261013-16f1",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect P0 order 2026-10-13 (owner m-20261013162710557-e4nos: always a system loop), approved by the architect in the owner place (card C29); lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [
    "WO-20261013-6463"
  ],
  "files": [
    "line/bin/merge.sh",
    "line/tests/cases/merge-hold.sh"
  ]
}
---

# WO-20261013-2d35 - Cause l: the merger merged onto a red main because the hold lived in prose; merge.sh refuses while the merge hold file exists (cause j's hold)

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

Cause l (record gsp29): PR 94 merged onto red main because the hold was a ruling in prose. Cause j: a rejected main must hold merges; verify-main.sh (WO-20261013-9bdd) writes the hold file, nothing reads it.

## Scope

**In**

- line/bin/merge.sh refuses with exit 3 and a 423 to the orchestrator lane while the hold file under the state root's run tree exists, naming its reason
- line/tests/cases/merge-hold.sh

**Out - non-goals**

- writing the hold (WO-20261013-9bdd)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* with the hold file present merge.sh merges nothing and posts one 423; without it the merge proceeds

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

## Outcome

_Written by `work-order done`. Empty until then._
