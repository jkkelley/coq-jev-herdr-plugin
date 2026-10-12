# ROADMAP

## Contents

- What this is
- Signals
- Why this roadmap exists
- Locked decisions
- Where runtime data lives
- Rules that keep agents from being gates
- Guardrails against a repeat
- Phases
- Work items
- How agents follow this
- After this roadmap

## What this is

The north star roadmap for this repository, locked by the owner on 2026-10-12 UTC.
It binds every agent, whatever its runtime, until every phase is done.
Only the owner adds to it or changes it.
Work that is not on it waits, unless the owner adds it.

The north star itself: a herdr-first software factory whose big loop takes an owner request from the bearings page to a released change, and whose small loop (worker, tester, reviewer, merger) builds and proves each ticket, with no agent standing as a gate in either.
This roadmap gets the small loop running on its own first, because the big loop is built on it.

## Signals

| Signal     | Meaning                                                                                                                                                               |
| ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `USERGO`   | The owner's go. A held line restarts only on it.                                                                                                                      |
| `USERHALT` | Halt now: stop the belt and every watch, interrupt every seat's turn, keep seats up, post a halt record. It never stops bearings stable. `make line-halt` once work item C lands; by hand until then. |

Owner order, 2026-10-12 UTC: the only monitoring that never shuts off is bearings stable, the server of the owner's page and the wait loop that carries the owner's messages to the architect.
Every other watch, monitor and loop stops on `USERHALT` and stays off until `USERGO`.

## Why this roadmap exists

On 2026-10-12 the line flooded the architect and stopped.
Four causes, all fixed below:

1. The architect's watches copied every record and every seat turn to the architect, one prompt each, and after a compaction they replayed stale.
2. The repository was used as the message bus: one committed file per runtime event, a changelog file per step, and a records branch only the architect carried to main.
3. The architect had become the gate for carries, verifies, merge conflicts, scheduler forwarding, block rulings and records, and wrote untested code on the records branch.
4. Halting was not a command.

The flow of the small loop was good and stays.
What changes is that neither git nor the architect sits in its path.

## Locked decisions

Owner answers on the bearings page, 2026-10-12 UTC.

| Card | Decision                                                                                                    |
| ---- | ----------------------------------------------------------------------------------------------------------- |
| C9   | The records pull request ships only tickets that were cut and never started; no runtime records.            |
| C10  | Events, the routed ledger, logs and checkpoints move out of git into the state root.                        |
| C11  | The event and changelog files already on main move out of git; copies are kept in the state root.           |
| C12  | The tester, reviewer and merger seats stay; their verdict records live in the state root.                   |
| C13  | The changelog is rendered from merged pull request titles at release; no changelog files in the repository. |
| C14  | The backlog lives in GitHub issues.                                                                         |
| C15  | NATS JetStream is dropped for now; the bus is files in the state root, owned by the Go scheduler.           |
| C16  | The scheduler design (pull request 37) is revised to these decisions before it merges.                      |
| C17  | The record bus (pull request 25) is closed; the state root replaces it.                                     |
| C18  | The verifier seat (pull request 29) is closed; the merger verifies on main after each merge.                |
| C19  | Pull requests 40, 42, 38, 41 and the tester playbook ticket land in phase 1 under today's gates.            |
| C20  | The factory spec (pull request 35) is revised to these decisions, then published as v2.1.                   |
| C21  | The bearings page links stay live until their own ticket lands.                                             |
| C22  | `USERHALT` exists next to `USERGO`.                                                                         |

Defaults the owner accepted: 30 days of runtime records kept, squash merges, the scheduler team kept up and idle until its design is revised.

## Where runtime data lives

The repository is the package source.
Logs, state, queues and caches live outside it, as a Linux package keeps them in `/var/log`, `/var/lib` and `/run`.

