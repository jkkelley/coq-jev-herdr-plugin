# RUNBOOK - the route runner

## Contents

- What it does
- Run it here
- Run it against another repo
- Add behaviour
- Read the belt
- When something goes wrong
- What it never does
- GOOD and NEVER
- Flow watch

Graph: `RUN-route-runner` is this runbook, `CMP-route-runner` is the component, and `CMP-route-runner` carries `defined_in RUN-route-runner`.
Ticket: WO-20261011-38c7 - Route runner: factory/bin/route.sh applies routes.json to every new record and nothing else.

## What it does

`factory/bin/route.sh` reads each new record in the event log, matches it against `factory/config/routes.json` top to bottom, and performs the first row that matches.
That is all it does.
No line in the script reads a kind, a code or a note except to match a row.

| Row `do`       | What the runner performs                                                                                  |
| -------------- | --------------------------------------------------------------------------------------------------------- |
| `wake`         | `herdr agent prompt <seat> "record <id> playbook <path>"`, the seat named by `roles/<to>.json`            |
| `notify_owner` | the same prompt to the interface agent, with `line <done or decision>` between the id and the playbook    |
| `enqueue`      | `queue/bin/queue.sh enqueue --ticket <ticket> --from <id>`, with `--priority` when the record carries one |
| `escalate`     | `events/bin/event.sh add --kind escalated --code <row code> --to <role>` for the ticket                   |
| `break-glass`  | `herdr/bin/seat.sh --break-glass <record's seat> --record <id>`; exit 3 is a refusal seat.sh already recorded as a 423, not a failure (herdr/RUNBOOK.md) |
| `none`         | nothing: the record is seen and receipted (the break glass lifecycle records 100, 201 and 204)              |

After every action it writes one `record.routed` 300, addressed to the row's `to`.
A record that matches no row, and an action that fails, each become a 500 `note` addressed to the monitor.
The monitor wakes on new events, so a 500 is seen without the runner waking anyone.

The wake prompt carries the record id and the playbook path and nothing else.
The seat reads the record, never a sentence.

Matching:

- `kind`, `code` and `attempt` compare to the record; a record with no `attempt` counts as attempt 1.
- `code_gte` is a floor on the code.
- `attempt_lt` and `attempt` compare the same way.
- `escalations` is the number of `escalated` records the runner wrote for the ticket before this record, which is how the table tells a first 423 from a second.

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

`--routes` replaces `routes_file` and `--state` replaces `state_dir`.
The state directory holds the ledger, the first-start boundary and the belt file, so give each events directory its own.
Case 07 of the suite runs exactly this and checks that nothing of this repo is read or written.

## Add behaviour

New behaviour is a row in `factory/config/routes.json`, validated by `factory/config/routes.schema.json`.
Add the row, run `make lint`, open a PR.
The runner reads the file on every tick, so the row is live on the next one, with no change to `route.sh` and no restart.
Case 05 of the suite adds a row to a copy of the table and proves the script stays byte for byte the same.

A new `do` is the only thing that needs runner code, and that is a design change to SPEC-03, not a row.

## Read the belt

`factory/state/belt` is rewritten every tick, so its age is the age of the last tick.
`route.sh status` prints it and exits 1 when it is older than `stale_seconds` (30 to 120, default 60), or missing.
A stopped runner stops touching the file and reads as stale within `stale_seconds`.
Bring-up and `seat.sh --check` will read it the same way once WO-20261011-5355 - Belt on: bringup.sh starts the route runner in its own pane before any seat and seat.sh refuses a seat while the belt is stopped, lands.

## When something goes wrong

| Symptom                                               | Cause and fix                                                                                                                   |
| ----------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| A 500 note: `no route for <kind> <code>`              | No row matches. Add a row, or the record is not one the factory routes.                                                         |
| A 500 note: `route failed ... herdr agent prompt ...` | The target seat is not up. Bring it up with `herdr/bin/seat.sh`; the record is not retried.                                     |
| A 500 note: `routing of record <id> was interrupted`  | The runner died between claiming a record and finishing it. The wake may or may not have been sent. Look, then re-send by hand. |
| A 500 note: `unreadable record`                       | A file under `events/` is not JSON. Fix or remove it; the runner ignores it from then on.                                       |
| A record never routed                                 | It was written before the first start without `--from-start`, or its seat is the runner's own seat.                             |

To route a record again on purpose, delete its file under `factory/state/routed/`.
That is the only supported way, and it is a decision, not a retry loop.

## What it never does

- It never routes a record its own seat wrote (`runner_seat`), which is what stops a receipt from being routed again.
- It never retries a failed action; the failure is a 500 and the monitor decides.
- It never reads a note.
- It never talks to the owner except through the `notify_owner` row and the interface agent.
- It never runs as a background job; every process is a labelled herdr pane.

## GOOD and NEVER

