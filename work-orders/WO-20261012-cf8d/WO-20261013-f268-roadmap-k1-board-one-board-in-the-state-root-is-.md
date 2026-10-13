---
{
  "id": "WO-20261013-f268",
  "slug": "roadmap-k1-board-one-board-in-the-state-root-is-",
  "title": "Roadmap K1 - Board: one board in the state root is the single intake, with a lane per role, leases, pull, done, sweep, digest and the health line, built on the queue script's contract",
  "type": "feature",
  "status": "in-progress",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T00:56:43+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": "feat/roadmap-k1-board-one-board-in-the-state-root-is-",
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "owner accepted SPEC-17 on card C25; lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [
    "WO-20261013-ba44",
    "WO-20261013-70c4"
  ],
  "files": [
    "line/bin/board.sh",
    "line/config/board.json",
    "line/config/board.schema.json",
    "line/Makefile",
    "line/tests/run.sh",
    "line/tests/lib/*",
    "line/tests/cases/board-*.sh",
    "queue/config/queue.json"
  ]
}
---

# WO-20261013-f268 - Roadmap K1 - Board: one board in the state root is the single intake, with a lane per role, leases, pull, done, sweep, digest and the health line, built on the queue script's contract

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

Records reach seats through watches, copies and prompts that carry content; on 2026-10-12 that flooded the architect and replayed stale after a compaction. SPEC-17 s-board and s-lanes define one board every record lands on and every seat pulls from; nothing implements it.

## Scope

**In**

- line/bin/board.sh with the verbs of SPEC-17 s-lanes: post, pull, renew, done, release, sweep, list, digest, health, check; exit codes 0, 2, 3, 4, 6 like queue/bin/queue.sh; items are files, a lease is a field with a deadline, done is a move into the done tree named by the state-root rule
- line/config/board.json and line/config/board.schema.json: state_root (variable), lanes (the record schema's addressee roles plus owner), priorities p0 to p3, default_priority, lease_seconds, nudge_seconds, digest_seconds, retention_days, health_file; a missing key is exit 3 naming the key; no literal path
- the ticket lane stays queue/bin/queue.sh; items_dir in queue/config/queue.json moves under the state root
- line/Makefile with a test target that runs line/tests/run.sh in Podman like herdr/tests/run.sh; cases T01 to T03 and T14 of SPEC-17 s-tests as line/tests/cases/board-*.sh

**Out - non-goals**

- the health checks (K2)
- the orchestrator seat's duties (K3)
- routes rows and the router's post (K7)
- cards on the page (K6)
- moving records out of git (A1 to A4)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [x] `AC-H1` *(human)* an item posted to lane tester is pulled once by one holder, a second pull exits 6, done moves it to the done tree, and the item id equals the record id (T01)
  - observed `2026-10-13` make -C line test in the test pane: board-t01-post-pull pass; a posted tester item is pulled once, a second pull exits 6, done moves it to board/done/YYYY/MM/<stamp>-<id>.json, item id equals record id; twelve parallel pullers lease eight items exactly once
- [x] `AC-H2` *(human)* fifty records posted to the architect lane produce at most one nudge within digest_seconds (T02) and twenty queued nudges to one seat collapse into one pull with nothing lost (T03)
  - observed `2026-10-13` make -C line test: board-t02-nudge-once and board-t03-compaction-replay pass; fifty posts with a nudge call after each sent one prompt (fifty parallel callers also one); twenty nudge attempts collapsed into one pull with all twenty items still on the lane
- [x] `AC-H3` *(human)* board check exits 3 naming the key on a missing key or a literal path (T14), and make lint passes
  - observed `2026-10-13` make -C line test: board-t14-config pass, every required key removed gives exit 3 naming it, literal paths exit 3; make lint: all ok; tests: 4 passed, 0 failed

## Test plan

```sh
make lint && make -C line test, in Podman through the repository targets
```

## Assumptions

1. the state root variable follows config/state.json of A1 when present and the same default otherwise, so this ticket can start before A1 merges
1. the line tree is created here when roadmap item I has not landed; I moves the old scripts in beside these files, disjoint

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-13` Retro. Built line/bin/board.sh on queue.sh's contract, plus a claim-by-rename on every mutation (queue.sh rewrites in place and can double-lease). The suite caught find on a missing done tree failing health under pipefail. NOT done: items_dir of queue/config/queue.json is unchanged, because queue.sh only substitutes ${repo} and the move needs a change to queue/bin/queue.sh, which this ticket does not declare; a follow-up ticket is needed. Also deferred by scope: nothing posts to the board yet (router, K7) and nothing calls nudge (health watch, K2).

## Outcome

_Written by `work-order done`. Empty until then._
