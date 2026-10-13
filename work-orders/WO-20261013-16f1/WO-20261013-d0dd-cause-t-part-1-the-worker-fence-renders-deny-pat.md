---
{
  "id": "WO-20261013-d0dd",
  "slug": "cause-t-part-1-the-worker-fence-renders-deny-pat",
  "title": "Cause t, part 1: the worker fence renders deny.paths as Edit rules only, and PR 118 and PR 125 changed roles/ from worker seats; render_settings denies Write beside Edit",
  "type": "bug",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T20:01:59+00:00",
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
    "WO-20261013-bcba"
  ],
  "blocks": [
    "WO-20261012-6f13"
  ],
  "files": [
    "herdr/bin/seat.sh",
    "herdr/tests/cases/38-fence-write-deny.test.sh"
  ]
}
---

# WO-20261013-d0dd - Cause t, part 1: the worker fence renders deny.paths as Edit rules only, and PR 118 and PR 125 changed roles/ from worker seats; render_settings denies Write beside Edit

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

herdr/bin/seat.sh render_settings (:129) turns deny.paths into Edit(...) rules only, on the comment's premise that Edit covers Write; workers on PR 118 and PR 125 still changed roles/, which the worker role denies (roles/worker.json deny.paths roles/, specs/, graph/). A path deny that one write tool walks past is not a fence.

## Scope

**In**

- render_settings emits Write(<path>) next to every Edit(<path>) deny rule, and the comment above it says why, naming this ticket and PR 118 and PR 125
- herdr/tests/cases/38-fence-write-deny.test.sh: a worker's rendered settings deny both Edit and Write on roles/, specs/ and graph/

**Out - non-goals**

- Bash writes (echo, cp, git checkout) past the fence: the gate (part 2) and merge.sh (part 3) are the real control
- allow rules

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* the case passes and fails when the Write rule is removed; cases 01 and 13 still pass; make lint and make -C herdr test pass

## Test plan

```sh
make lint && make -C herdr test, in Podman through the repository targets
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-13` Overlap with WO-20261013-69df (PR 143): both change herdr/bin/seat.sh. This ticket already waits on WO-20261013-bcba, which waits on PR 143 merging, so the order is 69df, bcba, d0dd. The case was renumbered from 36 to 38 because 69df owns 36-seat-canonical-state-root and bcba owns 37-seat-model-override.

## Outcome

_Written by `work-order done`. Empty until then._