GOOD: a new failure class is a row in `factory/config/routes.json`, `make lint`, a PR, and `route.sh` is not touched.
GOOD: a second runner for another repo gets its own `--state` directory, so the two ledgers never meet.
GOOD: a 500 `note` for `route failed` is read by the monitor, the target seat is brought up with `herdr/bin/seat.sh`, and the record is re-routed on purpose by deleting its ledger file.
GOOD: `route.sh run` lives in a labelled herdr pane, and Ctrl-C in that pane stops it at once.
NEVER: an `if` on a kind, a code or a note inside `route.sh`, because behaviour that is not a routes row is behaviour nobody can read from the table.
NEVER: `route.sh run &`, `nohup` or `setsid`, because a background runner is invisible and invisible work reads as nothing happening.
NEVER: two runners on one `--state` directory, because both would claim the same records.
NEVER: a record written under the runner's own seat name by hand, because the runner skips it and it is never routed.

## Flow watch

Ticket: WO-20261011-6842 - Flow watch: a shell watcher in a monitors pane turns a stalled line into a 500 (gate record with no consumer, belt heartbeat stale, runner pane gone) and recover.sh restarts the belt.
The runner above routes records.
`factory/bin/flow.sh` watches that the line is moving, and says so when it is not.
Without it a stalled line looks identical to a quiet one: on 2026-10-11 the line sat still from 18:01Z to 18:23Z with every gate record posted and nothing woken.

It writes three kinds of 500 note, seat `flow-watch`, kind `note`, addressed to the monitor.
The route runner turns a 500 into a wake of the monitor seat, and the monitor raises the owner notification.

| Stall       | Condition                                                                                                                     | Latch                                                              |
| ----------- | ----------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------ |
| Gate record | a `gates` row of `flow.json` (kind and code) older than `stall_seconds` with no record of a `consumers` kind on the same ticket after it | `factory/state/flow/<record id>`, never removed                    |
| Belt        | `route.sh status` exits 1 (belt file stale or missing, `stale_seconds` of `runner.json`)                                      | `factory/state/flow/belt-stale`, removed when the belt is fresh    |
| Runner pane | no herdr pane labelled like `runner_pane_label_regex`, or its foreground is the shell                                         | `factory/state/flow/runner-gone`, removed when the pane runs again |

A note is written once per latch.
A gate record is noted once for good, even if it stays stuck: the monitor owns it from there.
A belt or pane stall that clears and comes back is noted again.

### Run it here

Bring-up starts both watchers in monitors 2 (`herdr/config/monitors.json`): the runner in `2.2.2 route runner - runner`, then the flow watch in `2.2.3 flow watch - flow`.
Never start them from a shell of your own.

```sh
herdr/bin/bringup.sh --check     # lists pane-runner and pane-flow ok
herdr/bin/recover.sh --check     # lists ok belt, or FAILED belt (why)
herdr/bin/recover.sh --apply     # restarts the runner pane through monitors.sh take runner, then waits for a fresh belt
make -C factory flow-status      # the stalls present now; exit 1 when there is one; writes nothing
make -C factory flow-once        # one tick, writes any new note
```

`recover.sh` reads `belt.slot`, `belt.status` and `belt.settle_seconds` from `herdr/config/herdr.json`.
The pane and command come from the slot of the same name in `monitors.json`, so a restart is the same call bring-up makes.

### Tune it

Everything is `factory/config/flow.json`, validated by `flow.schema.json` in `make -C factory lint`.

- `poll_seconds` and `stall_seconds`: their sum may not pass `visible_within_seconds` (120), or `flow.sh` refuses to start with exit 3.
  A stall is then on the board within two minutes of when it began.
- `gates`: one row per record the line must pick up.
  A new gate is a new row with its `kind`, `code`, the `role` named in the note and the `consumers` kinds that mean someone took it.
  The script is not touched.
- The first start judges only records written after it (`factory/state/flow/since`).
  Pass `--from-start` on that first start to judge the log already there.

### When something goes wrong

| Symptom                                                   | Cause and fix                                                                                                                      |
| --------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| A 500: `stall: <kind> <code> <id> has no <role> record`   | The record was not picked up. Check `route.sh status`, then the role's seat; the monitor decides. It is not noted again.         |
| A 500: `stall: belt stopped (last touched Ns ago ...)`    | The runner is not ticking. `herdr/bin/recover.sh --apply` restarts it in its own pane.                                            |
| A 500: `stall: the route runner pane is not running`      | The pane is gone or sits at a prompt. `herdr/bin/recover.sh --apply` draws the grid and restarts it.                              |
| `flow.sh` exits 3 at start                                | `poll_seconds` plus `stall_seconds` passes `visible_within_seconds`, or `flow.json` is not JSON.                                  |
| No note for a stuck record                                | It was written before the first start without `--from-start`, it has no ticket, or its kind and code match no `gates` row.        |

To note a gate record again on purpose, delete its file under `factory/state/flow/`.

### What it never does

- It never restarts anything: `recover.sh` does, and only when asked.
- It never reads a note or a prose field; it matches kinds, codes, tickets and ids.
- It never talks to the owner; the monitor does, on the 500.
- It never runs as a background job; it lives in its labelled monitors pane.

GOOD: a new record the line must pick up is one `gates` row in `flow.json`, `make lint`, a PR.
GOOD: the runner dies at 18:01Z, the belt note lands by 18:03Z, `recover.sh --apply` restarts it, and the next tick is silent.
NEVER: a second threshold for a stale belt in `flow.json`, because `route.sh status` and `runner.json` are the one definition.
NEVER: `flow.sh run &`, `nohup` or `setsid`, because a background watcher is invisible and invisible work reads as nothing happening.
