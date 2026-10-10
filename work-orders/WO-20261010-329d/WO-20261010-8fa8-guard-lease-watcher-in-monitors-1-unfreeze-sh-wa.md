---
{
  "id": "WO-20261010-8fa8",
  "slug": "guard-lease-watcher-in-monitors-1-unfreeze-sh-wa",
  "title": "Guard lease watcher in monitors 1: unfreeze.sh --watch plugged in by bringup, with its Podman case",
  "type": "feature",
  "status": "draft",
  "priority": "p1",
  "created": "2026-10-10",
  "updated": "2026-10-10",
  "created_at": "2026-10-10T21:43:18+00:00",
  "parent": "WO-20261010-329d",
  "branch": null,
  "pr": null,
  "closed": null,
  "approval": null,
  "evidence": null,
  "surfaces": [],
  "depends_on": [],
  "blocks": []
}
---

# WO-20261010-8fa8 - Guard lease watcher in monitors 1: unfreeze.sh --watch plugged in by bringup, with its Podman case

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

A seat whose compaction-guard phase stays armed or compacting (a no-op /compact fires PreCompact and never PostCompact) has every write tool refused until the lease runs out, and the guard applies the lease only on the seat's next tool call, so a seat that is answering in text sits dark with nobody to wake it. On 2026-10-10 the architect seat sat frozen from 20:57 to 21:36 UTC until the owner asked what was going on. herdr/bin/unfreeze.sh (landed on main) releases an expired lease and wakes the seat, but nothing runs it.

## Scope

**In**

- herdr/config/monitors.json: reserved slot 1.1.1 becomes name lease, what 'guard lease watcher', command '${repo}/herdr/bin/unfreeze.sh --watch 30'; slot 1.1.2 becomes name guard, what 'compaction-guard watch', command 'compaction-guard watch --interval 15'; slot 1.1.3 stays reserved for the orchestrator watcher with no command
- bringup.sh already plugs in every reserved slot that carries a command; verify it takes both and that --check reports them
- herdr/tests/cases/04-bringup-monitors.test.sh: assert 1.1.1 and 1.1.2 run their commands like 2.1.1 and 2.1.2, with a stub compaction-guard on PATH in the world (as case 05 does) so watch never touches the host
- a new case 06-unfreeze: a world seat with a hand-written guard phase.json in phase compacting and armed_at older than freeze_seconds is released by one unfreeze.sh --all pass, the seat's pane receives the wake prompt, a note 100 from seat unfreeze is recorded; a fresh lease prints ok and is untouched; a pane equal to HERDR_PANE_ID is refused
- playbooks/worker.md and roles/worker.json: a worker may run 'herdr pane run' against the labelled test pane named in its brief, so it can satisfy a labelled-pane acceptance criterion itself (gap found closing WO-20261010-c274); the pane id comes from the brief, never chosen by the worker

**Out - non-goals**

- changing compaction-guard itself (a promoted release with its own suite, its owner changes it)
- any new tab or any change to the 3x3 shape

## Degrees of freedom

- [fixed] None declared: implement exactly as specified; raise a question before deviating.

## Acceptance criteria

- [ ] `AC-H1` *(human)* bringup.sh on an empty world leaves 1.1.1 running unfreeze.sh --watch and 1.1.2 running compaction-guard watch, labelled per SPEC-04, and --check reports both ok
- [ ] `AC-H2` *(human)* one unfreeze.sh --all pass over a world seat frozen past its lease prints released <pane> <name>, the pane's agent received the wake prompt, a note 100 from seat unfreeze exists, and a seat inside its lease prints ok and is untouched
- [ ] `AC-H3` *(human)* a worker seat can run the suite in the labelled test pane named in its brief and the run is refused for any other pane
- [ ] `AC-H4` *(human)* the suite is green from the labelled test pane: every case passes, 0 failed

## Test plan

```sh
make -C herdr test from the labelled test pane (herdr pane run <test pane> 'make -C herdr test'), then make lint
```

## Assumptions

_none_

## Open questions

_none_

## Notes

_Newest first. Appended only by `work-order note` - never by hand._

## Outcome

_Written by `work-order done`. Empty until then._
