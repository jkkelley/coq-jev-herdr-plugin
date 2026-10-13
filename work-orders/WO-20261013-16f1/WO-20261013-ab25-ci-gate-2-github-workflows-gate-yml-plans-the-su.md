---
{
  "id": "WO-20261013-ab25",
  "slug": "ci-gate-2-github-workflows-gate-yml-plans-the-su",
  "title": "CI gate 2: .github/workflows/gate.yml plans the suites from the diff, runs them on the coq runner, and one required check gate waits for all, with a fork guard",
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
    ".github/workflows/gate.yml",
    "ci/tests/cases/02-gate-workflow.test.sh"
  ]
}
---

# WO-20261013-ab25 - CI gate 2: .github/workflows/gate.yml plans the suites from the diff, runs them on the coq runner, and one required check gate waits for all, with a fork guard

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

Design /home/luna/.local/state/coq/coq-jev-herdr-plugin/plans/2026/10/20261013194800-ci-gate-design.md, ticket 2. Input: runner online (ticket 1), suites.sh (PR 109, WO-20261013-f1ff) and test-cases.sh (PR 115, WO-20261013-0bc0). Output: a required check named gate on every pull request. Security (copied verbatim from the design /home/luna/.local/state/coq/coq-jev-herdr-plugin/plans/2026/10/20261013194800-ci-gate-design.md): The repository is public, and a self-hosted runner must never run code from a fork. The workflow runs only when `github.event.pull_request.head.repo.full_name == github.repository`, and the repo setting "require approval for all outside collaborators" stays on. The runner runs as the normal user, with no access to the page key and no AWS profiles in its environment.

## Scope

**In**

- .github/workflows/gate.yml: on pull_request and on push to main; job plan runs factory/bin/suites.sh on the diff and emits a matrix (full on main); job suite per entry on runs-on [self-hosted, coq] with timeout-minutes from the suite budget; job gate needs all suites; concurrency group gate-github.ref with cancel-in-progress; every job guarded by head.repo.full_name == github.repository
- ci/tests/cases/02-gate-workflow.test.sh: checks the workflow has the fork guard, the concurrency block and the gate job

**Out - non-goals**

- merge.sh and main verdict records (tickets 3 and 4)

## Degrees of freedom

- [free] Action versions pinned in the workflow

## Acceptance criteria

- [ ] `AC-H1` *(human)* A pull request from this repo runs plan, the selected suites and gate on the coq runner
- [ ] `AC-H2` *(human)* A fork pull request runs no job

## Test plan

```sh
bash ci/tests/cases/02-gate-workflow.test.sh
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
