---
{
  "id": "WO-20261012-9790",
  "slug": "scheduler-config-package-the-loader-for-schedule",
  "title": "Scheduler config package: the loader for scheduler.json and executor.json, variables, no defaults, cross checks at start and hot reload of the tables, per SPEC-16.G",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T19:37:11+00:00",
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
    "WO-20261012-48ab",
    "WO-20261012-e27e"
  ],
  "blocks": [
    "WO-20261012-8e69",
    "WO-20261012-7a9a",
    "WO-20261012-6e43",
    "WO-20261012-3c7a",
    "WO-20261012-1ccf"
  ]
}
---

# WO-20261012-9790 - Scheduler config package: the loader for scheduler.json and executor.json, variables, no defaults, cross checks at start and hot reload of the tables, per SPEC-16.G

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

Every tunable comes from the two files; a missing or unknown key must be named, variables resolved, and a changed table swapped whole or not at all while the scheduler runs.

## Scope

**In**

- Owns: scheduler/internal/config/
- package config: Load, variable resolution, the typed configuration every domain reads, the cross checks of SPEC-16.G g-validate, and a Reloader that watches the tables by size and mtime
- tests for every case of SPEC-16.G g-tests except g-t6 (the repository lint)

**Out - non-goals**

- editing any file outside the directories this ticket owns, in particular scheduler/go.mod, scheduler/internal/core/ and any other ticket's package
- adding a dependency to the module (ask the architect)
- writing a record file directly; records go through the executor's record verb
- the tables' own checks (routes and policies packages own them; the reloader calls them)

## Degrees of freedom

- [free] the shape of the typed configuration struct, as long as every key of g-keys and g-executor maps to one field

## Acceptance criteria

- [ ] `AC-H1` *(human)* every case of SPEC-16.G g-tests but g-t6 passes in Podman
- [ ] `AC-H2` *(human)* loading scheduler/config/scheduler.json and executor.json with the variables set succeeds; removing any key fails naming it
- [ ] `AC-H3` *(human)* a Go literal fallback for any key is absent (grep for the key names finds no default assignment)

## Test plan

_Test plan from claude/workflow/templates/test-plan.md, shaped by claude/workflow/schemas/test-plan.schema.json. The tester runs exactly these cases and nothing else._

**Scope under test**

The config package.

**Cases**

- `TP-1`
  - intent: A missing key is named. (spec case g-t1)
  - command: `make -C scheduler test PKG='./internal/config -run TestMissingKeyNamed'`
  - expected: exit 0: a file lacking one key fails with exit 3 and the key's dotted name in the error
- `TP-2`
  - intent: No silent extras. (spec case g-t2)
  - command: `make -C scheduler test PKG='./internal/config -run TestUnknownKeyRefused'`
  - expected: exit 0: a file with an extra key fails naming it
- `TP-3`
  - intent: Portable values. (spec case g-t3)
  - command: `make -C scheduler test PKG='./internal/config -run TestVariablesResolved'`
  - expected: exit 0: repo, state_dir, host_repo, HOME and ENV names resolve; an unknown variable or unset name fails naming it
- `TP-4`
  - intent: Cross checks at start. (spec case g-t4)
  - command: `make -C scheduler test PKG='./internal/config -run TestCrossChecks'`
  - expected: exit 0: a role without an acknowledgement window, a gate kind without a deadline, and a broken visible bound each fail naming the key
- `TP-5`
  - intent: Whole or not at all. (spec case g-t5)
  - command: `make -C scheduler test PKG='./internal/config -run TestReloadSwapsWholeOrNot'`
  - expected: exit 0: a changed valid table is swapped with a new version; a changed invalid one leaves the old version in place with one note

**Isolation**

- runtime: podman
- image: `docker.io/library/golang@sha256:116d58cbd88c1297624acc6e967a060012422bacf9930927e23fb719189c6f36` (golang:1.26-bookworm, pulled 2026-08)

**Out of scope - CI covers**

- CI runs make -C scheduler test over the whole module on every change under scheduler/
- make lint on the repository validates every config file against its schema

## Assumptions

1. Worker seat: runtime claude, model claude-opus-5-5, effort high (the architect's pick for this epic).
1. The scheduler specs live under specs/scheduler/ on branch feat/go-scheduler-design-one-xml-spec-per-domain-unde until its pull request lands on main; until then read them with git show origin/<that branch>:specs/scheduler/<file>.
1. Go builds and tests run only in Podman through make -C scheduler targets; nothing runs on the host.

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-12` Test plan rewritten by sched-architect: every go test case now runs as make -C scheduler test PKG='<package> -run <Test>' (the skeleton's Podman target, network off); a bare go command fails on the host (test.failed onb71 on WO-20261012-48ab). The lint ticket's negative case runs inside the lint image.
- `2026-10-12` Correction: the runtime group is image (name and tag), memory, container_name as plain strings and image_digest as a variable from the environment COQ_SCHED_IMAGE_DIGEST; case g-t7 reads accordingly (SPEC-16.G 1.1.0).
- `2026-10-12` SPEC-16.G 1.1.0 (PR 37): the loader knows the runtime group (runtime.image, runtime.memory, runtime.container_name, plain strings, refused if they carry a variable) and reports it in Status; case g-t7 added to the spec, add it to this test plan at start.

## Outcome

_Written by `work-order done`. Empty until then._
