---
{
  "id": "WO-20261013-acbf",
  "slug": "roadmap-i-route-retry-sh-the-failed-route-retry-",
  "title": "Roadmap I - route-retry.sh, the failed-route retry moves from ~/.cache/coq-watch/route-retry.sh into line/bin/route-retry.sh with its test; the live copy runs from the repo and the cache copy is deleted",
  "type": "chore",
  "status": "in-progress",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T17:53:29+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": "feat/roadmap-i-route-retry-sh-the-failed-route-retry-",
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
    "line/bin/route-retry.sh",
    "line/tests/cases/route-retry.sh"
  ]
}
---

# WO-20261013-acbf - Roadmap I - route-retry.sh, the failed-route retry moves from ~/.cache/coq-watch/route-retry.sh into line/bin/route-retry.sh with its test; the live copy runs from the repo and the cache copy is deleted

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

Owner 2026-10-12 22:49Z (m-20261012224955626-rjghl): every script lives in the project and only its artifacts outside. ~/.cache/coq-watch/route-retry.sh runs the line from outside git: never tested or reviewed, with hardcoded /home/luna paths. Split from WO-20261012-90ce (Roadmap I) under the size rule, one ticket per script (architect ruling ykne9).

## Scope

**In**

- line/bin/route-retry.sh behaves as ~/.cache/coq-watch/route-retry.sh does on 2026-10-13, breadcrumb header kept and extended with this ticket; it finds the repository root from its own location and the state root through bin/state-root.sh (COQ_STATE, then the ROADMAP.md default); no /home/luna and no .cache/coq-watch in the file, and every file it writes lands under the state root
- line/tests/cases/route-retry.sh: a failed ledger entry for a gate record whose trouble note says max_seats or max_agents is cleared when a seat of that role is free (stub herdr agent list), and left alone when none is free
- after the merge (orchestrator lane): the running ~/.cache/coq-watch/route-retry.sh instance is stopped and started from $COQ_REPO/line/bin/route-retry.sh in the pane that runs it today, then ~/.cache/coq-watch/route-retry.sh and its .bak copies are copied to the state root archive and deleted from the cache

**Out - non-goals**

- changing what the script does
- line/tests/lib/world.sh and line/tests/run.sh, shared by every case: stubs the case needs live in the case file
- line/README.md (the closing ticket of the split)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [x] `AC-H1` *(human)* the case passes and fails when the behaviour it names is broken; grep finds no /home/luna or .cache/coq-watch in line/bin/route-retry.sh; with COQ_STATE set to a temp dir every file the script writes lands under it; make lint and make -C line test pass
  - observed `2026-10-13` line/tests/cases/route-retry.sh: 6 cases passed in test pane wD3:p18N (make lint exit 0, make -C line test: tests 6 passed 0 failed). Mutation: replacing the role capacity check in line/bin/route-retry.sh with true made the case FAIL on 6 checks, restored. grep -c '/home/luna' and '.cache/coq-watch' on the script: 0 and 0. With COQ_STATE and HOME set to scratch dirs the script wrote nothing outside the state root (HOME stayed empty).
- [x] `AC-H2` *(human)* after the merge: pgrep -f coq-watch/route-retry.sh is empty, ~/.cache/coq-watch/route-retry.sh is gone, and the archive path is in a 200 note on this ticket
  - observed `2026-10-13` Not observable on the branch: after-merge orchestrator lane step. The running cache instance (pid 511033, started 13:02Z) is still up and the cache copy still exists, deliberately; nothing was stopped or deleted by this ticket.

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

- `2026-10-13` Retro: moved the script to line/bin/route-retry.sh with a 6-case test. Two things differ from a byte copy, both forced by roadmap A2: the ledger entry is now named like the record FILE, not the record id, so the key is mapped to its record file and id before the failure note is searched; and the ledger, records and seats paths come from bin/state-root.sh and herdr.json instead of the old checkout trees. The cutoff 20261012170000 became ROUTE_RETRY_SINCE. Orchestrator lane after merge (AC-H2): the live cache instance is pid 511033; note the live ledger holds 104 failed entries since the cutoff, so the first pass clears only as many as there are free slots (the pending count). Cache copy and its .bak files are archived to the state root archive, then deleted, by the orchestrator.

## Outcome

_Written by `work-order done`. Empty until then._
