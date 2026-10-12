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
- Flow watch
- Standing policies
- Record bus

Graph: `RUN-route-runner` is this runbook, `CMP-route-runner` is the component, and `CMP-route-runner` carries `defined_in RUN-route-runner`.
Ticket: WO-20261011-38c7 - Route runner: factory/bin/route.sh applies routes.json to every new record and nothing else.

## What it does

`factory/bin/route.sh` reads each new record in the event log, matches it against `factory/config/routes.json` top to bottom, and performs the first row that matches.
That is all it does.
No line in the script reads a kind, a code or a note except to match a row.

| Row `do`       | What the runner performs                                                                                                                                 |
| -------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `wake`         | `herdr agent prompt <seat> "record <id> playbook <path>"`, the seat named by `roles/<to>.json`                                                           |
| `seat`         | `herdr/bin/seat.sh --ticket <ticket> --role <to>`, then the same prompt as `wake`; a seat that is already up is left as it is                            |
| `notify_owner` | the same prompt to the interface agent, with `line <done or decision>` between the id and the playbook                                                   |
| `enqueue`      | `queue/bin/queue.sh enqueue --ticket <ticket> --from <id>`, with `--priority` when the record carries one                                                |
| `escalate`     | `events/bin/event.sh add --kind escalated --code <row code> --to <role>` for the ticket                                                                  |
| `ignore`       | nothing but the ledger entry `ignored`; no receipt, no 500, no herdr call                                                                                |
| `break-glass`  | `herdr/bin/seat.sh --break-glass <record's seat> --record <id>`; exit 3 is a refusal seat.sh already recorded as a 423, not a failure (herdr/RUNBOOK.md) |
| `none`         | nothing: the record is seen and receipted (the break glass lifecycle records 100, 201 and 204)                                                           |

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
| - | `policy.applied` 200 | `none` monitor |  | The policy watch took a default (see Standing policies). Seen and receipted, so it is not a no-route 500. In `routes.json` it sits before the 5xx rows, with the break glass rows this table does not list. |

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
`route.sh status` prints it and exits 1 when it is `stale_seconds` old or older (30 to 120, default 60), or missing; it is running only while fresher than that.
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

## Standing policies

Ticket: WO-20261012-9b2c - Standing policies: an escalation carries a deadline and a default drawn from the owner's locked decisions, so the line takes the default when nobody answers instead of waiting.
Under epic WO-20261012-187e - The line runs without the architect: every station is a seat or a rule, so a dead architect or an absent owner never stops a ticket moving.
The runner above sends some records to the architect or the owner and then has no clock: a record sent stays sent until a person acts.
`factory/bin/policy.sh` is the clock.
It reads the event log and `factory/config/policies.json`, and when an escalation that a policy row covers has no answer by its deadline, it takes that row's default.

An escalation here is a record that `routes.json` sends on with an `escalate` row or a `notify_owner` decision line, for example a `blocked` 423.
A row of `policies.json` covers one kind of it.

| Field              | Meaning                                                                                                                              |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------ |
| `id`               | `POL-<words>`, named on the record the watch writes and counted by `limit_per_ticket`                                                |
| `match`            | `kind` and `code` of the escalation, and `attempt` when the row is only for one attempt; never `break.glass`                         |
| `deadline_seconds` | how old the escalation, by its own `at`, may get before the default is taken                                                         |
| `answered_by`      | record kinds that, landing on the same ticket after the escalation, mean someone answered it; the router's records are not among them |
| `limit_per_ticket` | defaults this row may apply to one ticket; the next repeat waits for the owner                                                       |
| `decision`         | the locked decision (`graph/nodes/DEC-*.json`) the default is drawn from; case 12 checks that the node exists                        |
| `default`          | `do: wake`, `to: source` (the seat that wrote the escalation) or a role, and `answer`, the default in at most 160 characters         |

The default is two steps, in this order.
First a `policy.applied` 200 record, seat `policy-watch`, with `--policy <row id>`, `--answer <the escalation's id>` and the answer in the note.
Then `herdr agent prompt <seat> "record <id> playbook <path>"`, the same line `route.sh` sends, so the seat reads its answer from the record.
A wake that fails is a 500 note to the monitor and the record stands.

An escalation with no row is never touched: it waits for the architect or the owner, however old it is.
`break.glass` never has a row.
`policy.sh` exits 3 at start if the table gives it one, and the schema refuses it too.

### Run it here

Bring-up starts the watch in `2.3.2 policy watch - policy` (`herdr/config/monitors.json`).
Never start it from a shell of your own.

```sh
herdr/bin/bringup.sh --check     # lists pane-policy ok
make -C factory policy-status    # escalations a policy covers that still wait; exit 1 when one is past its deadline
make -C factory policy-once      # one tick, applies any default now due
```

`status` exiting 1 means the watch is not running: a default is due and nothing took it.

### Add a policy

