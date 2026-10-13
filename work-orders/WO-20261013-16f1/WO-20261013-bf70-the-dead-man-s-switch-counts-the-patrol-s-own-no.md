---
{
  "id": "WO-20261013-bf70",
  "slug": "the-dead-man-s-switch-counts-the-patrol-s-own-no",
  "title": "The dead man's switch counts the patrol's own notes as records, so it never fired in a 9.5h outage (re-cut at line/bin/watchdog.sh)",
  "type": "bug",
  "status": "ready",
  "priority": "p1",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T17:54:32+00:00",
  "parent": "WO-20261013-16f1",
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
    "WO-20261013-1258",
    "WO-20261013-2fc5"
  ],
  "blocks": [],
  "files": [
    "line/bin/watchdog.sh",
    "line/tests/cases/watchdog-quiet.sh"
  ]
}
---

# WO-20261013-bf70 - The dead man's switch counts the patrol's own notes as records, so it never fired in a 9.5h outage (re-cut at line/bin/watchdog.sh)

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

watchdog.sh:33 counts any record file in the last 30 minutes; patrol-tick.sh:66 writes a note 100 under --seat monitor for every finding and the route runner writes 500 notes, so between 03:32Z and 13:00Z the window always held a fresh file and no card reached the owner while the line was dead. Rejected: a longer window (notes come every 10 minutes); counting only 2xx (a seat blocked at 423 is still a seat record). Re-cut of WO-20261013-f06b, whose files named line/watchdog.sh, a path the move never creates.

## Scope

**In**

- the quiet test counts only records written by a role seat (worker, tester, reviewer, merger, orchestrator, architect, interface-agent), read from roles/, never monitor, route-runner, patrol or system
- the check mode prints how many seat records and how many system records fell in the window
- line/tests/cases/watchdog-quiet.sh builds a state root with dated record files and runs watchdog.sh check

**Out - non-goals**

- restarting the patrol (the watchdog's first half stays as is)
- the move of the script (its own ticket, which this follows)

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* 31 minutes of only seat=monitor and seat=route-runner records: check reports NONE and one stub card is posted
- [ ] `AC-H2` *(human)* one seat=worker record in the window: check reports yes and posts nothing; make lint and make -C line test pass

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
