# scheduler/testdata

## Contents

- What lives here
- The layout of a replay case
- Placeholders: why no fixture holds a real id
- The context file
- The expected file
- The check
- Adding or changing a case
- Choices the specs leave open

## What lives here

Golden replay fixtures for the Go scheduler (SPEC-16.K k-replay, k-coverage).
Each case under `replay/` is derived from a bash belt case in `factory/tests/cases/` or from the spec section it names.
It holds the same records and the same expected calls, so the Go engine proves the belt's behaviour before it proves its own.
`replay.schema.json` is the shape of the context and expected files.
`bin/check.sh` proves every case against the routes and policies tables.
`forbidden.json` is a pinned copy of the scheduler check config's forbidden list (see "The check").

## The layout of a replay case

```text
replay/<case>/records.jsonl   the records, one per line, in id order, as the event writer writes them
replay/<case>/context.json    what the engine knows besides the records: clock, seats, gates, history, executor script
replay/<case>/expected.json   per record the verdict, the routes row index and the jobs; policy defaults; other domains' calls
```

The case name is free and says what the case proves.
Every case must cover something no other case covers, so removing any one case fails the check naming what it alone covered.

## Placeholders: why no fixture holds a real id

The copy rule forbids anything shaped like a ticket id or a record id in a fixture (SPEC-16.K k-replay-data).
The engine still needs ids of the real shape, because intake checks the id pattern (SPEC-16.A a-validate).
So fixture files hold placeholders, and every reader expands them in the raw text before parsing:

| Placeholder                                  | Expands to                                                             |
| -------------------------------------------- | ---------------------------------------------------------------------- |
| `<<ticket:x>>`, x in a to f                  | a work order id dated 2000-01-01 whose four hex digits are `000x`      |
| `<<tkt:x>>`                                  | the same id lowercased, as a seat label carries it                     |
| `<<id:NN:CCC>>`, NN 00 to 59, CCC 100 to 599 | a record id at 2000-01-01 00:00:NN UTC, code CCC, suffix `syn` then NN |

The expansion rule is `expand` in `bin/check.sh`; the Go testkit implements the same rule and nothing else.
A record's `at` must equal the time its id says, and its `code` the code its id says.
The year 2000 marks every expanded id as synthetic at a glance.

## The context file

`file` is `context`.
`clock` is the fake clock: policy deadlines and housekeeping periods are judged against it.
`runner_seats` are `intake.runner_seats`: records from them are `own`, and only their `escalated` records count toward `escalations`.
`playbooks_dir` and `evidence_dir` fix the wake line's playbook path and the receipt's evidence path.
`history` holds records already in the log before the boundary: never routed or judged, but counted for escalations and policy limits.
`seats` are what the observer reports; `quiet` says the seat's quiet file exists.
`gates` say what `factory/bin/gate.sh` answers for a record whose row names `when` or `supersede`; every fixture gate proceeds, because a held record is not a SPEC-16 verdict.
`executor` is the fake executor's script: an exit code and stdout for a verb and exact arguments; every other call exits 0 with no output.

## The expected file

`file` is `expected`; `case` is the directory name; `derived_from` names the bash case or spec section the case reproduces.
`decisions` has one entry per record, in the order of `records.jsonl`: the verdict (`routed`, `ignored`, `unrouted`, `own`), the first matching routes row index or null, and the plan's jobs.
`defaults` has one entry per escalation a policies row defaults in this replay.
`engine` lists jobs and executor calls other domains make while the replay runs: the quiet window, observation, housekeeping.

A job is `key`, `verb`, `args` and `after`, as SPEC-16 s-contracts names them.

- `key` is the record id (or `housekeeping`, or `observe`), the verb, and the target, joined by colons.
  The target is the seat for prompt, seat_up, seat_down, break_glass, seat_quiet, inbox and pane_read, the ticket for enqueue, and the record kind written for record.
- `args` bind to the verb's argv template in SPEC-16.H h-verbs by position.
  For `record` they are the writer's flags in the order `factory/bin/route.sh` and `factory/bin/policy.sh` pass them.
- `after` lists the keys the job waits on; a trailing `?` accepts done or dead (the down after its primary), a plain key done only.
- `{out:KEY}` inside an argument is replaced at run time by the first stdout line of the job KEY names, which must be in `after`.
  The wake after a policy default uses it for the id the writer printed (SPEC-16.D d-args-ref).
- `state` is the job's state when the replay ends, `done` when absent; `hold` is the reason of a `held` job; `exit` is a non-zero code the job kept as a handled result.

Within one `engine` entry the calls appear in the fake executor's log in the order listed, with other calls allowed between them.
Entries are independent of each other.

## The check

```bash
bash scheduler/testdata/bin/check.sh            # from the repo root; runs in the lint image
bash scheduler/testdata/bin/check.sh --json     # the same, as one JSON object
```

On the host it re-execs itself in the lint image (`localhost/coq-lint:1`, built from `lint/Containerfile` when missing), with the repo and this directory mounted read-only and the network off.
The host needs only podman and bash, so the tester runs the command above as written.

It checks the cases beside it, so a copy of this directory checks itself.
It reads the routes table, the policies table, the event schema and the roles from the repo: `--repo`, else `$REPO_ROOT`, else the working directory when it holds `factory/config/routes.json`, else the repo this directory sits in.

What it proves, each problem named on stderr with exit 3:

1. No line of a fixture matches a forbidden pattern of `specs/scheduler/config/check.json`.
2. Every placeholder expands; every record validates against `events/schema/event.schema.json`; the context and expected files validate against `replay.schema.json`.
3. Records sort in id order after the history, and each record's `at` and `code` agree with its id.
4. Every decision is the one `route.sh` makes: own by seat, the first matching row with the escalation count, ignored, unrouted with its 500 note, or routed with exactly the primary, down and receipt jobs, wake line and receipt note character for character.
5. The defaults are exactly the ones `policy.sh` applies: overdue by the clock, unanswered, under the limit per ticket counted from history and records.
6. Every routes row, every policies row, every verb and every verdict is covered, and every case covers something alone.

It prints what each case alone covers, then the rows, policies, verbs and verdicts covered.
Exit codes: 0 ok, 2 usage, 3 validation, 4 io.

`forbidden.json` exists because `specs/scheduler/config/check.json` is not on main until the scheduler design lands.
When `check.json` exists the check reads it and fails if the copy differs, so the copy cannot drift; delete the copy once `check.json` is on main.
The verb set is the enum in `replay.schema.json`; when `specs/scheduler/SPEC-16.H-*.xml` exists the check fails if the two differ.

## Adding or changing a case

1. Find the bash case or spec section the behaviour comes from and name it in `derived_from`.
2. Write the records with placeholders, then the context, then the expected jobs by hand from what the bash case asserts.
3. Run the check.
   It recomputes every decision from the tables, so a wrong row, line or note fails naming both sides.
4. A new routes or policies row fails the check until some case covers it; that is the point.

Never copy a record from the live log, and never write an expanded id into a fixture.

## Choices the specs leave open

These are the fixtures' own decisions where SPEC-16 names a behaviour but not its every detail.
The engine tickets read them from here.

- Job keys for record jobs name the kind written (`<id>:record:record.routed`); probe calls have keys too (`observe:agent_list:<UTC>`).
- `gates` carry gate.sh's answers, because SPEC-16.B does not yet name the `when` and `supersede` fields `factory/config/routes.json` has.
- The quiet window case pins `seat_quiet` then `inbox` with the wake line; the observe case pins one `agent_list` per tick and a `pane_read` of the seat a confirmation waits on, with `seat.read_lines` lines.
