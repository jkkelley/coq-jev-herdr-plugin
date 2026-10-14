---
{
  "id": "WO-20261013-e3f6",
  "slug": "spec-16-b-routing-lands-the-wake-is-one-herdr-pr",
  "title": "SPEC-16.B routing lands: the wake is one herdr prompt to the item's owner on a status change, and a routes row runs the merge",
  "type": "feature",
  "status": "ready",
  "priority": "p1",
  "created": "2026-10-13",
  "updated": "2026-10-14",
  "created_at": "2026-10-13T03:24:52+00:00",
  "parent": "WO-20261012-5826",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "owner 2026-10-13 03:00Z (record 57h60): pull request 37 lands one pull request per SPEC-16 file; lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261013-fe37"
  ],
  "blocks": [
    "WO-20261012-be64",
    "WO-20261013-7951"
  ],
  "files": [
    "specs/scheduler/SPEC-16.B-routing.xml",
    "graph/nodes/REQ-routing-table-only.json"
  ]
}
---

# WO-20261013-e3f6 - SPEC-16.B routing lands: the wake is one herdr prompt to the item's owner on a status change, and a routes row runs the merge

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

- specs/scheduler/SPEC-16.B-routing.xml with REQ-routing-table-only from 012fa41
- revisions: the wake is one herdr agent prompt to the seat that owns the item, on a status change only (02:41Z); routes rows read the owner seat from the ticket; one per-kind table (input, output codes, next kind, start-to-close, heartbeat, max attempts); merged 200 goes to the merger only; a row runs the merge job on test.passed 201 and review.passed 201 for the newest head (03:02Z); routing by loop

**Out - non-goals**

- any other SPEC-16 file (each has its own ticket) and any Go code

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* check.sh check passes in Podman; the file stays under 1000 lines, generic (no paths, keys or hostnames) and every element cites its source; make lint passes (graph check and sync-specs)

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

- `2026-10-13` Note (ruling zi4u6): specs/scheduler/bin/check.sh in the test plan lands with WO-20261013-fc47, which this ticket follows through its depends_on chain; a tester that finds it missing has a branch older than fc47 on main and posts test.failed naming that, never a pass.

## Outcome

_Written by `work-order done`. Empty until then._
