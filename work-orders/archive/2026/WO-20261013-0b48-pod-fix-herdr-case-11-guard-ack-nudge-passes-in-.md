---
{
  "id": "WO-20261013-0b48",
  "slug": "pod-fix-herdr-case-11-guard-ack-nudge-passes-in-",
  "title": "Pod fix: herdr case 11-guard-ack-nudge passes in arm64 pods (herdr seen idle twice in 4s), and guard AC-H1 passes under pod cpu limits; set pod cpu requests in the test image's pod spec",
  "type": "bug",
  "status": "done",
  "priority": "p1",
  "created": "2026-10-13",
  "updated": "2026-10-14",
  "created_at": "2026-10-13T23:11:14+00:00",
  "parent": "WO-20261013-16f1",
  "branch": "feat/pod-fix-herdr-case-11-guard-ack-nudge-passes-in-",
  "pr": 176,
  "closed": "2026-10-14",
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

- [x] `AC-H1` *(human)* herdr case 11-guard-ack-nudge passes in at least 5 of 6 consecutive arm64 pod runs with the cause named in a breadcrumb
  - observed `2026-10-14` ci/pod/herdr-suite.pod.yaml: case 11-guard-ack-nudge run in 6 arm64 pods (k8s-worker-01 and -02) after the fix: 6 of 6 Succeeded; baseline before the fix, same sha: 2 of 6. Cause named in the breadcrumb: herdr fetches the remote agent-detection manifest in a pod (curl and network up), re-detects the agent when the brief arrives and reports unknown ~3.5 s, longer than nudge_settle_seconds 4. With a failing curl 3 of 3 passed.
- [x] `AC-H2` *(human)* guard AC-H1 passes under the pod cpu limits
  - observed `2026-10-14` The pod spec already requests cpu 1000m with no cpu limit; the same 6 pod runs passed case 11 AC-H1 (nudged once) under those requests, so no cpu change was needed. The failure was not CPU: two pods alone on a node flapped the same way.

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

- `2026-10-14` Retro: the ticket guessed CPU speed; the measurement said otherwise (herdr-server.log: a second 'agent changed previous_agent=None' at brief time, only when curl and network exist). Fix is one env var in the pod spec; case and seat.sh untouched. Method that worked: base64 the probe into COQ_CMD, run it in 1-3 pods, read herdr-server.log.

## Outcome

_Written by `work-order done`. Empty until then._