```text
$COQ_STATE   default ${XDG_STATE_HOME:-~/.local/state}/coq/<repo>
├── records/YYYY/MM/       20261012203505-test-passed-pr-36-wo-20261012-0677.json
├── logs/YYYY/MM/          20261012204200-belt-route-runner.log
├── tests/YYYY/MM/         20261012205612-pr-40-herdr-suite-clean-checkout.log
├── checkpoints/YYYY/MM/   20261012203252-architect-checkpoint.md
├── plans/YYYY/MM/         20261012212500-roadmap-progress.md
├── ledger/routed/         <record file name>
├── seats/<seat>/          settings.json
└── run/                   line.halted, locks, pids
$COQ_CACHE   default ${XDG_CACHE_HOME:-~/.cache}/coq/<repo>, safe to delete
├── worktrees/<ticket>/
└── scratch/
```

File names are `YYYYMMDDHHMMSS-<descriptive name>.<ext>` in UTC.
The name is lowercase letters, digits and hyphens, at most 55 characters, and says what the file is without opening it.
The extension says the format: `.json` for a record, `.log` for text output, `.md` for people.
One script writes each tree and refuses a bad name.
A file is never edited after it is written; a log is appended only by the process that opened it.
A same-second, same-name write gets `-2`, then `-3`, by exclusive create, with no lock.
Retention deletes whole `YYYY/MM` folders past the configured age.
`ledger/`, `seats/` and `run/` are lookups, so they are keyed by name and not dated.
One state root serves every worktree and slot of a repository, so no record is ever copied between them.

## Rules that keep agents from being gates

1. Every record kind has exactly one consumer, named in `factory/config/routes.json`; lint fails a kind with no route.
2. Routing reads the owner seat from the ticket, never builds a seat name.
3. A pull request whose own files are byte-identical to the tested commit carries its test and review by rule.
4. The merger merges on rule and verifies on main; no merge waits on the architect.
5. A block meets the standing policies first; only what they cannot answer reaches the architect, with a deadline.
6. The architect receives one digest of items addressed to it and not yet answered, never a copy of everything; after a compaction the resume notice comes first.
7. A stall wakes the seat that owes the next record, retries, and only then escalates; owner notices are capped.
8. Halt and resume are commands, and the supervisor honours the halt flag.
9. Architect prompts are counted per hour by kind; every recurring kind becomes a rule.

## Guardrails against a repeat

- No records branch, ever. A ticket is cut and started on its own branch and rides its own pull request.
- Code reaches main only through a ticket in the small loop; nobody, the architect included, commits code on any other branch.
- At most four tickets in flight at once.
- Tickets that touch the same files run one after another; their files are declared when they are cut.
- The supervisor stays uninstalled until work item C gives it the halt flag; while halted, it brings back only bearings stable.
- Bearings stable is never stopped by a halt, a restart or a cleanup; if its server or wait loop dies, bringing it back comes before anything else.
- Until work item D lands, the belt restarts without the stall escalation to the owner, and the architect gets one batched digest every 30 minutes.
- Every phase gate checks the architect prompt count.

## Phases

| Phase               | Goal                                                     | Done when                                                                                       |
| ------------------- | -------------------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| 0 Hold              | Halt, capture, lock decisions                            | every card answered and the owner sends `USERGO`                                                |
| 1 Unblock           | Records pull request merged, laws in place, line back up | no records branch, and the architect gets only addressed prompts                                |
| 2 Source only       | Runtime data out of git                                  | a day of running leaves `git status` clean and every pull request holds only its ticket's files |
| 3 Rules, not agents | Every gate is a rule or a seat                           | a ticket goes from cut to verified with zero architect prompts                                  |
| 4 Go scheduler      | The scheduler runs the small loop and the factory DAG    | the bash belt is retired                                                                        |
| 5 Owner interface   | The page is the only interface                           | the owner talks only on the page and the line runs itself                                       |

Rough sizes: phase 1 hours, phases 2 and 3 a few days, phase 4 about a week, phase 5 days.
A phase that runs past its size is reported on the page with the reason.

