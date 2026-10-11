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
2. Bring the seat up on the ticket the PR belongs to, never on the seat's own ticket: `herdr/bin/seat.sh --ticket <WO of the PR> --role tester|reviewer|merger`. The tester and reviewer are named `<role>-wo-<id>`; the merger is the fixed seat `merger` (roles/merger.json, one on the host, so bring it up on the first PR in the chain and leave it up while others follow).
   The slot is leased to the ticket; a second seat on the same ticket shares that lease and worktree (seat.sh prints `already holds a treehouse lease, using it`).
   The brief names the ticket, the playbook and the test pane.
   When the record the seat waits on already exists at seat-up, the seat acts on its brief without a wake and posts its record straight away (observed 2026-10-11, tester on PR 12, test 201 within 90 s); step 3 is for the seat that comes up before its record.
3. If the record it waits on exists, wake it: `herdr agent prompt <agent pane> "<record id>: <kind> <code> on PR <n>. Playbook playbooks/<role>.md. Post exactly one record and stop."` The pane id is in the JSON line seat.sh printed (`agent`). Send nothing else; the record is the handoff.
4. Watch for its record: `events/bin/event.sh tail` in the seat's monitor pane shows test.passed|test.failed (tester), review.passed|review.changes (reviewer), merged|merge.conflict (merger). One record per wake; a seat that posts none within its context window is stalled: `herdr/bin/seat.sh --check <name>`.
5. Chain by hand until the runner exists: tester 201 wakes the reviewer (step 3), reviewer 201 wakes the merger. A 422 wakes the ticket's worker with the record id, through the same prompt shape.
6. After `merged 200`: the merger ran `work-order.sh cleanup` and downed the worker seat (`herdr/bin/seat.sh --down worker-wo-<id>`), which returned the slot. Down a tester or reviewer as soon as its one record is posted and the next station has it: `herdr/bin/seat.sh --down <role>-wo-<id>`. The host caps live agents (herdr/config/herdr.json max_agents, 8 on 2026-10-11) and a finished seat that stays up blocks the next PR's seat (seen 2026-10-11: reviewer for PR 13 refused with 429 while the finished testers sat idle). A 422 bounce brings a fresh tester up on the new pr.opened, so nothing is lost. Exception: a seat that owns a lease other seats share (seat.sh printed `owned: true` and later seats `using it`) cannot return the slot while they run, so it stays up until the PR is closed. Down `merger` only when no PR is left in the chain. A --down that lists a foreign process in the slot refuses; move or end that process, rerun.
7. Record anything you had to do by hand as an event record (`events/bin/event.sh add --code 100 --seat architect --kind note --ticket <WO>`) so the seats can read it, and as a work-order note on the PR's ticket when the ticket is on the current branch (never push a note commit onto a PR branch that already carries a test or review record: it moves the head sha and voids the gate); a repeated hand step is a ticket or a routes.json row, never a habit.

## Verification

A step that cannot be verified is a wish.
Record what the successful run actually printed.

Step 2, seat up: `seat.sh` prints one JSON line ending `"started":true`; its `agent` field is the pane to wake and `lease.owned` says whether this seat returns the slot.
The second seat on the same ticket first prints `seat <name>: ticket <WO> already holds a treehouse lease, using it`.
Observed 2026-10-11 21:38Z: `{"name":"tester-wo-20261011-f896", ... "agent":"wD3:p5M", ... "lease":{"holder":"WO-20261011-f896", ... "owned":false},"started":true}`.
Within three minutes `events/bin/event.sh tail` shows the seat's own `100 seat.up <name> <WO> <role> seat up: <model> <effort> bypassPermissions` line, then a `100 work.started` line.
A seat that printed `no guard ack within 180s, no nudge` still came up; that line is a timing note, not a failure.

Steps 3 to 5, the gate records: `event.sh tail` prints one tab separated line per record, `<UTC> <code> <kind> <seat> <WO> <note>`, and the note names the PR and the head sha.
Observed 2026-10-11 on PR 13: `201 test.passed tester-wo-20261011-9639` (a24h8), `201 review.passed reviewer-wo-20261011-9639` (gkkza), `200 merged merger` (66gbp).
A record whose note names a sha other than the PR head is stale and the merger refuses it; observed 21:17Z: `PR 15 head 798dad3 not mergeable: no test 201 or review 201 on this sha`.
`herdr/bin/seat.sh --check <name>` prints nothing and exits 0 while the seat is healthy; each difference prints as `<name>: <what differs>` and the exit is 1; a finished seat prints `<name>: down since <UTC>` and exits 3.

Step 6, seat down: `--down` writes a `100 seat.down` record and the name leaves `herdr agent list`; the lease owner's down also prints the treehouse return of the slot.
A refused down prints `refusing treehouse return --force on <worktree> while a foreign process is in it`; end that process and rerun, never force the return (a forced return killed parked shells twice on 2026-10-11).

Step 7: `events/bin/event.sh list --since <date> --seat architect` lists every hand step; a hand step with no record did not happen.
