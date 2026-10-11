---
{
  "id": "WO-20261010-8fa8",
  "slug": "guard-lease-watcher-in-monitors-1-unfreeze-sh-wa",
  "title": "Guard lease watcher in monitors 1: unfreeze.sh --watch plugged in by bringup, with its Podman case",
  "type": "feature",
  "status": "done",
  "priority": "p1",
  "created": "2026-10-10",
  "updated": "2026-10-11",
  "created_at": "2026-10-10T21:43:18+00:00",
  "parent": "WO-20261010-329d",
  "branch": "feat/guard-lease-watcher-in-monitors-1-unfreeze-sh-wa",
  "pr": 5,
  "closed": "2026-10-11",
  "approval": {
    "via": "override",
    "reason": "architect approval; owner order 2026-10-10 UTC: approval is the architect's job, Lavish is prohibited for Zenith",
    "at": "2026-10-10"
  },
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

- [x] `AC-H1` *(human)* bringup.sh on an empty world leaves 1.1.1 running unfreeze.sh --watch and 1.1.2 running compaction-guard watch, labelled per SPEC-04, and --check reports both ok
  - observed `2026-10-11` Case 04-bringup-monitors in the full suite from wD3:pF (tree of ce8006e, tests: 7 passed, 0 failed): bringup on an empty world printed 'fixed pane-lease (guard lease watcher plugged in) fixed pane-guard (compaction-guard watch plugged in)' ahead of pane-events and pane-queue; monitors.sh status showed '1.1.1 guard lease watcher - lease [pane] in use' and '1.1.2 compaction-guard watch - guard [pane] in use' and 1.1.3 still OPEN; the 1.1.1 pane printed an unfreeze.sh --watch tick line and the 1.1.2 pane printed the stub 'compaction-guard watch --interval 15'; a later bringup.sh --check exited 0 with 'ok pane-lease ok pane-guard ok pane-events ok pane-queue'. The watch in the suite is the stub compaction-guard, as the ticket requires; the live host panes were not started.
- [x] `AC-H2` *(human)* one unfreeze.sh --all pass over a world seat frozen past its lease prints released <pane> <name>, the pane's agent received the wake prompt, a note 100 from seat unfreeze exists, and a seat inside its lease prints ok and is untouched
  - observed `2026-10-11` Case 06-unfreeze (CASES=06 and the full suite, wD3:pF): one 'unfreeze.sh --all' over a world with an expired worker lease printed 'released w1:p1 worker-wo-20261010-8777 (compacting 600s, lease 180s)', 'released w1:p5 w1:p5 (compacting 900s, lease 180s)' for the hand-started exempt pane, and 'ok w1:p3 reviewer-wo-20261010-539f (armed 30s, lease 180s not yet up)' for the seat inside its lease; both released agents' screens carried 'guard lease released by unfreeze.sh at', the reviewer's carried none; two note 100 records from seat unfreeze existed; the fresh lease's phase stayed armed; a second pass released nothing; a pane equal to HERDR_PANE_ID printed 'refused' and kept its lease.
- [x] `AC-H3` *(human)* a worker seat can run the suite in the labelled test pane named in its brief and the run is refused for any other pane
  - observed `2026-10-11` Case 07-testpane (stub herdr, in the full suite from wD3:pF): testpane.sh with COQ_TEST_PANE=w9:pT logged exactly one 'pane run w9:pT <command in one piece>' and exited 0; w9:p1, w9:pTT and wD3:pF each exited 3 with 'refused - <pane> is not the test pane your brief names (w9:pT)' and herdr was never asked; no COQ_TEST_PANE exited 3, missing command or arguments exited 2. Case 01: seat.sh with no HERDR_TAB_ID refused a ticket seat with exit 3 and built nothing; with the fixture tab the brief read 'Your test pane is <pane>; run commands only there, through herdr/bin/testpane.sh' and the agent pane's environment line carried COQ_TEST_PANE. Not exercised: a live worker seat started after this change (this seat predates it and runs under its older rendered settings).
- [x] `AC-H4` *(human)* the suite is green from the labelled test pane: every case passes, 0 failed
  - observed `2026-10-11` Full suite from labelled test pane wD3:pF on the tree that became ce8006e: 'tests: 7 passed, 0 failed' (cases 01 to 07), make lint clean. Cases 04 and 05 and 06 were also run alone earlier in the same pane (2 passed, 0 failed; 1 passed, 0 failed).

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

- `2026-10-11` Retro. Went well: three small steps each landed with a checkpoint; the world fixture made the production test-pane path the one every case runs. Went wrong: my first wait-output matched stale 'tests: N passed' lines left in wD3:pF scrollback by the previous worker, so wait on a marker unique to the run; merging origin/main conflicted in CONTEXT_STATE.md and work-orders/INDEX.md both times a checkpoint landed on both sides. Gaps for the architect: no slot.sh or treehouse lease exists; SPEC-04 s-seat does not list COQ_TEST_PANE (specs/ is denied to workers); testpane.sh fences pane run only; roles/bin/brief.sh's second usage string still lacks [--test-pane ID] (a sed -i on roles/ was denied and not worked around).
- `2026-10-11` Decision 2026-10-11 UTC (architect answer): a worker runs commands in a pane only through herdr/bin/testpane.sh, which compares the pane to COQ_TEST_PANE. seat.sh resolves that pane as the one labelled 'test - herdr' in the tab the seat was started from (HERDR_TAB_ID), refuses a ticket seat when none exists, exports COQ_TEST_PANE next to COQ_SEAT, and roles/bin/brief.sh --test-pane prints it in the brief so the worker reads it and never chooses it. Why a wrapper: role allow/deny are static rules and a seat runs under bypassPermissions, so no rule can say 'this pane only'. Rejected: allow 'herdr pane run *' plus a playbook rule (AC-H3 asks for a refusal). Cost: the wrapper fences pane run only, send-text and send-keys are not denied. Test world: world.sh adds an architect-fixture workspace with a pane labelled 'test - herdr fixture' so every case runs the production resolution path. Also fixed inside this ticket: unfreeze.sh --all never read exemptions.json ('now_iso' for '$now_iso'; jq failed to compile, 2>/dev/null hid it), so the hand-started architect pane was never visited; case 06 now covers it.

## Outcome

_Written by `work-order done`. Empty until then._
