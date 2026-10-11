# RUNBOOK - the route runner

## Contents

- What it does
- The routes, row by row
- Run it here
- Run it against another repo
- Add behaviour
- Read the belt
- When something goes wrong
- What it never does
- GOOD and NEVER

## What it does

`factory/bin/route.sh` reads each new record in the event log, matches it against `factory/config/routes.json` top to bottom, and performs the first row that matches.
That is all it does.
No line in the script reads a kind, a code or a note except to match a row.

| Row `do`       | What the runner performs                                                                                                                  |
| -------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| `wake`         | `herdr agent prompt <seat> "record <id> playbook <path>"`, the seat named by `roles/<to>.json`                                            |
| `seat`         | `herdr/bin/seat.sh --ticket <ticket> --role <to>`, then the same prompt as `wake`; a seat that is already up is left as it is             |
| `notify_owner` | the same prompt to the interface agent, with `line <done or decision>` between the id and the playbook                                    |
| `enqueue`      | `queue/bin/queue.sh enqueue --ticket <ticket> --from <id>`, with `--priority` when the record carries one                                 |
| `escalate`     | `events/bin/event.sh add --kind escalated --code <row code> --to <role>` for the ticket                                                   |
| `ignore`       | nothing but the ledger entry `ignored`; no receipt, no 500, no herdr call                                                                 |

Two optional fields on a row change what the action carries.

| Field        | Meaning                                                                                                                                                  |
| ------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `with: pr`   | the wake line gains ` pr <N>` and ` sha <S>` from the record, whichever it carries (`event.sh add --pr N --sha S`); a malformed value is a 500           |
| `down: role` | after the row's action, `herdr/bin/seat.sh --down <seat of that role for the ticket>`; it runs even when the action failed, and a failure of either is one 500 |

After every action except `ignore` it writes one `record.routed` 300, addressed to the row's `to`, whose note ends with `, down <role>` when the row has a `down`.
A record that matches no row, and an action that fails, each become a 500 `note` addressed to the monitor.
The monitor wakes on new events, so a 500 is seen without the runner waking anyone.

The wake prompt carries the record id and the playbook path, and for a `with pr` row the PR number and head sha the record holds.
The seat reads the record, never a sentence.

Matching:

- `kind`, `code` and `attempt` compare to the record; a record with no `attempt` counts as attempt 1.
- `code_gte` is a floor on the code.
- `attempt_lt` and `attempt` compare the same way.
- `escalations` is the number of `escalated` records the runner wrote for the ticket before this record, which is how the table tells a first 423 from a second.

## The routes, row by row

This is `factory/config/routes.json` in order; the first row that matches wins, so a row placed above another shadows it.
Behaviour lives in the table; this section explains it and `make lint` checks the table against its schema.

| # | Record | Action | Then | What it means |
| - | ------ | ------ | ---- | ------------- |
| 1 | `request.forwarded` 300 | `enqueue` architect |  | An owner request the interface agent forwarded waits in `queue/` for the architect. |
| 2 | `ticket.cut` 100 | `wake` worker (with ticket) |  | A cut ticket wakes its worker. This row only prompts: the worker seat is still brought up by hand. |
| 3 | `pr.opened` 100 | `seat` tester (with pr) |  | The worker opened a PR. The tester seat for the ticket is brought up if it is not, and woken with the PR and head sha. |
| 4 | `test.passed` 201 | `seat` reviewer (with pr) | down tester | The tester passed the PR. The reviewer is brought up and woken, then the tester is taken down. |
| 5 | `test.failed` 422 attempt < 3 | `wake` worker (with record) | down tester | The tester failed the PR. The worker is woken with the record, then the tester is taken down. |
| 6 | `test.failed` 422 attempt 3 | `escalate` architect (code 423) | down tester | The third failure is not woken to the worker again: it is an escalated 423 to the architect, and the tester is taken down. |
| 7 | `review.passed` 201 | `seat` merger (with pr) | down reviewer | The reviewer passed the PR. The merger is brought up and woken with the head sha, then the reviewer is taken down. |
| 8 | `review.changes` 422 attempt < 3 | `wake` worker (with record) | down reviewer | The reviewer asked for changes. The worker is woken with the record, then the reviewer is taken down. |
| 9 | `review.changes` 422 attempt 3 | `escalate` architect (code 423) | down reviewer | The third change request is an escalated 423 to the architect, and the reviewer is taken down. |
| 10 | `merged` 200 | `wake` architect (with verify) | down merger | The merger merged. The architect is woken to verify, then the merger is taken down. |
| 11 | `merge.conflict` 409 | `wake` worker (with record) | down merger | The merge conflicted. The worker is woken with the record, then the merger is taken down. |
| 12 | `verified` 201 | `notify_owner` interface-agent (line done) |  | The architect verified the merge. The interface agent gets the done line for the owner. |
| 13 | `blocked` 423 escalations < 1 | `escalate` architect (code 423) |  | A seat is blocked. The first 423 for a ticket is escalated to the architect; a second one becomes a decision line for the owner. |
| 14 | `blocked` 423 escalations 1 | `notify_owner` interface-agent (line decision) |  | A second blocked 423 for the ticket: the interface agent gets a decision line for the owner. |
| 15 | `seat.up` 100 | `ignore` |  | Housekeeping: seat.sh recorded a seat coming up. |
| 16 | `seat.down` 100 | `ignore` |  | Housekeeping: seat.sh recorded a seat going down. This is the record the `down` field produces. |
| 17 | `note` 100 | `ignore` |  | Housekeeping: a seat noted something. Notes are never routed on. |
| 18 | `record.routed` 300 | `ignore` |  | Housekeeping: a receipt. The runner skips its own, this covers a receipt another seat name wrote. |
| 19 | `seat.down` 500 | `wake` monitor (with record) |  | A seat went down badly. The monitor is woken with the record. |
| 20 | code >= 500 | `wake` monitor (with record) |  | Any other 5xx. The monitor is woken with the record. |

