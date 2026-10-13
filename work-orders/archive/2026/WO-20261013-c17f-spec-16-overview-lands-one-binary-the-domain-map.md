---
{
  "id": "WO-20261013-c17f",
  "slug": "spec-16-overview-lands-one-binary-the-domain-map",
  "title": "SPEC-16 overview lands: one binary, the domain map and shared contracts, revised for cards C10 to C18 and for SPEC-16 as the engine and the end state",
  "type": "feature",
  "status": "done",
  "priority": "p1",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T03:24:43+00:00",
  "parent": "WO-20261012-5826",
  "branch": "feat/spec-16-overview-lands-one-binary-the-domain-map",
  "pr": 114,
  "closed": "2026-10-13",
  "approval": {
    "via": "override",
    "reason": "owner 2026-10-13 03:00Z (record 57h60): pull request 37 lands one pull request per SPEC-16 file; lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261013-fc47",
    "WO-20261013-7fa3"
  ],
  "blocks": [
    "WO-20261013-fe37",
    "WO-20261013-18d6",
    "WO-20261013-31d1",
    "WO-20261012-be64"
  ],
  "files": [
    "specs/scheduler/SPEC-16-scheduler-overview.xml",
    "graph/nodes/CMP-scheduler.json",
    "graph/nodes/CMP-scheduler-executor.json"
  ]
}
---

# WO-20261013-c17f - SPEC-16 overview lands: one binary, the domain map and shared contracts, revised for cards C10 to C18 and for SPEC-16 as the engine and the end state

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

- specs/scheduler/SPEC-16-scheduler-overview.xml with graph/nodes/CMP-scheduler.json and CMP-scheduler-executor.json from 012fa41
- revisions: the cards that touch it (state root, seats kept, the merger verifies on main, no NATS); s-shape: the domain loops run in the one binary under one supervised unit and no reconciler gets its own unit; s-laws: no LLM in routing, health, retry or cleanup; s-build: the files land one pull request each and the fourteen build tickets are re-cut after the owner accepts the revised specs

**Out - non-goals**

- any other SPEC-16 file (each has its own ticket) and any Go code

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [x] `AC-H1` *(human)* check.sh check passes in Podman; the file stays under 1000 lines, generic (no paths, keys or hostnames) and every element cites its source; make lint passes (graph check and sync-specs)
  - observed `2026-10-13` check.sh check in localhost/coq-lint:1 printed 'ok specs/scheduler/SPEC-16-scheduler-overview.xml (283 lines)', exit 0; no paths, keys or hostnames (forbidden patterns pass); every word element cites a source; make lint ended 'lint: all ok' with graph check + specs agree ok (108 nodes)
- [x] `AC-H2` *(human)* s-shape, s-laws and s-build carry the three revisions, each citing the owner ruling
  - observed `2026-10-13` s-shape sh-unit (one binary, one supervised unit, no reconciler its own unit) cites owner:bearings:2026-10-13T02:50Z; s-laws l-llm (no LLM in routing, health, retry or cleanup) cites owner 01:47Z and 02:50Z, plus l-bus, l-state, l-seats for cards C10 to C18; s-build w-land cites owner 03:00Z and w-size owner 03:02Z

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

- `2026-10-13` Retro: the XSD takes one text per graph node and owner sources only as owner:<lowercase channel>:<UTC minute>, so card citations go through ROADMAP.md#Locked decisions and node sources omit at. The four nodes from 7fa3 were already revised on main; the overview's copies now match their titles and edges.
- `2026-10-13` Note (ruling zi4u6): specs/scheduler/bin/check.sh in the test plan lands with WO-20261013-fc47, which this ticket follows through its depends_on chain; a tester that finds it missing has a branch older than fc47 on main and posts test.failed naming that, never a pass.

## Outcome

_Written by `work-order done`. Empty until then._
