---
{
  "id": "WO-20261012-9f5d",
  "slug": "case-17-resume-checkpoint-builds-its-own-context",
  "title": "Case 17-resume-checkpoint builds its own CONTEXT_STATE.md in its test world, so it passes now that the file is gitignored",
  "type": "bug",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T22:29:42+00:00",
  "parent": "WO-20261012-265d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "regression found on the architect verify of main; Getting My Bearings is the review surface",
    "at": "2026-10-12"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [],
  "files": [
    "herdr/tests/cases/17-resume-checkpoint.test.sh"
  ]
}
---

# WO-20261012-9f5d - Case 17-resume-checkpoint builds its own CONTEXT_STATE.md in its test world, so it passes now that the file is gitignored

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

On main c22cb99 herdr case 17-resume-checkpoint fails: PR 36 made CONTEXT_STATE.md a gitignored render, so the test world copied from the repository has no checkpoint to show. PR 40 fixed the missing checkpoint.sh but was tested before PR 36 landed (verify rihow).

## Scope

**In**

- the case writes the CONTEXT_STATE.md fixture it needs into its own world

**Out - non-goals**

- changing resume-checkpoint.sh behaviour

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* make -C herdr test on a clean worktree of main passes case 17 with no CONTEXT_STATE.md in the repository

## Test plan

```sh
make -C herdr test CASES=17 and the full make -C herdr test, in Podman
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
