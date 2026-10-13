---
{
  "id": "WO-20261013-2298",
  "slug": "cause-t-part-2-nothing-checks-who-changed-roles-",
  "title": "Cause t, part 2: nothing checks who changed roles/, specs/ or graph/; gate.sh pr-fence holds a pull request that changes them unless its ticket was seated as spec-author",
  "type": "bug",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T20:02:11+00:00",
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
  "depends_on": [],
  "blocks": [
    "WO-20261013-4464",
    "WO-20261012-7a46"
  ],
  "files": [
    "factory/bin/gate.sh",
    "factory/tests/cases/24-gate-pr-fence.test.sh"
  ]
}
---

# WO-20261013-2298 - Cause t, part 2: nothing checks who changed roles/, specs/ or graph/; gate.sh pr-fence holds a pull request that changes them unless its ticket was seated as spec-author

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

Settings deny rules fence the tools, not the shell, so a worker seat can still change roles/, specs/ or graph/ (PR 118 and PR 125, 2026-10-13). Lint cannot catch it: it runs in a container with no git and no state root (lint/check-conflict-markers.sh breadcrumb), so it sees neither the diff nor the seat. The gate already checks a diff against its ticket (gate.sh pr-files), so the fence check sits beside it.

## Scope

**In**

- factory/bin/gate.sh pr-fence --ticket ID [--base REF] [--head REF]: 0 when the diff touches nothing under roles/, specs/ or graph/, or when every seat.up record for the ticket in the records tree names role spec-author; 1 hold, each fenced path and the seat role on one line; 4 io; the header gains the verb and a breadcrumb
- factory/tests/cases/24-gate-pr-fence.test.sh: a roles/ change seated as worker holds, the same change seated as spec-author passes, a diff outside the three trees passes

**Out - non-goals**

- calling the verb from merge.sh (part 3)
- lint/lint.sh, which cannot see git or the state root

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* the case passes and fails when the role check is removed; make lint and make -C factory test pass

## Test plan

```sh
make lint && make -C factory test, in Podman through the repository targets
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
