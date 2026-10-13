---
{
  "id": "WO-20261013-3a6e",
  "slug": "roadmap-i-flow-tick-sh-the-3-minute-flow-tick-mo",
  "title": "Roadmap I - flow-tick.sh, the 3-minute flow tick moves from ~/.cache/coq-watch/flow-tick.sh into line/bin/flow-tick.sh with its test; the live copy runs from the repo and the cache copy is deleted",
  "type": "chore",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T17:52:30+00:00",
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
    "WO-20261013-ccb8"
  ],
  "blocks": [
    "WO-20261013-acdd"
  ],
  "files": [
    "line/bin/flow-tick.sh",
    "line/tests/cases/flow-tick.sh"
  ]
}
---

# WO-20261013-3a6e - Roadmap I - flow-tick.sh, the 3-minute flow tick moves from ~/.cache/coq-watch/flow-tick.sh into line/bin/flow-tick.sh with its test; the live copy runs from the repo and the cache copy is deleted

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

Owner 2026-10-12 22:49Z (m-20261012224955626-rjghl): every script lives in the project and only its artifacts outside. ~/.cache/coq-watch/flow-tick.sh runs the line from outside git: never tested or reviewed, with hardcoded /home/luna paths. Split from WO-20261012-90ce (Roadmap I) under the size rule, one ticket per script (architect ruling ykne9).

## Scope

**In**

- line/bin/flow-tick.sh behaves as ~/.cache/coq-watch/flow-tick.sh does on 2026-10-13, breadcrumb header kept and extended with this ticket; it finds the repository root from its own location and the state root through bin/state-root.sh (COQ_STATE, then the ROADMAP.md default); no /home/luna and no .cache/coq-watch in the file, and every file it writes lands under the state root
- line/tests/cases/flow-tick.sh: one run writes the flow table under the state root, adds the bottleneck stage to aq.sh as p1 (p0 when a stuck ticket is P0 on the priority list), adds each record addressed to the architect as p2, and prompts the stub monitor once
- after the merge (orchestrator lane): the running ~/.cache/coq-watch/flow-tick.sh instance is stopped and started from $COQ_REPO/line/bin/flow-tick.sh in the pane that runs it today, then ~/.cache/coq-watch/flow-tick.sh and its .bak copies are copied to the state root archive and deleted from the cache

**Out - non-goals**

- changing what the script does
- line/tests/lib/world.sh and line/tests/run.sh, shared by every case: stubs the case needs live in the case file
- line/README.md (the closing ticket of the split)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* the case passes and fails when the behaviour it names is broken; grep finds no /home/luna or .cache/coq-watch in line/bin/flow-tick.sh; with COQ_STATE set to a temp dir every file the script writes lands under it; make lint and make -C line test pass
- [ ] `AC-H2` *(human)* after the merge: pgrep -f coq-watch/flow-tick.sh is empty, ~/.cache/coq-watch/flow-tick.sh is gone, and the archive path is in a 200 note on this ticket

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
