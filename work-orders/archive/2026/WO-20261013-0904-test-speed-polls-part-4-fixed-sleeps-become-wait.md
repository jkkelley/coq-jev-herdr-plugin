---
{
  "id": "WO-20261013-0904",
  "slug": "test-speed-polls-part-4-fixed-sleeps-become-wait",
  "title": "Test speed, polls part 4: fixed sleeps become wait_until polls in herdr cases 15-resume, 01-seat-up-check-down, 03-gate-and-caps, 05-recover, 08-treehouse-lease",
  "type": "feature",
  "status": "done",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T15:51:12+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": "feat/test-speed-polls-part-4-fixed-sleeps-become-wait",
  "pr": 138,
  "closed": "2026-10-13",
  "approval": {
    "via": "override",
    "reason": "architect P0 order 2026-10-13 (owner m-20261013154808303-p0c28: test suites cannot be the bottleneck); lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261013-892f"
  ],
  "blocks": [],
  "files": [
    "herdr/tests/cases/15-resume.test.sh",
    "herdr/tests/cases/01-seat-up-check-down.test.sh",
    "herdr/tests/cases/03-gate-and-caps.test.sh",
    "herdr/tests/cases/05-recover.test.sh",
    "herdr/tests/cases/08-treehouse-lease.test.sh"
  ]
}
---

# WO-20261013-0904 - Test speed, polls part 4: fixed sleeps become wait_until polls in herdr cases 15-resume, 01-seat-up-check-down, 03-gate-and-caps, 05-recover, 08-treehouse-lease

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

- every fixed sleep in these cases becomes wait_until on the condition it waited for; a sleep that is the thing under test stays with a comment

**Out - non-goals**

- herdr/tests/lib/world.sh (part 1)
- cases of other parts

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [x] `AC-H1` *(human)* these cases pass and carry no uncommented fixed sleep; make -C herdr test passes
  - observed `2026-10-13` Cases 01, 03, 05, 08 and 15 pass (tests: 5 passed, 0 failed) before and after, in the test pane (CASES='01 03 05 08 15' bash herdr/tests/run.sh); 4:12 before, 3:42 after on a host busy with other seats; grep shows no uncommented sleep left in the five files; make lint all ok. Per architect ruling 20:50Z the full make -C herdr test is verify's job after merge and was stopped.

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

- `2026-10-13` Retro: each fixed sleep was a guess at when a stub agent had echoed its first prompt (01, 03, 08, 15) or a 1 s loop step (05 gone); all became wait_until on the prompt text or herdr no longer answering for the agent, with an agent_shows/agent_absent helper local to each case since world.sh is out of scope. Full suite not run by this seat (architect ruling 20:50Z); baseline timing is noisy because other seats' suites share the host.

## Outcome

_Written by `work-order done`. Empty until then._
