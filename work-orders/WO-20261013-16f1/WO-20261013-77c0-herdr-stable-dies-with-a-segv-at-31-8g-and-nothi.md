---
{
  "id": "WO-20261013-77c0",
  "slug": "herdr-stable-dies-with-a-segv-at-31-8g-and-nothi",
  "title": "herdr-stable dies with a SEGV at 31.8G and nothing brings the seats back: it has no memory ceiling, no core kept, and no restart that resumes each seat by its pane session id",
  "type": "bug",
  "status": "ready",
  "priority": "p1",
  "created": "2026-10-13",
  "updated": "2026-10-13",
  "created_at": "2026-10-13T13:20:30+00:00",
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
    "herdr/systemd/herdr-stable.service.in",
    "herdr/bin/supervisor.sh",
    "herdr/bin/resume-seats.sh",
    "herdr/tests/cases/30-herdr-restart-resumes-seats.test.sh"
  ]
}
---

# WO-20261013-77c0 - herdr-stable dies with a SEGV at 31.8G and nothing brings the seats back: it has no memory ceiling, no core kept, and no restart that resumes each seat by its pane session id

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

herdr-stable.service core-dumped (status=11/SEGV) at 2026-10-13T03:32:18Z after 1d 9h of CPU with a 31.8G memory peak and 292.6M swap peak (journalctl --user -u herdr-stable; the WSL ceiling is 36GB in .wslconfig). The unit file ~/.config/systemd/user/herdr-stable.service has Restart=on-failure and no MemoryHigh or MemoryMax, so growth runs to the box limit. Restart=on-failure brought the server back at 03:32:25Z with the pane layout, but systemd killed every pane shell in the control group, so every seat and line process died and nothing resumed them; the line sat dark for 9.5h until the owner noticed. The only evidence is a 877MB WSL crash capture (wsl-crash-1791862334-424-_home_luna_.local_bin_herdr-11.dmp) that WSL may purge; it is copied to the state root crash/20261013T033218Z-herdr-stable/. herdr pane list keeps each pane's agent_session.value, so a resume by session id is possible.

## Scope

**In**

- a restart unit or supervisor node that, after a herdr server start, brings each labelled line process and each seat back by itself: herdr agent start <name> --kind claude --pane <pane> -- --resume <session id> with the model and permission mode the seat had
- the restart order from the 2026-10-13 recovery as code: bearings, belt, watches, orchestrator and architect, then the orchestrator brings the work seats
- a memory ceiling on herdr-stable (MemoryHigh below the WSL limit) so a leak ends in a clean restart, and the crash capture copied to the state root at each restart
- a design note in the ticket's Notes that reads the dump (gdb or lldb in Podman) and says what grew, filed upstream if it is a herdr bug

**Out - non-goals**

- fixing herdr itself
- the compaction watcher and the dead man's switch (own tickets under this epic)

## Degrees of freedom

- [free] MemoryHigh value, as long as it stays below the 36GB WSL limit with room for the rest of the box
- [free] supervisor node or systemd ExecStartPost for the resume, as long as it is repo code under herdr/ and idempotent

## Acceptance criteria

- [ ] `AC-H1` *(human)* after kill -SEGV of the herdr server in a test world, every seat that had an agent_session.value is running again with --resume and its context within 5 minutes and no hand step
- [ ] `AC-H2` *(human)* a seat with no session id is reported in a record, never skipped silently
- [ ] `AC-H3` *(human)* the unit file carries a memory ceiling and a breadcrumb comment naming this ticket

## Test plan

```sh
podman run --rm -v $PWD:/repo -w /repo <digest-pinned image> make -C herdr test (a new case 18-herdr-restart-resumes-seats kills the server in a test world and checks the resume commands)
```

## Assumptions

1. the crash dump stays under the state root crash/ until this ticket is done
1. the unit file lives outside the repo today, so the repo carries a template like herdr/systemd/coq-supervisor.service.in

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
