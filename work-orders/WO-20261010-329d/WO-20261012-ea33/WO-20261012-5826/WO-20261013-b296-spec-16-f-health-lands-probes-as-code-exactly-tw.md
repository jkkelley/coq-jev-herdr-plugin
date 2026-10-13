---
{
  "id": "WO-20261013-b296",
  "slug": "spec-16-f-health-lands-probes-as-code-exactly-tw",
  "title": "SPEC-16.F health lands: probes as code, exactly two supervised units, the dead man's switch and the orphan sweep",
  "type": "feature",
  "status": "ready",
  "priority": "p1",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T03:25:05+00:00",
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
    "WO-20261012-be64"
  ],
  "files": [
    "specs/scheduler/SPEC-16.F-health-supervision.xml",
    "graph/nodes/REQ-stall-two-signal.json"
  ]
}
---

# WO-20261013-b296 - SPEC-16.F health lands: probes as code, exactly two supervised units, the dead man's switch and the orphan sweep

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

- specs/scheduler/SPEC-16.F-health-supervision.xml with REQ-stall-two-signal from 012fa41
- revisions: probes are code against G's keys (screen unchanged, idle, blocked words, process count, repeat-action fingerprint) and a model only explains a finding the code raised; f-supervisor supervises exactly two things, the scheduler binary and the interim bash belt until the cut-over; the dead man's switch is the f-belt heartbeat whose age bearings stable checks outside the line; f-housekeeping removes orphan worktrees, seats and processes by owner record id; alerts are symptoms (unseated records), never idle seats; halt and drain are the flag files the interim line writes

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
