---
{
  "id": "WO-20261013-fe37",
  "slug": "spec-16-g-config-schema-lands-every-scheduler-ke",
  "title": "SPEC-16.G config schema lands: every scheduler key, revised for the state root and for the keys the other domains add",
  "type": "feature",
  "status": "ready",
  "priority": "p1",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T03:24:46+00:00",
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
    "WO-20261013-c17f"
  ],
  "blocks": [
    "WO-20261013-badd",
    "WO-20261013-e3f6",
    "WO-20261013-3aea",
    "WO-20261013-4ce5",
    "WO-20261013-c64d",
    "WO-20261013-b296",
    "WO-20261013-dd17",
    "WO-20261013-223e"
  ],
  "files": [
    "specs/scheduler/SPEC-16.G-config-schema.xml",
    "graph/nodes/SCH-scheduler-config.json"
  ]
}
---

# WO-20261013-fe37 - SPEC-16.G config schema lands: every scheduler key, revised for the state root and for the keys the other domains add

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

- specs/scheduler/SPEC-16.G-config-schema.xml with graph/nodes/SCH-scheduler-config.json from 012fa41
- revisions: state root keys (cards); F's probe thresholds (screen unchanged, idle, blocked words, process count, repeat-action window); C's sixty-second idle limit and lease seconds; B's per-kind start-to-close and heartbeat; the two loop budgets

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

## Outcome

_Written by `work-order done`. Empty until then._
