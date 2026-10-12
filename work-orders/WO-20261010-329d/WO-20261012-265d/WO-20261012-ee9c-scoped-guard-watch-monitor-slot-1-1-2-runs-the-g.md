---
{
  "id": "WO-20261012-ee9c",
  "slug": "scoped-guard-watch-monitor-slot-1-1-2-runs-the-g",
  "title": "Scoped guard watch: monitor slot 1.1.2 runs the guard only for live seats, each pane resolved to the Claude session running in it every tick",
  "type": "feature",
  "status": "ready",
  "priority": "p0",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T16:32:49+00:00",
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
  "depends_on": [],
  "blocks": [
    "WO-20261012-898a"
  ]
}
---

# WO-20261012-ee9c - Scoped guard watch: monitor slot 1.1.2 runs the guard only for live seats, each pane resolved to the Claude session running in it every tick

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

compaction-guard watch --interval 15 (herdr/config/monitors.json:19-24) walks every host-wide binding (231 at 15:45Z, 115 from other projects) and memos any session bound to a pane, live or dead; on 2026-10-12 02:16Z that flooded the architect pane with about 189 GOV-100 memos and the watch has been off since, so stall recovery is off too. unfreeze.sh sessions_of (herdr/bin/unfreeze.sh:43-51) has the same flaw.

## Scope

**In**

- a repo script herdr/bin/guardwatch.sh in slot 1.1.2 replacing the bare guard watch
- each tick: live seats as unfreeze.sh lists them, pane to claude pid via herdr pane process-info, pid to sessionId via ~/.claude/sessions/<pid>.json, then compaction-guard watch --once --session <sid> for exactly those
- the same live-session filter in unfreeze.sh sessions_of
- seat.sh writes the resolved session into seat.json at seat up and when it changes, so recover.sh gets its per-seat --session

**Out - non-goals**

- any compaction-guard change
- a compact request (sibling ticket)

## Degrees of freedom

- [free] tick interval, as long as it comes from herdr/config, never hard-coded
- [free] script name, as long as monitors.json and the runbook name it

## Acceptance criteria

- [ ] `AC-H1` *(human)* a Podman case with two bindings on one pane, one dead, gets exactly one memo, for the live session
- [ ] `AC-H2` *(human)* a pane with no claude process is skipped with one line and no guard call
- [ ] `AC-H3` *(human)* unfreeze.sh never releases a dead session's lease into a live seat's pane
- [ ] `AC-H4` *(human)* seat.json carries the resolved session id after seat up
- [ ] `AC-H5` *(human)* slot 1.1.2 runs guardwatch.sh from monitors.json and lh51y's done-when holds

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
