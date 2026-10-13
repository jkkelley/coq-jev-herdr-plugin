---
{
  "id": "WO-20261013-2fc5",
  "slug": "roadmap-i-watchdog-sh-the-patrol-s-watchdog-and-",
  "title": "Roadmap I - watchdog.sh, the patrol's watchdog and dead man's switch, moves from ~/.cache/coq-watch into line/bin/watchdog.sh with its test and its systemd units; the timer runs the repo copy and the cache copy is deleted",
  "type": "chore",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T17:54:08+00:00",
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
    "WO-20261013-1258"
  ],
  "blocks": [
    "WO-20261013-bf70",
    "WO-20261013-acdd"
  ],
  "files": [
    "line/bin/watchdog.sh",
    "line/systemd/watchdog.service",
    "line/systemd/watchdog.timer",
    "line/tests/cases/watchdog.sh"
  ]
}
---

# WO-20261013-2fc5 - Roadmap I - watchdog.sh, the patrol's watchdog and dead man's switch, moves from ~/.cache/coq-watch into line/bin/watchdog.sh with its test and its systemd units; the timer runs the repo copy and the cache copy is deleted

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

Owner 2026-10-12 22:49Z (m-20261012224955626-rjghl): every script lives in the project. ~/.cache/coq-watch/watchdog.sh runs from systemd user units outside git (watchdog.service, watchdog.timer in ~/.config/systemd/user) and restarts the patrol at its cache path. Split from WO-20261012-90ce (Roadmap I), one ticket per script (architect ruling ykne9).

## Scope

**In**

- line/bin/watchdog.sh behaves as ~/.cache/coq-watch/watchdog.sh does on 2026-10-13 and restarts line/bin/patrol-tick.sh; repository root from its own location, state root through bin/state-root.sh; no /home/luna and no .cache/coq-watch in the file
- line/systemd/watchdog.service and line/systemd/watchdog.timer: the units as installed today, ExecStart at the repo copy, with a comment naming this ticket
- line/tests/cases/watchdog.sh: with a stub patrol pid that is dead the check restarts it, and with no seat record in 30 minutes one stub card is posted
- after the merge (orchestrator lane): the user units are re-linked from $COQ_REPO/line/systemd with systemctl --user link and daemon-reload, and ~/.cache/coq-watch/watchdog.sh and its .bak copies are copied to the state root archive and deleted from the cache

**Out - non-goals**

- what the quiet test counts (WO for the dead man's switch fix, cut beside this one)
- line/tests/lib/world.sh and line/tests/run.sh
- line/README.md

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* the case passes; the units name the repo copy; grep finds no /home/luna or .cache/coq-watch in the four files; make lint and make -C line test pass
- [ ] `AC-H2` *(human)* after the merge: systemctl --user cat watchdog.service shows the repo path, the timer is active and ~/.cache/coq-watch/watchdog.sh is gone

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
