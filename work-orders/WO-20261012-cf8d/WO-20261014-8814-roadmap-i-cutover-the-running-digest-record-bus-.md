---
{
  "id": "WO-20261014-8814",
  "slug": "roadmap-i-cutover-the-running-digest-record-bus-",
  "title": "Roadmap I cutover - the running digest, record-bus, aq, start-roadmap and seat-queue instances run from line/bin, and their ~/.cache/coq-watch copies are archived to the state root and deleted",
  "type": "chore",
  "status": "ready",
  "priority": "p1",
  "created": "2026-10-14",
  "updated": "2026-10-14",
  "created_at": "2026-10-14T00:00:58+00:00",
  "parent": "WO-20261012-cf8d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "duplicate audit split 2026-10-13T23:55Z: the AC-H2 of five merged Roadmap I tickets, ruled by the architect",
    "at": "2026-10-14"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261013-0ffe",
    "WO-20261013-1637",
    "WO-20261013-51e8",
    "WO-20261013-af23",
    "WO-20261013-ca12"
  ],
  "blocks": [
    "WO-20261013-acdd"
  ],
  "files": [
    "line/bin/digest.sh",
    "line/bin/record-bus.sh",
    "line/bin/aq.sh",
    "line/bin/start-tickets.sh",
    "line/bin/seat-queue.sh"
  ]
}
---

# WO-20261014-8814 - Roadmap I cutover - the running digest, record-bus, aq, start-roadmap and seat-queue instances run from line/bin, and their ~/.cache/coq-watch copies are archived to the state root and deleted

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

Split from the AC-H2 of WO-20261013-0ffe, WO-20261013-1637, WO-20261013-51e8, WO-20261013-af23 and WO-20261013-ca12 by the duplicate audit (2026-10-13T23:55Z). Their code is on main under line/bin (PRs 119, 120, 121, 142, 129), but at 2026-10-13 23:55Z pgrep -f coq-watch/digest.sh and coq-watch/record-bus.sh each still show a running instance and all five scripts still exist in ~/.cache/coq-watch, so the AC-H2 of each ticket (after the merge: no instance of the cache copy, the cache copy gone, the archive path in a 200 note) was not observed and is not ticked there.

## Scope

**In**

- for each of digest.sh, record-bus.sh, aq.sh, start-roadmap.sh (now start-tickets.sh) and seat-queue.sh: stop the running cache instance, start the line/bin copy in its place, copy the cache file and its .bak files to the state root archive, delete them from ~/.cache/coq-watch
- post one 200 record per script naming its archive path (the five source tickets are archived, so a note on them is no longer possible)

**Out - non-goals**

- the other Roadmap I scripts (patrol-tick, flow-tick, architect-rounds, watchdog, verify-phase1): their own tickets
- line/README.md and the no-cache-paths case: WO-20261013-acdd
- any change to line/bin code

## Degrees of freedom

- [free] the order the five scripts are cut over in, as long as only one is stopped at a time and the line has no gap longer than one tick

## Acceptance criteria

- [ ] `AC-H1` *(human)* for each of the five scripts, pgrep -f coq-watch/<script> is empty, ~/.cache/coq-watch/<script> and its .bak files are gone, the line/bin copy is running where the cache copy ran, and the archive path is in a 200 record

## Test plan

```sh
pgrep -af 'coq-watch/(digest|record-bus|aq|start-roadmap|seat-queue)' prints nothing; ls ~/.cache/coq-watch lists none of the five; events/bin/event.sh list --code 200 shows one record per script naming its archive path
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
