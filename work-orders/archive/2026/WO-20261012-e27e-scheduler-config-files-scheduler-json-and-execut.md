---
{
  "id": "WO-20261012-e27e",
  "slug": "scheduler-config-files-scheduler-json-and-execut",
  "title": "Scheduler config files: scheduler.json and executor.json with their schemas, every key of SPEC-16.G, variables only, validated by the repository lint",
  "type": "feature",
  "status": "done",
  "priority": "p0",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T19:36:52+00:00",
  "parent": "WO-20261012-ea33",
  "branch": "feat/scheduler-config-files-scheduler-json-and-execut",
  "pr": 38,
  "closed": "2026-10-12",
  "approval": {
    "via": "override",
    "reason": "architect: lavish is prohibited for Claude seats; cut from SPEC-16 by the scheduler architect with disjoint files and a generated test plan; owner order on the bearings page 2026-10-12 18:34Z, CRITICAL",
    "at": "2026-10-12"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [
    "WO-20261012-9790",
    "WO-20261012-d7f4"
  ]
}
---

# WO-20261012-e27e - Scheduler config files: scheduler.json and executor.json with their schemas, every key of SPEC-16.G, variables only, validated by the repository lint

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

The scheduler holds no default for any key, so the two files and their schemas must exist, complete and validated, before the loader and the executor are written.

## Scope

**In**

- Owns: scheduler/config/
- scheduler/config/scheduler.json with every key of SPEC-16.G g-keys, values as variables where a path or a host-specific value would otherwise appear
- scheduler/config/scheduler.schema.json with additionalProperties false, required for every key, types and ranges as the spec states
- scheduler/config/executor.json with every key of SPEC-16.G g-executor and the full verb table of SPEC-16.H h-verbs: name, argv, timeout_seconds, final, and the allowed flag set of the record verb
- scheduler/config/executor.schema.json with additionalProperties false

**Out - non-goals**

- editing any file outside the directories this ticket owns, in particular scheduler/go.mod, scheduler/internal/core/ and any other ticket's package
- adding a dependency to the module (ask the architect)
- writing a record file directly; records go through the executor's record verb
- any Go code
- changing a table under factory/config

## Degrees of freedom

- [free] the numeric values of windows, deadlines and retry keys, within the spec's words (for example a tester acknowledgement window longer than a reviewer's)

## Acceptance criteria

- [x] `AC-H1` *(human)* make lint reports configs: schema ok with both files validated against their schemas
  - observed `2026-10-12` make lint in Podman (coq-lint:1): 'configs: schema ok' and 'lint: all ok'. The step reaches scheduler/config: with a relative $id it failed on scheduler.schema.json (RefResolutionError) before the urn $id fix.
- [x] `AC-H2` *(human)* every key named in SPEC-16.G g-keys and g-executor is present with the stated type; a key the specs do not name is absent
  - observed `2026-10-12` Script in the lint image parsed SPEC-16.G XML: scheduler.json keys == g-keys (48), executor.json keys == g-executor (9), both schemas' required == the registries. Schemas refuse a missing key, an unknown key, a literal path, mode 'on', jitter 1, log level 'verbose'.
- [x] `AC-H3` *(human)* no line of either file matches the forbidden patterns of specs/scheduler/config/check.json (home path, host, key, person, ticket id)
  - observed `2026-10-12` TP-2 in the pinned lint image: grep -nE '/home/|localhost|://' scheduler/config/*.json; test $? -eq 1 -> exit 0. Every line of both files checked against all 8 forbidden regexes of specs/scheduler/config/check.json: no match.
- [x] `AC-H4` *(human)* every verb of SPEC-16.H h-verbs is in the table with the argv, timeout and final codes the spec states
  - observed `2026-10-12` Script compared executor.json verbs to SPEC-16.H h-verbs XML: 15 of 15 names, argv (split on spaces), timeout_seconds and final equal; record flags == h-verbs-record-flags (13). Schema refuses a missing verb, an extra 'shell' verb, record flag 'seat', a verb without final, an argv ${repo}.

## Test plan

_Test plan from claude/workflow/templates/test-plan.md, shaped by claude/workflow/schemas/test-plan.schema.json. The tester runs exactly these cases and nothing else._

**Scope under test**

The scheduler's two config files and their schemas.

**Cases**

- `TP-1`
  - intent: The repository lint covers the files. (spec case g-t6)
  - command: `make lint`
  - expected: configs: schema ok, with scheduler.json and executor.json validated against their schemas
- `TP-2`
  - intent: the acceptance criterion this command proves, as the ticket states it
  - command: `grep -nE '/home/|localhost|://' scheduler/config/*.json; test $? -eq 1`
  - expected: exit 0: no forbidden pattern in the files

**Isolation**

- runtime: podman
- image: `localhost/coq-lint@sha256:d2f6ded8d64627b8e7c02552431a4205431312d2570f1562313d8d26dc815077` (coq-lint:1, the repository lint image)

**Out of scope - CI covers**

- CI runs make -C scheduler test over the whole module on every change under scheduler/
- make lint on the repository validates every config file against its schema

## Assumptions

1. Worker seat: runtime claude, model claude-opus-5-5, effort high (the architect's pick for this epic).
1. The scheduler specs live under specs/scheduler/ on branch feat/go-scheduler-design-one-xml-spec-per-domain-unde until its pull request lands on main; until then read them with git show origin/<that branch>:specs/scheduler/<file>.

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-12` Retro: keys are flat and dotted because g-keys names both seat (string) and seat.busy_regex; nesting would collide. $schema is omitted because TP-2 greps every file for '://' (jsonschema 4.10 defaults to 2020-12); $id is a urn because a relative $id broke $ref resolution in the lint. host_repo is ${ENV:COQ_REPO} in both files; repo, state_dir, mode and session are ENV variables the run wrapper sets. Free values: poll 2, deadlines 600-900 within visible 900, tester ack 180 over reviewer 120.

## Outcome

_Written by `work-order done`. Empty until then._
