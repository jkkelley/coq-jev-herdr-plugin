---
{
  "id": "WO-20261013-ccb8",
  "slug": "roadmap-i-flow-table-sh-the-per-ticket-stage-tab",
  "title": "Roadmap I - flow-table.sh, the per-ticket stage table moves from ~/.cache/coq-watch/flow-table.sh into line/bin/flow-table.sh with its test; the live copy runs from the repo and the cache copy is deleted",
  "type": "chore",
  "status": "done",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T17:51:51+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": "feat/roadmap-i-flow-table-sh-the-per-ticket-stage-tab",
  "pr": 131,
  "closed": "2026-10-13",
  "approval": {
    "via": "override",
    "reason": "architect ruling ykne9 2026-10-13 (Roadmap I split one ticket per script); lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [
    "WO-20261013-3a6e",
    "WO-20261013-acdd"
  ],
  "files": [
    "line/bin/flow-table.sh",
    "line/tests/cases/flow-table.sh"
  ]
}
---

# WO-20261013-ccb8 - Roadmap I - flow-table.sh, the per-ticket stage table moves from ~/.cache/coq-watch/flow-table.sh into line/bin/flow-table.sh with its test; the live copy runs from the repo and the cache copy is deleted

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

Owner 2026-10-12 22:49Z (m-20261012224955626-rjghl): every script lives in the project and only its artifacts outside. ~/.cache/coq-watch/flow-table.sh runs the line from outside git: never tested or reviewed, with hardcoded /home/luna paths. Split from WO-20261012-90ce (Roadmap I) under the size rule, one ticket per script (architect ruling ykne9).

## Scope

**In**

- line/bin/flow-table.sh behaves as ~/.cache/coq-watch/flow-table.sh does on 2026-10-13, breadcrumb header kept and extended with this ticket; it finds the repository root from its own location and the state root through bin/state-root.sh (COQ_STATE, then the ROADMAP.md default); no /home/luna and no .cache/coq-watch in the file, and every file it writes lands under the state root
- line/tests/cases/flow-table.sh: from a fixture records tree, each ticket's stage is its newest lifecycle record, minutes in stage are now minus that record, and the bottleneck is the stage with the most summed minutes
- after the merge (orchestrator lane): nothing runs it today; ~/.cache/coq-watch/flow-table.sh and its .bak copies are copied to the state root archive and deleted from the cache

**Out - non-goals**

- changing what the script does
- line/tests/lib/world.sh and line/tests/run.sh, shared by every case: stubs the case needs live in the case file
- line/README.md (the closing ticket of the split)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [x] `AC-H1` *(human)* the case passes and fails when the behaviour it names is broken; grep finds no /home/luna or .cache/coq-watch in line/bin/flow-table.sh; with COQ_STATE set to a temp dir every file the script writes lands under it; make lint and make -C line test pass
  - observed `2026-10-13` AC-H1 observed 2026-10-13 in test pane wD3:p194: CASES=flow-table passes (52 checks); it fails when broken - a tester seat.up counting as working, minutes halved, bottleneck by max wait, queued ranked, and scratch written under TMPDIR each failed named checks; grep of line/bin/flow-table.sh for /home/luna and .cache/coq-watch finds nothing (the case asserts it); with COQ_STATE set to a temp dir the run leaves nothing outside records/ and no scratch dir; make lint: all ok; make -C line test: 6 passed, 0 failed on three reruns (one earlier run failed board-t02-nudge-once under load average 18, a pre-existing race outside this ticket).
- [x] `AC-H2` *(human)* after the merge: pgrep -f coq-watch/flow-table.sh is empty, ~/.cache/coq-watch/flow-table.sh is gone, and the archive path is in a 200 note on this ticket
  - observed `2026-10-13` AC-H2 is the orchestrator lane after the merge (pgrep, delete of the cache copy, archive path in a 200 note); not done by this seat, nothing in this PR touches the cache directory.

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

- `2026-10-13` Correction to the AC-H1 evidence: the flow-table case makes 50 checks, not 52 (counted afterwards in the test pane); evidence is immutable, so the correction is here.
- `2026-10-13` Retro: the script moved with its behaviour unchanged; only the root discovery (script location plus bin/state-root.sh) and the scratch location (mktemp under the run tree, trap-removed) differ, and show done became show "done" for shellcheck SC1010. The test image has no column, so the case stubs it. board-t02-nudge-once (fifty callers at once) failed once at load average 18 and passed on four later runs: a load-sensitive race in a line case outside this ticket's files, for a separate ticket. AC-H2 (delete the cache copy and its two .bak copies after archiving them under the state root, pgrep empty) is the orchestrator lane after the merge.

## Outcome

_Written by `work-order done`. Empty until then._
