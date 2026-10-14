# L02 - State stores

Investigated 2026-10-14T02:43Z (UTC) by the L02 investigator, step R-01, read-only.
Main checkout `/home/luna/projects/coq-jev-herdr-plugin` at main `5ad1996`, state root `~/.local/state/coq/coq-jev-herdr-plugin/`.
Counts below were taken live between 02:00Z and 02:43Z and move every minute.

## 1. Contents

1. Contents
2. What it is
3. Where it lives
4. What works
5. What broke and why
6. Waits, polls, sleeps and leases
7. Decisions an LLM makes that a rule could make
8. What to carry forward
9. What to kill
10. Open questions for the owner
11. Sources

## 2. What it is

The factory keeps its state in at least eleven separate stores, and for the facts that matter most (which ticket is in what state, which record has been routed, which seat is alive, who holds a slot) there are four to eight copies with no authoritative one.
The newest design (ROADMAP.md "Where runtime data lives", lines 75-103) says one state root serves every worktree and slot and no record is ever copied between them.
What is true on the machine today: the append-only record log in the state root works and is the best store the owner has built, but a legacy second state root, a git-tracked ticket status field, an untracked pile of 5,983 event files in the checkout, three unrelated queues, one built-and-unwired board, and several hand-maintained flag and lease files all disagree with it.
Every disagreement found below is a place where a seat or a script read one copy while another copy was the one that had moved.
The evidence does not show a missing store.
It shows too many stores, written by too many scripts, with the join between them done by polling scripts and, when those fail, by agents and by hand.

## 3. Where it lives

