---
{
  "id": "WO-20261012-0113",
  "slug": "scheduler-lint-and-ci-wiring-lint-lint-sh-runs-s",
  "title": "Scheduler lint and CI wiring: lint/lint.sh runs specs/scheduler/bin/check.sh and the Jenkinsfile runs make -C scheduler test when scheduler/ changes",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T19:37:49+00:00",
  "parent": "WO-20261012-ea33",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect: lavish is prohibited for Claude seats; cut from SPEC-16 by the scheduler architect with disjoint files and a generated test plan; owner order on the bearings page 2026-10-12 18:34Z, CRITICAL",
    "at": "2026-10-12"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261012-48ab"
  ],
  "blocks": []
}
---

# WO-20261012-0113 - Scheduler lint and CI wiring: lint/lint.sh runs specs/scheduler/bin/check.sh and the Jenkinsfile runs make -C scheduler test when scheduler/ changes

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

The scheduler specs are checked only by hand until the lint calls their check, and the module is tested only locally until CI runs it; both files are in flight in other pull requests, so this ticket starts when they have landed.

## Scope

**In**

- Owns: lint/lint.sh, Jenkinsfile
- one step in lint/lint.sh: specs/scheduler/bin/check.sh check, after the specs steps
- one stage in the Jenkinsfile: make -C scheduler test in the test image when the changeset touches scheduler/

**Out - non-goals**

- editing any file outside the directories this ticket owns, in particular scheduler/go.mod, scheduler/internal/core/ and any other ticket's package
- adding a dependency to the module (ask the architect)
- writing a record file directly; records go through the executor's record verb
- any other lint step or stage
- starting before pull requests touching lint/lint.sh or the Jenkinsfile have merged

## Degrees of freedom

- [free] the stage's agent container definition, as long as it is the pinned test image

## Acceptance criteria

- [ ] `AC-H1` *(human)* make lint prints a scheduler specs step with ok
- [ ] `AC-H2` *(human)* a deliberately broken spec (a text over 240 characters, in a scratch copy) makes make lint fail naming it
- [ ] `AC-H3` *(human)* the Jenkins job runs the scheduler stage on a push touching scheduler/ and skips it otherwise

## Test plan

_Test plan from claude/workflow/templates/test-plan.md, shaped by claude/workflow/schemas/test-plan.schema.json. The tester runs exactly these cases and nothing else._

**Scope under test**

The lint step and the CI stage.

**Cases**

- `TP-1`
  - intent: the acceptance criterion this command proves, as the ticket states it
  - command: `make lint`
  - expected: exit 0, with a line for the scheduler specs check reading ok
- `TP-2`
  - intent: the acceptance criterion this command proves, as the ticket states it
  - command: `podman run --rm --network=none --userns=keep-id -v "$PWD:/repo:ro,Z" localhost/coq-lint:1 bash -c 'cp -r /repo /tmp/r && sed -i "s#<text id=\"g-in\" source=\"lint/lint.sh\">#<text id=\"g-in\">#" /tmp/r/specs/scheduler/SPEC-16.G-config-schema.xml && bash /tmp/r/specs/scheduler/bin/check.sh check --repo /tmp/r; test $? -eq 3'`
  - expected: exit 0: the check on the copy exits 3 naming the spec whose element lost its source attribute

**Isolation**

- runtime: podman
- image: `localhost/coq-lint@sha256:d2f6ded8d64627b8e7c02552431a4205431312d2570f1562313d8d26dc815077` (coq-lint:1, the repository lint image)

**Out of scope - CI covers**

- CI runs make -C scheduler test over the whole module on every change under scheduler/
- make lint on the repository validates every config file against its schema

## Assumptions

1. Worker seat: runtime claude, model claude-opus-5-5, effort high (the architect's pick for this epic).
1. The scheduler specs live under specs/scheduler/ on branch feat/go-scheduler-design-one-xml-spec-per-domain-unde until its pull request lands on main; until then read them with git show origin/<that branch>:specs/scheduler/<file>.
1. Start only when no open pull request touches lint/lint.sh or the Jenkinsfile (owner rule: no file in two open pull requests).

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-12` Test plan rewritten by sched-architect: every go test case now runs as make -C scheduler test PKG='<package> -run <Test>' (the skeleton's Podman target, network off); a bare go command fails on the host (test.failed onb71 on WO-20261012-48ab). The lint ticket's negative case runs inside the lint image.

## Outcome

_Written by `work-order done`. Empty until then._
