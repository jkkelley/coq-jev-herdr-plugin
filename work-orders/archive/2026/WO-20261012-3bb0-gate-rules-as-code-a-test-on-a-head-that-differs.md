---
{
  "id": "WO-20261012-3bb0",
  "slug": "gate-rules-as-code-a-test-on-a-head-that-differs",
  "title": "Gate rules as code: a test on a head that differs only by records counts, a head that moves re-wakes the tester, and a PR conflicting with main gets main merged by its worker, all from routes and the merger's checks",
  "type": "feature",
  "status": "done",
  "priority": "p0",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T14:04:49+00:00",
  "parent": "WO-20261012-187e",
  "branch": "feat/gate-rules-as-code-a-test-on-a-head-that-differs",
  "pr": 28,
  "closed": "2026-10-12",
  "approval": {
    "via": "override",
    "reason": "lavish is prohibited for Claude seats; owner order 2026-10-12: get the factory working without the architect or owner as a gate",
    "at": "2026-10-12"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": []
}
---

# WO-20261012-3bb0 - Gate rules as code: a test on a head that differs only by records counts, a head that moves re-wakes the tester, and a PR conflicting with main gets main merged by its worker, all from routes and the merger's checks

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

The architect judged by hand that a test on efc1cd2 covered 43c22b4 (one record file apart), told testers to wait for moved heads, and woke workers to merge main on conflict; none of it is written down, so it stops when the architect does.

## Scope

**In**

- merger check: tree equality outside events/ counts as the same sha
- pr.opened on a PR whose tester has a run in flight supersedes it
- merge.conflict routes to the worker with merge main

**Out - non-goals**

- generated-file conflicts (WO-20261011-5064)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [x] `AC-H1` *(human)* the merger merges when test and review name shas whose trees differ only under events/, and holds when any other path differs
  - observed `2026-10-12` factory cases 12-gate and 13-gate-route, run in test pane wD3:p8J (make -C factory test: 18 passed 0 failed). gate.sh same-head treats a head one events/ record file apart as the same head and a code.txt change as different. In 13-gate-route a review.passed on B (tested on A, one record file apart) seats and wakes the merger with pr 5 sha B, and a review.passed on C (code.txt differs) is held: receipt 'held review.passed 201 (id): test.passed ... differ outside events/: code.txt', no merger seat, no 500.
- [x] `AC-H2` *(human)* a second pr.opened makes the tester drop the older head and post nothing for it
  - observed `2026-10-12` 13-gate-route case T4, same run: the second pr.opened wakes the tester with 'pr 9 sha C supersedes <first record id>'; a test.passed and a test.failed on the older head are held by head_current (receipt 'the head moved: pr.opened <id> names C'), so no reviewer wake, no worker wake, and the tester seat is not taken down; a test.passed on the newer head wakes the reviewer. Gap, not observed: the tester playbook has no words for supersedes because playbooks are rendered from roles/tester.json, which a worker may not edit, so the tester itself is not told to drop the run; nothing it posts for the old head is routed.

## Test plan

```sh
make -C factory test
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-12` Review changes bahk9: merged origin/main (generated files re-rendered, CONTEXT_STATE union of both sides). Playbooks cannot be edited by a worker, so the wake line now carries the instruction for supersedes (drop that run, post nothing for it) and merge main (fetch, merge origin/main, fix conflicts, push, post pr.opened); case 13 pins both. Still open for the architect: put the same steps into roles/tester.json and roles/worker.json so the playbooks say it.
- `2026-10-12` Test 422 bs49j (backlog disva): the factory suite was flaky. Causes: the host clock stepping back broke 'sleep 1 between records' ordering (08-break-glass, 10-sha, 03-escalate), and gate.sh log_all failed under pipefail when an unreadable record file was listed last (02-no-route). Fixed in world.sh evo, 08-break-glass, gate.sh and case 12-gate; 20 consecutive green runs of make -C factory test in the test pane.
- `2026-10-12` Correction to retro finding 5: the records this seat posted (work.started and pr.opened) were found in both the slot's events/ and the checkout's events/, so event.sh from a slot does reach the route runner; how the copy happens was not traced and is not claimed here.
- `2026-10-12` Retro. Built factory/bin/gate.sh and wired it through two routes.json row fields (when, supersede) and with merge-main; the flow watch now skips a gate whose consumer seat is working (busy_grace_seconds 1800 backstop). Findings: (1) roles/ is denied to a worker, so playbooks/tester.md and merger.md cannot yet say what to do with 'supersedes <id>' or cite gate.sh; the runner holds the stale results either way, but a roles edit is the architect's to make. (2) factory case 04-restart raced a TERM between the herdr prompt and its receipt and left the record 'claimed'; it now waits for receipts. (3) factory/schema/routes.schema.json and factory/config/routes.schema.json had drifted (the first lacked break-glass and none); both are now identical, and only the config copy is read by lint. (4) A held review.passed has no consumer record, so flow.sh will note it after stall_seconds, which is the intended alarm. (5) event.sh run inside a slot writes into the slot's events/, not the checkout the runner reads, so a worker record reaches the route runner only after the PR merges until the record bus ticket (WO-20261012-da52 - Record bus) lands.
- `2026-10-12` Add to scope at start: flow-watch stall rule (90s after a gate trigger with no next record) fired three false alarms on 2026-10-12 (ch471, 0ui6q-class, 06gu1) while the seat was mid-task; judge a stall by the seat's process/turn state, not a fixed timer.

## Outcome

_Written by `work-order done`. Empty until then._