Why a record can need a `seat` and a `down` at once: it is one record and one row, and a second row would never get its turn.
The merger is one shared seat named `merger`, so the `down` on `merged` and `merge.conflict` is safe only while one ticket is merging at a time.

A `ticket.cut` is not a `seat` row yet: the row wakes a worker that the architect still brings up with `herdr/bin/seat.sh`.

## Run it here

Run the loop in a labelled herdr pane, never as a background job.

```sh
factory/bin/route.sh run         # ticks every poll_seconds from factory/config/runner.json (5 to 30)
factory/bin/route.sh once        # one tick, then exit
factory/bin/route.sh status      # exit 0 when the belt file is fresher than stale_seconds, 1 when not
make -C factory test             # the suite, in Podman, herdr stubbed
```

The first start routes only records written after it.
Pass `--from-start` on that first start to route the records already in the log.

A `seat` or `down` row calls `herdr/bin/seat.sh`, which finds the labelled test pane from `HERDR_TAB_ID`.
So the runner pane has to sit in the architect tab, the one that holds the pane labelled `test - herdr`, or every bring-up is refused and becomes a 500 that says so.

Stop it with Ctrl-C or TERM in its pane.
It stops at once, not after the poll interval, and a restart over the same log routes nothing twice.

## Run it against another repo

Everything the runner touches hangs off `${repo}`, and three flags move it.

```sh
factory/bin/route.sh run \
  --repo /path/to/other-repo \
  --routes /path/to/other-routes.json \
  --state /path/to/other-state
```

The other repo needs these, at the paths `factory/config/runner.json` names (edit the config copy, or pass `--config`):

- an events directory written by an `event.sh` (`events_dir`, `event_bin`)
- `roles/<role>.json` with a `label` for every role the routes name (`roles_dir`)
- `playbooks/<role>.md` for every role a wake can reach (`playbooks_dir`)
- `queue/bin/queue.sh` when the table has an `enqueue` row (`queue_bin`)
- `herdr/bin/seat.sh` when the table has a `seat` row or a `down` field (`seat_bin`)

`--routes` replaces `routes_file` and `--state` replaces `state_dir`.
The state directory holds the ledger, the first-start boundary and the belt file, so give each events directory its own.
Case 07 of the suite runs exactly this and checks that nothing of this repo is read or written.

## Add behaviour

New behaviour is a row in `factory/config/routes.json`, validated by `factory/config/routes.schema.json`.
Add the row, run `make lint`, open a PR.
The runner reads the file on every tick, so the row is live on the next one, with no change to `route.sh` and no restart.
Case 05 of the suite adds a row to a copy of the table and proves the script stays byte for byte the same.

A new `do` or a new row field is the only thing that needs runner code, and that is a design change to SPEC-03, not a row.
`seat`, `ignore` and `down` were added that way by WO-20261011-4db1 - Belt seats the line: route.sh brings a role seat up before a wake, takes a seat down after its gate record, and ignores housekeeping records by table.

