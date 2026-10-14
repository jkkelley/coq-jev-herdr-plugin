---
{
  "id": "WO-20261013-acdd",
  "slug": "roadmap-i-closes-verify-phase1-sh-retires-into-l",
  "title": "Roadmap I closes - verify-phase1.sh retires into line/bin/verify-main.sh, line/README.md maps every old ~/.cache/coq-watch script to its line/bin home, and a case keeps cache paths out of line/",
  "type": "chore",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-14",
  "created_at": "2026-10-13T17:54:44+00:00",
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
    "WO-20261013-ccb8",
    "WO-20261013-1258",
    "WO-20261013-4f4c",
    "WO-20261013-3a6e",
    "WO-20261013-0ffe",
    "WO-20261013-7719",
    "WO-20261013-1637",
    "WO-20261013-acbf",
    "WO-20261013-ca12",
    "WO-20261013-af23",
    "WO-20261013-2fc5",
    "WO-20261013-9bdd",
    "WO-20261014-8814"
  ],
  "blocks": [],
  "files": [
    "line/README.md",
    "line/tests/cases/no-cache-paths.sh"
  ]
}
---

# WO-20261013-acdd - Roadmap I closes - verify-phase1.sh retires into line/bin/verify-main.sh, line/README.md maps every old ~/.cache/coq-watch script to its line/bin home, and a case keeps cache paths out of line/

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

verify-phase1.sh was a one-off check of main after the phase 1 merges (make lint, the herdr suite, the scheduler host suite); WO-20261013-9bdd's line/bin/verify-main.sh runs the same checks as code, so the script moves nowhere. Roadmap I (WO-20261012-90ce) also asked for a README that says, per script, what it does, what runs it, how it stops and every file it writes, and for no file under line/ to name /home/luna or .cache/coq-watch. Split from WO-20261012-90ce, one ticket per script (architect ruling ykne9).

## Scope

**In**

- line/README.md: one row per old ~/.cache/coq-watch script (13) with its line/bin home or its retiring ticket, what it does, the pane or unit that runs it, how it stops (the halt flag run/line.halted) and the exact path of every file it writes under the state root
- line/tests/cases/no-cache-paths.sh fails when any file under line/ names /home/luna or .cache/coq-watch, and when a line/bin script is missing from the README
- after the merge (orchestrator lane): ~/.cache/coq-watch/verify-phase1.sh is copied to the state root archive and deleted; ~/.cache/coq-watch holds no script

**Out - non-goals**

- ROADMAP.md (the owner adds roadmap rows)
- line/tests/lib/world.sh and line/tests/run.sh

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* the case passes on the merged line/ and fails on a planted /home/luna path; make lint and make -C line test pass
- [ ] `AC-H2` *(human)* after the merge: ls ~/.cache/coq-watch/*.sh finds nothing

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
