---
{
  "id": "WO-20261012-277d",
  "slug": "supervisor-judges-a-pane-busy-by-the-processes-i",
  "title": "Supervisor judges a pane busy by the processes in its foreground, so a live bearings wait loop is never called dead and restarted",
  "type": "bug",
  "status": "in-progress",
  "priority": "p0",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T17:19:41+00:00",
  "parent": "WO-20261012-187e",
  "branch": "feat/supervisor-judges-a-pane-busy-by-the-processes-i",
  "pr": null,
  "closed": null,
  "approval": {
    "via": "override",
    "reason": "lavish is prohibited for Claude seats; architect verification of PR 26 on main found it, owner order: the line runs without the architect as a gate",
    "at": "2026-10-12"
  },
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": []
}
---

# WO-20261012-277d - Supervisor judges a pane busy by the processes in its foreground, so a live bearings wait loop is never called dead and restarted

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

supervisor.sh pane_busy (herdr/bin/supervisor.sh:146) and monitors.sh busy (herdr/bin/monitors.sh:69) call a pane idle when foreground_process_group_id equals shell_pid. The bearings wait pane wD3:p8P runs node wait.mjs in the zsh's own process group (fg 4175695 = shell 4175695, foreground_processes node and zsh), so make -C herdr supervisor CHECK=1 on main 55e799e printed FAILED bearings (the wait loop is not running) while the loop was live and delivering owner answers. Installed, every tick would restart the owner's wait loop. Blocks the supervisor install (SOP-0003 step 1).

## Scope

**In**

- pane_busy and busy judge busy as: foreground_processes holds a process whose argv[0] is not a shell from config
- one shared helper both scripts call, so the two rules cannot drift
- a herdr case reproducing node in the shell's process group

**Out - non-goals**

- changes to bearings wait.mjs or how bearings places its wait pane

## Degrees of freedom

- [free] the shell name list, as long as it lives in herdr/config/herdr.json

## Acceptance criteria

- [ ] `AC-H1` *(human)* a pane whose foreground is node wait.mjs in the shell's process group is judged busy by both scripts
- [ ] `AC-H2` *(human)* a bare shell pane is still judged idle by both
- [ ] `AC-H3` *(human)* make -C herdr supervisor CHECK=1 on the live host prints ok bearings while the wait loop runs (human)

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