## Read the belt

`factory/state/belt` is rewritten every tick, so its age is the age of the last tick.
`route.sh status` prints it and exits 1 when it is older than `stale_seconds` (30 to 120, default 60), or missing.
A stopped runner stops touching the file and reads as stale within `stale_seconds`.
The runner is serial, so a `seat` row holds every later record until `seat.sh` returns.
A bring-up can take about 45 seconds (15 for the shell prompt, 30 for the agent to start), and the belt is touched again as soon as `seat.sh` returns.
One bring-up that outlasts `stale_seconds` still reads as stopped while it runs, which is WO-20261011-5355 - Belt on: bringup.sh starts the route runner in its own pane before any seat and seat.sh refuses a seat while the belt is stopped to settle.
Bring-up and `seat.sh --check` will read it the same way once WO-20261011-5355 - Belt on: bringup.sh starts the route runner in its own pane before any seat and seat.sh refuses a seat while the belt is stopped, lands.

## When something goes wrong

| Symptom                                               | Cause and fix                                                                                                                   |
| ----------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| A 500 note: `no route for <kind> <code>`              | No row matches. Add a row, or the record is not one the factory routes.                                                         |
| A 500 note: `route failed ... herdr agent prompt ...` | The target seat is not up, and the row is a `wake`. Bring it up with `herdr/bin/seat.sh`; the record is not retried.             |
| A 500 note: `seat.sh --ticket T --role R failed`      | `seat.sh` refused; the note ends with its last line. Typical: the monitor seat is down, a seat cap, no `test - herdr` pane, the ticket is not started. Fix that, then route the record again on purpose. |
| A 500 note: `seat.sh --down NAME failed`              | `seat.sh` would not take the seat down: a foreign process holds its slot, or the seat never existed (a gate record posted by hand). The row's own action was still done. |
| A record with a ledger entry `ignored`                | A housekeeping row matched. That is the only trace it leaves.                                                                   |
| A 500 note: `routing of record <id> was interrupted`  | The runner died between claiming a record and finishing it. The wake may or may not have been sent. Look, then re-send by hand. |
| A 500 note: `unreadable record`                       | A file under `events/` is not JSON. Fix or remove it; the runner ignores it from then on.                                       |
| A record never routed                                 | It was written before the first start without `--from-start`, or its seat is the runner's own seat.                             |

To route a record again on purpose, delete its file under `factory/state/routed/`.
That is the only supported way, and it is a decision, not a retry loop.

## What it never does

- It never routes a record its own seat wrote (`runner_seat`), which is what stops a receipt from being routed again.
- It never retries a failed action; the failure is a 500 and the monitor decides.
- It never reads a note.
- It never asks whether a seat is up before `seat.sh` is called; `seat.sh` leaves a live seat as it is.
- It never takes a seat down before the gate record is on disk, and never leaves it up because the row's own action failed.
- It never talks to the owner except through the `notify_owner` row and the interface agent.
- It never runs as a background job; every process is a labelled herdr pane.

## GOOD and NEVER

GOOD: a new failure class is a row in `factory/config/routes.json`, `make lint`, a PR, and `route.sh` is not touched.
GOOD: a second runner for another repo gets its own `--state` directory, so the two ledgers never meet.
GOOD: a 500 `note` for `route failed` is read by the monitor, the target seat is brought up with `herdr/bin/seat.sh`, and the record is re-routed on purpose by deleting its ledger file.
GOOD: `route.sh run` lives in a labelled herdr pane, and Ctrl-C in that pane stops it at once.
GOOD: a `pr.opened` 100 for a ticket with no tester seat brings `tester-<ticket>` up through `seat.sh` and prompts it, with no architect in the loop.
GOOD: a `seat.up` 100 or `seat.down` 100 record is an `ignore` row, so the monitor only ever sees a 500 that is real.
NEVER: an `if` on a kind, a code or a note inside `route.sh`, because behaviour that is not a routes row is behaviour nobody can read from the table.
NEVER: `route.sh run &`, `nohup` or `setsid`, because a background runner is invisible and invisible work reads as nothing happening.
NEVER: two runners on one `--state` directory, because both would claim the same records.
NEVER: a record written under the runner's own seat name by hand, because the runner skips it and it is never routed.
NEVER: a skip list of kinds inside `route.sh` for housekeeping, because an `ignore` row says the same thing where everyone can read it.
NEVER: `seat.sh &` or a seat started outside `seat.sh`, because the wake would race a seat nobody can see.