| #   | Store                                       | Path or URL                                                                                                                     | Writer                                                                                            | Readers                                                                        | Size now (2026-10-14 ~02:40Z)                                                                       |
| --- | ------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------- |
| S1  | Record log, state root                      | `~/.local/state/coq/coq-jev-herdr-plugin/records/YYYY/MM/<stamp>-<name>.json`                                                   | `events/bin/event.sh add` (every seat, monitor, runner, merge script, hook listener)              | route.sh, digest, flow-table, board loop, gate.sh, route-retry                 | 3,334 files, 14M, from 2026-10-13T00:42Z                                                            |
| S2  | Record log, repo copy                       | `events/2026/10/*.json` in the main checkout                                                                                    | old event.sh (before WO-20261012-7e13), then `line/bin/record-bus.sh` bridge until 00:35Z today   | flow-table.sh line 49, digest/aq readers until A3, humans via `git status`     | 5,983 files (171 tracked on main, 5,812 untracked)                                                  |
| S3  | Routed ledger                               | `ledger/routed/<record file name>` in the state root                                                                            | `factory/bin/route.sh`, deleted by `line/bin/route-retry.sh` and by hand                          | route.sh only                                                                  | 3,238 entries + README                                                                              |
| S4  | Run dir (belt, since, latches, locks, pids) | `run/` in the state root                                                                                                        | route.sh, flow.sh, policy.sh, merge-watch, patrol-tick, flow-tick                                 | route.sh status, board, supervisor                                             | 506 files, 2.6M, of which `run/patrol/` holds 489 latch files                                       |
| S5  | Architect queue                             | `queues/architect/{open,done}` in the state root                                                                                | `line/bin/aq.sh` fed by flow-table, patrol, record rules                                          | the architect, digest                                                          | 14 open, 830 done                                                                                   |
| S6  | Work queue                                  | `queue/items/` in the repo (gitignored, `.gitignore` line 119)                                                                  | `queue/bin/queue.sh`                                                                              | route.sh enqueue action, seats                                                 | 1 item (`p2-20261014T012050Z-WO-20261013-0b48.json`)                                                |
| S7  | Line board (K1)                             | `<state>/board/` per `line/config/board.json`                                                                                   | `line/bin/board.sh`                                                                               | nothing                                                                        | directory does not exist                                                                            |
| S8  | Ticket files                                | `work-orders/**/WO-*.md` in git, JSON front matter                                                                              | `work-order` skill scripts, `bin/wo-start.sh`, humans                                             | seat.sh, claims.sh, board loop, route.sh                                       | 263 files: 23 draft, 115 ready, 1 in-progress, 97 done, 27 cancelled (124 of them under `archive/`) |
| S9  | Seat records, legacy root                   | `~/.local/state/coq/seats/<seat>/{seat.json,settings.json}`                                                                     | `herdr/bin/seat.sh`                                                                               | seat-lib.sh, route-retry, supervisor                                           | 426 directories, 16 of them without `seat.json`, 4.9M                                               |
| S10 | Seat records, canonical root                | `~/.local/state/coq/coq-jev-herdr-plugin/seats/`                                                                                | nothing now                                                                                       | state-root.sh tree `seats`                                                     | 3 empty directories                                                                                 |
| S11 | Stranded state roots                        | `~/.local/state/coq/{start-WO-20261013-496d,start-case12-fix,verify-fba7551}/records/`                                          | seats started from a worktree with its own COQ_REPO (cause v)                                     | nothing                                                                        | 11 record files that no belt ever read                                                              |
| S12 | Treehouse pool                              | `~/.treehouse/coq-jev-herdr-plugin-f314e6/treehouse-state.json` and the nine slot checkouts                                     | treehouse CLI, `seat.sh` lease calls                                                              | seat.sh, merge.sh, the cleanup lane                                            | 9 slots, 1 lease                                                                                    |
| S13 | herdr session                               | `~/.config/herdr/sessions/stable/session.json` and the live socket                                                              | herdr                                                                                             | every script through `herdr agent list`                                        | live: 6 agents                                                                                      |
| S14 | Bearings page folder                        | `~/.bearings/coq-stable/{questions.json,answers.jsonl,messages.jsonl,delivered.json,session.json,server.json}`                  | agent writes questions and session, page writes answers and messages, `wait.mjs` writes delivered | the architect (via wait.mjs), the owner (via page)                             | 274 messages, 42 answers, 1 open card                                                               |
| S15 | Factory board output                        | `report/loop/out/{data.json,index.html}` in the repo (gitignored)                                                               | `report/loop/loop.sh watch`                                                                       | bearings `/board`, the owner                                                   | rewritten every 10 s, last 02:34Z                                                                   |
| S16 | GitHub                                      | PRs, branches, `coq/gate` commit statuses, webhooks                                                                             | GitHub, Jenkins `coqGate()`, `line/bin/hook-listener.sh`                                          | merge-watch (polls once a minute), seat.sh `gh pr list`, board loop, claims.sh | 1 open PR (#35), 80 refs local and remote                                                           |
| S17 | Knowledge graph                             | `graph/nodes/*.json`, `graph/INDEX.md` in git                                                                                   | `graph/bin/graph.sh`, seats                                                                       | lint, report blueprint                                                         | 109 nodes, 114 tracked files, INDEX header says generated 2026-10-11T19:20Z                         |
| S18 | Changelog and misc tracked step files       | `changelog/2026/10/*.md` in git                                                                                                 | `bin/changelog.sh`, `make step`                                                                   | `CHANGELOG.md` render (gitignored)                                             | 340 tracked files, 106 added since 2026-10-13T05:00Z                                                |
| S19 | Hand backups of state                       | `backup/2026/10/` in the state root                                                                                             | the orchestrator and architect, by hand                                                           | nobody                                                                         | 17 directories or patches, 25M, 5,902 files                                                         |
| S20 | Loose scripts and their state               | `~/.cache/coq-watch/` (22 files, including 7 `.bak` copies) and `~/.cache/coq-held-records/` (15 files)                         | the owner's seats, by hand                                                                        | `patrol-tick.sh` still runs from here (pid 3868571)                            | outside git                                                                                         |
| S21 | Other                                       | `~/.cache/coq/` worktrees (463M), `crash/` (837M core dump), `logs/`, `tests/`, `test-output/`, `plans/` (24 files), `archive/` | scripts, humans                                                                                   | humans                                                                         | not factory state; counted for completeness                                                         |

Branches: there is no records branch any more (AGENTS.md line 118, ROADMAP.md line 119, `git branch -a` lists none), the records pull request 32 retired it.
The scheduler (Go, `scheduler/`) will add its own state under `${state_dir}` (`shadow`, `belt`, `HALT`, `scheduler.sock`) per `scheduler/config/scheduler.json` and an `intake.poll_seconds` loop over the same records tree.

## 4. What works

1. The record log writer is correct and lock-free.
   `events/bin/event.sh` line 143 uses `ln "$tmp" "$target"` as an exclusive create, so a name clash cannot overwrite and a half-written file is never visible.
   One file per record means 20 seats can write at once with no lock and no git conflict.
   Evidence: 3,334 records written 2026-10-13T00:42Z to now by seat families including route-runner, monitor, workers, testers, reviewers and merge scripts, none lost (the ledger covers 3,238 of 3,238 records at or after `run/since`, computed by comparing file names, zero unledgered, zero ledger entries without a record).
2. The ledger design is sound and cheap.
   `ledger/routed/<record file name>` makes the router idempotent across restarts (`factory/bin/route.sh` lines 301-309, `tick()`), and `recover_interrupted` (line 295) turns a half-routed record into an `interrupted` entry plus a 500 note.
3. One resolver exists for where state lives: `bin/state-root.sh` plus `config/state.json` (trees records, logs, tests, checkpoints, plans, ledger, seats, run).
   Every script written after 2026-10-12 asks it, and `seat.sh` now refuses a seat whose own resolver disagrees (`herdr/bin/seat-lib.sh` breadcrumb for WO-20261013-69df, cause v).
4. The file-and-atomic-rename queue pattern is reused and works at its scale.
   `line/bin/aq.sh` dedupes on source plus ref (lines 49-56), bumps priority and count, and kept the architect's open list at 14 items after 844 entries passed through (830 done, 194 of them the same `flow-table bottleneck` item re-sighted).
5. The bearings page folder is a clean small protocol.
   Files are append-only JSON lines for answers and messages, one watermark file for delivery (`delivered.json`), and the README in `~/.bearings/README.md` names the writer of every file and says when a folder is safe to delete.
   `wait.mjs` marks delivery only after printing, so an owner message is not lost across a restart.
6. Hand fixes were backed up before they were made, with the reason in the folder name, so the drift history is recoverable: 17 entries under `backup/2026/10/`, for example `20261013012632-routed-ledger-cleared-by-orchestrator` and `20261013024515-stray-events-from-5b33-slot`.
7. The derived-view pattern works when the view carries its own staleness alarm.
   `report/loop/loop.sh age` (header lines 14-16) posts a 500 when `data.json` is older than a bound.
   `report/loop/out/data.json` is 13,835 bytes, `at` 2026-10-14T02:34:13Z, fresh at the time of reading.
8. The GitHub webhook bridge is the right direction: `line/bin/hook-listener.sh` (WO-20261013-ca2a) turns `coq/gate` statuses into records with the sha, so GitHub can become an input to the log without polling.
   It is not yet the source of any gate decision (see section 5, item 11).

## 5. What broke and why

The numbering is by severity to the factory, not by date.
Every item says what the evidence is.
Where the evidence disagrees with the brief's framing, section 5 item 12 says so.

1. Two state roots, and the seat store is on the wrong one.
   `herdr/config/herdr.json` line 5 sets `"state_dir": "~/.local/state/coq"`, which is not the canonical root `~/.local/state/coq/coq-jev-herdr-plugin`.
   `herdr/bin/seat-lib.sh` line 70 reads `STATE="${COQ_STATE:-<state_dir>}"`, so every seat record, `settings.json`, the supervisor's `last.log` and `reseats`, and the bringup dedupe live under the legacy root: 426 seat directories, 16 without a `seat.json`.
   The canonical root has 3 near-empty seat directories (`seats/tester-x` and two testers from 2026-10-13).
   The `state-root.sh` header says this was a known cost ("herdr.json state_dir still says ~/.local/state/coq, which is not this root until roadmap item A2 points the seats here"), and A2 (WO-20261012-0229, merged) moved the router but not the seats.
   Consequence: anything that asks the resolver for `seats` (it is in `config/state.json`) looks in the wrong place, and `queues/` is not a resolver tree at all (`line/bin/aq.sh` lines 30-31 say adding one "is a change to that resolver").
2. Stranded state roots from the same cause.
   `~/.local/state/coq/verify-fba7551/records/` holds `test.passed` records for PRs 127, 128 and 112 written 2026-10-13T20:03Z-20:08Z, `start-WO-20261013-496d/` holds the `pr.opened` for PR 108 and a `test.failed`, `start-case12-fix/` holds the `pr.opened` for PR 113.
   Root cause is stated in the breadcrumb at `herdr/bin/seat-lib.sh` (WO-20261013-69df): seat.sh exported `COQ_REPO` as the checkout it ran from, and `state-root.sh` names the root after `COQ_REPO`'s basename.
   The merger never saw those verdicts and "the orchestrator copied them by hand" (same breadcrumb).
   The fix landed (PR 143) but the stranded files are still there, and nothing reconciles or deletes them.
3. The repository still holds a second copy of the record log, and it is the one `git status` shows.
   `events/2026/10/` has 5,983 files: 171 tracked on main, 5,812 untracked (`git status --short` count).
   ROADMAP items C10 and C11 say events leave git; item A4 (WO-20261012-99d6, "events/ and factory/state leave git") is still `status: ready` on main (`work-orders/WO-20261012-cf8d/WO-20261012-99d6-...md`), so the cut-over never happened.
   The untracked 5,812 are not leftovers of the old writer.
   `line/bin/record-bus.sh` copies every state-root record into the checkout by id (`$target/$rel/$id.json`, lines 98-105) when started with `--target <checkout>/events`, because "digest, aq.sh and the architect queue read the checkout events/ until A3" (breadcrumb 13:35Z).
   File mtimes show it ran until 2026-10-14T00:35Z; 3,015 ids exist in both trees; the live instance (pid 3932071, started 00:46Z) runs with no flags, so its target is the state root and the bridge is off.
   Cost today: `git status` in the owner's checkout shows 5,812 untracked files, `flow-table.sh` line 49 still scans `$REPO/events` as well as the state root, and slots 4 and 10 each hold 1,767 event files against 171 in the other slots.
4. The router's outcome store says most records did nothing.
   Of 3,238 ledger entries: 1,433 ignored, 925 own (the runner's own notes and receipts), 394 unrouted, 373 failed, 74 done, 38 held, 1 interrupted.
   Taking only records that wanted an action (done, held, failed, unrouted, interrupted = 880), 74 completed (8%), 767 (87%) ended failed or unrouted.
   Counter-evidence for fairness: `route-retry.sh` deletes the ledger entry of a seat-refused failure so the record is routed again, which turns some failures into later successes; the ledger keeps no history of that, so the 8% is a floor, not a measurement.
   The reasons are in the 500 notes the runner itself wrote into S1 (786 route-runner 500s on 2026-10-13 and 14): 394 "no route for ..." (286 for kind `note`, 59 for `work.started`, 21 `verified`, 18 `rejected`, 10 `pr.opened`), 66 "herdr agent prompt interface failed" for `verified`, and 188 seat.sh refusals, of which most are a state-read failure: "ticket WO has no branch yet" (89) and "no ticket WO under work-orders/" (43), plus "no treehouse slot" and "slot ... " variants.
   The runner therefore writes about 28% of the whole log (925 of 3,334 records have seat `route-runner`), each of which is itself routed or ledgered as `own`.
5. The ticket is the join key for everything and its state lives in git, so it is stale by design.
   `herdr/bin/seat.sh` line 457 reads `$SL_REPO/work-orders` (the main checkout's working tree), line 459 refuses "no ticket ... (archived or never cut)", and line 490 refuses "ticket ... has no branch yet (frontmatter branch is null)".
   A ticket cut by a tickets-only PR has no file in the main checkout until that PR merges, and a ticket on a feature branch has `branch: null` on main.
   The breadcrumb at line 466-480 (WO-20261013-a0e2, cause f) records that the orchestrator "seated the gates by hand with --worktree, with the build line starving behind it".
   Status never converges on its own: main today has 16 tickets named in the last 80 commit subjects that still read `status: ready` (some are cut-only commits, so this is an upper bound), 1 `in-progress`, and the record `20261014T002901Z-100-p6cx0` says "WO-20261013-b6f3 (PR 157 merged) still shows in-progress on main ... Needs a close PR for b6f3".
   `wo-start.sh` rewrites front matter in the main checkout and leaves it dirty; the hand backups `20261013184900-checkout-start-residue-c17f-f1ff.patch`, `20261013191600-checkout-start-residue-fe37-44b3.patch`, `20261014003100-start-residue-0b48-a18c.diff`, `20261014005500-residue.diff` and `20261013152845-checkout-untracked-ticket-copies` are five instances of an operator cleaning that by hand in a 24-hour window.
   Today's `git status` still shows one such residue (`work-orders/WO-20261013-16f1/WO-20261014-539a-...md` modified, plus two uncommitted bearings asset files).
6. Seat records say seats are alive that are not.
   12 seat records have `ended_at: null`; `herdr agent list` (read-only) shows only 6 live agents (`architect`, `monitor`, two unnamed, `sched-worker-1`, `sched-worker-2`).
   Eleven of the twelve have no agent: `worker-wo-20261012-5d09` (started 2026-10-12T20:36Z), `worker-wo-20261013-89c7` (2026-10-13T15:03Z), `reviewer-wo-20261012-fd87` (2026-10-12T20:36Z) and eight more.
   `route-retry.sh` and `seat.sh` count live seats from "open seat records whose agent is live" (route-retry breadcrumb 23:50Z, `sl_live_seats`), so each stale record is a place the cap arithmetic must route around.
7. A lease that outlives its TTL by a day.
   `herdr/config/leases.json` gives the slot lease `ttl_seconds: 14400` (4 h) and says "The monitor releases an expired one".
   `treehouse-state.json` for the pool shows slot 2 `leased: true`, holder `WO-20261012-fd87`, `leased_at 2026-10-12T20:36:16Z`, about 30 hours old at read time, held by the ticket whose PR 35 is the only open PR on GitHub.
   `treehouse.toml` says `max_trees = 8`; the pool has 9 slots (names 1, 2, 4-10) and there is a second empty pool `coq-jev-herdr-plugin-81af2c`.
   Nothing in treehouse state carries an expiry, so the TTL in `leases.json` is a number only the monitor could enforce and no script in `herdr/bin` or `line/bin` does (grep for `ttl_seconds` outside config finds queue.sh and board.sh, not the slot lease).
8. Four different halt flags.
   `herdr/config/herdr.json` line 50 and `scheduler/config/scheduler.json` line 14: `${state_dir}/HALT`; `line/config/board.json` line 8: `${state_root}/run/halt`; `line/bin/merge-watch.sh` line 39: `$RUN/line.halted`; ROADMAP.md says `run/line.halted`.
   `${state_dir}/HALT` is the legacy root for herdr (finding 1) and an unknown root for the scheduler.
   A halt written to one name is invisible to the scripts that read another.
9. A built queue nothing uses, and a second and third queue that overlap it.
   `line/bin/board.sh` (roadmap K1, WO-20261013-f268, commit `e5cef84`) is "the single intake of the line" with ten lanes and leases, but no script, route row, Makefile, unit or role file calls it, and `<state>/board/` does not exist.
   The live intake is S1 + route.sh, the live human queue is `aq.sh` (S5), and the work queue is `queue/bin/queue.sh` with its items in the repo working tree (S6).
   Three queue implementations share the same pattern (directory, atomic rename, lease field), differ in claim semantics (board.sh claims by renaming to `.claim.<epoch>.<pid>`; queue.sh rewrites in place, per board.sh breadcrumb choice 1), and none feeds another.
10. State that is fed by scripts that are no longer running, and nothing says so.
    `run/digest.last` is 00:34Z, `run/flow-table.txt` and `run/flow-tick.marker` are 00:35Z (about 2 hours stale at read time); `ps` shows no digest, flow-tick or architect-rounds process; the open architect queue item `p2 patrol proc.digest_sh_` (count 5) says "PROCESS 'digest.sh' has 0 top-level instances, expected exactly 1".
    The p1 item `bottleneck:working` still names `WO-20261013-e2c3(59m)`, a 2-hour-old reading.
    `patrol-tick.sh` (pid 3868571, running since 00:45Z) is still launched from `~/.cache/coq-watch/` and has no copy in `line/bin/`, against the owner order of 2026-10-12T22:49Z that no script lives outside the repo (the AGENTS.md and the `line/bin/aq.sh` breadcrumb both cite it).
    `~/.cache/coq-watch/` still holds 22 files including 7 hand `.bak` copies; `record-bus.sh`, `aq.sh`, `digest.sh`, `flow-table.sh`, `merge-watch.sh`, `route-retry.sh` were moved into `line/bin/` but the cache copies remain.
11. GitHub carries no verdict.
    `gh pr list --state merged --limit 5` shows `statusCheckRollup` of length 0 for PRs 177 to 181, merged 2026-10-14T01:07Z to 01:59Z; `gh api .../commits/<sha>/status` for `5ad1996`, `c9b6f9f`, `17df7c9`, `2247679` returns state `pending` with zero statuses and `check-runs` total 0; `gh api .../branches/main/protection` returned no `required_status_checks`.
    So the gate verdict (test.passed, review.passed with a sha) exists only as records in S1, and the merge decision reads S1 plus the ticket plus the PR.
    `ci/README.md` documents `coq/gate` as the status the merger will act on, but as of this reading it has been posted on none of the last five merges (PR 179, which introduced `coqGate()`, merged at 01:18Z).
    The webhook bridge and the status are built; the loop that makes GitHub the verdict store is not closed.
12. Where the brief's diagnosis is partly contradicted.
    The brief frames the problem as "we're using herdr wrong".
    For the state stores the evidence points elsewhere: herdr (S13) is read through a stable CLI and is the only store with no drift found, because it is queried live (`herdr agent list`) and never copied.
    The drift is entirely in the stores the owner's own scripts copy: record log to checkout (S2), ledger to retry (S3), seat record to live agent (S9 vs S13), ticket file to merged PR (S8 vs S16), slot lease to ticket (S12).
    A second correction: ROADMAP.md says "the repository was used as the message bus" is fixed (C10-C13).
    Records were moved out of git, but the work-order status field, the changelog files (106 added since 2026-10-13T05:00Z against C13 "no changelog files in the repository"; AGENTS.md line 62 still says `make step` writes one and line 117 says the changelog is rendered from PR titles), the `graph/` nodes and `INDEX.md` (header 2026-10-11T19:20Z, nodes edited as late as 2026-10-13T15:21Z) are still git-resident state that every PR touches.
13. Retention does not exist.
    `factory/bin/route.sh` line 317 says "the retention job removes whole records/YYYY/MM folders"; `line/config/board.json` has `retention_days: 30` for the unused board; `grep -rI retention` over `bin line factory herdr Makefile` finds only those mentions.
    The state root is already 14M of records, 3.4M of queues, 2.6M of run files, 25M of hand backups, 837M of crash dump, and the cache 463M, with no job that bounds any of it.
14. The owner page is a derived view that failed silently once.
    The bearings message `m-c20261013224555780` records the board froze at 16:24Z and stayed frozen "six hours ago ... every pass failed quietly".
    A second message `m-c20261013224955609` records it counted "every ticket marked in progress, including ones that stalled or already merged", which the owner's question "no way we have 17 lines running" (`m-20261013224920550-jsnf3`) exposed.
    Both are the same shape as items 5 and 6: a view computed from stale copies, answered to the owner by an agent in prose.
    `loop.sh age` and `WO-20261013-d182` (board counts only a ticket with a live seat or open PR, commit `0435ea5`) are the fixes; ticket `d182` still reads `status: ready` on main.

## 6. Waits, polls, sleeps and leases

Only those that read or write one of the stores above.
"Bound" means a maximum wait or attempt count; "none" means the loop runs until killed.

| Where                                                   | What it waits on                                                                                                 | Interval or bound                                                                                                                                    |
| ------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| `factory/bin/route.sh` `run` (config `poll_seconds` 10) | new files in S1                                                                                                  | 10 s poll over a full `find` of the records tree (`tick()` line 308), O(files) per tick, 3,334 files; no bound; belt stale at 60 s (`stale_seconds`) |
| `factory/bin/route.sh` `recover_interrupted` line 295   | a `claimed` ledger entry left by a crash                                                                         | once at start; turns it into `interrupted` and posts a 500                                                                                           |
| `line/bin/route-retry.sh`                               | a free seat slot, then deletes the ledger entry                                                                  | every 30 s (`ROUTE_RETRY_SECONDS`), no bound; retries only max_seats and max_agents refusals                                                         |
| `line/bin/record-bus.sh`                                | slot `events/` trees and the state records tree                                                                  | every 5 s (`interval=5`), copy window 60 minutes fixed at start; no bound                                                                            |
| `line/bin/merge-watch.sh`                               | GitHub merged PR list                                                                                            | every 60 s (`MERGE_WATCH_SECONDS`); self-exits after 7 days, on `line.halted`, or when WO-20261012-6f13 merges; one instance by `flock -n`           |
| `line/bin/digest.sh`                                    | architect queue and records                                                                                      | every 1800 s (`DIGEST_SECONDS`); not running at read time                                                                                            |
| `line/bin/flow-table.sh` / flow tick                    | records of the last HOURS                                                                                        | marker and table stale since 00:35Z                                                                                                                  |
| `herdr/bin/turnwatch.sh`                                | architect turn state                                                                                             | `turn_poll_seconds` 15 s                                                                                                                             |
| `herdr/bin/recwatch.sh`                                 | records of listed kinds                                                                                          | `record_poll_seconds` 10 s                                                                                                                           |
| `herdr/bin/patrolwatch.sh`, `patrol-tick.sh`            | seat probes and screens                                                                                          | `patrol_seconds` 60 s; writes 489 latch files to `run/patrol/`                                                                                       |
| `herdr/bin/unfreeze.sh --watch 30`                      | frozen seats                                                                                                     | 30 s                                                                                                                                                 |
| `herdr/bin/guardwatch.sh`                               | compaction guard per live seat                                                                                   | `guard_watch_interval_seconds` 15 s                                                                                                                  |
| `report/loop/loop.sh watch`                             | records, tickets, panes, gh                                                                                      | `watch_seconds` 10 s; 3 failed passes post one 500 and end; `age` bound default 120 s                                                                |
| `line/bin/seat-queue.sh` lines 28-29                    | the ticket's branch on origin, then a worker slot                                                                | 15 s and 60 s (`SEAT_QUEUE_BRANCH_WAIT`, `SEAT_QUEUE_SLOT_WAIT`), `until` loops with no attempt bound                                                |
| `line/bin/merge.sh`, `verify-main.sh`                   | git and the suites                                                                                               | 3 retries, `BACKOFF * n` seconds (2, 4, 6); suite timeout 1800 s                                                                                     |
| `line/bin/hook-listener.sh`                             | handler hooks per delivery                                                                                       | `retry_seconds` and `retries` from `hook.json`; handler inside the request                                                                           |
| `tools/bearings/scripts/wait.mjs`                       | `messages.jsonl` and `answers.jsonl` growth                                                                      | blocks until news, `settle_ms` 3000; `idle_minutes` 240 on the server                                                                                |
| `queue/bin/queue.sh`                                    | none; lease field                                                                                                | `lease_ttl_seconds` 7200, `renew_grace_seconds` 300; enforced only when `sweep` runs                                                                 |
| `line/bin/board.sh`                                     | none; lease field                                                                                                | `lease_seconds` 1800, `nudge_seconds` 60, `retention_days` 30; unused                                                                                |
| `herdr/config/leases.json`                              | slot 14400 s, tier 86400 s, ticket 7200 s, seat 900 s                                                            | declared, not enforced for the slot (finding 7)                                                                                                      |
| `scheduler/config/scheduler.json`                       | `intake.poll_seconds`, `housekeeping.queue_sweep_seconds`, `jobs.keep_days` 7, `housekeeping.prune_seconds` 3600 | the Go scheduler will poll the same records tree on a timer                                                                                          |
| Jenkins `coqGate()` (ci/README.md)                      | GitHub webhook                                                                                                   | event driven, "nothing polls or waits"; the only store write path with no timer                                                                      |

The pattern: every cross-store join is a timer, and the interval is a number somebody picked (5, 10, 15, 30, 60, 1800).
The two joins with no timer are the webhook bridge and the bearings page; both are the ones with no reported lost message.

## 7. Decisions an LLM makes that a rule could make

Only those that are decisions about state, not about code.

| #   | Decision                                                                          | Where                                                                                                            | Rule that replaces it                                                                                                                                             |
| --- | --------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Clear a routed-ledger entry so a record routes again                              | `backup/2026/10/20261013012632-routed-ledger-cleared-by-orchestrator`; `route-retry.sh` automates one class only | Ledger entry carries `attempt` and `next_at`; the router re-attempts on its own up to 3 times and then records `failed` with a reason code. No deletion by anyone |
| 2   | Decide which records are held out of a commit or the log                          | `~/.cache/coq-held-records` (15 files), read by `record-bus.sh` line 97                                          | Records are never in a commit, so the list is not needed. Delete on the A4 cut-over                                                                               |
| 3   | Copy a record or verdict from a stray root to the canonical root                  | WO-20261013-69df breadcrumb: "the orchestrator copied them by hand"                                              | The writer resolves the root from the git common dir only (landed), plus a startup reconcile that moves any `*/records` outside the canonical root                |
| 4   | Seat a tester or reviewer by hand with `--worktree` when the ticket has no branch | `herdr/bin/seat.sh` breadcrumb a0e2                                                                              | Derive the branch from the PR (landed for the title case); for the rest the gate record carries `branch` and `sha`, and the router passes them                    |
| 5   | Clean `start` residue from the main checkout                                      | five hand backups, 2026-10-13T15:28Z to 2026-10-14T00:55Z                                                        | Ticket start writes to its own worktree and branch, never the main checkout; or ticket status leaves git (see section 8)                                          |
| 6   | Decide that a ticket is done after its PR merged                                  | record `20261014T002901Z-100-p6cx0`: "Needs a close PR for b6f3"                                                 | The merge event sets the ticket terminal state in the same transaction; a ticket is never a hand-edited file                                                      |
| 7   | Decide a seat record is dead and close it                                         | 11 of 12 open seat records are dead                                                                              | A reconcile loop: seat record `ended_at` set when `herdr agent get` fails twice 15 s apart                                                                        |
| 8   | Answer the owner how many lines are running                                       | `m-c20261013224955609`                                                                                           | The board's own count, with its derivation shown, never an agent paraphrase                                                                                       |
| 9   | Decide which of three queues gets an item                                         | S5, S6, S7                                                                                                       | One queue with lanes; kind, code and lane come from the routes table                                                                                              |
| 10  | Release an expired slot lease                                                     | `leases.json` text "The monitor releases an expired one"; slot 2 held 30 h                                       | A timer-driven sweep that releases a lease older than its TTL and posts one record; treehouse has no expiry field, so the sweep owns it                           |

## 8. What to carry forward

1. The one-file-per-record log with exclusive-create writes (`events/bin/event.sh` line 143) and the name rule `YYYYMMDDHHMMSS-<descriptive name>.json`.
   It is the only store with no drift of its own.
   The record schema (`events/schema/event.schema.json`) with the enumerated status code map is worth keeping whatever carries it.
2. The ledger keyed on the record file name, claimed before performed, with recovery of a `claimed` leftover.
   It is exactly an idempotency key plus an in-flight marker, the same shape as Argo and Temporal use.
3. `bin/state-root.sh` plus `config/state.json` as the one resolver, and the rule of deriving the repository identity from the git common directory (`seat-lib.sh` breadcrumb, WO-20261013-69df).
4. The directory-queue-with-atomic-rename pattern (queue.sh, aq.sh, board.sh) and especially board.sh's claim-by-rename, which is the only variant safe for two concurrent pullers.
5. The bearings page folder protocol (append-only JSON lines, a delivery watermark, README naming each writer).
6. Derived views that carry a freshness bound (`loop.sh age`) and the principle "GitHub is the one place every merge shows up, whoever made it" from the merge-watch header, which is the right reason to make GitHub the verdict store.
7. The named, dated, reasoned backups of hand fixes.
   They are the real incident log of state drift and should become an automated `incident` record kind rather than a folder of diffs.

## 9. What to kill

1. The repository copy of the record log: delete `events/2026/10/` (171 tracked, 5,812 untracked) after the A4 cut-over, and stop the bridge in `record-bus.sh`.
   Two places records live is the stated reason A2 refused to read both trees.
2. The legacy state root `~/.local/state/coq/` as a place for seats (426 directories), bringup, supervisor and the three stranded roots; point `herdr.json` `state_dir` at the canonical root, or better remove the key.
3. `line/bin/board.sh` or the other two queues.
   Keep one implementation of the queue pattern; today three exist, one is unused and one is in the repo working tree.
4. Ticket status as a git-resident field changed by hand or by `wo-start.sh`.
   All 263 tickets and every status transition ride PRs and cause the file-overlap claims, the "close PR" tickets, the start residue, and the "has no branch yet" refusals.
   Status needs a store that the merge event can write; the ticket text can stay in git.
5. The four spellings of the halt flag; keep one path.
6. The `changelog/` tracked step files and the `graph/INDEX.md` generated file, per owner decision C13 and the `.gitignore` reasoning at the aggregates block.
7. Scripts launched from `~/.cache/coq-watch/` and its `.bak` copies once their `line/bin/` versions are the running ones (`patrol-tick.sh` first).
8. Polling joins (record-bus 5 s, route-retry 30 s, merge-watch 60 s) wherever an event source exists: the webhook listener already covers GitHub, and the router can enqueue its own retry.

## 10. Open questions for the owner

1. Is ticket status allowed to leave git (a store the merge event writes), with the ticket body staying in the repository?
   Everything in finding 5 is a symptom of status being a file in a branch; the alternatives are an issue tracker, a record-derived state, or a small database the control plane owns.
2. Is GitHub (commit status and PR state) meant to be the authority for gate verdicts, with records as the notification, or the other way round?
   Today it is the second, and the CI gate was built for the first.
3. Is the owner willing to drop the git-tracked `graph/` and `changelog/` as state and rebuild them as renders, given that both are touched by routine PRs?

## 11. Sources

All local paths were read on 2026-10-14 between 02:00Z and 02:43Z.

Repo files (main checkout, main at `5ad1996`):
`events/bin/event.sh` (lines 41, 143), `bin/state-root.sh`, `config/state.json`, `factory/bin/route.sh` (lines 15-40, 295-309, 317), `factory/config/runner.json`, `line/bin/record-bus.sh`, `line/bin/route-retry.sh`, `line/bin/aq.sh`, `line/bin/board.sh`, `line/config/board.json`, `line/bin/merge-watch.sh`, `line/bin/digest.sh`, `line/bin/flow-table.sh`, `line/bin/hook-listener.sh`, `line/bin/seat-queue.sh`, `herdr/bin/seat.sh` (lines 457-490), `herdr/bin/seat-lib.sh` (line 70 and cause v breadcrumb), `herdr/config/herdr.json`, `herdr/config/leases.json`, `queue/bin/queue.sh`, `queue/config/queue.json`, `report/loop/loop.sh`, `report/loop/out/data.json`, `scheduler/config/scheduler.json`, `ci/README.md`, `treehouse.toml`, `ROADMAP.md` (lines 43-44, 56-71, 75-103, 119), `AGENTS.md` (lines 62, 108, 117, 118), `.gitignore` (queue/items, aggregates block), `factory/bin/claims.sh`, `work-orders/WO-20261012-cf8d/WO-20261012-99d6-roadmap-a4-events-and-factory-state-leave-git-cu.md`, `work-orders/WO-20261013-16f1/WO-20261013-0ad7-before-seating-a-gate-seat-route-sh-and-seat-sh-.md`.

State and cache (counts by `ls`, `find`, `jq`, `comm`):
`~/.local/state/coq/coq-jev-herdr-plugin/{records,ledger/routed,run,queues/architect,backup/2026/10,seats,crash}`, `~/.local/state/coq/{seats,bringup,supervisor,start-WO-20261013-496d,start-case12-fix,verify-fba7551}`, `~/.cache/coq-watch/`, `~/.cache/coq-held-records/`, `~/.treehouse/coq-jev-herdr-plugin-f314e6/treehouse-state.json`, `~/.bearings/coq-stable/` and `~/.bearings/README.md` (the page access key in `server.json` was deliberately not copied here).

Record ids cited: `20261014T002901Z-100-p6cx0`, `20261013T011901Z-201-z864c` (a ledger-clear backup file), `20261012T171716Z-500-udz1g` (an untracked repo event).
Bearings messages cited: `m-c20261013224555780`, `m-20261013224920550-jsnf3`, `m-c20261013224955609`.
Commits cited: `e5cef84` (K1 board), `0435ea5` (board counts live work), `5ad1996`, `c9b6f9f`, `17df7c9`, `2247679` (main), `7e114c9` (K5 writer).

Read-only live queries: `ps -eo pid,etimes,args` (route.sh, record-bus, merge-watch, patrol-tick present; digest, flow-tick, architect-rounds absent), `herdr --session stable agent list` (6 agents), `gh pr list`, `gh api repos/jkkelley/coq-jev-herdr-plugin/commits/<sha>/status` and `/check-runs` and `/branches/main/protection` on 2026-10-14.
