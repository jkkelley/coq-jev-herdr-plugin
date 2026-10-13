---
{
  "id": "WO-20261013-9040",
  "slug": "a-tester-plan-runs-reindex-check-in-a-fresh-tree",
  "title": "A tester plan runs reindex --check in a fresh tree where INDEX.md is gitignored, so it fails on a clean main",
  "type": "bug",
  "status": "ready",
  "priority": "p1",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T13:20:39+00:00",
  "parent": "WO-20261013-16f1",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect P0 order 2026-10-13 (owner m-20261013162710557-e4nos: always a system loop), approved by the architect in the owner place (card C29); lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [],
  "files": [
    "bin/aggregates.sh",
    "Makefile",
    "lint/lint.sh"
  ]
}
---

# WO-20261013-9040 - A tester plan runs reindex --check in a fresh tree where INDEX.md is gitignored, so it fails on a clean main

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

work-orders/INDEX.md is gitignored (.gitignore:114, WO-20261012-aac3), so a fresh worktree has none and work-order.sh reindex --check (vendored SKILL.md:354, exit 3 when INDEX.md and the tickets disagree) fails with nothing to compare. A tester ran the plan for PR 87 that way and posted test.failed 422 20261013T032847Z-422-emr6m; the architect ruled it false (7vx39, 20261013T130356Z-100-7vx39: reindex then reindex --check exit 0 on ae4bf50, same as main). The failed record also reached the worker via route.sh, which failed to prompt a gone worker (20261013T032908Z-500-nglal). Cause is that the repo gives a plan author the bare verb, not a command that is correct in a clean tree. Rejected: tracking INDEX.md again (it made every PR clash, aac3).

## Scope

**In**

- bin/aggregates.sh gains --check: it runs reindex then reindex --check and exits with the check's code, so one command is right in a fresh tree where work-orders/INDEX.md is gitignored
- make aggregates-check calls it; lint refuses a ticket test plan that contains reindex --check without a preceding reindex

**Out - non-goals**

- the vendored work-order skill (upstream in dotfiles)
- the tester role and the suites map, which name make aggregates-check through WO-20261013-dd11 and WO-20261013-f1ff

## Degrees of freedom

- [free] make target name, as long as it is documented in the Makefile help

## Acceptance criteria

- [ ] `AC-H1` *(human)* in a fresh clone make aggregates-check exits 0 on main
- [ ] `AC-H2` *(human)* a plan with a bare reindex --check fails lint with a message naming aggregates-check

## Test plan

```sh
make lint && make -C factory test, in Podman through the repository targets; make aggregates-check exits 0 in a fresh clone
```

## Assumptions

1. Roadmap G (aac3) is merged, so aggregates.sh already works in a clean checkout

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
