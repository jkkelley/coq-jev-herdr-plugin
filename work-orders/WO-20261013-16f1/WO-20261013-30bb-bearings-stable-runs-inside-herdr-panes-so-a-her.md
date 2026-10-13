---
{
  "id": "WO-20261013-30bb",
  "slug": "bearings-stable-runs-inside-herdr-panes-so-a-her",
  "title": "bearings stable runs inside herdr panes, so a herdr crash takes the owner page down with every seat",
  "type": "bug",
  "status": "ready",
  "priority": "p1",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T13:20:36+00:00",
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
    "tools/bearings/scripts/bearings.sh",
    "tools/bearings/systemd/bearings-stable.service.in",
    "herdr/bin/supervisor-units.sh"
  ]
}
---

# WO-20261013-30bb - bearings stable runs inside herdr panes, so a herdr crash takes the owner page down with every seat

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

tools/bearings/scripts/bearings.sh:157 starts the page server with herdr pane run "$P" "node server.mjs ..." and :216 starts the wait loop the same way, and :163 allows nohup only under --no-herdr for tests. Both are processes in a herdr pane, so when herdr-stable died at 03:32:18Z (status=11/SEGV) systemd killed the control group and the owner page and its wait loop died with it. herdr/bin/supervisor.sh:113 bearings_node restarts them, but only when the supervisor tick runs and herdr is back, and it needs a tab to claim an OPEN slot in, so with no seat alive nothing restarted it. Owner rule 2026-10-12: bearings stable is the only always-on monitor and a halt never stops it.

## Scope

**In**

- the stable-tier page server and its wait loop run as a systemd user unit of their own (outside the herdr cgroup) with Restart=always, rendered from a template in the repo
- the wait loop reaches the architect through the herdr API when herdr is up and queues the owner's messages on disk while it is down, draining them on the first successful prompt
- bearings.sh serve keeps working inside herdr for the other tiers; the stable tier is the one that moves

**Out - non-goals**

- the dev and uat tiers
- the page's content and cards

## Degrees of freedom

- [free] unit file layout, as long as it is a template under tools/bearings/ or herdr/systemd/ and installed by the supervisor units script

## Acceptance criteria

- [ ] `AC-H1` *(human)* kill -SEGV of the herdr server leaves the owner page answering HTTP 200 on its unchanged url and key
- [ ] `AC-H2` *(human)* an owner message posted while herdr is down reaches the architect within one minute of herdr coming back
- [ ] `AC-H3` *(human)* systemctl --user status shows the unit enabled and the supervisor's bearings node reports it ok

## Test plan

```sh
podman run --rm -v $PWD:/repo -w /repo <digest-pinned image> make -C tools/bearings test (a case starts the server outside any herdr, kills a fake herdr, and checks the page and the queue)
```

## Assumptions

1. the key stays in server.json and is never printed (bearings-restart-and-page-key)

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
