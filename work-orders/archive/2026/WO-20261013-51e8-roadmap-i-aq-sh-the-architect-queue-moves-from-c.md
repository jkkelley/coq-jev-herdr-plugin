---
{
  "id": "WO-20261013-51e8",
  "slug": "roadmap-i-aq-sh-the-architect-queue-moves-from-c",
  "title": "Roadmap I - aq.sh, the architect queue moves from ~/.cache/coq-watch/aq.sh into line/bin/aq.sh with its test; the live copy runs from the repo and the cache copy is deleted",
  "type": "chore",
  "status": "done",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-14",
  "created_at": "2026-10-13T17:51:38+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": "feat/roadmap-i-aq-sh-the-architect-queue-moves-from-c",
  "pr": 121,
  "closed": "2026-10-14",
  "approval": {
    "via": "override",
    "reason": "architect ruling ykne9 2026-10-13 (Roadmap I split one ticket per script); lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [
    "WO-20261013-1258",
    "WO-20261013-4f4c",
    "WO-20261013-3a6e",
    "WO-20261013-acdd",
    "WO-20261014-8814"
  ],
  "files": [
    "line/bin/aq.sh",
    "line/tests/cases/aq.sh"
  ]
}
---

# WO-20261013-51e8 - Roadmap I - aq.sh, the architect queue moves from ~/.cache/coq-watch/aq.sh into line/bin/aq.sh with its test; the live copy runs from the repo and the cache copy is deleted

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

Owner 2026-10-12 22:49Z (m-20261012224955626-rjghl): every script lives in the project and only its artifacts outside. ~/.cache/coq-watch/aq.sh runs the line from outside git: never tested or reviewed, with hardcoded /home/luna paths. Split from WO-20261012-90ce (Roadmap I) under the size rule, one ticket per script (architect ruling ykne9).

## Scope

**In**

- line/bin/aq.sh behaves as ~/.cache/coq-watch/aq.sh does on 2026-10-13, breadcrumb header kept and extended with this ticket; it finds the repository root from its own location and the state root through bin/state-root.sh (COQ_STATE, then the ROADMAP.md default); no /home/luna and no .cache/coq-watch in the file, and every file it writes lands under the state root
- line/tests/cases/aq.sh: add, list and done against a temp queue dir: p0 sorts before p1, older before newer within a priority, done moves the file atomically, and an id added twice is one item
- after the merge (orchestrator lane): nothing runs it today; ~/.cache/coq-watch/aq.sh and its .bak copies are copied to the state root archive and deleted from the cache

**Out - non-goals**

- changing what the script does
- line/tests/lib/world.sh and line/tests/run.sh, shared by every case: stubs the case needs live in the case file
- line/README.md (the closing ticket of the split)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [x] `AC-H1` *(human)* the case passes and fails when the behaviour it names is broken; grep finds no /home/luna or .cache/coq-watch in line/bin/aq.sh; with COQ_STATE set to a temp dir every file the script writes lands under it; make lint and make -C line test pass
  - observed `2026-10-13` Case line/tests/cases/aq.sh passes (47 assertions) in the test pane through herdr/bin/testpane.sh, and fails under three mutations of line/bin/aq.sh (sort reversed: 5 failing assertions, dedupe removed: 6, done copies instead of moves: 3, a literal state path: 12). grep finds no /home/luna or .cache/coq-watch in line/bin/aq.sh. With COQ_STATE set to a temp dir the case finds no written file outside it. make lint exit 0, make -C line test: 6 passed, 0 failed.
- [x] `AC-H2` *(human)* after the merge: pgrep -f coq-watch/aq.sh is empty, ~/.cache/coq-watch/aq.sh is gone, and the archive path is in a 200 note on this ticket
  - observed `2026-10-14` NOT MET, split out, not ticked as done work: PR 121 is MERGED 2026-10-13T20:21:44Z, but at 2026-10-14 00:02Z pgrep -f coq-watch/aq.sh counts 0 process(es) and ~/.cache/coq-watch/aq.sh is exists, so the cutover has not happened. This criterion moved to WO-20261014-8814 - Roadmap I cutover (duplicate audit F7, ruled 2026-10-13T23:55Z); closing this ticket on AC-H1 (the merged code), per the ruling to split what cannot be observed.

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

- `2026-10-13` Retro: the test pane's lease check (treehouse status) found no slot leased to this ticket because the seat works in a start- worktree under ~/.cache/coq/.../worktrees, so the playbook's step 1 lease gate did not apply; the brief named the worktree and the work proceeded there. shellcheck SC1010 rejects a bare 'done' argument, so the case's helper is named queue and passes "done" quoted. AC-H2 (cache copy deleted, archive path in a 200 note) is the orchestrator lane after the merge.

## Outcome

_Written by `work-order done`. Empty until then._
