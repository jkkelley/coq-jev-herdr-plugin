---
{
  "id": "WO-20261013-f06b",
  "slug": "the-dead-man-s-switch-counts-the-patrol-s-own-no",
  "title": "The dead man's switch counts the patrol's own notes as records, so it never fired in a 9.5h outage",
  "type": "bug",
  "status": "ready",
  "priority": "p1",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T13:20:33+00:00",
  "parent": "WO-20261013-16f1",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect P0 order 2026-10-13 (owner m-20261013162710557-e4nos: always a system loop), approved by the architect in the owner place (card C29); lavish prohibited for Claude seats",
    "at": "2026-10-13"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": [],
  "files": [
    "line/watchdog.sh",
    "line/tests/cases/watchdog-quiet.sh"
  ]
}
---

# WO-20261013-f06b - The dead man's switch counts the patrol's own notes as records, so it never fired in a 9.5h outage

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

watchdog.sh:33 sets quiet=$(find $REPO/events/2026/10 $STATE/records -name '*.json' -mmin -30 -print -quit), which counts any record file. patrol-tick.sh:66 writes a note 100 under --seat monitor for every finding (rec=$(... event.sh add --code 100 --kind note --seat monitor ...)), and the route runner writes 500 notes for its own failures. Between 03:32Z and 13:00Z the patrol kept posting findings about dead processes, so the 30 minute window always held a fresh file, the watchdog.sh:50 reason never set, and no card reached the owner while the whole line was dead. Rejected: lengthening the window (the notes arrive every 10 minutes, any window is filled); counting only code 2xx (a seat blocked at 423 is still a seat record).

## Scope

**In**

- the quiet test counts only records written by a seat: a role seat name (worker, tester, reviewer, merger, orchestrator, architect, interface-agent), never monitor, route-runner, patrol or system
- the patrol's check mode prints how many seat records and how many system records fell in the window
- the script is edited at its repo home line/watchdog.sh once Roadmap I (WO-20261012-90ce) has moved it; before that, in ~/.cache/coq-watch with a backup

**Out - non-goals**

- restarting the patrol (watchdog.sh part 1 stays as is)

## Degrees of freedom

- [free] how a seat record is told from a system record (the seat field against the role list, or a kind list), as long as the list is read from roles/ and not typed in the script

## Acceptance criteria

- [ ] `AC-H1` *(human)* in a test world with 31 minutes of only seat=monitor and seat=route-runner records, watchdog.sh check reports NONE and a card is posted
- [ ] `AC-H2` *(human)* with one seat=worker record in the window it reports yes and posts nothing

## Test plan

```sh
podman run --rm -v $PWD:/repo -w /repo <digest-pinned image> bash line/tests/watchdog-quiet.test.sh (builds a state root with dated record files and runs watchdog.sh check)
```

## Assumptions

1. line/ exists after Roadmap I; if not, the ticket edits the file where it lives and the move carries the change

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
