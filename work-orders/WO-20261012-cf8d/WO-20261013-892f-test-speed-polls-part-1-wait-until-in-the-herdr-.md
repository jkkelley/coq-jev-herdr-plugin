---
{
  "id": "WO-20261013-892f",
  "slug": "test-speed-polls-part-1-wait-until-in-the-herdr-",
  "title": "Test speed, polls part 1: wait_until in the herdr test world, and the fixed sleeps of 20-reseat and 10-down-slot-processes become polls",
  "type": "feature",
  "status": "in-progress",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T15:51:04+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": "feat/test-speed-polls-part-1-wait-until-in-the-herdr-",
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

- [x] `AC-H1` *(human)* the two cases pass, carry no uncommented fixed sleep and run faster than before; make -C herdr test passes
  - observed `2026-10-13` Cases 10 and 20 pass (CASES='10 20', tests: 2 passed, 0 failed) in 180 s against 220 s for the same two cases on the unmodified base, run in the test pane through testpane.sh; every sleep left in them is commented (sleep 3016 and 3017 are the processes under test, world.sh's sleep 30 is an idle slot command, wait_until's 0.2 s is the poll interval). make lint passes. make -C herdr test: 26 passed, 1 failed - 12-blueprint-panes, which fails identically on the unmodified base (dev server serves 'no page yet (nothing promoted)'); its files are another ticket's, so it is reported, not fixed here.

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

- `2026-10-13` Retro. Worked: probing the monitor pane's process-info once showed the interrupt condition (foreground pid equals shell_pid); grace waits poll the supervisor's own dead marker, with the previous tick's end as the stand-in for a seat the tick skipped. Slow: the full suite takes about 19 minutes, so the proof loop was cases 10 and 20 alone (3 min). Found: 12-blueprint-panes fails on main (dev serves no page, nothing promoted) - needs its own ticket; its two fixed-sleep loops are for parts 2 to 5. The treehouse lease check in playbooks/worker.md step 1 cannot hold for a work-order start worktree (path start-WO-..., not a pool slot) - the brief named this worktree, so I proceeded; the playbook line wants updating. The work.started record was posted with seat worker-892f because COQ_SEAT (worker-wo-20261013-892f) was not read before posting.

## Outcome

_Written by `work-order done`. Empty until then._
