---
{
  "id": "WO-20261013-f6ae",
  "slug": "merge-is-code-line-bin-merge-sh-squash-merges-a-",
  "title": "Merge is code: line/bin/merge.sh squash-merges a pull request whose newest head has test.passed 201 and review.passed 201, posts merged 200 with the merge sha for the merger's verify, and posts merge.conflict 409 to the worker lane on a conflict",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T03:14:46+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "owner 2026-10-13 03:00Z (record 57h60) size rule and 03:02Z merge is code, via the architect; lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [],
  "files": [
    "line/bin/merge.sh",
    "line/tests/cases/merge.test.sh"
  ]
}
---

# WO-20261013-f6ae - Merge is code: line/bin/merge.sh squash-merges a pull request whose newest head has test.passed 201 and review.passed 201, posts merged 200 with the merge sha for the merger's verify, and posts merge.conflict 409 to the worker lane on a conflict

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

Owner 2026-10-13 03:02Z ('I hate bottlenecks'): one Haiku merger seat merged pull requests one at a time, about fifteen minutes each, though the merge is mechanical. The merge becomes a script; the merger seat only verifies main and handles conflicts.

## Scope

**In**

- line/bin/merge.sh --pr N, and --all for one pass over every open pull request: read the newest head with gh; merge only when factory/bin/gate.sh heads_match holds (test.passed 201 and review.passed 201 name that head); gh pr merge --squash --match-head-commit HEAD so a moved head is refused; post merged 200 through events/bin/event.sh with --sha MERGE_SHA --pr N --ticket ID, which the routes table hands to the merger seat for the verify (verified 201 or rejected)
- a conflict posts merge.conflict 409 to the worker lane with the pull request and head; a held head (the 201s name an older head) posts nothing and exits 3; a pull request already merged exits 0 and posts nothing twice
- each gh call retries three times with backoff, then exits 4 and posts one blocked 423 to the orchestrator lane
- line/tests/cases/merge.test.sh, self-wrapping (it re-runs itself in Podman), with a fake gh and fixture records: merged, held, conflict, rerun

**Out - non-goals**

- every factory/ file, route.sh and routes.json (A2, WO-20261012-0229, holds them); the routes row that calls merge.sh is a follow-up after A2 merges
- the merger role and playbook; a follow-up shrinks the merger to the verify and conflicts
- wiring the patrol tick, which lives outside the repository until roadmap item I moves it into line/

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* with fixture 201s on the newest head, gh pr merge --squash --match-head-commit HEAD is called and exactly one merged 200 with the merge sha is posted
- [ ] `AC-H2` *(human)* with 201s on an older head nothing is merged or posted; a conflict posts merge.conflict 409 to the worker lane; a rerun after the merge posts nothing
- [ ] `AC-H3` *(human)* make lint passes and the merge case passes in Podman

## Test plan

```sh
make lint && bash line/tests/cases/merge.test.sh, which re-runs itself in Podman
```

## Assumptions

1. records are read through the A1 resolver (config/state.json), the same root gate.sh reads; gate.sh is called read-only
1. line/ may not exist yet; this ticket creates line/bin and line/tests/cases if the line test harness has not landed, and the harness picks the case up later

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
