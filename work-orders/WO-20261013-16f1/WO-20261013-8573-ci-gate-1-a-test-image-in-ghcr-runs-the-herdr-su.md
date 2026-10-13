---
{
  "id": "WO-20261013-8573",
  "slug": "ci-gate-1-a-test-image-in-ghcr-runs-the-herdr-su",
  "title": "CI gate 1: a test image in GHCR runs the herdr suite and the suite families in Kubernetes pods, without podman on the host",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T19:46:38+00:00",
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
  "depends_on": [],
  "blocks": [
    "WO-20261013-ab25"
  ],
  "files": [
    "ci/image/Containerfile",
    "ci/image/build.sh",
    "ci/image/README.md",
    "ci/config/images.json",
    "ci/pod/herdr-suite.pod.yaml",
    "ci/tests/cases/01-test-image.test.sh"
  ]
}
---

# WO-20261013-8573 - CI gate 1: a test image in GHCR runs the herdr suite and the suite families in Kubernetes pods, without podman on the host

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

Design /home/luna/.local/state/coq/coq-jev-herdr-plugin/plans/2026/10/20261013194800-ci-gate-design.md, ticket 1, as amended 2026-10-13T20:00Z (Jenkins, not GitHub Actions), 20:04Z (in the cluster, through a shared library) and 20:07Z (hooks and ladder). Tests run as pod containers in the owner's Kubernetes cluster, where Jenkins is free and a shared library is ours to control, never on a tester seat and not on this host. The suites already run inside containers (the lint image ghcr.io/jkkelley/coq-lint:1; the herdr cases one podman container each, per the 18:20Z ruling), so this ticket builds the image or images they run in and proves the herdr suite runs in a pod without podman. Input: the approved design. Output: test image(s) in GHCR and the herdr suite green in a pod. Security (copied from the design /home/luna/.local/state/coq/coq-jev-herdr-plugin/plans/2026/10/20261013194800-ci-gate-design.md, with its gate.yml sentence rewritten to the Jenkins fork guard by the 20:00Z amendment): The repository is public, and a self-hosted runner must never run code from a fork. The Jenkins multibranch job builds pull requests only from origin branches (trust "From users with Admin or Write permission"), so a fork pull request never reaches a pod or the host agent, and the repo setting "require approval for all outside collaborators" stays on. The runner runs as the normal user, with no access to the page key and no AWS profiles in its environment.

## Scope

**In**

- ci/image/Containerfile: the test image, one for all suites or one per suite family, with herdr and the suite dependencies baked in, built like lint/Containerfile and multi-arch (a cached amd64 image under the same tag once died with exec format error, see the Jenkinsfile header)
- ci/image/build.sh: build and push to ghcr.io/jkkelley, the version pinned in ci/config/images.json and never a literal in a script, retry 3 times then report
- ci/pod/herdr-suite.pod.yaml: the pod spec the proof uses and the shared-library step in ticket 2 reuses
- ci/image/README.md: build, push, the ghcr-pull-secret, how to run one case in a pod by hand, and the cleanup command
- ci/tests/cases/01-test-image.test.sh: checks the image carries the tools the suites need and that no case needs podman; with CI_POD=1 it runs the herdr suite in a pod

**Out - non-goals**

- the shared-library step coqGate() and the Jenkinsfile (ticket 2)
- a Jenkins inbound agent on this host (a fallback only, cut as its own ticket when a suite is proven to need the host, and none is today)
- the systemd user unit and the GitHub Actions self-hosted runner (reversed by the 20:00Z amendment)

## Degrees of freedom

- [free] One image for every suite or one per suite family
- [free] The image version pinned in ci/config/images.json
- [free] Whether a herdr case is its own container in one pod or its own pod

## Acceptance criteria

- [ ] `AC-H1` *(human)* The image(s) are pullable from GHCR by the cluster with the ghcr-pull-secret, run on the cluster's architecture, and the pod uses imagePullPolicy Always
- [ ] `AC-H2` *(human)* The herdr suite runs green in a pod in the cluster with no podman, each case in its own container or pod
- [ ] `AC-H3` *(human)* A pod's environment holds no page key and no AWS profile

## Test plan

```sh
bash ci/tests/cases/01-test-image.test.sh
```

## Assumptions

- Jenkins in the owner's cluster already runs pods through the kubernetes cloud that runs the lint pod (Jenkinsfile), with the ghcr-pull-secret
- The pod is the isolation, so a herdr case needs no podman; any case this ticket proves cannot run in a pod is named in the README and goes to the host-agent fallback

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-13` 2026-10-13T20:02Z: amended on PR 130 to fold in the design amendments 20:00Z (Jenkins, not GitHub Actions), 20:04Z (in the cluster via coqGate(), test images in GHCR, host agent fallback only) and 20:07Z (webhooks, no pollSCM, status event triggers, 5-rung ladder). The ticket is ready and amend refuses non-drafts, so the body and files were edited directly by the cut seat under the architect's order; approval and status are unchanged.

## Outcome

_Written by `work-order done`. Empty until then._
