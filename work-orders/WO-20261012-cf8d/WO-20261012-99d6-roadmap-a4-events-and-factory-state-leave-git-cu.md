---
{
  "id": "WO-20261012-99d6",
  "slug": "roadmap-a4-events-and-factory-state-leave-git-cu",
  "title": "Roadmap A4 - events/ and factory/state leave git: cut over under USERHALT, records copied to the state root, merging main strips events/ from a branch, rollback written",
  "type": "chore",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-12",
  "updated": "2026-10-13",
  "created_at": "2026-10-12T22:13:25+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "owner locked ROADMAP.md 2026-10-12 (cards C9 to C22) and gave USERGO; Getting My Bearings is the review surface, lavish is prohibited",
    "at": "2026-10-12"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261013-496d",
    "WO-20261013-5c06",
    "WO-20261013-f9f2",
    "WO-20261013-3abe",
    "WO-20261013-a0d1"
  ],
  "blocks": [
    "WO-20261012-41a3"
  ],
  "files": [
    "events/20*",
    ".gitignore",
    "lint/lint.sh",
    "docs/runbooks/state-root-cutover.md"
  ]
}
---

# WO-20261012-99d6 - Roadmap A4 - events/ and factory/state leave git: cut over under USERHALT, records copied to the state root, merging main strips events/ from a branch, rollback written

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

With every reader on the state root, the committed events/ tree and the in-checkout ledger are dead weight that rides pull requests (owner cards C10, C11).

## Scope

**In**

- a cut-over runbook: USERHALT, copy events/ and factory/state into the state root, verify counts, git rm events/20*, gitignore events/20* and factory/state, USERGO
- lint stops validating a repository events/ tree
- a written rollback

**Out - non-goals**

- deleting the copies kept in the state root

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* after the cut-over git ls-files events/20 lists nothing and the state root holds every record that was there, counted
- [ ] `AC-H2` *(human)* the belt routes a new record within one poll after USERGO
- [ ] `AC-H3` *(human)* the rollback was read through once and names each command

## Test plan

```sh
make lint && make -C factory test && make -C herdr test, all in Podman through the repository targets
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
