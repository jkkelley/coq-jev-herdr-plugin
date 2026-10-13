---
{
  "id": "WO-20261013-fc47",
  "slug": "spec-16-toolchain-lands-from-pull-request-37-the",
  "title": "SPEC-16 toolchain lands from pull request 37: the specs/scheduler XSD, check.sh and its config, so each SPEC-16 file is checked as it lands",
  "type": "feature",
  "status": "done",
  "priority": "p1",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T03:24:38+00:00",
  "parent": "WO-20261012-5826",
  "branch": "feat/spec-16-toolchain-lands-from-pull-request-37-the",
  "pr": 102,
  "closed": "2026-10-13",
  "approval": {
    "via": "override",
    "reason": "owner 2026-10-13 03:00Z (record 57h60): pull request 37 lands one pull request per SPEC-16 file; lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [
    "WO-20261013-c17f"
  ],
  "files": [
    "specs/scheduler/schema/scheduler-spec.xsd",
    "specs/scheduler/bin/check.sh",
    "specs/scheduler/config/check.json",
    "specs/scheduler/config/check.schema.json"
  ]
}
---

# WO-20261013-fc47 - SPEC-16 toolchain lands from pull request 37: the specs/scheduler XSD, check.sh and its config, so each SPEC-16 file is checked as it lands

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

Owner 2026-10-13 03:00Z (record 57h60): pull request 37 (WO-20261012-5826, the SPEC-16 scheduler design, 2,585 lines) lands as one small pull request per SPEC-16 file, overview first, then A to K, and closes once these tickets are cut. The file comes from pull request 37 (branch feat/go-scheduler-design-one-xml-spec-per-domain-unde at 012fa41) with the revisions it owes: cards C10 to C18 from the prepared inventory ($COQ_STATE/archive/2026/10/20261012225500-coq-watch-one-off-scripts-and-logs/sched-backup/pr37-revision-inventory-20261012T2145Z.md) and the owner rulings of 2026-10-13: SPEC-16 is the engine and the end state (02:50Z, record lvvtd), the delivery model (02:41Z, ay9lm), the merge is code (03:02Z).

## Scope

**In**

- specs/scheduler/schema/scheduler-spec.xsd, specs/scheduler/bin/check.sh, specs/scheduler/config/check.json and check.schema.json from 012fa41, changed only so check.sh passes while some SPEC-16 files are not on main yet

**Out - non-goals**

- any other SPEC-16 file (each has its own ticket) and any Go code

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [x] `AC-H1` *(human)* check.sh check exits 0 on main with this ticket alone and on pull request 37's branch with all twelve files
  - observed `2026-10-13` 2026-10-13 UTC, lint image: check.sh check exits 0 on main with this ticket alone (ok no spec files yet, 0 of 12 in spec_set); on a 012fa41 export with all twelve files it exits 0 (ownership ok: 27 routes rows and 12 status codes each owned once); each file landed alone on main with its graph nodes exits 0; a row owned twice in a partial tree exits 3; an unknown spec id exits 3
- [x] `AC-H2` *(human)* make lint passes
  - observed `2026-10-13` 2026-10-13 UTC: make lint prints lint: all ok, exit 0 (configs: schema validates check.json against check.schema.json with the new spec_set key; shellcheck ok)

## Test plan

```sh
podman run --rm --network=none --userns=keep-id -v "$PWD:/repo:ro,Z" localhost/coq-lint:1 bash /repo/specs/scheduler/bin/check.sh check --repo /repo && make lint
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-13` Retro: the twelve SPEC-16 files cite each other in a cycle (overview cites A to K, A cites the overview), so relaxing ownership alone was not enough; no file could be first to pass. spec_set (file and id pairs) in check.json now makes a citation of a not-yet-landed spec pending rather than failed, and spec ids resolve from every spec on disk, not only the FILE arguments. The remaining per-file failure on main is the graph nodes each file's own ticket lands.

## Outcome

_Written by `work-order done`. Empty until then._
