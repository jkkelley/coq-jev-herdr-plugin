---
{
  "id": "WO-20261013-a0d1",
  "slug": "roadmap-a3-the-bearings-sitrep-build-reads-recor",
  "title": "Roadmap A3 - The bearings sitrep build reads records from the state root",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T14:11:22+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect P1 order 2026-10-13: A3 split under the owner size rule (03:00Z); lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261013-b221"
  ],
  "blocks": [
    "WO-20261012-99d6"
  ],
  "files": [
    "tools/bearings/config/sitrep.json",
    "tools/bearings/scripts/sitrep-build.mjs",
    "tools/bearings/tests/sitrep.sh"
  ]
}
---

# WO-20261013-a0d1 - Roadmap A3 - The bearings sitrep build reads records from the state root

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

tools/bearings/scripts/sitrep-build.mjs walks the repository path from sitrep.json events_dir (events), so the sitrep shows the checkout's copy, not the state root. Split from WO-20261012-541a.

## Scope

**In**

- sitrep.json names the records tree instead of a repository path; sitrep-build.mjs resolves it through bin/state-root.sh tree records (COQ_STATE, else the config default)
- tools/bearings/tests/sitrep.sh: a record written to COQ_STATE/records appears in the built sitrep

**Out - non-goals**

- the owner page and owner lane (WO-20261013-b221)
- any other bearings file

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* the sitrep build shows a record written to the state root and none from the repository's events/
- [ ] `AC-H2` *(human)* make -C tools/bearings test passes; make lint passes

## Test plan

```sh
make lint && make -C tools/bearings test, in Podman through the repository targets
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
