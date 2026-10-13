---
{
  "id": "WO-20261013-8573",
  "slug": "ci-gate-1-a-github-actions-self-hosted-runner-wi",
  "title": "CI gate 1: a GitHub Actions self-hosted runner with label coq is installed on this host as a systemd user unit, with a cleanup doc",
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
    "ci/runner/install.sh",
    "ci/runner/coq-runner.service",
    "ci/runner/README.md",
    "ci/tests/cases/01-runner-install.test.sh"
  ]
}
---

# WO-20261013-8573 - CI gate 1: a GitHub Actions self-hosted runner with label coq is installed on this host as a systemd user unit, with a cleanup doc

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

Design /home/luna/.local/state/coq/coq-jev-herdr-plugin/plans/2026/10/20261013194800-ci-gate-design.md, ticket 1. Tests move off tester seats onto a self-hosted runner on this host (the herdr and podman suites need this machine). Input: the approved design. Output: the runner online in the repo settings. Security (copied verbatim from the design /home/luna/.local/state/coq/coq-jev-herdr-plugin/plans/2026/10/20261013194800-ci-gate-design.md): The repository is public, and a self-hosted runner must never run code from a fork. The workflow runs only when `github.event.pull_request.head.repo.full_name == github.repository`, and the repo setting "require approval for all outside collaborators" stays on. The runner runs as the normal user, with no access to the page key and no AWS profiles in its environment.

## Scope

**In**

- ci/runner/install.sh: download, configure and register the runner for the repo with label coq, capacity min(cores,4), work dir under XDG_CACHE_HOME, retry 3 times then report
- ci/runner/coq-runner.service: the systemd --user unit
- ci/runner/README.md: install, status, remove and cleanup commands, and the fork-safety rules
- ci/tests/cases/01-runner-install.test.sh: dry-run test of install.sh

**Out - non-goals**

- gate.yml (ticket 2)

## Degrees of freedom

- [free] The runner version pinned in config, not literals

## Acceptance criteria

- [ ] `AC-H1` *(human)* The runner shows online in the repo settings with label coq
- [ ] `AC-H2` *(human)* The unit runs as the normal user with no AWS profile and no page key in its environment

## Test plan

```sh
bash ci/tests/cases/01-runner-install.test.sh
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