1. Find the escalation in `routes.json`: the row with `escalate` or `notify_owner` and `line: decision`.
2. Find the locked decision that answers it in `graph/nodes/`. If there is none, the escalation has no policy: the owner decides.
3. Add a row to `policies.json` with the kind and code of that escalation, a deadline, the `answered_by` kinds, a limit and the decision's id.
4. `make -C factory lint` and `make -C factory test`. Case 12 checks that every row matches an escalating row of `routes.json` and cites a node that exists.

The script is not touched.

### Tune it

- `deadline_seconds` is per row.
  A default lands at most `poll_seconds` after it.
- The first start judges only records written after it (`factory/state/policy/since`).
  Pass `--from-start` on that first start to judge the log already there.
- To apply a default again on purpose, delete its latch file under `factory/state/policy/<escalation id>` and raise `limit_per_ticket`, or write the escalation again.

### When something goes wrong

| Symptom                                                    | Cause and fix                                                                                                                 |
| ---------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| A 500: `policy <id> on record <id>: herdr agent prompt ... failed` | The seat is gone. The `policy.applied` record stands for the seat that is brought back; the supervisor re-seats it.   |
| A 500: `... no seat or role for ...`                       | The escalation's seat name matches no `roles/*.json` label, so the record has no addressee. Nothing was woken.                |
| `policy.sh` exits 3 at start                               | A row matches `break.glass`, two rows share an id, or the config is not JSON.                                                 |
| No default for a blocked seat                              | No row covers it, it was written before the first start, a record in `answered_by` landed after it, or the limit was reached. |

### What it never does

- It never decides an answer: the text is in the row, drawn from a locked decision.
- It never touches an escalation no row covers, and never a `break.glass`.
- It never reads a prose field to decide; it matches kinds, codes, tickets and ids.
- It never runs as a background job; it lives in its labelled monitors pane.

GOOD: a worker blocks at 12:00Z, nobody answers, and at 12:30Z a `policy.applied` record carries the owner's default and the worker is prompted with it.
GOOD: a `test.failed` attempt 3 is escalated to the architect and waits, because no row covers it.
NEVER: a `policies.json` row for `break.glass`, because the owner authorises each one by hand.
NEVER: a default written into `policy.sh`, because a new default is a row and `make lint`.

## Record bus

Ticket: WO-20261012-da52 - Record bus: every slot's new records reach the checkout events/ within ten seconds, so the belt routes seat records with no copy by hand.
A seat writes its records into the `events/` of its own treehouse slot, because `event.sh` writes into the tree it lives in.
The route runner reads only the checkout's `events/`.
`factory/bin/bus.sh` closes that gap: it copies every new slot record into the checkout, byte for byte, once.

How it works:

- The slots are read from `treehouse status --json`, run in the checkout, every tick. No slot path is typed anywhere, so a pool that grows needs no edit.
- A record is copied when its file name sorts after the `since` boundary, it parses as JSON, and `factory/state/bus/copied/<id>` does not exist yet. The copy goes to `<name>.tmp` and is renamed, so the runner never reads half a record.
- The ledger is what makes "once" true. A record the architect removes from the checkout on purpose does not come back.
- A same-named file in the checkout that differs is never overwritten. It is logged and claimed.
- The first start copies nothing older than `lookback_seconds` of `factory/config/bus.json`. Later starts keep the first boundary.
- `poll_seconds` is at most 5, so a record lands inside ten seconds.

Bring-up starts it in `2.3.3 record bus - bus` (`herdr/config/monitors.json`).
Never start it from a shell of your own.

```sh
herdr/bin/bringup.sh --check     # lists pane-bus ok
make -C factory bus-once         # one tick, copies any new record, prints each copy
factory/bin/bus.sh slots         # the slot paths treehouse lists
```

Verify with `make -C factory test` (case 12-bus) from the labelled test pane.

### Cut-over from the interim bus

The interim bus is a loop script in the user cache directory, running in monitor slot 2.3.3.
The belt needs it until `bus.sh` runs from `main`, so the cut-over happens after the merge and belongs to the architect.
No worker removes the interim script or stops its loop.

1. Merge the ticket's PR and bring the checkout to `main`.
2. Stop the job in slot 2.3.3 with `herdr/bin/monitors.sh release <pane>`, where the pane comes from `herdr/bin/monitors.sh status`.
3. Delete the interim script from the user cache directory.
4. Run `herdr/bin/bringup.sh`, which plugs `bus.sh run` into slot 2.3.3, then `herdr/bin/bringup.sh --check` and expect `ok pane-bus`.
5. Write one record in a treehouse slot and see it in the checkout `events/` within ten seconds.

Order matters: stop the interim loop before the repo bus starts, so two copiers never race on one record.
The ticket's AC-H2 is checked at verification, after these steps.
Its grep half (no user cache path in `herdr/` or `factory/`) holds on the PR head and is checked by case 12-bus.
