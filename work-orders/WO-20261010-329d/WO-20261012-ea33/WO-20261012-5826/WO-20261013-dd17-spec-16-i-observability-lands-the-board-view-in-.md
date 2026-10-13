---
{
  "id": "WO-20261013-dd17",
  "slug": "spec-16-i-observability-lands-the-board-view-in-",
  "title": "SPEC-16.I observability lands: the board view in one herdr pane, read from the status answer",
  "type": "feature",
  "status": "ready",
  "priority": "p1",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T03:25:12+00:00",
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
  "blocks": [],
  "files": [
    "specs/scheduler/SPEC-16.I-observability.xml"
  ]
}
---

# WO-20261013-dd17 - SPEC-16.I observability lands: the board view in one herdr pane, read from the status answer

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

- specs/scheduler/SPEC-16.I-observability.xml from 012fa41
- revisions: the board view rendered in one herdr pane from the status answer (02:41Z); the health line is the status answer; the changelog from pull request titles (cards)

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
