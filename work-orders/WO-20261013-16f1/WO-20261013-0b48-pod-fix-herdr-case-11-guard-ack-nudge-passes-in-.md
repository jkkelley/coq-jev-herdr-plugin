---
{
  "id": "WO-20261013-0b48",
  "slug": "pod-fix-herdr-case-11-guard-ack-nudge-passes-in-",
  "title": "Pod fix: herdr case 11-guard-ack-nudge passes in arm64 pods (herdr seen idle twice in 4s), and guard AC-H1 passes under pod cpu limits; set pod cpu requests in the test image's pod spec",
  "type": "bug",
  "status": "in-progress",
  "priority": "p1",
  "created": "2026-10-13",
  "updated": "2026-10-14",
  "created_at": "2026-10-13T23:11:14+00:00",
  "parent": "WO-20261013-16f1",
  "branch": "feat/pod-fix-herdr-case-11-guard-ack-nudge-passes-in-",
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect order 23:08Z and 23:12Z (w6uxu): pod follow-up for PR 156, system slot; approved by the architect in the owner place",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [],
  "files": [
    "herdr/tests/cases/11-guard-ack-nudge.test.sh",
    "ci/pod/herdr-suite.pod.yaml"
  ]
}
---

# WO-20261013-0b48 - Pod fix: herdr case 11-guard-ack-nudge passes in arm64 pods (herdr seen idle twice in 4s), and guard AC-H1 passes under pod cpu limits; set pod cpu requests in the test image's pod spec

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

PR 156 (WO-20261013-8573, CI gate 1) shipped with herdr case 11-guard-ack-nudge failing in 5 of 6 arm64 pods, a known gap the architect accepted at 23:12Z. Guard AC-H1 also fails under pod cpu limits. CI gate 2 reads pod results, so both must pass in pods.

## Scope

**In**

- herdr/tests/cases/11-guard-ack-nudge.test.sh: find why herdr is not seen idle twice in 4s on arm64 and fix the cause; raising nudge_settle_seconds is the fallback only if the cause is plain CPU speed, with a breadcrumb naming the measurement
- ci/pod/herdr-suite.pod.yaml: set pod cpu requests so guard AC-H1 and the herdr cases pass under the pod's limits

**Out - non-goals**

- CI gate 2 and the runner (other tickets)

## Degrees of freedom

- [free] [free] Whether the fix is in the case, in guard timing or in the pod spec

## Acceptance criteria

- [ ] `AC-H1` *(human)* herdr case 11-guard-ack-nudge passes in at least 5 of 6 consecutive arm64 pod runs with the cause named in a breadcrumb
- [ ] `AC-H2` *(human)* guard AC-H1 passes under the pod cpu limits

## Test plan

```sh
bash ci/image/build.sh then run the herdr suite pod; CASES=11 bash herdr/tests/run.sh in the pod, six times
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
