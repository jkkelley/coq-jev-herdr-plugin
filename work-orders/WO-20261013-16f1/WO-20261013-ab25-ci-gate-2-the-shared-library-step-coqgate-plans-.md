---
{
  "id": "WO-20261013-ab25",
  "slug": "ci-gate-2-the-shared-library-step-coqgate-plans-",
  "title": "CI gate 2: the shared-library step coqGate() plans the suites from the diff, fans them out as pod containers, and posts the coq/gate status on the head sha, webhook-triggered, with abortPrevious, a fork guard and the retry ladder",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T19:46:44+00:00",
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
    "WO-20261013-f1ff",
    "WO-20261013-0bc0",
    "WO-20261013-8573"
  ],
  "blocks": [
    "WO-20261013-3217",
    "WO-20261013-aff2"
  ],
  "files": [
    "Jenkinsfile",
    "ci/jenkins-lib/vars/coqGate.groovy",
    "ci/README.md",
    "ci/tests/cases/02-gate-pipeline.test.sh"
  ]
}
---

# WO-20261013-ab25 - CI gate 2: the shared-library step coqGate() plans the suites from the diff, fans them out as pod containers, and posts the coq/gate status on the head sha, webhook-triggered, with abortPrevious, a fork guard and the retry ladder

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

Design /home/luna/.local/state/coq/coq-jev-herdr-plugin/plans/2026/10/20261013194800-ci-gate-design.md, ticket 2, as amended 2026-10-13T20:00Z, 20:04Z and 20:07Z. Input: the test image(s) (ticket 1), suites.sh (PR 109, WO-20261013-f1ff) and test-cases.sh (PR 115, WO-20261013-0bc0). Output: a status named coq/gate on the head sha of every pull request and every main push, posted by one shared-library step coqGate() that the Jenkinsfile calls. Everything is event driven: a GitHub webhook triggers the Jenkins job on push and pull request, pollSCM goes, and nothing polls or waits. Security (copied from the design /home/luna/.local/state/coq/coq-jev-herdr-plugin/plans/2026/10/20261013194800-ci-gate-design.md, with its gate.yml sentence rewritten to the Jenkins fork guard by the 20:00Z amendment): The repository is public, and a self-hosted runner must never run code from a fork. The Jenkins multibranch job builds pull requests only from origin branches (trust "From users with Admin or Write permission"), so a fork pull request never reaches a pod or the host agent, and the repo setting "require approval for all outside collaborators" stays on. The runner runs as the normal user, with no access to the page key and no AWS profiles in its environment.

## Scope

**In**

- Jenkinsfile: calls coqGate() beside the existing Lint and Blueprint stages; drops `pollSCM('H/10 * * * *')`; sets `disableConcurrentBuilds(abortPrevious: true)` per branch, so a newer push aborts the older build
- ci/jenkins-lib/vars/coqGate.groovy: the shared-library step. It runs factory/bin/suites.sh on the pull request diff (the full set on main), fans the selected suites and the herdr cases out as parallel pod containers from the ticket 1 image(s), each with a timeout from the suite budget, and posts coq/gate on the head sha: pending at the start, then success, failure or error. The step refuses to run for a fork head
- the retry ladder inside coqGate(). Rungs 1 to 3: automatic retry of an infrastructure failure (pod scheduling, image pull, network), never of a test assertion. Rung 4: one clean re-run of the suite on a fresh pod. Rung 5: coq/gate stays red with its target URL on the failing log, and a page goes to the orchestrator with that log link. It never stalls silently and never loops
- ci/README.md: the installed-plugin inventory first (GitHub Branch Source or the commit status publisher, whichever is installed, read through the Jenkins tools), how the library is registered, the multibranch job and its trust setting, the GitHub webhook (push, pull_request and the status event, with the URL it posts to), and the host-agent fallback rule
- ci/tests/cases/02-gate-pipeline.test.sh: static checks that the Jenkinsfile has no pollSCM and has abortPrevious, that it calls coqGate(), and that the library posts coq/gate, holds the fork guard and carries the four automatic rungs and the page

**Out - non-goals**

- merge.sh and the main verdict records (tickets 3 and 4)
- a Jenkins inbound agent on this host (a fallback only, none today)
- any .github/workflows file or GitHub Actions job (reversed by the 20:00Z amendment)

## Degrees of freedom

- [free] A commit status or a check run, named coq/gate either way
- [free] Whether the library lives in this repo's ci/jenkins-lib registered as a library, or in the owner's existing shared library
- [free] Plugin and library versions pinned in config, not literals

## Acceptance criteria

- [ ] `AC-H1` *(human)* A push or pull request from this repo triggers the job by webhook, with no pollSCM, and coq/gate appears on the head sha as pending and then as its final state
- [ ] `AC-H2` *(human)* A newer push aborts the older build, and the older sha's coq/gate ends not-success with the description superseded, never left pending
- [ ] `AC-H3` *(human)* A fork pull request builds nothing and reaches no pod and no agent
- [ ] `AC-H4` *(human)* An injected infrastructure failure (an image that cannot be pulled) climbs the ladder: three automatic retries, one clean re-run, then red with the log link and a page; a failing test assertion is never retried

## Test plan

```sh
bash ci/tests/cases/02-gate-pipeline.test.sh
```

## Assumptions

- The Jenkins job today is single-branch (Jenkinsfile header, job coq-jev-herdr-plugin) with githubPush and pollSCM; pull request builds need the GitHub Branch Source multibranch job, so this ticket converts the job or adds a second one after the plugin inventory
- The lint pod and the Blueprint stage stay as they are

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-13` 2026-10-13T20:02Z: amended on PR 130 to fold in the design amendments 20:00Z (Jenkins, not GitHub Actions), 20:04Z (in the cluster via coqGate(), test images in GHCR, host agent fallback only) and 20:07Z (webhooks, no pollSCM, status event triggers, 5-rung ladder). The ticket is ready and amend refuses non-drafts, so the body and files were edited directly by the cut seat under the architect's order; approval and status are unchanged.

## Outcome

_Written by `work-order done`. Empty until then._
