# SOP-0002: Give a seat its own test pane and repair it when it is lost

## Contents

- Purpose
- When to run this
- Steps
- Verification
- GOOD and NEVER

Diataxis mode: **how-to**.
Last reviewed: 2026-10-11.

## Purpose

Each seat runs its commands in a test pane of its own, in its own tab, so many seats test at once instead of queueing on the architect tab's one pane (WO-20261011-f896 - Test pane per seat: seat.sh opens a labelled test pane in the seat's own tab and exports it as COQ_TEST_PANE, so sixteen seats test in parallel instead of queueing on the architect tab's one pane). Portable: the layout, seat.sh and testpane.sh carry the behaviour.

## When to run this

A seat is brought up, a worker reports its make queued behind another seat, seat.sh --check says a test pane is missing, or the factory is set up on another repo.

## Steps

1. Nothing to start by hand: `herdr/bin/seat.sh --ticket <WO> --role <role>` builds the pane when the role's layout has a slot of kind test (herdr/layouts/seat-1x2.json, which every seat role names today), labelled `test - herdr - <seat>`, split down from the monitor pane so the agent keeps the left half of its tab.
   The JSON line seat.sh prints carries it as `test_pane`, the environment line exports it as `COQ_TEST_PANE`, and the brief names it ("Your test pane is <id>").
2. The seat runs every `make` through `herdr/bin/testpane.sh "$COQ_TEST_PANE" '<command>'`.
   testpane.sh compares the pane with COQ_TEST_PANE and refuses every other pane with exit 3, so a seat cannot run in another seat's pane or in the architect tab's.
   Sixteen seats hold sixteen panes and no run queues behind another seat's.
3. The pane's shell is moved to the checkout that brought the seat up (the slot's own `cd ${repo}`), never into the leased slot, so `treehouse return --force` on `--down` cannot end it.
   Read it with `herdr pane process-info --pane <id>` (`shell_pid`, then `readlink /proc/<pid>/cwd`).
4. Check: `herdr/bin/seat.sh --check <seat>` exits 0, and `herdr pane list` shows three panes in the seat's tab (agent, MONITOR, test).
   A lost pane shows as `pane missing: test - herdr - <seat>`.
5. A lost test pane: rerun the same `seat.sh --ticket ...` command.
   It splits the missing pane back and prints its new id, but a running agent keeps the COQ_TEST_PANE it started with and testpane.sh would refuse the new id.
   Ask the seat to commit and push, then `herdr/bin/seat.sh --down <seat>` and bring it up again.
6. `herdr/bin/seat.sh --down <seat>` closes the seat's tab and with it the test pane.
   Another seat's tab and the architect tab's `test - herdr` pane are untouched.
7. A layout with no slot of kind test (player-1x3, interface-2x2) still gets the architect tab's pane labelled `test - herdr`, resolved from the tab seat.sh was started in.
   A ticket seat on such a layout is refused before any lease when that tab has none.
   That pane stays as the fallback and as the owner's watch pane.

## Verification

A step that cannot be verified is a wish.
Record what the successful run actually printed.

Observed 2026-10-11 in `herdr/tests/cases/16-test-pane-per-seat.test.sh` against a headless scratch herdr (not the live `stable` session), run as `make -C herdr test` from the seat's test pane, which finished `tests: 15 passed, 0 failed` on the tree merged with main 55f4e22:

- Two worker seats brought up back to back (`worker-wo-20261010-8777`, `worker-wo-20261010-c274`) got different tabs (`w2:t1`, `w2:t2`) and different test panes, and neither was the architect tab's pane.
  The first seat's pane carried the label `test - herdr - worker-wo-20261010-8777`, the seat record kept it (`pane` `w2:p3`), and each brief named its own seat's pane.
- `herdr pane list` showed three panes in the seat's tab (agent, MONITOR, test).
- `herdr/bin/testpane.sh` run by seat A in seat B's pane, by B in A's pane, and by A in the architect tab's pane each exited 3; run by A in its own pane it exited 0 and printed `ran-in-a`, while B's printed `ran-in-b` at the same time.
- The test pane's shell stood in the checkout that brought the seat up (`/proc/<shell_pid>/cwd` was the repo, not the slot).
- With A's test pane closed by hand, `herdr/bin/seat.sh --check` exited 1 and named `pane missing: test - herdr - <seat>`; the rerun of the same `seat.sh --ticket ...` built a new pane in A's tab and `--check` then exited 0.
- `herdr/bin/seat.sh --down <seat>` exited 0, left no pane of that seat's tab, and left the other seat's pane and the architect tab's pane in place.
- With a layout that has no test slot (`seat-nt`), `COQ_TEST_PANE` was the architect tab's labelled pane and the seat tab held 2 panes.

On a live seat the same checks are `herdr/bin/seat.sh --check <seat>` exiting 0 and `herdr pane list` showing the `test - herdr - <seat>` pane in the seat's tab.

## GOOD and NEVER

GOOD: a worker runs `herdr/bin/testpane.sh "$COQ_TEST_PANE" 'make lint'`, so its run starts at once in its own pane and no other seat's suite is ahead of it.
GOOD: a lost test pane is put back by rerunning the seat's `seat.sh --ticket ...` command, and a running agent is then restarted with `--down` and a fresh up so its `COQ_TEST_PANE` matches the new pane.
GOOD: `seat.sh --check <seat>` after any repair, until it exits 0.
NEVER: run a seat's commands in the architect tab's `test - herdr` pane or in another seat's pane, because `testpane.sh` refuses it with exit 3 and the queue the pane per seat removed comes back.
NEVER: `cd` the test pane's shell into the leased slot, because `treehouse return --force` on `--down` ends a shell that stands in the slot, and the pane with it.
NEVER: rely on the rerun alone to fix a running agent's `COQ_TEST_PANE`, because the agent keeps the id it started with.
