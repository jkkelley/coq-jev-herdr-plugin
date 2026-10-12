---
{
  "id": "WO-20261012-277d",
  "slug": "supervisor-judges-a-pane-busy-by-the-processes-i",
  "title": "Supervisor judges a pane busy by the processes in its foreground, so a live bearings wait loop is never called dead and restarted",
  "type": "bug",
  "status": "done",
  "priority": "p0",
  "created": "2026-10-12",
  "updated": "2026-10-12",
  "created_at": "2026-10-12T17:19:41+00:00",
  "parent": "WO-20261012-187e",
  "branch": "feat/supervisor-judges-a-pane-busy-by-the-processes-i",
  "pr": 34,
  "closed": "2026-10-12",
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

- [x] `AC-H1` *(human)* a pane whose foreground is node wait.mjs in the shell's process group is judged busy by both scripts
  - observed `2026-10-12` make -C herdr test cases 19 (supervisor --check says ok bearings with the job in the shell's group, apply tick fixes nothing) and 17 (monitors health calls an open slot with such a job busy) pass; live: herdr pane process-info on wD3:p8P through sl_pane_busy exits 0
- [x] `AC-H2` *(human)* a bare shell pane is still judged idle by both
  - observed `2026-10-12` same cases: after C-c and kill the pane is a bare shell, supervisor says FAILED/fixed bearings and monitors health says 'is open and its pane is a bare shell'; sl_pane_busy on a bare zsh reply exits 1
- [x] `AC-H3` *(human)* make -C herdr supervisor CHECK=1 on the live host prints ok bearings while the wait loop runs (human)
  - observed `2026-10-12` make -C herdr supervisor CHECK=1 run from test pane wD3:pE4 on the live host printed 'ok bearings' while wait.mjs ran in wD3:p8P (other FAILED lines were belt and monitors state paths of the worktree, not this ticket)

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

- `2026-10-12` retro: the live node wait.mjs shares the zsh process group, so the group-id test alone mislabels it; fixed once in seat-lib.sh sl_pane_busy (group test OR a non-shell argv[0], shells in herdr.json). Test trick: 'set +m; sleep 600 & p=$!; wait' keeps a job in the shell's group. Found on main, not mine: case 04 prints 'jq: parse error: Invalid numeric literal at line 1, column 14' and still passes.

## Outcome

_Written by `work-order done`. Empty until then._
