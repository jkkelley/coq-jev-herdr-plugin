# L01 - Line scripts

Investigator: area L01, step R-01 of the Factory Rebuild investigation.
First written 2026-10-14T02:40Z (UTC), attempt 1.
Revised 2026-10-14T02:50Z (UTC), attempt 2, to close the critic's gaps (see the table in section 3a).
Snapshot of the live machine: 2026-10-14T02:45Z (processes, ledger, records) and main at 5ad1996.
Read-only throughout: no line script, herdr mutation, bearings script, event script or scheduler was run.

## 1. Contents

1. Contents
2. What it is
3. Where it lives (3a: what attempt 2 changed)
4. What works
5. What broke and why (F1 to F14)
6. Waits, polls, sleeps and leases
7. Decisions an LLM makes that a rule could make
8. What to carry forward
9. What to kill
10. Open questions for the owner
11. Sources

## 2. What it is

The line is about 5,900 lines of bash (herdr/bin, factory/bin, line/bin, queue/bin, events/bin, plus 822 lines in bin/) and a Go scheduler scaffold whose only runnable subcommand is `version`.
Together they implement a record-driven factory: a seat posts a JSON record, a poll loop (route.sh) matches it against a table (routes.json), and the action is almost always "type a line into another LLM seat's herdr pane".
Every process that matters is a bash loop typed into a herdr pane; herdr is the supervisor, the message bus, the process table and the UI at the same time.
Only the pieces written in the last 36 hours as "X is code" (merge.sh, verify-main.sh, gate.sh, claims.sh) are deterministic functions of records and git, and none of them is wired to run on its own yet.
The first half of the seat lifecycle (ticket cut, ticket start, branch cut, worker seated) has no automatic driver at all: nothing posts `ticket.cut`, and starting a ticket is a bash script an LLM types (section 5, F12).
The evidence disagrees with one framing in the brief: the dominant route failure is not capacity or timing, it is a wake aimed at a seat that does not exist (section 5, F1).
The mechanism behind most of the stalls is that delivery is one-shot and fire-and-forget into a pane, with no durable pending state and no retry owned by the system.

## 3. Where it lives

