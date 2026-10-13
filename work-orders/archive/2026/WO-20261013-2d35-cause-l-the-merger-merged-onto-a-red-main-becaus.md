---
{
  "id": "WO-20261013-2d35",
  "slug": "cause-l-the-merger-merged-onto-a-red-main-becaus",
  "title": "Cause l: the merger merged onto a red main because the hold lived in prose; merge.sh refuses while the merge hold file exists (cause j's hold)",
  "type": "bug",
  "status": "done",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T16:37:29+00:00",
  "parent": "WO-20261013-16f1",
  "branch": "feat/cause-l-the-merger-merged-onto-a-red-main-becaus",
  "pr": 144,
  "closed": "2026-10-13",
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

- [x] `AC-H1` *(human)* with the hold file present merge.sh merges nothing and posts one 423; without it the merge proceeds
  - observed `2026-10-13` line/tests/cases/merge-hold.sh in the test pane wD3:p1HV: tests 1 passed 0 failed. With the hold file present merge.sh --pr and --all exit 3, make no gh call, merge nothing and post exactly one blocked 423 to orchestrator naming the reason (reruns post none); with the file removed the same PR merges and one merged 200 posts. make lint and make -C line test: exit 0, 14 passed 0 failed.

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

- `2026-10-13` Retro: hold_reason first printed the reason through $(...), which lost HOLD_SHA to the subshell and posted the 423 with no sha; the case caught it. Fixed by setting globals. The 423 is deduped on its note so the patrol tick posts it once per hold, not once a minute. Worktree was a start worktree, not a treehouse lease (seat seated with --worktree), so the lease check had nothing to find.

## Outcome

_Written by `work-order done`. Empty until then._
