---
{
  "id": "WO-20261013-aff2",
  "slug": "ci-gate-4-a-green-gate-on-main-posts-verified-fo",
  "title": "CI gate 4: a green coq/gate status on main posts verified for every merge since the last verified sha, a red one posts rejected and sets the merge hold, triggered by the GitHub status event",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T19:46:58+00:00",
  "parent": "WO-20261013-16f1",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect order 19:50Z (C29 CI gate design approved, owner m-20261013194434026-yz0ob), system loop p0; approved by the architect in the owner place",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261013-ab25",
    "WO-20261013-ca2a"
  ],
  "blocks": [
    "WO-20261013-3eac"
  ],
  "files": [
    "ci/bin/main-gate.sh",
    "ci/tests/cases/04-main-gate.test.sh"
  ]
}
---

# WO-20261013-aff2 - CI gate 4: a green coq/gate status on main posts verified for every merge since the last verified sha, a red one posts rejected and sets the merge hold, triggered by the GitHub status event

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

Design /home/luna/.local/state/coq/coq-jev-herdr-plugin/plans/2026/10/20261013194800-ci-gate-design.md, ticket 4, as amended 2026-10-13T20:07Z (hooks and ladder). Input: coq/gate runs on a push to main (ticket 2), and its status event reaches the line by webhook. Output: verified 200 or rejected 422 records for the range, replacing the verify-main seat runs, written by a handler that the status event triggers, so no seat and no loop watches a run.

## Scope

**In**

- ci/bin/main-gate.sh: the handler for one GitHub status event payload on stdin; it ignores every context but coq/gate and every sha that is not a main commit. On success it posts verified per merged pull request in the range since the last verified sha. On failure it posts rejected naming the failing suite and sets the hold. Retry 3 times then report, per the ladder; a red or error status already carries its log link and page from ticket 2, so this script adds none
- ci/tests/cases/04-main-gate.test.sh

**Out - non-goals**

- removing line/bin/verify-main.sh (a follow-up)
- the listener that delivers the webhook payload to the handler (see ticket 3)

## Degrees of freedom

- [free] Where the last verified sha is kept (outside the repo)

## Acceptance criteria

- [ ] `AC-H1` *(human)* A coq/gate success event on a main sha posts one verified per merged pull request since the last verified sha
- [ ] `AC-H2` *(human)* A coq/gate failure event on a main sha posts rejected with the failing suite and sets the hold
- [ ] `AC-H3` *(human)* An event for a non-main sha or another context posts nothing, and no process polls

## Test plan

```sh
bash ci/tests/cases/04-main-gate.test.sh
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-13` 2026-10-13T20:02Z: amended on PR 130 to fold in the design amendments 20:00Z (Jenkins, not GitHub Actions), 20:04Z (in the cluster via coqGate(), test images in GHCR, host agent fallback only) and 20:07Z (webhooks, no pollSCM, status event triggers, 5-rung ladder). The ticket is ready and amend refuses non-drafts, so the body and files were edited directly by the cut seat under the architect's order; approval and status are unchanged.

## Outcome

_Written by `work-order done`. Empty until then._
