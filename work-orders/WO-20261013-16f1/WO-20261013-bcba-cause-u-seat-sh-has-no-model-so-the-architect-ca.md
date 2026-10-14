---
{
  "id": "WO-20261013-bcba",
  "slug": "cause-u-seat-sh-has-no-model-so-the-architect-ca",
  "title": "Cause u: seat.sh has no --model, so the architect cannot start a tester on Sonnet; seat.sh --model is honoured only when the role's model.architect_may_override is true",
  "type": "bug",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-14",
  "created_at": "2026-10-13T20:01:46+00:00",
  "parent": "WO-20261013-16f1",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect ruling 2026-10-13 20:12Z (causes t and u); lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261013-d127",
    "WO-20261013-0ad7"
  ],
  "blocks": [
    "WO-20261013-d0dd"
  ],
  "files": [
    "herdr/bin/seat.sh",
    "herdr/tests/cases/37-seat-model-override.test.sh"
  ]
}
---

# WO-20261013-bcba - Cause u: seat.sh has no --model, so the architect cannot start a tester on Sonnet; seat.sh --model is honoured only when the role's model.architect_may_override is true

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

Ruling 20:09Z put new testers on Sonnet until the CI gate lands, but herdr/bin/seat.sh:484 takes the model from the role file only (MODEL from .model[runtime]) and has no flag, so every override was a hand restart in the pane. The role schema already carries model.architect_may_override (roles/schema/role.schema.json:102; true for worker, tester, reviewer, merger, player).

## Scope

**In**

- herdr/bin/seat.sh up accepts --model M; when the role file's model.architect_may_override is true the seat starts on M and the seat record and seat.up note name M; when it is false or absent seat.sh refuses with the role name and starts nothing
- herdr/tests/cases/37-seat-model-override.test.sh: an overridable role starts on the given model and records it; a role without the flag is refused and no agent starts

**Out - non-goals**

- changing any role's model or flag
- the roles/ fence (cause t)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* the case passes and fails when the flag check is removed; make lint and make -C herdr test pass

## Test plan

```sh
make lint && make -C herdr test, in Podman through the repository targets
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-14` Duplicate audit ruling 2026-10-13T23:55Z (F15): this ticket is interim. It fixes the live tester-era line and retires with WO-20261013-3eac (CI gate 5), which retires the tester role; nobody extends it past that.
- `2026-10-13` Overlap with WO-20261013-69df (PR 143): both change herdr/bin/seat.sh, and 69df also changes seat-lib.sh and adds herdr/tests/cases/36-seat-canonical-state-root.test.sh. Do not start this ticket until PR 143 is merged; start it from the merged main, so no two in-flight tickets share seat.sh. Case 37 here follows 69df's case 36.

## Outcome

_Written by `work-order done`. Empty until then._
