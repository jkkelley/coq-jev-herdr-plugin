---
{
  "id": "WO-20261013-3217",
  "slug": "ci-gate-3-line-bin-merge-sh-keys-on-the-gate-che",
  "title": "CI gate 3: line/bin/merge.sh keys on the coq/gate status of the head sha plus review.passed, triggered by the GitHub status event, not on a test.passed record",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-14",
  "created_at": "2026-10-13T19:46:51+00:00",
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
    "WO-20261013-ca2a",
    "WO-20261013-4464"
  ],
  "blocks": [
    "WO-20261013-3eac"
  ],
  "files": [
    "line/bin/merge.sh",
    "line/tests/cases/merge-gate-check.test.sh",
    "ci/bin/pr-gate-hook.sh",
    "ci/tests/cases/03-pr-gate-hook.test.sh"
  ]
}
---

# WO-20261013-3217 - CI gate 3: line/bin/merge.sh keys on the coq/gate status of the head sha plus review.passed, triggered by the GitHub status event, not on a test.passed record

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

Design /home/luna/.local/state/coq/coq-jev-herdr-plugin/plans/2026/10/20261013194800-ci-gate-design.md, ticket 3, as amended 2026-10-13T20:07Z (hooks and ladder). Input: coq/gate exists on the head sha (ticket 2). Output: the merger merges on coq/gate success of the head sha plus review.passed, and it is triggered by the GitHub status event for coq/gate, not by a test.passed record and not by polling. Note: WO-20261013-2d35 also names merge.sh; run after it.

## Scope

**In**

- line/bin/merge.sh: read the coq/gate status of the head sha with gh, merge only on success, hold on failure, error or pending; its gh calls keep their 3 retries and then post blocked 423, so the ladder ends in a report and never in a loop
- ci/bin/pr-gate-hook.sh: the handler for one GitHub status event payload on stdin; it is run by the listener from WO-20261013-ca2a (the coq/gate record it writes pipes the same payload to this script on stdin), it ignores every context but coq/gate and every sha that is not the head of an open pull request, resolves the pull request for the sha, and on state success runs line/bin/merge.sh --pr N
- line/tests/cases/merge-gate-check.test.sh and ci/tests/cases/03-pr-gate-hook.test.sh

**Out - non-goals**

- routes (ticket 5)
- the main verdict records (ticket 4)
- the listener that delivers the webhook payload to the handler: ticket WO-20261013-ca2a - CI gate 6 owns it, and its line/config/hook.json already names ci/bin/pr-gate-hook.sh as the handler of a coq/gate status event, so this ticket edits no listener file

## Degrees of freedom

- [free] How the status is read (gh api for the commit status, or gh pr checks)

## Acceptance criteria

- [ ] `AC-H1` *(human)* merge.sh --pr N refuses with exit 3 when the coq/gate status of the head sha is not success
- [ ] `AC-H2` *(human)* With coq/gate success and review.passed it merges
- [ ] `AC-H3` *(human)* A coq/gate success status event for a pull request head runs merge.sh for that pull request, an event for any other context runs nothing, and no process polls

## Test plan

```sh
bash line/tests/cases/merge-gate-check.test.sh && bash ci/tests/cases/03-pr-gate-hook.test.sh
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
