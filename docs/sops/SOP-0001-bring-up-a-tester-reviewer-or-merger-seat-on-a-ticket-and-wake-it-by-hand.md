# SOP-0001: Bring up a tester, reviewer or merger seat on a ticket and wake it by hand

## Contents

- Purpose
- When to run this
- Steps
- Verification

Diataxis mode: **how-to**.
Last reviewed: 2026-10-11.

## Purpose

A non-worker seat (tester, reviewer, merger) comes up through herdr/bin/seat.sh exactly like a worker: door 1 on the ticket whose PR it acts on, in a leased treehouse slot checked out on that ticket's branch, with the role file as the whole contract. Until the route runner owns the belt (WO-20261011-5355 - Belt on: bringup.sh starts the route runner in its own pane before any seat and seat.sh refuses a seat while the belt is stopped), the architect wakes the seat with one herdr prompt carrying the record id. Portable: nothing here names this repo; the role files, routes.json and seat.sh travel with the tree.

## When to run this

A PR has pr.opened (tester), test.passed 201 (reviewer) or review.passed 201 (merger) and no seat of that role is up; or when setting the factory up on another repo.

## Steps

1. Preconditions: the monitor seat is up (seat.sh refuses otherwise, DEC-system-before-agents); the architect tab holds one pane labelled `test - <tool> <ticket>` (the tester runs the test plan there through herdr/bin/testpane.sh); the ticket's branch exists on origin (`work-order start` pushed it; seat.sh derives `feat/<slug>` when the frontmatter copy on this checkout still says null).
2. Bring the seat up on the ticket the PR belongs to, never on the seat's own ticket: `herdr/bin/seat.sh --ticket <WO of the PR> --role tester|reviewer|merger`. The name is `<role>-wo-<id>`; the slot is leased to the ticket; the brief names the ticket, the playbook and the test pane.
3. If the record it waits on exists, wake it: `herdr agent prompt <agent pane> "<record id>: <kind> <code> on PR <n>. Playbook playbooks/<role>.md. Post exactly one record and stop."` The pane id is in the JSON line seat.sh printed (`agent`). Send nothing else; the record is the handoff.
4. Watch for its record: `events/bin/event.sh tail` in the seat's monitor pane shows test.passed|test.failed (tester), review.passed|review.changes (reviewer), merged|merge.conflict (merger). One record per wake; a seat that posts none within its context window is stalled: `herdr/bin/seat.sh --check <name>`.
5. Chain by hand until the runner exists: tester 201 wakes the reviewer (step 3), reviewer 201 wakes the merger. A 422 wakes the ticket's worker with the record id, through the same prompt shape.
6. After `merged 200`: the merger ran `work-order.sh cleanup` and downed the worker seat (`herdr/bin/seat.sh --down worker-wo-<id>`), which returned the slot. Down the three role seats the same way when the PR is closed: `herdr/bin/seat.sh --down <role>-wo-<id>`. A --down that lists a foreign process in the slot refuses; move or end that process, rerun.
7. Record anything you had to do by hand as a work-order note on the PR's ticket; a repeated hand step is a ticket or a routes.json row, never a habit.

## Verification

A step that cannot be verified is a wish.
Record what the successful run actually printed.
