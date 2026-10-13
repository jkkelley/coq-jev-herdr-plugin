---
{
  "id": "WO-20261013-892f",
  "slug": "test-speed-polls-part-1-wait-until-in-the-herdr-",
  "title": "Test speed, polls part 1: wait_until in the herdr test world, and the fixed sleeps of 20-reseat and 10-down-slot-processes become polls",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T15:51:04+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect P0 order 2026-10-13 (owner m-20261013154808303-p0c28: test suites cannot be the bottleneck); lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [
    "WO-20261013-2b64",
    "WO-20261013-b2fe",
    "WO-20261013-0904",
    "WO-20261013-f2c0"
  ],
  "files": [
    "herdr/tests/lib/world.sh",
    "herdr/tests/cases/20-reseat.test.sh",
    "herdr/tests/cases/10-down-slot-processes.test.sh"
  ]
}
---

# WO-20261013-892f - Test speed, polls part 1: wait_until in the herdr test world, and the fixed sleeps of 20-reseat and 10-down-slot-processes become polls

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

Owner 2026-10-13: test suites cannot be the bottleneck. Every suite runs its cases one after another, every pull request reruns whole suites main already ran, and herdr cases wait on fixed sleeps. Design: $COQ_STATE/plans/2026/10/20261013160000-test-speed-design.md (section d-shape 5)

## Scope

**In**

- herdr/tests/lib/world.sh: wait_until SECONDS CMD... polls every 0.2s and fails naming CMD; its own three sleeps become polls
- herdr/tests/cases/20-reseat and 10-down-slot-processes: every fixed sleep becomes wait_until on the condition it waited for; a sleep that is the thing under test stays with a comment

**Out - non-goals**

- other cases (parts 2 to 5)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* the two cases pass, carry no uncommented fixed sleep and run faster than before; make -C herdr test passes

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

## Outcome

_Written by `work-order done`. Empty until then._