## Work items

Each lettered item is cut as one ticket under the roadmap epic, with its files declared, in the order shown.

### Phase 1

- Records pull request 32 merged with only never-started tickets, `ROADMAP.md` and these laws; the records branch retired.
- Checkout moved onto main; the live bearings page edits kept until their ticket (C21).
- Preflight: every record posted since the halt listed, stale ones marked done, then the belt restarted without the stall escalation and without the architect watches.
- Seats woken one at a time, merger first, worker last; the first 15 minutes watched, and more than a handful of architect prompts means halt.
- Pull requests 40, 42, 38, 41 and the tester playbook ticket landed (C19); 38 and 41 checked first for assumptions the revised scheduler design drops.
- Pull requests 25 and 29 closed (C17, C18).
- Pull requests 17 and 15 decided: rebased after phase 3, or closed and re-cut.
- A short retro of 2026-10-12 written to the state root.

### Phase 2

- **A - State root.** `$COQ_STATE` and `$COQ_CACHE` in config, the layout above, every writer naming files by the rule; `events/` and `factory/state/` leave git (C10, C11). Cut over under `USERHALT`: move, verify, `USERGO`; merging main strips `events/` from any branch; a written rollback.
- **F - Changelog from pull request titles (C13).** `make step` writes no entry; `changelog/` leaves git.
- **G - `make aggregates` works in a clean checkout,** without the gitignored skill copy it calls today.
- **H - Backlog to GitHub issues (C14).** Each item becomes an issue with a priority label; `backlog.sh` files issues; `backlog/` leaves git.
- **L - Laws and design graph.** The decision nodes for C10 to C22 added to `graph/`, the NATS decision node marked deferred (C15), and the bus ticket WO-20261010-539f re-scoped or cancelled.

### Phase 3

Order: B, then D, then E, then C, because they share the belt's files.

- **B - Seats on rules (C12, C18).** Tester, reviewer and merger read and write verdict records in the state root; the merger verifies on main after each merge.
- **D - Routing and the digest.** One consumer per record kind, owner seat from the ticket, the architect digest, the stall policy, the architect prompt counter, and a test that pushes 50 records through the router and allows the architect at most one prompt.
- **E - Carry rule.** The gate carries a test and review when the pull request's own files equal the tested commit.
- **C - Halt and resume.** `make line-halt`, `make line-resume` with its preflight, the halt flag the supervisor honours, `USERHALT` (C22); `make line-halt` leaves bearings stable running and the supervisor keeps only it alive while halted; then the supervisor is installed.

### Phase 4

- The scheduler design (pull request 37) revised to the locked decisions (C16): state root, seats kept, merger verifies, no NATS.
- The 14 scheduler build tickets re-cut against the revised design; the replay fixtures ticket WO-20261012-8d87 re-checked, since its golden cases read `events/`.
- Config and host files merged, the build tickets run in waves of at most four.
- Shadow mode, then cut-over (WO-20261012-fa36); the bash belt retired.

### Phase 5

- The interface agent (pull request 17) merged, pull request 15 resolved.
- The bearings page links landed as their own ticket.
- The factory spec (pull request 35) revised to the locked decisions, tested, reviewed, merged, scrubbed, and published to the public repository as v2.1.0 (C20).
- The architect seat becomes the interface agent.

## How agents follow this

- Read this file before any work; if the work in front of you is not on it, stop and ask the owner on the page.
- The architect checks the next open item every turn and keeps progress, each item with the record or pull request that proves it, in `$COQ_STATE/plans/`.
- A ticket for a lettered item names the letter in its title, for example `Roadmap A - State root`.
- When a phase is done, the architect tells the owner on the page with a link.

## After this roadmap

The big loop has no design of its own yet.
When phase 5 is done, its DAG, from an owner request on the page to a released change, is the next design, and only the owner puts it on a roadmap.
