---
{
  "id": "WO-20261013-4f4c",
  "slug": "roadmap-i-architect-rounds-sh-the-architect-s-1-",
  "title": "Roadmap I - architect-rounds.sh, the architect's 1-minute fact sheet moves from ~/.cache/coq-watch/architect-rounds.sh into line/bin/architect-rounds.sh with its test; the live copy runs from the repo and the cache copy is deleted",
  "type": "chore",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T17:52:17+00:00",
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
  "depends_on": [
    "WO-20261013-51e8",
    "WO-20261013-1258"
  ],
  "blocks": [
    "WO-20261013-acdd"
  ],
  "files": [
    "line/bin/architect-rounds.sh",
    "line/tests/cases/architect-rounds.sh"
  ]
}
---

# WO-20261013-4f4c - Roadmap I - architect-rounds.sh, the architect's 1-minute fact sheet moves from ~/.cache/coq-watch/architect-rounds.sh into line/bin/architect-rounds.sh with its test; the live copy runs from the repo and the cache copy is deleted

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

Owner 2026-10-12 22:49Z (m-20261012224955626-rjghl): every script lives in the project and only its artifacts outside. ~/.cache/coq-watch/architect-rounds.sh runs the line from outside git: never tested or reviewed, with hardcoded /home/luna paths. Split from WO-20261012-90ce (Roadmap I) under the size rule, one ticket per script (architect ruling ykne9).

## Scope

**In**

- line/bin/architect-rounds.sh behaves as ~/.cache/coq-watch/architect-rounds.sh does on 2026-10-13, breadcrumb header kept and extended with this ticket; it finds the repository root from its own location and the state root through bin/state-root.sh (COQ_STATE, then the ROADMAP.md default); no /home/luna and no .cache/coq-watch in the file, and every file it writes lands under the state root
- line/tests/cases/architect-rounds.sh: with a stub herdr showing the architect idle one tick sends exactly one prompt holding the fact sheet; with a live spinner on its screen no prompt is sent; the halt flag ends it
- after the merge (orchestrator lane): the running ~/.cache/coq-watch/architect-rounds.sh instance is stopped and started from $COQ_REPO/line/bin/architect-rounds.sh in the pane that runs it today, then ~/.cache/coq-watch/architect-rounds.sh and its .bak copies are copied to the state root archive and deleted from the cache

**Out - non-goals**

- changing what the script does
- line/tests/lib/world.sh and line/tests/run.sh, shared by every case: stubs the case needs live in the case file
- line/README.md (the closing ticket of the split)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* the case passes and fails when the behaviour it names is broken; grep finds no /home/luna or .cache/coq-watch in line/bin/architect-rounds.sh; with COQ_STATE set to a temp dir every file the script writes lands under it; make lint and make -C line test pass
- [ ] `AC-H2` *(human)* after the merge: pgrep -f coq-watch/architect-rounds.sh is empty, ~/.cache/coq-watch/architect-rounds.sh is gone, and the archive path is in a 200 note on this ticket

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
