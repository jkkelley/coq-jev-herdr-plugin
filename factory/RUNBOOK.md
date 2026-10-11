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
