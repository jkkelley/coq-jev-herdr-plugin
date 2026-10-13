---
{
  "id": "WO-20261013-7719",
  "slug": "roadmap-i-merge-watch-sh-the-1-minute-merge-watc",
  "title": "Roadmap I - merge-watch.sh, the 1-minute merge watch moves from ~/.cache/coq-watch/merge-watch.sh into line/bin/merge-watch.sh with its test; the live copy runs from the repo and the cache copy is deleted",
  "type": "chore",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T17:52:56+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": null,
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
    "line/bin/merge-watch.sh",
    "line/tests/cases/merge-watch.sh"
  ]
}
---

# WO-20261013-7719 - Roadmap I - merge-watch.sh, the 1-minute merge watch moves from ~/.cache/coq-watch/merge-watch.sh into line/bin/merge-watch.sh with its test; the live copy runs from the repo and the cache copy is deleted

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

Owner 2026-10-12 22:49Z (m-20261012224955626-rjghl): every script lives in the project and only its artifacts outside. ~/.cache/coq-watch/merge-watch.sh runs the line from outside git: never tested or reviewed, with hardcoded /home/luna paths. Split from WO-20261012-90ce (Roadmap I) under the size rule, one ticket per script (architect ruling ykne9).

## Scope

**In**

- line/bin/merge-watch.sh behaves as ~/.cache/coq-watch/merge-watch.sh does on 2026-10-13, breadcrumb header kept and extended with this ticket; it finds the repository root from its own location and the state root through bin/state-root.sh (COQ_STATE, then the ROADMAP.md default); no /home/luna and no .cache/coq-watch in the file, and every file it writes lands under the state root
- line/tests/cases/merge-watch.sh: with a stub gh, the first run seeds past merges without a prompt, one new merge gives exactly one stubbed prompt to the target seat, a second tick repeats nothing, and the halt flag ends it
- after the merge (orchestrator lane): the running ~/.cache/coq-watch/merge-watch.sh instance is stopped and started from $COQ_REPO/line/bin/merge-watch.sh in the pane that runs it today, then ~/.cache/coq-watch/merge-watch.sh and its .bak copies are copied to the state root archive and deleted from the cache

**Out - non-goals**

- changing what the script does
- line/tests/lib/world.sh and line/tests/run.sh, shared by every case: stubs the case needs live in the case file
- line/README.md (the closing ticket of the split)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* the case passes and fails when the behaviour it names is broken; grep finds no /home/luna or .cache/coq-watch in line/bin/merge-watch.sh; with COQ_STATE set to a temp dir every file the script writes lands under it; make lint and make -C line test pass
- [ ] `AC-H2` *(human)* after the merge: pgrep -f coq-watch/merge-watch.sh is empty, ~/.cache/coq-watch/merge-watch.sh is gone, and the archive path is in a 200 note on this ticket

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

## Outcome

_Written by `work-order done`. Empty until then._
