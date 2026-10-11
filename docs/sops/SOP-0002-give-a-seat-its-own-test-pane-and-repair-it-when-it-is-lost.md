# SOP-0002: Give a seat its own test pane and repair it when it is lost

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
