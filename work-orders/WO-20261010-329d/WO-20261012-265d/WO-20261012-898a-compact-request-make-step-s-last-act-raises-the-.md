---
{
  "id": "WO-20261012-898a",
  "slug": "compact-request-make-step-s-last-act-raises-the-",
  "title": "Compact request: make step's last act raises the seat's compact request and the scoped guard watch sends one /compact when the seat is quiet and its checkpoint is fresh",
  "type": "feature",
  "status": "ready",
  "priority": "p1",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T16:32:51+00:00",
  "parent": "WO-20261012-265d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "lavish is prohibited for Claude seats; owner answered card C4 on the bearings page 2026-10-12 16:32Z: cut all four",
    "at": "2026-10-12"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [
    "WO-20261012-ee9c"
  ],
  "blocks": []
}
---

# WO-20261012-898a - Compact request: make step's last act raises the seat's compact request and the scoped guard watch sends one /compact when the seat is quiet and its checkpoint is fresh

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

AGENTS.md:38 and :42 and locked node REQ-checkpoint-every-step say a seat compacts after a step lands, never at a threshold, but nothing reads a request: every seat compacts only at 30 percent, the last line of defence the owner said must never be the trigger.

## Scope

**In**

- make step touches <seat state>/compact-request as its last act
- the scoped guard watch sends one /compact for a request only when the transcript is quiet, the turn is closed, the guard phase is idle or green, and the seat's checkpoint was written after its last restore
- a cooldown between requests from config

**Out - non-goals**

- any compaction-guard change
- per-role thresholds (sibling ticket)

## Degrees of freedom

- [free] quiet window length and cooldown, as long as both come from herdr/config

## Acceptance criteria

- [ ] `AC-H1` *(human)* a request with a fresh checkpoint on a quiet seat gets exactly one /compact
- [ ] `AC-H2` *(human)* a request with a stale checkpoint is refused with one line in the slot pane and no /compact
- [ ] `AC-H3` *(human)* a request during the cooldown or while the guard phase is busy is held, never sent twice
- [ ] `AC-H4` *(human)* make step raises the request after the commit lands and never before

## Test plan

```sh
make -C herdr test
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
