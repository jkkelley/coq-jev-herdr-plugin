---
{
  "id": "WO-20261013-2b64",
  "slug": "test-speed-polls-part-2-fixed-sleeps-become-wait",
  "title": "Test speed, polls part 2: fixed sleeps become wait_until polls in herdr cases 11-guard-ack-nudge, 06-unfreeze, 17-pane-health, 09-testpane-subshell, 13-recover-belt",
  "type": "feature",
  "status": "done",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T15:51:07+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": "feat/test-speed-polls-part-2-fixed-sleeps-become-wait",
  "pr": 139,
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
    "herdr/tests/cases/11-guard-ack-nudge.test.sh",
    "herdr/tests/cases/06-unfreeze.test.sh",
    "herdr/tests/cases/17-pane-health.test.sh",
    "herdr/tests/cases/09-testpane-subshell.test.sh",
    "herdr/tests/cases/13-recover-belt.test.sh"
  ]
}
---

# WO-20261013-2b64 - Test speed, polls part 2: fixed sleeps become wait_until polls in herdr cases 11-guard-ack-nudge, 06-unfreeze, 17-pane-health, 09-testpane-subshell, 13-recover-belt

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
  - observed `2026-10-13` 2026-10-13 Cases 06-unfreeze, 09-testpane-subshell, 11-guard-ack-nudge, 13-recover-belt, 17-pane-health pass (CASES run from the test pane through testpane.sh, tests: 5 passed, 0 failed) in 202 s against 257 s for the same five on an unmodified export of HEAD b68be5b. make lint passes. Per the architect ruling of 20:50Z the full make -C herdr test was not run by this seat (a run started before the ruling was stopped); verify runs it after merge. Sleeps left, all commented as the thing under test (absence of a prompt has nothing to poll): 11 x2, 06 x1; wait_until's 0.2 s is the poll interval. 17's sleep 600 is the process under test. No JOBS option or bin/test-cases.sh exists yet, so the runs were serial.

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

- `2026-10-13` Retro: 5 cases converted. Three helper shapes recur (pane_bare, pane_idle, fg_has) and are copied per case, not put in world.sh, because world.sh is part 1's file and no open PR may touch it twice; a follow-up can lift them. Absence checks (no second prompt, no prompt to a working seat, no wake to a reviewer) keep a commented sleep. 09's failing-command step now touches a marker so the wait cannot pass before the command ran. The architect ruling mid-ticket (workers run only the cases their diff touches) cut the full-suite proof.

## Outcome

_Written by `work-order done`. Empty until then._
