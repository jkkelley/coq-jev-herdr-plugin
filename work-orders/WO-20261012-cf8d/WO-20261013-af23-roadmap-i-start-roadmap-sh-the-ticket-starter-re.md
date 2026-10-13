---
{
  "id": "WO-20261013-af23",
  "slug": "roadmap-i-start-roadmap-sh-the-ticket-starter-re",
  "title": "Roadmap I - start-roadmap.sh, the ticket starter (renamed start-tickets.sh) moves from ~/.cache/coq-watch/start-roadmap.sh into line/bin/start-tickets.sh with its test; the live copy runs from the repo and the cache copy is deleted",
  "type": "chore",
  "status": "in-progress",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T17:53:56+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": "feat/roadmap-i-start-roadmap-sh-the-ticket-starter-re",
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect ruling ykne9 2026-10-13 (Roadmap I split one ticket per script); lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [
    "WO-20261013-acdd"
  ],
  "files": [
    "line/bin/start-tickets.sh",
    "line/tests/cases/start-tickets.sh"
  ]
}
---

# WO-20261013-af23 - Roadmap I - start-roadmap.sh, the ticket starter (renamed start-tickets.sh) moves from ~/.cache/coq-watch/start-roadmap.sh into line/bin/start-tickets.sh with its test; the live copy runs from the repo and the cache copy is deleted

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

Owner 2026-10-12 22:49Z (m-20261012224955626-rjghl): every script lives in the project and only its artifacts outside. ~/.cache/coq-watch/start-roadmap.sh runs the line from outside git: never tested or reviewed, with hardcoded /home/luna paths. Split from WO-20261012-90ce (Roadmap I) under the size rule, one ticket per script (architect ruling ykne9).

## Scope

**In**

- line/bin/start-tickets.sh behaves as ~/.cache/coq-watch/start-roadmap.sh does on 2026-10-13, breadcrumb header kept and extended with this ticket; it finds the repository root from its own location and the state root through bin/state-root.sh (COQ_STATE, then the ROADMAP.md default); no /home/luna and no .cache/coq-watch in the file, and every file it writes lands under the state root
- line/tests/cases/start-tickets.sh: with stub wo-start and git, each id is started in order, its worktree lands under COQ_CACHE and its log under the state root logs tree, never ~/.cache/coq-watch/start-roadmap.log
- after the merge (orchestrator lane): nothing runs it today; ~/.cache/coq-watch/start-roadmap.sh and its .bak copies are copied to the state root archive and deleted from the cache

**Out - non-goals**

- changing what the script does
- line/tests/lib/world.sh and line/tests/run.sh, shared by every case: stubs the case needs live in the case file
- line/README.md (the closing ticket of the split)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [x] `AC-H1` *(human)* the case passes and fails when the behaviour it names is broken; grep finds no /home/luna or .cache/coq-watch in line/bin/start-tickets.sh; with COQ_STATE set to a temp dir every file the script writes lands under it; make lint and make -C line test pass
  - observed `2026-10-13` make lint: all ok; make -C line test: 12 passed, 0 failed (start-tickets case included, run in the test pane wD3:p1E9). Mutation check: with the script changed to cut from HEAD, put the worktree outside COQ_CACHE and skip the worktree removal, the case fails 5 assertions. grep -c '/home/luna' and grep -c '.cache/coq-watch' on line/bin/start-tickets.sh both 0. With COQ_STATE and COQ_CACHE set, the case asserts HOME stays empty and the log is one dated file under the state root logs tree, the worktree under COQ_CACHE.
- [ ] `AC-H2` *(human)* after the merge: pgrep -f coq-watch/start-roadmap.sh is empty, ~/.cache/coq-watch/start-roadmap.sh is gone, and the archive path is in a 200 note on this ticket

## Test plan

```sh
make lint && make -C line test, in Podman through the repository targets
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

- `2026-10-13` Retro: the port was mechanical. Changes beyond the move: every expansion quoted, cd failures now exit (shellcheck SC2164), the log is one dated file per run under the logs tree and not one file appended forever. A failed id still leaves its worktree under COQ_CACHE until the next start of that id removes it (as before; recorded in the breadcrumb). AC-H2 (cache copy archived and deleted after merge) is the orchestrator lane and is not done by this seat.

## Outcome

_Written by `work-order done`. Empty until then._
