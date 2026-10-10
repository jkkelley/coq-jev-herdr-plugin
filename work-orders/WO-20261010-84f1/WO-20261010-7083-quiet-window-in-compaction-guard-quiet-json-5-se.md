---
{
  "id": "WO-20261010-7083",
  "slug": "quiet-window-in-compaction-guard-quiet-json-5-se",
  "title": "Quiet window in compaction-guard: quiet.json, 5 second countdown, watchers pause and queue, inbox drains after resume",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-10",
  "updated": "2026-10-10",
  "created_at": "2026-10-10T19:37:38+00:00",
  "parent": "WO-20261010-84f1",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "architect: sure of it; owner 2026-10-10 UTC: approval is the architect's job, Lavish is prohibited for this project",
    "at": "2026-10-10"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": []
}
---

# WO-20261010-7083 - Quiet window in compaction-guard: quiet.json, 5 second countdown, watchers pause and queue, inbox drains after resume

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

A watcher that prints into a seat's pane during a compaction merges with the /compact line and stalls the cycle; the owner saw it on 2026-10-10. Nothing may stop a compaction and nothing may be lost (SPEC-05 s-quiet, REQ-compaction-quiet-window).

## Scope

**In**

- compaction-guard writes quiet.json before the countdown and removes it in PostCompact
- COMPACTION IN 5 .. 1 system message typed into the seat's pane, one line per second
- bearings wait loop, pane watchers and the monitor seat hold delivery while quiet.json exists and write each signal to the seat's inbox queue (queue/ shape)
- PostCompact re-arms watchers and drains the inbox oldest first into the first turn
- Claude Code seat today: TaskStop every Monitor before the compact, re-arm after, documented in the role playbook

**Out - non-goals**

- changing the 30 percent threshold or the checkpoint format
- a new notification channel; herdr notifications are SPEC-05 s-monitoring

## Degrees of freedom

- [free] Where quiet.json lives (seat state dir vs queue/) and the exact inbox filename shape, as long as it is UTC named and one file per signal.

## Acceptance criteria

- [ ] `AC-H1` *(human)* with quiet.json present a page message is written to inbox/ and nothing is printed to the pane
- [ ] `AC-H2` *(human)* the countdown prints five lines five seconds apart and /compact follows on the sixth
- [ ] `AC-H3` *(human)* after PostCompact the inbox is empty and the queued message is the first line of the next turn
- [ ] `AC-H4` *(human)* a seat killed inside the window restarts through seat.sh with the checkpoint and the inbox intact

## Test plan

```sh
podman run --rm -v $PWD:/w -w /w <lint image digest> bash tests/quiet-window.sh (fake pane via a fifo, fake clock)
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