- Main checkout, read only: `/home/luna/projects/coq-jev-herdr-plugin`, branch main, HEAD 5ad1996 (2026-10-13T20:44-05:00, which is 2026-10-14T01:44Z).
- Route runner: `factory/bin/route.sh` (342 lines), table `factory/config/routes.json`, config `factory/config/runner.json`.
- Gate rules: `factory/bin/gate.sh`, `factory/bin/flow.sh`, `factory/bin/policy.sh`, `factory/bin/claims.sh`, `factory/bin/suites.sh`.
- Seat lifecycle: `herdr/bin/seat.sh` (848 lines), `herdr/bin/seat-lib.sh` (317), `herdr/bin/retire.sh`, `herdr/config/herdr.json`, role files `roles/*.json`.
- Ticket start, the first half of the seat lifecycle: `bin/wo-start.sh` (23 lines), which calls `factory/bin/claims.sh start` and then `exec`s `.claude/skills/work-order/scripts/work-order.sh start` (a gitignored managed skill copy, `.gitignore:91`); the driver `line/bin/start-tickets.sh` (51 lines) and `line/bin/seat-queue.sh`.
- Shared helpers in `bin/`: `state-root.sh` (79 lines, the one state and cache resolver), `step.sh` (56, `make step`), `mint-id.sh` (43, SOP and ADR numbers), plus `backlog.sh`, `changelog.sh`, `aggregates.sh`, `test-cases.sh`, `new-sop.sh`, `md-contents.sh`.
- Supervision: `herdr/bin/supervisor.sh`, `bringup.sh`, `belt.sh`, `recover.sh`, `monitors.sh`, `herdr/config/monitors.json`, templates `herdr/systemd/*.in`.
- Watchers in herdr panes: `herdr/bin/turnwatch.sh`, `recwatch.sh`, `patrolwatch.sh`, `guardwatch.sh`, `unfreeze.sh`.
- Line scripts (Roadmap I moved here): `line/bin/{merge,verify-main,route-retry,merge-watch,seat-queue,start-tickets,aq,digest,record-bus,flow-table,board,hook-listener}.sh`, units `line/units/*.service`, config `line/config/{board,hook}.json`.
- Queue: `queue/bin/queue.sh`, `queue/config/queue.json`, items (gitignored, `.gitignore:119`) `queue/items/`.
- Go scheduler: `scheduler/` (module, protobuf, `config/scheduler.json` 75 lines, `config/executor.json` 181 lines, `host/bin/{run,run-exec,inbox}.sh`, `host/lib/config.sh`, `internal/cli`, `internal/core`, `internal/testkit`, RUNBOOK), specs `specs/scheduler/`.
- Make: root `Makefile` (51 lines), `line/Makefile` (18 lines), `herdr/Makefile`, `factory/Makefile`, `scheduler/Makefile` (targets `run`, `run-exec`, `status` at `:99-107`).
- Still outside the repo and still running: `/home/luna/.cache/coq-watch/patrol-tick.sh` and `watchdog.sh`, plus systemd units `~/.config/systemd/user/watchdog.{service,timer}`.
- State read at snapshot: `/home/luna/.local/state/coq/coq-jev-herdr-plugin/{run,ledger/routed,records}`.
- A second, older state root that one `bin/` script still writes: `/home/luna/.local/state/coq-jev-herdr-plugin/ids/SOP.counter` (contents `0006`).
- Open GitHub issues traced: 76, 77, 78 (the brief's three) and 67, 73 (belt freeze, missing queue) on jkkelley/coq-jev-herdr-plugin; all five are OPEN at 2026-10-14T02:45Z and none has a comment (`gh issue view`, state OPEN, comments 0, all created 2026-10-12T22:40:01Z to 22:40:15Z).

### 3a. What attempt 2 changed (the critic's gaps and where each is closed)

| Gap | Closed in |
| --- | --- |
| `bin/wo-start.sh`, `bin/state-root.sh`, `bin/step.sh` never read | Section 5 F12 and the new rows in section 6 (`bin/` rows); sources list the files with lines |
| Citation: notify_owner rows | Section 5 F1 table and section 7 now cite `routes.json:17`, `:21`, `:28` and the seat `interface-agent` (role label `interface`) |
| Citation: "An LLM opinion is not a probe" | Section 4 item 5 now cites `patrol-tick.sh:8` (verified by `sed -n 6,8p`) |
| Count drift 86 versus 88 | Section 5 F1: both numbers are right and measure different things; the grep and the explanation are there |
| Issues 67 and 73 status | Section 5 F6 (67) and F13 (73): both remain OPEN, with the lines that keep them open |
| `scheduler/` cited only by names | Section 5 F14, section 6 scheduler rows, section 11 |
| `max_attempts` declared in the Go config | Section 5 F2 (three competing declarations) and section 6 |

## 4. What works

1. Table-driven routing with a claim ledger.
   `route.sh` matches the first row of `routes.json` with jq (`route.sh:151-158`), claims the record in the ledger before acting (`route.sh:266`), and a runner that dies mid-action leaves "claimed" so the next start writes one 500 and never repeats a wake (`route.sh:291-297`).
   Evidence of at-most-once behaviour: at 2026-10-14T02:45Z `ledger/routed` holds 3,242 entries by first word: `ignored 1437, own 925, unrouted 394, failed 373, done 74, held 38, interrupted 1, claimed 0` (a `README.md` accounts for the 3,243rd file).
2. The "X is code" scripts are well shaped and tested.
   `line/bin/merge.sh` decides on records and head (`merge.sh:2-6`), uses `--match-head-commit` so a moved head is refused by GitHub (`merge.sh:359-360`), retries each gh call 3 times with backoff (`merge.sh:106-132`), posts at most one `merged 200`, and does the post-merge cleanup itself.
   `line/bin/verify-main.sh` runs the suites in a clean detached worktree, posts `verified` or `rejected`, writes a hold file `merge.sh` reads, and times a suite out at 1800 s (`verify-main.sh:2-24`, `:39`).
   `factory/bin/gate.sh` turns three architect rules (same head ignoring events/, supersede, heads_match) into exit codes (`gate.sh:2-17`).
3. Single writer, validated at write time.
   `events/bin/event.sh add` refuses a code outside the schema enum and a gate kind with no `--sha` (`event.sh:95-97`), writes with an exclusive hard link and no lock (`event.sh:137-146`).
4. Atomic file queues with leases are simple and correct: `queue/bin/queue.sh` enqueue is a write, dequeue is a rename plus lease field (`queue.sh:2-14`, `:35-45`).
5. Liveness decided by probes, not by an LLM.
   `patrol-tick.sh` header records the lesson verbatim: "An LLM opinion is not a probe" (`~/.cache/coq-watch/patrol-tick.sh:8`; lines 6-8 tell the story: v1 asked the Haiku monitor to judge every screen and it answered OK on every tick).
   `route.sh status` and `belt.sh` give the belt a freshness verdict by file age (`route.sh:335-336`, `belt.sh:2-7`).
6. Bounded retries exist where a script talks to GitHub: `MERGE_RETRIES` and `VERIFY_RETRIES` default 3 (`merge.sh:30`, `verify-main.sh:23`), and the hook listener retries a handler 3 times (`hook.json`).
   The retry the owner rule asks for is also declared as data in two more places, and read by no running code: `factory/config/routes.json:4` (`max_attempts: 3`) and `scheduler/config/scheduler.json:29` (`retry.max_attempts: 5`, with base 5 s, factor 2, cap 300 s, jitter 0.2 at `:30-33`) and `:47` (`wake.max_attempts: 3`); see F2 for why that is a defect and not a strength.
7. Every script carries a breadcrumb with what broke, why and cost.
   107 breadcrumb blocks across the line scripts; they are the most reliable record of failure history available (see section 11).
8. Timer-driven recovery by systemd exists in exactly one place that is installed: `watchdog.timer` every 2 min restarts patrol-tick and posts a dead man's card (`~/.config/systemd/user/watchdog.timer`, `watchdog.sh:1-24`).
9. The small `bin/` helpers are deterministic, wait on nothing the network owns beyond one `gh` call, and refuse rather than guess.
   `bin/state-root.sh` is the one resolver of the state and cache roots, reads its defaults from `config/state.json`, refuses a relative `COQ_STATE` and an unusable repo name (`state-root.sh:2-12`, `:46`, `:38`), and has real callers: `factory/bin/paths.sh:20`, `line/bin/start-tickets.sh:32`, `report/loop/loop.sh:168`, `factory/tests/lib/world.sh:49`.
   `bin/wo-start.sh` puts the claims check in front of every ticket start (`wo-start.sh:21-22`), and `claims.sh` treats an unreachable GitHub as "not granted" (exit 4) and not "free" (`claims.sh:32`, `:97`).
   `bin/mint-id.sh` takes the highest of four views plus a shared counter under a `mkdir` lock with a 10 s bound (`mint-id.sh:28`, `:35-42`).

## 5. What broke and why

F1. The runner's dominant failure is a wake to a seat that does not exist, or a seat started before its input exists.
Of 391 "route failed" notes in the state-root records (first 2026-10-13T15:29:18Z, last 2026-10-14T02:22:25Z, read 2026-10-14T02:45Z), classified by the ordered rules below:

| Count | Cause | Where the line causes it |
| ----: | ----- | ------------------------ |
| 89 | `seat.sh` refuses: ticket has no branch yet | `route.sh:220-221` calls `seat.sh` once, no wait for the branch; `seat-queue.sh:28` has the wait, `route.sh` does not |
| 88 | `merged 200` wake to `architect-wo-<ticket>` (86) or to `architect--` when the record carries no ticket (2), a seat nobody ever starts | `routes.json:15` `"do":"wake","to":"architect"`, name built by `seat_of` from `roles/architect.json` label `architect-${ticket}` (`route.sh:165-168`), prompt at `route.sh:223` |
| 75 | `notify_owner` to the `interface-agent` role, whose seat label is `interface`, a seat that is not running (66 from `verified 201`, 9 from `blocked 423`) | `routes.json:17` (verified 201) and `:21` (blocked, second escalation); `:28` (break.glass 300) is the third notify_owner row and has produced no failure; `herdr_prompt` at `route.sh:205`; role file `roles/interface-agent.json:30,38`; the owner surface is the bearings page, not an agent |
| 43 | `seat.sh`: no ticket under work-orders/ (archived or never cut) | `seat.sh` looks the ticket up by file; a ticket archived before its gate record routes breaks it |
| 42 | `herdr agent prompt` to another seat failed (worker 27 via `review.changes`, `test.failed`, `merge.conflict`; reviewer 10; tester 5; merger 2) | `route.sh:223`; the wake rows `routes.json:10`, `:13`, `:16` address a worker or reviewer seat that has already gone |
| 19 | treehouse slot problem (no slot, slot not on the branch, or a `--down` that fails on the slot) | `seat.sh` slot lease |
| 18 | capacity refusal (`max_seats`, `max_agents`) | `seat.sh:530-537`; the only class `route-retry.sh` retries |
| 11 | other `seat.sh` exit 3 or 4: `--down` of a tester that no longer exists (9), `herdr agent start` failed (2) | `route.sh` `down` step on a gone seat |
| 6 | record has no ticket, so `seat` and `down` have nothing to name | `route.sh:265` `ticket_of_pr` fallback, WO-20261013-9b21 |
| 391 | total | the nine rows add to 391 |

The classifier, so the count can be reproduced: take the 391 record files that contain the text `route failed`, extract `.note` with jq, and assign each note to the first rule that matches, in this order: `herdr agent prompt architect-`, `herdr agent prompt interface failed`, `has no branch yet`, `under work-orders`, `max_seats|max_agents`, `treehouse|slot`, `needs a ticket`, `herdr agent prompt`, anything else.
The rules give 88, 75, 89, 43, 18, 19, 6, 42, 11 (sum 391).
Attempt 1 printed 44, 17 and 6 for three of these rows and its rows summed to 380, not 391; that table is replaced by the one above.

On 86 versus 88 (the critic's recount): both numbers are correct and they count different things.
`grep -l 'route failed' * | xargs grep -l 'architect-wo-' | wc -l` gives 86, the wake to a ticket-named architect seat.
`grep -c 'prompt architect'` over the extracted notes gives 88, because two more `merged 200` records (`20261013T170632Z-200-n3pse` and `20261013T230647Z-200-negur`) failed with `herdr agent prompt architect-- failed; down needs a ticket`: the seat name was built from an empty ticket.
All 88 come from the single row `routes.json:15`.
Attempt 1 wrote "architect-wo-<ticket>" next to 88, which was loose; the table now says 86 plus 2.

The 89 no-branch count matches the critic's grep (`grep -c 'has no branch yet'` gives 89) and none of those 89 overlaps the 43 "no ticket under work-orders" class.
Capacity, the cause GitHub issue 76 names, is 18 of 391 (4.6 percent).
The other 95 percent is naming and addressing, or ordering: the table names a role, `seat_of` derives a pane name, and nothing checks the name resolves, or that the branch exists, before the prompt is typed.
Every one of these is a permanent `failed` ledger entry: 373 `failed` entries exist right now (391 notes against 373 entries is explained by `route-retry.sh` deleting entries so the belt routes them again and writes a fresh note).

F2. Issue 76, "route.sh never retries a failed route", traced to lines; the retry limit is declared three times and enforced nowhere.
`route.sh:288` writes `failed` to the ledger and moves on; the header and breadcrumb state it is a design choice (`route.sh:104-105`: "a failed action is never retried (a 500 names it)").
Declaration 1: `factory/config/routes.json:4` declares `"max_attempts": 3`, and the schema requires it with `const: 3` (`factory/config/routes.schema.json:5-7`; the unread duplicate `factory/schema/routes.schema.json:5-7` says the same).
Declaration 2: `scheduler/config/scheduler.json:29` declares `retry.max_attempts: 5` with exponential backoff (`:30-33`), allowed range 1 to 20 (`scheduler/config/scheduler.schema.json:167`).
Declaration 3: `scheduler/config/scheduler.json:47` declares `wake.max_attempts: 3`, allowed range 1 to 10 (`scheduler.schema.json:198`), next to per-role ack waits of 90 to 180 s (`:36-46`).
So the Go scheduler config disagrees with the owner's rule (5 versus 3 for retries) and with the bash table (3), and the binary that would read it cannot run (F14).
The grep `grep -rn max_attempts factory herdr line events queue report roles` finds the key only in `routes.json:4` and the two routes schemas; no script reads it.
The owner rule "every automated step retries up to 3 times" is therefore declared as data and implemented nowhere in the runner.
Partial fix: `line/bin/route-retry.sh` deletes a `failed` ledger entry so the belt routes it again, but only after it greps the prose of the 500 note for `max_seats|max_agents` and extracts the role from the text `--role X` (`route-retry.sh:65-68`).
That is routing on prose, which `route.sh` itself forbids (`route.sh:3-4`), and it leaves 373 minus at most 18 failures permanent.
Issue 76 is still OPEN on GitHub although `route-retry.sh` is merged, because the script is a ledger-deleting side loop and not a retry in the runner.
`route-retry.sh` is not declared in `monitors.json` or any unit; PID 3932149 (running 1 h 58 min at 02:46Z) runs because a zsh child of herdr (PPID 33695, parent herdr server 32412) had it typed in.

F3. Issue 77, "seats post their start notice under a gate kind with code 100", traced to lines.
`event.sh:95-97` checks the code is in the schema enum and the sha is present on gate kinds, but never that a kind's code is the code its table row expects, so `test.passed 100` is accepted.
`event.sh:68` still lists legacy kinds `gate|test|review|merge` in `KINDS`.
Current state: in the state-root records since 2026-10-13T00:42Z every `test.passed`, `review.passed`, `merged` and `test.failed` carries its table code (105 x 201, 85 x 201, 92 x 200, 12 x 422), and no gate kind has code 100; the repo `events/2026/10` tree (5,983 files, untracked) still holds 1 `test.passed 100`, 1 `review.passed 100`, 5 `test 100` and 1 `review 100`.
So the symptom has stopped in practice but the validator that would prevent it is still missing; the issue is correctly open.
A neighbouring mismatch the issue does not name: `verify-main.sh` posts `verified 200` (`verify-main.sh:4`) while `routes.json:17` matches `verified` only at 201 and `:19` ignores the rest, so 22 `verified 200` records and 21 "no route for verified 200" notes exist next to 66 `verified 201`.

F4. Issue 78, "a merge wake sent to the one busy merger is lost", traced to lines.
`routes.json:12` seats the shared merger for every `review.passed`; the merger label has no ticket token (`roles/merger.json` label `merger`, `max_seats 1`), so `seat.sh` finds it already running, "leaves it as is" (`seat.sh:791`), and `route.sh:223` types the wake into a pane that may be mid-turn.
`routes.json:15` then runs `down: merger` after any `merged`, which takes down the shared seat while another ticket's wake may be in its input (`route.sh:107-110` documents the cost).
Superseded in design by `line/bin/merge.sh --all`, which has no seat, but nothing calls `merge.sh` on a timer or from a route row: grep finds callers only in docs, tests and ticket files, and the comment in `merge.sh:53` that "the patrol tick runs --all every minute" is false for `patrol-tick.sh`, which contains no `merge.sh` call.
The wiring ticket `WO-20261014-d93a` (R1 - routes.json run action: review.passed and merged run merge.sh and after-merge.sh, the architect wake on merged deleted) is status ready, not built.
Merges today are run by the acting orchestrator LLM seat (`merge-watch.sh:2-4` prompts `sched-worker-2`; `patrol-tick.sh` header names sched-worker-1 as "gates and merges").

F5. Components exist that nothing starts.

- `systemctl --user list-unit-files` shows only `herdr-stable.service` and `watchdog.{service,timer}` for this stack.
- The supervisor timer (`herdr/systemd/coq-supervisor.timer.in`, 30 s) is a template; `supervisor-units.sh install` is a manual host step (`supervisor-units.sh:4-8`) and was not done.
- `coq-hook-listener.service`, `coq-hook-forward.service`, `coq-hook-page.service` need "Install once, as the owner or orchestrator" (`line/units/coq-hook-listener.service:2`) and are not installed; nothing listens on 9371.
- The listener's handlers point at `${repo}/ci/bin/pr-gate-hook.sh` and `main-gate.sh` (`line/config/hook.json`), and `ci/bin/` does not exist on any branch (`git log --all -- ci/bin` is empty), so the listener would log "skipping handler: the file does not exist yet" (`hook-listener.sh:85`) for every event.
- `queue/bin/queue.sh dequeue` and `sweep` have no caller anywhere in the repo outside the scheduler's executor verb table (`scheduler/config/executor.json:111,123,136`, which cannot run, F14); the queue is write-only and displayed by a pane (`monitors.json` slot "queue").
  A queue item exists for WO-20261013-0b48, a ticket whose PR #176 already merged (`queue/items/p2-20261014T012050Z-WO-20261013-0b48.json`, commit 5ad1996), so the queue also drifts.
- `verify-main.sh` has no automatic caller either; the `merged 200` row wakes a seat that does not exist (F1), so verification after a merge is a person or an LLM reading a prompt.
- Processes running at 02:38Z: `unfreeze.sh --watch`, `turnwatch.sh`, `report/loop/loop.sh watch`, `patrol-tick.sh` (cache copy), `record-bus.sh`, `route.sh run`, `route-retry.sh`, `merge-watch.sh`.
  Not running although `monitors.json` declares them: `flow.sh run`, `policy.sh run`, `recwatch.sh`, `patrolwatch.sh`, `guardwatch.sh`, the `supervisor` log pane, `blueprint-*`, the `glass` sweep.
  The stall detector (`flow.sh`) and the default-answer clock (`policy.sh`) that the design relies on are therefore not alive on this snapshot, and no timer started them.

F6. Seat bring-up is a serial, blocking, bounded-by-hope sequence inside the belt tick; issue 67 is still open and correctly so.
`route.sh` runs `seat.sh` synchronously inside its single serial tick (`route.sh:220`, `:308`).
`seat.sh` waits for a shell prompt (15 s), starts the agent, waits for a compaction-guard ACK (`nudge_wait_seconds` 15, `herdr.json:13`, was 180 s; WO-20261013-7af7; wait at `seat.sh:778`), polls idle for 10 s (`herdr.json:14`), polls for a claude session file for 10 s (`herdr.json:15`).
Worst case about 50 s of blocked belt per bring-up; `route.sh status` goes "stopped" at `stale_seconds` 60 (`runner.json:15`), and `belt.sh` or a human can then start a second runner.
Issue 67 (created 2026-10-12T22:40:01Z, OPEN, 0 comments) asks for two outcomes: the ACK wait "no longer blocks routing (async or skipped when no guard nudge is pending)" and "two pr.opened records 10s apart are both routed within 30s".
The config change lowered the wait from 180 s to 15 s, with a schema cap of 30 (`herdr.schema.json:92-95`); that is a smaller block, not removal of the block.
The first acceptance criterion is not met (`seat.sh:778` still waits on the belt's thread) and the second cannot be met when one bring-up can take about 50 s, so the issue is open because the structure that caused it is unchanged.
Attempt 1 said "closed in the config"; that was too generous and is corrected here.

F7. The state and the transport are the same thing as the UI.
`herdr agent prompt` is the wake channel (`route.sh:205`, `merge-watch.sh:84`, `patrolwatch.sh:35`, `patrol-tick.sh:74`, `turnwatch.sh`), so a wake is lost whenever the target pane is busy, restarted or absent, and the sender gets only an exit code.
`record-bus.sh` copies records between trees every 5 s (`record-bus.sh:14`) because seats, checkouts and the state root disagreed about where records live; two trees (state root 3,338 files at 02:45Z, repo `events/2026/10` 5,983 files) still coexist.
The disagreement is visible in one more place: the state root has 0 `ticket.cut` records while the repo tree has 19, so a row that fires on the state-root tree never sees them (F12).

F8. Outside-the-repo scripts survive Roadmap I.
`patrol-tick.sh` (19,876 bytes) and `watchdog.sh` (6,006 bytes) still run from `~/.cache/coq-watch/` with `REPO=/home/luna/projects/coq-jev-herdr-plugin` hardcoded; the watchdog header records the exception as interim (`watchdog.sh:6-8`).
Every health guarantee on this machine rests on those two files and on the owner's pane layout.

F9. The Makefile is an entry-point list, not a DAG.
Root `Makefile` targets (`Makefile:21-48`) are help, images, lint, test, graph-check, contents, event, changelog, aggregates, step, lint-image-push and the pattern `bearings-%` (`:34`); `line/Makefile` has help, test, image, check (`:11-17`); `scheduler/Makefile` has `run`, `run-exec` and `status` (`:99-107`) that call wrappers for subcommands that do not exist (F14).
Nothing expresses "start a ticket", "seat a worker", "merge", "verify main" or "bring the line up" as targets with prerequisites, so the owner's stated preference for Make-driven automation is unused for the line itself.
The nearest thing is `make step` (`Makefile:45-46`), which is one linear script (`bin/step.sh`), not a graph.

F10. The commit history shows the repair pattern.
Of 246 commits on main 2026-10-10 to 2026-10-14, 50 match cause, fix, broke or stall; 94 landed on 2026-10-13 alone.
Typical shape: a breadcrumb names the previous patch (for example `route.sh` has 6 breadcrumb blocks, each patching the one before: A2 paths, 3bb0 gate rules, 9b21 ticket_of_pr, 4db1 ignore and seat, 38c7 original, 0229 state root).

F11. Issue 73 is still open and is not fixed by the code that exists: a refused seat is never queued.
Issue 73 (created 2026-10-12T22:40:10Z, OPEN, 0 comments; body: "WO-20261012-c41f was refused at 16:41Z with 8 workers live and nothing would seat it; the architect ran a retry loop by hand"; done when "a refused seat lands in a queue file and the belt or supervisor seats it when a slot of that role frees; a herdr case proves it").
The line that causes it: `herdr/bin/seat.sh:532` refuses with the words "the queue holds the ticket", and `seat.sh` contains no call to `queue.sh` anywhere (the other two matches for "queue" in the file, `:81` and `:90`, are about a shared pane, not the work queue).
A queue now exists (`queue/bin/queue.sh`, committed in 920807a), but the only enqueue call in the runner is the `request.forwarded` row (`routes.json:6`, `route.sh:224-227`), which enqueues a request for the architect, not a refused seat.
Nothing calls `queue.sh dequeue` (F5), so even an enqueued item would never leave.
What exists instead is the side loop `route-retry.sh` (F2) and the unbounded `until` loop in `line/bin/seat-queue.sh:29`, both outside the runner.
The refusal message is therefore false, which is worse than silence: `seat.sh:532` tells a reader a queue holds the ticket.
Capacity is only 18 of 391 failures (F1), so closing 73 alone would not move the dominant cause.

F12. The first half of the seat lifecycle (ticket cut, start, branch, seat) has no automatic driver and contains three hand-off gaps.
The chain, with the line each step lives on:
1. A ticket is cut by an LLM (`work-order.sh`, the skill).
   The route row for it, `routes.json:7` (`ticket.cut 100` wakes `worker`), has never fired in the window: `grep -l '"kind": "ticket.cut"'` over the 3,338 state-root records finds 0 (the repo's stale `events/2026/10` tree has 19).
2. A ticket is started by `bin/wo-start.sh`, called by `line/bin/start-tickets.sh:42` and by hand (`AGENTS.md:260`); no route row, unit, timer or Make target calls either.
   `wo-start.sh:21` runs `claims.sh start`, which runs `gh pr list --state open --limit 200` with no `timeout` (`claims.sh:97`) and `git worktree list` (`claims.sh:115`), refuses on an overlap with exit 3, then `exec`s `work-order.sh start` (`wo-start.sh:23`).
   `work-order.sh` `cmd_start` (`work-order.sh:800-828`) requires status `ready` (`:805`) and a clean tree (`:812-813`), refuses an existing branch (`:817-818`), and cuts `feat/<slug>` from the CHECKOUT HEAD with `git checkout -b` (`:820`), not from origin/main.
   That is why `start-tickets.sh:37-41` makes a throwaway worktree of origin/main per ticket (breadcrumb `start-tickets.sh:12-15`: six branches were cut from the records branch on 2026-10-11).
   `work-order.sh` is a gitignored managed skill copy replaced on every session start (`.gitignore:91`; `wo-start.sh:7-12` explains why a wrapper is used instead of a patch), so the first half of the lifecycle depends on a file the repo does not own.
3. `start-tickets.sh` runs the whole chain serially per id: `make step` (lint, changelog, commit, push; `:43`, its output sent to `/dev/null` so a failure reports only "FAIL id step"), `git push -u origin HEAD` (`:44`, no timeout), copies the started ticket file into the main checkout (`:45`, which leaves the checkout dirty: `git status` at the start of this session shows ` M work-orders/WO-20261013-16f1/WO-20261014-539a-...md`), then seats a worker synchronously (`:48`).
   It is typed by an LLM; its own breadcrumb calls it "interim" (`start-tickets.sh:2-3`, `:12`).
4. The `pr.opened` route (`routes.json:8`) seats a tester via `seat.sh`, which refuses a ticket with no branch (89 failures, F1) because the ticket file in the checkout was not yet copied or pulled (`start-tickets.sh:2-3`: "seat.sh reads the branch from the checkout copy", interim until roadmap item B).
`bin/step.sh` is the commit and push step inside every worker's loop and inside `start-tickets.sh:43`.
It holds no wait of its own (a `make lint` at `step.sh:23`, a `git push -q origin HEAD` at `:35` with no timeout), but it carries three defects: the `Claude-Session` trailer is a constant session id written into every commit (`step.sh:32`, `session_01694jMaqrg4CVo5zWF3jq6Z`), the `/compact` prompt target defaults to a fixed pane id `wD3:p2` (`step.sh:10`, `:54`, only with `--compact`), and `git add -A` (`step.sh:26`) stages everything in the tree, which is the root of the file-overlap storms that `claims.sh` was built to stop.
`bin/state-root.sh` and `bin/mint-id.sh` disagree about where state lives: `state-root.sh` resolves `~/.local/state/coq/<repo>` (`state-root.sh:41-57`), while `mint-id.sh:19` hardcodes `~/.local/state/coq-jev-herdr-plugin/ids` (note the different parent), and that directory exists on this machine with `SOP.counter` at `0006`; `herdr.json` still says `state_dir "~/.local/state/coq"` (`herdr.json`, flagged as unfinished at `state-root.sh:21`).
So `state-root.sh:2-3`, "none carries a root of its own", is false for `mint-id.sh`, and three roots coexist.
`mint-id.sh:28` takes its lock with `mkdir` and gives up after 10 s with exit 4; the lock is removed by an `EXIT` trap (`:29`), so a `kill -9` leaves it and every later mint fails until someone deletes the directory (no lease expiry).

F13. Issue 67 and 73 status, in one place.
Both remain OPEN on GitHub (checked 2026-10-14T02:45Z), both have zero comments, and both were filed in the same 15-second burst as 76, 77 and 78 (2026-10-12T22:40:01Z to 22:40:15Z), which looks like one backlog dump, not triage.
67 is open because the belt still blocks on a pane (F6).
73 is open because a refusal enqueues nothing (F11).
The brief names 76, 77 and 78 only; 67 and 73 matter because each is a second symptom of the same mechanism: the belt does a blocking action against an LLM pane or a pane-managed resource and has no durable "pending" state for it.

F14. The Go scheduler is a scaffold that cannot run, and carries its own bounds and retries that nothing exercises.
`scheduler/internal/cli/registry.go:46` defines `Register`, and `version.go:16` is the only call to it; `grep -rn 'Register(' scheduler --include='*.go'` excluding tests finds just those two lines, so the only subcommand is `version` (`version.go:15-28`).
The wrappers call subcommands that are not registered: `scheduler/host/bin/run.sh:116` ends the `podman run` with `run --config "$CFG"` and `scheduler/host/bin/run-exec.sh:30` execs `"$BIN" exec --config "$CFG"`, and `Dispatch` answers any other name with `unknown subcommand` and exit 2 (`registry.go:86-90`).
So `make -C scheduler run` and `run-exec` (`Makefile:99-103`) fail at the first record, and the RUNBOOK modes off, shadow and active (`RUNBOOK.md:104-116`) describe a system that does not exist yet.
Go is 1,281 lines in `internal/core` and `internal/testkit` including tests (contracts, a fake clock and executor), plus the CLI (127 lines) and `cmd/scheduler/main.go` (14 lines); `git log -- scheduler` shows three commits c22cb99, d268fe9, fc16622 (all 2026-10-12, PRs #41, #38, #39).
The scheduler holds no loop, sleep or timer in Go: `grep -rnE 'time\.Sleep|time\.After|NewTicker|context\.With(Timeout|Deadline)'` over non-test Go finds nothing.
Its waits are declared as data only, in `scheduler/config/scheduler.json` and `executor.json`; they are tabulated in section 6.
Two of those declared values already disagree with the shell line: `retry.max_attempts` 5 (F2) and the executor's `seat_up` verb timeout of 240 s (`executor.json:85`) against a measured worst case of about 50 s in `seat.sh`.

## 6. Waits, polls, sleeps and leases

Bound = the stated limit; "none" means an unbounded loop.
"Declared only" means the value is data in a config file that no running code reads.

| Where (file:line) | Waits on | Bound | Interval or bound value |
| ----------------- | -------- | ----- | ----------------------- |
| `factory/bin/route.sh:341` | next tick of the belt | none (forever) | `poll_seconds` 10 (`runner.json:3`) |
| `route.sh:220` | `seat.sh` bring-up, synchronously | indirect | prompt 15 s + ACK 15 s + settle 10 s + session 10 s |
| `route.sh:180` | `gh pr view` in `ticket_of_pr` | `timeout 20` | 20 s |
| `factory/bin/gate.sh:77` | `git fetch origin` | `timeout 20` | 20 s |
| `route.sh:335-336` | belt freshness | read-only | `stale_seconds` 60 (`runner.json:15`) |
| `factory/bin/flow.sh:163` | next flow tick (not running at snapshot) | none | 15 s; stall 90 s; busy grace 1800 s (`flow.json`) |
| `factory/bin/policy.sh:183` | next policy tick (not running) | none | `poll_seconds` from `policies.json` |
| `herdr/bin/seat.sh:804` | shell prompt in the new pane | bounded | `prompt_timeout_ms` 15000 |
| `seat.sh:778` | `pane wait-output` for the guard ACK line | bounded | `nudge_wait_seconds` 15 (schema cap 30, `herdr.schema.json:95`) |
| `seat.sh:781-785` | idle polling after the ACK | bounded | `nudge_settle_seconds` 10, 1 s steps |
| `seat.sh:830-833` | claude session file | bounded | `session_wait_seconds` 10, 1 s steps |
| `seat.sh:370` | `down_wait_seconds` before the tab close | bounded | 3 s |
| `herdr/bin/seat-lib.sh:300-311` | process death after SIGTERM then SIGKILL | bounded | 3 tries x 2 s, 0.2 s steps |
| `herdr/bin/retire.sh:29` | agent gone after `/exit` and C-c | bounded | `retire_poll_seconds` 10, twice |
| `seat.sh:530-537` | slot or agent count | refusal, no wait | `max_seats` per role (`roles/*.json`), `max_agents` 8 |
| `herdr/bin/belt.sh:59` | belt fresh after a restart | bounded | `belt.settle_seconds` 20 |
| `herdr/bin/supervisor.sh:83` | herdr session answers | bounded | `herdr_wait_seconds` 30; each step killed at 120 s; timer 30 s (not installed) |
| `supervisor.reseat` in `herdr.json` | re-seat rate | bounded | grace 20 s, 3 per 1800 s, down lock 300 s, up 90 s |
| `line/bin/route-retry.sh:88` | next retry pass | none | 30 s |
| `line/bin/merge-watch.sh:91` | next GitHub poll | 7-day backstop, halt flag | 60 s |
| `line/bin/seat-queue.sh:28` | ticket branch on origin (`git ls-remote`, itself with no timeout) | none (`until` loop) | 15 s |
| `line/bin/seat-queue.sh:29` | a worker slot; retries on ANY `seat.sh` failure, not only capacity | none (`until` loop) | 60 s |
| `line/bin/start-tickets.sh:37` | `git fetch -q origin` | none (no `timeout`) | one call |
| `line/bin/start-tickets.sh:43` | `make step` (lint container, commit, push), output discarded | none | seconds to minutes |
| `line/bin/start-tickets.sh:44` | `git push -q -u origin HEAD` | none (no `timeout`) | one call |
| `line/bin/start-tickets.sh:48` | `seat.sh` for the worker, synchronous, output cut to one line | indirect | the four `seat.sh` waits above |
| `bin/wo-start.sh:21` | `claims.sh start`: `gh pr list --limit 200` (`claims.sh:97`) and `git worktree list` (`claims.sh:115`) | none (no `timeout` on `gh`) | one call; exit 4 if gh fails, exit 3 on overlap |
| `bin/wo-start.sh:23` | `exec work-order.sh start` (`work-order.sh:800-828`: status, clean tree, branch check, `git checkout -b`) | none, no wait | local git only |
| `bin/step.sh:23` | `make lint` (lint container) | none | the lint run |
| `bin/step.sh:35` | `git push -q origin HEAD` | none (no `timeout`) | one call |
| `bin/step.sh:54` | `herdr agent prompt` with `/compact` | not reached by default (`--compact` only), fire and forget | `compact=0` at `step.sh:15` |
| `bin/state-root.sh` | nothing | holds no wait, poll, lease or LLM decision | pure function of env and `config/state.json` |
| `bin/mint-id.sh:28` | an id lock directory (`mkdir`) | bounded | 10 s, 1 s steps; stale lock after `kill -9` is never reaped |
| `bin/mint-id.sh:39` | `gh pr list --limit 200` | none (no `timeout`) | one call |
| `line/bin/digest.sh:41` | next architect digest | none | 1800 s |
| `line/bin/record-bus.sh` loop | next copy tick | none | 5 s (`--interval`) |
| `herdr/bin/turnwatch.sh:49` | seat turn ends | none | `turn_poll_seconds` 15 |
| `herdr/bin/recwatch.sh:54` | new gate record | none | `record_poll_seconds` 10 |
| `herdr/bin/patrolwatch.sh:40` | next patrol prompt to the compliance LLM | none | `patrol_seconds` 60 |
| `herdr/bin/guardwatch.sh:64` | next guard tick | none | 15 s |
| `herdr/bin/unfreeze.sh:94` | next lease release pass | none | 30 s |
| `monitors.json` slots events, queue, supervisor, glass, boardage | `while :; sleep N` display loops | none | 15, 15, 10, 15, 60 s |
| `~/.cache/coq-watch/patrol-tick.sh:197-239` | next probe | none | 60 s; idle limit 60 s, stall 600 s, io stall 1200 s, down retry 180 s |
| `~/.config/systemd/user/watchdog.timer` | restart patrol, dead man's card | timer | 120 s |
| `line/bin/merge.sh:107,255` | gh backoff, process exit | bounded | 2 s x attempt, 3 tries; 0.1 s x 10 |
| `line/bin/verify-main.sh:85,39` | io backoff, each suite | bounded | 2 s x attempt, 3 tries; suite timeout 1800 s |
| `line/bin/hook-listener.sh:74` | handler retries | bounded | `retries` 3, 1 s; handler 300 s (`hook.json`) |
| `queue/bin/queue.sh:43,54-56` | ticket lease | lease TTL, expiry by `sweep` (no caller) | `lease_ttl_seconds` 7200 |
| `herdr/config/leases.json` | slot 14400 s, tier 86400 s, ticket 7200 s, seat 900 s | declared TTLs | releasing expired leases is "the monitor", an LLM seat (`monitor.json`) |
| `route.sh` ledger | claimed entry across a crash | until next start | one 500, never a repeat |
| `scheduler/host/bin/run.sh:115` | `podman run --stop-timeout "$drain"`: a stop waits for the drain | bounded, declared | `drain_seconds` 30 (`scheduler.json:15`) |
| `scheduler/host/bin/run.sh:114-116` and `run-exec.sh:30` | `exec` replaces the shell; the wrappers hold no loop, sleep or poll | none in the scripts | the process they exec cannot start (F14) |
| `scheduler/config/scheduler.json:16` | intake poll | declared only | `intake.poll_seconds` 2 |
| `scheduler.json:26-28` | seat cap wait, seat absent wait, seat idle | declared only | 600 s, 1800 s, 120 s |
| `scheduler.json:29-33` and `:47` | retries | declared only | `retry.max_attempts` 5, backoff 5 s x2 capped at 300 s, jitter 0.2; `wake.max_attempts` 3 |
| `scheduler.json:36-46` | wake acks per role | declared only | 90 to 180 s |
| `scheduler.json:48-57` | stall deadlines per record kind, visibility | declared only | 600 to 900 s; visible within 900 s |
| `scheduler.json:59` and `:61-62` | belt staleness, executor dial and health | declared only | 60 s; 5 s and 2 s |
| `scheduler.json:65-67` | queue sweep, glass sweep, prune | declared only | 60 s, 15 s, 3600 s |
| `scheduler/config/executor.json:26-177` | per-verb `timeout_seconds` | declared only | 5 to 240 s; `seat_up` 240 (`:85`), `seat_down` 180 (`:90`) |
| `scheduler/internal/**/*.go` (non-test) | `time.Sleep`, `time.After`, tickers, context deadlines | none exist | grep finds no match |

Every polling loop in the table is an unbounded `while true` in a pane.
The only blocking waits on the belt's critical path are the four inside `seat.sh`, and they run inside the serial tick.
Only the first `read -t` form is interruptible by TERM (`route.sh:339-341`); the `sleep` loops are not.
There is no wait that is event-driven except `wait-output` in `seat.sh`; there is no `inotify`, no socket subscription, no systemd path unit anywhere in the line.
The ticket-start path (`wo-start.sh`, `start-tickets.sh`, `step.sh`, `mint-id.sh`) has five network or container calls with no `timeout` at all (`claims.sh:97`, `start-tickets.sh:37`, `:44`, `step.sh:35`, `mint-id.sh:39`), in a repo whose own gate calls use `timeout 20` (`route.sh:180`, `gate.sh:77`).
The Go scheduler is the only place that declares per-step retries and bounds as data, and it has no code that waits on any of them.

## 7. Decisions an LLM makes that a rule could make

| Decision | Where | Replacement rule |
| -------- | ----- | ---------------- |
| Run `merge.sh --all` after a review | acting orchestrator seat, prompted by `merge-watch.sh:84` and the patrol header; route row `review.passed` seats a merger (`routes.json:12`) | a route row `do: run` of `merge.sh --pr N` (ticket WO-20261014-d93a) or a timer unit every minute; delete the merger seat |
| Run `verify-main.sh` and the post-merge cleanup after a merge | `merged 200` row wakes `architect-wo-<id>` (`routes.json:15`), fails 88 times | same `run` row on `merged 200` |
| Clear a failed route | the architect or orchestrator, with `route-retry.sh` as a ledger-deleting loop | the runner owns `max_attempts`: retry a failed row with backoff three times, then one escalation record, decided by the exit code of `seat.sh` (distinct codes for capacity, no branch, no ticket) |
| Cut a ticket and start it, then seat the worker | an LLM types `work-order.sh` to cut, then `start-tickets.sh WO-...` or `seat-queue.sh WO-...` (`start-tickets.sh:42-48`, `seat-queue.sh:28`); `AGENTS.md:260` is the only instruction | a Make target or route row `ticket.cut` that runs `wo-start.sh` then `seat.sh`; the branch wait becomes a ledger hold with a deadline, not an `until` loop; the dead row `routes.json:7` becomes the real trigger |
| Decide which ticket starts next, and in what order | the architect or orchestrator reads `work-order.sh next`; `queue.sh dequeue` has no caller | the `dequeue` rule with its dependency oracle (`queue.sh:39`) driven by a timer, bounded by `max_agents` and the four-ticket guardrail |
| Decide the file claims are free to start | already a rule (`wo-start.sh:21`, `claims.sh:90-116`) | none, keep; add a `timeout` on its `gh` call |
| Tell the owner "done" or "decision" | `notify_owner` rows to the `interface-agent` role (seat label `interface`) at `routes.json:17`, `:21`, `:28`; 75 recorded failures (66 + 9) | write a card to the bearings page directly from the route action; no agent in the path |
| Decide a seat is stuck and down it | compliance-officer Haiku prompted every 60 s (`patrolwatch.sh:35`), and `patrol-tick.sh` which decides with probes then prompts an LLM | keep the probes, delete the LLM prompt; the probe result goes to a record and the downing is `seat.sh --down` by rule |
| Decide whether a gate record is current | already a rule (`gate.sh`) | none, keep |
| Triage 500 notes ("no route for", "route failed") | `to: monitor` Haiku seat (`routes.json:24`, `:36`, `monitor.json`) | classify by failure code in the runner; unrecoverable ones become one owner card, recoverable ones retry |
| Release an expired lease | "the monitor" per `leases.json` description | `queue.sh sweep` and a lease reaper on a timer (the verbs exist) |
| Batch what the architect hears | `digest.sh` prompts the architect every 1800 s | the architect reads the architect queue (`aq.sh list`) and is never prompted |
| Decide the seat name for a role | `seat_of` is a rule, but the table can name a role whose seat is never started (architect, interface) | lint rule: every `to` in `routes.json` must name a role the runner can start or a non-agent sink |
| Number the next SOP or ADR | already a rule (`mint-id.sh`) | none, keep; move its counter under `state-root.sh` |
| Decide the retry limit for a step | nobody: three declared values (3, 5, 3) with no reader | one key, read by the runner and the scheduler config, lint-checked against the owner rule |

## 8. What to carry forward

1. The record as the only hand-off, written through one validating writer (`events/bin/event.sh`), with a schema-enforced status code map.
2. The ledger idea in `route.sh`: claim before acting, mark done, an interrupted claim becomes one escalation and is never silently repeated (`route.sh:266`, `:291-297`).
3. `line/bin/merge.sh` and `line/bin/verify-main.sh` as the template for every seat job: a pure function of records and git, 3 bounded attempts, one escalation, no seat.
   They are worth lifting nearly unchanged into whatever the control plane becomes.
4. `factory/bin/gate.sh` head logic (same-head ignoring events/, supersede, heads_match) as a library of predicates.
5. The `merge-hold.json` pattern: a red main as a file that the merge function reads, not a sentence (`verify-main.sh:29`).
6. `claims.sh` and `bin/wo-start.sh`: files declared on the ticket, overlap refused at start and at the gate, a missing proof meaning "not granted"; this stops conflict storms mechanically.
7. Atomic-rename queue with priority, lease and sweep (`queue.sh`), once it has a driver; its shape matches Argo or Kueue style queues closely enough to be replaced later without changing callers.
8. Probes over opinions: liveness by screen change, readiness by idle time, an input/output probe by record (`patrol-tick.sh:15-34`).
9. The breadcrumb habit: each fix names what broke, the rejected alternative and the cost; this is the corpus every later design should be checked against.
10. A watchdog that is a systemd timer with a dead man's switch card, so the thing that watches is not a pane (`watchdog.service`, installed and the only supervisor that is).
11. `bin/state-root.sh`: one resolver with its defaults in a schema-validated config, every other script asking it (`paths.sh:20`, `start-tickets.sh:32`); extend it to `mint-id.sh` and `herdr.json` rather than replacing it.
12. From the Go scaffold, the idea only: a retry, ack, stall and cap value per role and per record kind as data in one validated file (`scheduler.json:26-57`), and a verb table with a timeout per host action (`executor.json`).
    The values should be reconciled with the owner rule (3 attempts) before reuse.

## 9. What to kill

1. Pane-typing as the wake channel for any step a script could run itself (`herdr_prompt`, `route.sh:205`), and with it every one-shot `wake`/`notify_owner` row to an LLM that exists only as a derived name.
2. The shared merger seat, its role file, `routes.json:12`, `:15` and playbook, once `merge.sh` is wired (WO-20261014-d93a).
3. The `architect-<ticket>` and `interface` wakes in `routes.json` (88 plus 75 recorded failures).
4. `route-retry.sh` as a prose-greping ledger deleter; replace with retry state inside the runner.
5. `seat-queue.sh` unbounded `until` loops and the interim `start-tickets.sh` typed by hand, once the start chain is a route or a Make target.
6. `record-bus.sh`: a bridge for two record trees that should be one.
7. `digest.sh`, `merge-watch.sh`, `patrolwatch.sh`, `turnwatch.sh`, `recwatch.sh`: each is a poll that prompts an LLM to compensate for a missing system action; their existence is the list of unautomated steps.
8. The three unread `max_attempts` declarations as they stand (`routes.json:4`, `scheduler.json:29`, `:47`) and the unread duplicate schema `factory/schema/routes.schema.json` (issue 66); keep exactly one.
9. Legacy event kinds `gate|test|review|merge` in `event.sh:68` and their no-route 500 noise.
10. `queue/items` as a gitignored write-only directory with a display pane and no consumer.
11. The cache-directory copies of `patrol-tick.sh` and `watchdog.sh` once they move under the supervisor.
12. The false refusal text `seat.sh:532` ("the queue holds the ticket") until a queue really does; and `step.sh:32`'s constant session trailer and `step.sh:10`'s fixed pane id.
13. The Go scaffold's `run` and `exec` wrappers (`run.sh:116`, `run-exec.sh:30`) and the RUNBOOK's modes, unless the control-plane decision (question 1) keeps a custom scheduler; today they are documentation for a binary that cannot start.

## 10. Open questions for the owner

1. Is `herdr` to stay as a human-visible terminal for seats only, with routing, retry, queueing and liveness moved to a timer-driven or event-driven control plane that never types into a pane?
   The evidence in F1, F6 and F7 says the pane is the wrong transport for system actions; the answer shapes the whole rebuild.
2. Should the system's own scripts (merge, verify, route retry, queue drain, ticket start) run as systemd user units or as pods, given that the only supervisor that is installed today is a timer and the supervisor and hook listener units were never installed?
3. Does the Go scheduler (a custom binary, 1,281 lines of contracts and fakes, no running subcommand) stay on the path, or does the rebuild use an off-the-shelf workflow engine and drop it?
   This changes the design because the answer decides whether `scheduler.json` is the retry and timeout contract or one more unread declaration.

## 11. Sources

Repository files (checkout `/home/luna/projects/coq-jev-herdr-plugin`, HEAD 5ad1996, read 2026-10-14):

- `factory/bin/route.sh` lines 2-19, 104-117, 151-168, 180, 205-289, 291-342
- `factory/config/routes.json` lines 4, 6-36 (rows `:7`, `:12`, `:15`, `:17`, `:21`, `:28` cited); `factory/config/runner.json` lines 3, 11, 15; `factory/config/flow.json`
- `factory/config/routes.schema.json:5-7`; `factory/schema/routes.schema.json:5-7`
- `factory/bin/gate.sh` lines 2-17, 77; `factory/bin/flow.sh` lines 2-16, 68-74, 163; `factory/bin/policy.sh` lines 2-15, 183; `factory/bin/claims.sh` lines 2-32, 90-116 (`:97` gh call, `:115` worktree list)
- `herdr/bin/seat.sh` lines 2-35, 503-537, 725-848; `herdr/bin/seat-lib.sh` lines 296-316; `herdr/bin/retire.sh` lines 5-29
- `herdr/config/herdr.json` lines 7, 13-15 and `state_dir`; `herdr/config/herdr.schema.json` lines 92-95; `herdr/config/monitors.json`; `herdr/config/leases.json`; `herdr/systemd/coq-supervisor.{service,timer}.in`
- `herdr/bin/supervisor.sh` lines 2-26, 83; `herdr/bin/supervisor-units.sh` lines 2-12; `herdr/bin/belt.sh`; `herdr/bin/turnwatch.sh`; `herdr/bin/recwatch.sh`; `herdr/bin/patrolwatch.sh`; `herdr/bin/guardwatch.sh`; `herdr/bin/unfreeze.sh`; `herdr/bin/bringup.sh`
- `bin/wo-start.sh` (all 23 lines); `bin/state-root.sh` (all 79 lines); `bin/step.sh` (all 56 lines); `bin/mint-id.sh` (all 43 lines); `bin/new-sop.sh:20-22`; `bin/test-cases.sh` (grep for waits only)
- `.claude/skills/work-order/scripts/work-order.sh` lines 800-828 (`cmd_start`); `.gitignore:91`
- `line/bin/merge.sh` lines 2-60, 106-132, 255, 359-382; `line/bin/verify-main.sh` lines 2-40, 85; `line/bin/route-retry.sh` lines 2-89; `line/bin/merge-watch.sh` lines 2-92; `line/bin/seat-queue.sh` lines 24-32; `line/bin/start-tickets.sh` lines 1-51; `line/bin/record-bus.sh` lines 2-30; `line/bin/digest.sh` lines 2-20; `line/bin/aq.sh` lines 2-45; `line/bin/hook-listener.sh` lines 2-20, 74-91; `line/config/hook.json`; `line/units/*.service`
- `queue/bin/queue.sh` lines 2-64; `queue/config/queue.json`; `.gitignore:119`; `queue/items/p2-20261014T012050Z-WO-20261013-0b48.json`
- `events/bin/event.sh` lines 2-17, 68-71, 83-97, 137-147; `events/schema/event.schema.json:14` (the `ticket.cut` kind)
- `roles/interface-agent.json` lines 30, 38; `roles/architect.json`; `roles/merger.json`; `roles/*.json` (labels, max_seats, models)
- `scheduler/internal/cli/registry.go` lines 14-99 (`Register` at `:46`, `Dispatch` at `:73-92`, unknown subcommand at `:87`); `scheduler/internal/cli/version.go` lines 15-28; `scheduler/cmd/scheduler/main.go`
- `scheduler/host/bin/run.sh` lines 1-117 (`:114-116` the exec); `scheduler/host/bin/run-exec.sh` (`:30`); `scheduler/host/bin/inbox.sh`; `scheduler/host/lib/config.sh`
- `scheduler/config/scheduler.json` lines 15-75 (retry `:29-33`, wake `:36-47`, stall `:48-57`, belt `:58-59`); `scheduler/config/scheduler.schema.json` lines 167, 198; `scheduler/config/executor.json` lines 26-181 (`:85`, `:90`, queue verbs `:111`, `:123`, `:136`)
- `scheduler/Makefile` lines 99-107; `scheduler/RUNBOOK.md` lines 1-30, 104-116; `scheduler/internal/core/*.go`, `scheduler/internal/testkit/*.go` (line counts only)
- git log of `scheduler/`: c22cb99 (#41), d268fe9 (#38), fc16622 (#39), all 2026-10-12
- `Makefile` (all 51 lines), `line/Makefile`; `AGENTS.md` lines 62, 125-175, 260-262 (Laws: agents are never gates, three loops, chain of command; the start and mint-id instructions)
- `playbooks/merger.md`, `playbooks/orchestrator.md`; `ci/README.md`; `ci/` tree (no `ci/bin`); `git log --all -- ci/bin` empty
- Tickets: `work-orders/WO-20261013-16f1/WO-20261014-d93a-*.md` (R1, status ready), `WO-20261013-3217-*.md` (CI gate 3, status ready), `WO-20261014-5e4a-*.md`

Outside the repo (read-only):

- `~/.cache/coq-watch/patrol-tick.sh` lines 1-74 (the quote at `:8`), 197-239; `~/.cache/coq-watch/watchdog.sh` lines 1-25
- `~/.config/systemd/user/watchdog.{service,timer}`; `systemctl --user list-unit-files` and `list-timers` at 2026-10-14T02:38Z
- `ps` at 2026-10-14T02:38Z and 02:46Z (PIDs 3932105 route.sh, 3932149 route-retry.sh, 3932234 merge-watch.sh, 3932071 record-bus.sh, 3868571 patrol-tick.sh, 511002 unfreeze.sh, 735301 turnwatch.sh; parents are zsh children of herdr server 32412)
- `herdr --session stable agent list` (read only): architect, monitor, sched-worker-1, sched-worker-2 and two unnamed idle panes at the snapshot
- `~/.local/state/coq/coq-jev-herdr-plugin/ledger/routed` (3,243 files at 02:45Z, first-word tally in section 4), `run/belt` (pid 3932105), `run/since` (20261013152859), `records/2026/10` (3,338 files at 02:45Z, 391 "route failed" notes from 2026-10-13T15:29:18Z to 2026-10-14T02:22:25Z, 206+55+51+21+20+18+10+8+2+2+1 "no route for" notes)
- `~/.local/state/coq-jev-herdr-plugin/ids/SOP.counter` (`0006`)
- Classifier input: `jq -r .note` over every record file containing `route failed`, kept in the investigator scratchpad only, not in the repo or the investigation root.

GitHub (gh CLI against jkkelley/coq-jev-herdr-plugin, read 2026-10-14T02:45Z):

- Issue 67 (created 2026-10-12T22:40:01Z, open, 0 comments): belt seat-ups block the line
- Issue 73 (created 2026-10-12T22:40:10Z, open, 0 comments): seat.sh max_seats refusal says the queue holds the ticket, but no queue exists
- Issue 76 (created 2026-10-12T22:40:13Z, open, 0 comments): route.sh never retries a failed route
- Issue 77 (created 2026-10-12T22:40:14Z, open, 0 comments): seats post their start notice under a gate kind with code 100
- Issue 78 (created 2026-10-12T22:40:15Z, open, 0 comments): a merge wake to the one busy merger is lost
- `git log` of main: 246 commits, 50 matching cause, fix, broke or stall; 94 on 2026-10-13; commit 920807a (queue scripts committed)
