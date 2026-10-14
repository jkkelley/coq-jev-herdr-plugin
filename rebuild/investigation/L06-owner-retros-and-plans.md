# L06 - The owner's own retros and plans

Investigator: area L06, Factory Rebuild step R-01, attempt 2.
Revised 2026-10-14T02:52Z (UTC) from a read-only pass.
Source key: P = `~/.local/state/coq/coq-jev-herdr-plugin/plans/2026/10/`, S = `~/.local/state/coq/coq-jev-herdr-plugin/`, R = `~/projects/coq-jev-herdr-plugin/`, C = `~/.cache/coq-watch/`.
Every evidence tag below is a short file name plus a line number, a record count, a commit, or a card id.
Attempt 2 re-checked every `retro:NN`, `roadmap:NN`, `runbook:NN`, `lineops:NN` and `crashbrief:NN` tag against the file with `cat -n`, and corrected the ones that were off.
The short names are expanded in section 11.

## 1. Contents

1. Contents
2. What it is
3. Where it lives
4. What works (includes 4.1, the owner decision cards C9 to C31 and what the owner answered)
5. What broke and why (includes 5.8, where the evidence disagrees with the brief)
6. Waits, polls, sleeps and leases
7. Decisions an LLM makes that a rule could make
8. What to carry forward
9. What to kill
10. Open questions for the owner
11. Sources

## 2. What it is

L06 is the owner's own written record of what broke on the line between 2026-10-12 and 2026-10-14 and what was decided in response.
It is 25 files in P: one retro of the architect flood (retro), the binding progress file called the roadmap (roadmap, 401 lines), the runtime-out-of-repo plan (rtplan), a restart runbook (runbook), a duplicate-work audit with its rulings (audit, audit-rulings), a priority list (prio), a best-practices research report (bestpractices), a test-speed design (testspeed), a CI-gate design with five amendments (cigate), a line-ops-are-code design (lineops), a SPEC-17 1.1.0 draft pair (spec17), four maintenance or orchestrator briefs, seven owner decision cards C23 to C29 in JSON, and one pointer file written 2026-10-14 02:41Z, `20261014-factory-rebuild-plan.md`, which points at the rebuild plan and is not itself a retro or a plan (see section 3).
Outside P it also covers the crash folder (S/crash/) and the memory notes the architect kept about the same events.
Read together, the files say the same thing four times in four vocabularies: a mechanical step was given to an LLM seat, the seat was late, wrong or duplicated, and each incident became a lettered "cause" ticket instead of a change to who drives the line.
The owner's verbatim summary lines are in roadmap:17-26, roadmap:193, roadmap:200-205 and lineops:4.

## 3. Where it lives

- Plans folder: `S/plans/2026/10/` (25 files, 342,015 bytes, `ls -la` on 2026-10-14T02:47Z; the earlier pass counted 24 because the pointer file did not exist yet).
  - `20261012222000-retro-architect-flood-and-halt.md` (2,674 bytes, 40 lines) is the only file named a retro.
  - `20261012212500-roadmap.md` (62,131 bytes, 401 lines) is the binding progress log; it is edited by the architect and was last modified 2026-10-14 01:42Z.
  - `20261013-duplicate-work-audit.md` (68,595 bytes) and `20261013235500-duplicate-audit-rulings.md`.
  - `20261013025600-priority-list.md`, `20261013021500-best-practices-agent-line.md`, `20261013160000-test-speed-design.md`, `20261013194800-ci-gate-design.md`, `20261014004500-line-ops-are-code-design.md`, `20261012210500-runtime-out-of-repo-plan.md`, `20261012215500-line-restart-runbook.md`.
  - `20261013021301-spec17-1-1-0-draft-loops-maintenance-controller.xml` (117,288 bytes, 548 lines) and its `.md` note.
  - Briefs: `20261013023257-maintenance-watchdog-brief.md`, `20261013025139-maintenance-pr86-roles-edit-brief.md`, `20261013131747-maintenance-brief-crash-causes.md`, `20261013162038-brief-sched-worker-2-second-orchestrator.md`.
  - Cards: `20261012235522-card-c23-orchestrator-runs-the-line.json`, `20261013000800-card-c24-system-first-drain-and-design.json`, `20261013004357-card-c25-accept-spec-17-system-design.json`, `20261013011800-card-c26-system-tickets-own-loop.json`, `20261013020600-card-c27-build-faster.json`, `20261013030800-card-c28-bearings-on-k8s.json`, `20261013032509-card-c29-design-reader-while-away.json` (7 files; C23 to C29).
  - `20261014-factory-rebuild-plan.md` (559 bytes, written 2026-10-14 02:41Z): a pointer, included here and not excluded.
    It says the rebuild plan is XML at `rebuild/factory-rebuild-plan.xml` on main of the repository, with the ledger and the rail page under `S/rebuild/2026/10/plan/`, and that the 2026-10-12 roadmap stays binding beside it (pointer lines 3-6).
    Check on 2026-10-14T02:48Z: `R/rebuild/` does not exist in the local main checkout; `git branch -a` lists `factory-rebuild/plan-and-rail` (local and origin), and `S/rebuild/2026/10/plan/` holds `ledger.tsv` and `page.html`.
    The branch state belongs to L05; this file only records that the pointer names a path not present on the checked-out main.
- Crash folder: `S/crash/README.md` and `S/crash/20261013T033218Z-herdr-stable/wsl-crash-1791862334-424-_home_luna_.local_bin_herdr-11.dmp` (877,330,432 bytes, copied 2026-10-13 13:19Z).
- Runtime state read for corroboration: `S/records/2026/10/` (3,338 record files on 2026-10-14T02:47Z), `S/run/patrol/`, `~/.config/systemd/user/`.
- Repo corroboration: `R/factory/config/routes.json`, `R/work-orders/WO-20261013-16f1/` (the system-loop epic), `R/line/`, `git log` on main (246 commits, first 2026-10-10T18:16Z).
- Memory notes about the same events: `~/.claude/projects/-home-luna-projects-coq-jev-herdr-plugin/memory/` (herdr-crash-restart-order, three-loops-always, architect-sends-specs-off, right-size-agent-models, architect-queue-clear-by-listed-id, rulings-gates-check-are-records).

## 4. What works

Each item is something the plans show working, with the evidence that it worked.

- Writing the retro and the roadmap at all, and making the roadmap binding.
  The flood was stopped, the records branch was retired and four PRs merged within 13 minutes of the restart with zero per-record architect prompts (retro:10, roadmap:67, roadmap:81).
- Moving runtime data out of git.
  The state-root layout `<kind>/YYYY/MM/YYYYMMDDHHMMSS-<name>.<ext>` is on disk today: `S/records/2026/10/` holds 3,338 files, plus `S/logs/`, `S/crash/`, `S/plans/` (rtplan:103-122; confirmed by `ls S/records/2026/10 | wc -l` on 2026-10-14T02:47Z).
- Merge as code.
  `line/bin/merge.sh` replaced the merger's judgement for the happy path (prio:40 row 5 "PR 87: WO-20261013-f6ae merge is code", roadmap:338 on the stale claim for f6ae and 5b33).
  Verify as code: `line/bin/verify-main.sh` with the coalescing rule "verify only the newest main sha; green verifies the whole range since the last verified sha; red bisects" (roadmap:324).
  Its suites carry a 1800 s timeout so "a hung suite cannot leave main unverified for ever" (R/line/bin/verify-main.sh:39, :51).
  Main verified green at 8b1b6cf, 37f57e0, 4a40c6a, 7e114c9 on 2026-10-13 and bda0eaa on 2026-10-14 (roadmap:341, 354, 374, 381, 394).
- Path-to-suite scoping.
  `factory/config/suites.json` plus `suites.sh` (PR 109) print the suites a diff needs; the full set runs once on main (testspeed:25-26, roadmap:244).
- Parallel case runner, one podman container per case (ruling at 18:25Z, roadmap:298-300; PR 115 merged, roadmap:350-351).
- The CI gate design and its amendments.
  Tests run as pod containers through a Jenkins shared-library step `coqGate()`, a `coq/gate` status on the head sha, webhooks in and out, a five-rung ladder, `gh webhook forward` as the outbound-only ingress (cigate:102-149).
  CI gates 1, 2 and 6 had merged by 2026-10-14T01:43Z: `git log` on main lists WO-20261013-8573 "CI gate 1" (PR 156, roadmap:394), commit 2247679 WO-20261013-ab25 "CI gate 2" (#179) and commit 3584b1e WO-20261013-ca2a "CI gate 6".
- Gate seat dedup: commit 96fc609 WO-20261013-0ad7 "Gate seat dedup: refuse a second live gate seat or a gate whose result exists for the head sha (cause af)" (#160) is on main, after five documented duplicate-gate incidents (section 5.3).
- Mechanical probes replaced an LLM monitor.
  After the Haiku monitor answered OK on every patrol including one after the merger said it was blocked (roadmap:200), `patrol-tick.sh` v2 does blocked-text, screen-unchanged, idle and exactly-one-process probes in code (C/patrol-tick.sh:54, :210, :216-221, :228-237).
  Corroborated by `S/run/patrol/` finding files (finding.blocked.*, finding.hung.*, finding.idle.*).
- The hold file for a red main, with a named exempt fix ticket (causes l and ah, roadmap:236, roadmap:390, roadmap:393; commit subject "WO-20261013-dec6 - Main is red" in `git log`).
- Records are countable by kind: 92 `merged`, 88 `verified`, 18 `rejected` records exist, so the verify loop is measurable (count of `S/records/2026/10/*-merged-*`, `-verified-*`, `-rejected-*`, 2026-10-14T02:47Z).
- The duplicate-work audit itself: 16 findings over 155 live tickets in nine minutes, with a status-code map and a per-finding action (audit:28-30, 76-83, 85-94).
- The best-practices report (bestpractices) is the strongest single design input: it maps each night's failure to a named pattern from Kubernetes, OTP, Temporal, Step Functions, SQS, SRE book and 2025-2026 agent literature (bestpractices:178-190, recommended architecture :192-205, sources in section 10 of that file).
- Owner cards gave the architect unambiguous answers and the roadmap records them (roadmap:35-52 for C9 to C22; per card below).

### 4.1 Owner decision cards: question, options, owner answer

The seven JSON cards C23 to C29 sit in P.
None of them carries an answer field: each file holds the question, the options and a `rec` index, and the owner's answer is recorded in the roadmap entry named below.
In every case where the roadmap names the answer, the owner took the first (recommended) option or a stronger variant of it, except C28.

| Card (file in P) | Question put to the owner | Owner answer and where recorded |
| --- | --- | --- |
| C23 `20261012235522-card-c23-orchestrator-runs-the-line.json` | Cut Roadmap K (the orchestrator runs the line) and start it first, or after I? | "Yes, first" plus "doc design first, this better line up"; K starts as a design doc first, with inventory, mermaid DAG, status code map, XML spec through an architect seat (roadmap:173). |
| C24 `20261013000800-card-c24-system-first-drain-and-design.json` | Drain the line and design the system first, or keep going? | Drain and design, "do it fast": no new ticket starts, the four in flight finish, K design ticket to the scheduler architect (roadmap:178-181). |
| C25 `20261013004357-card-c25-accept-spec-17-system-design.json` | Accept SPEC-17 (one board, the chain, the system checks every agent) so build tickets K1 to K7 are cut? | Accepted at 00:48Z, record 12wlf (roadmap:187). |
| C26 `20261013011800-card-c26-system-tickets-own-loop.json` | Give system tickets their own loop with own worker, tester, reviewer and merger, or own lane only? | "Own loop", record 16o3w (roadmap:196); the three-loops rule followed at 16:28Z (roadmap:256). |
| C27 `20261013020600-card-c27-build-faster.json` | Pull four levers: freeze the design, raise the agent cap 8 to 16, tester and merger on Sonnet, file-disjoint K tickets in parallel? | "All four", ruling gxmaw (roadmap:206). Evidence on lever 2 in section 5.8: `herdr/config/herdr.json:18` still says `"max_agents": 8`. |
| C28 `20261013030800-card-c28-bearings-on-k8s.json` | When should the bearings page move to the owner's cluster? | The owner parked it and claimed it (roadmap:221). It is closed to further mention under the owner's standing rule and is listed here only because the card exists. |
| C29 `20261013032509-card-c29-design-reader-while-away.json` | May the architect read and approve designs in the owner's place while the owner is away? | "Architect approves", logged at 13:13Z (roadmap:230); the approvals are listed at roadmap:242, 262, 326, 398. The owner later halted the architect for authoring designs it should have sent to a spec seat (roadmap:399). |

Cards outside the seven files, from the roadmap only:
- C9 to C22 (answered 2026-10-12, roadmap:37-50): PR 32 contents, runtime data to the state root, move the 171 events and 186 changelog files out, keep the tester/reviewer/merger/verifier seats with verdict records in the state root (C12), changelog from PR titles (C13), backlog as GitHub issues (C14), NATS JetStream dropped for now (C15), revise PR 37 first (C16), close PR 25 record bus (C17), close PR 29 verifier (C18), land PRs 40/42/5d09/38/41 (C19), revise PR 35 to v2.1 (C20), keep bearings page links live (C21), USERHALT accepted (C22).
- C30 (roadmap:290-296): the owner answered "Keep Opus as the global default"; seats set the model with `--model` at start, never `/model`.
- C31 (roadmap:397): "24h Opus line-fixer batching defects without a ticket each", recommended yes.
  No answer is recorded in the roadmap or in `S/records/2026/10/` (grep for "C31" returned no file), so it is unanswered as far as the files show.

## 5. What broke and why

The owner's own words come first, then the evidence for each break.

Owner words, in order (all UTC):
- 2026-10-12 20:41Z "you go pounded with messages, i see a failure point" (retro:7, roadmap:17).
- 2026-10-12 "I said I didn't want friction on PRs and you fucking did that" (roadmap:23, rtplan:8).
- 2026-10-13 01:10Z "you are the gate, you are the problem" (roadmap:193).
- 01:47Z "things are being reported ok when they are not" (roadmap:200).
- 02:01Z-02:08Z "idle limit 1 minute", "do their job and go", "nobody is a gate", "if they have met their AC why be around" (roadmap:203-205).
- 02:13Z "input output system sucks, nobody checking" (roadmap:207).
- 03:03Z "I hate bottlenecks" (prio:90).
- 12:59Z "everything crashed" (roadmap:227, memory herdr-crash-restart-order).
- 16:21Z "15 seats, why idle" (roadmap:250).
- 19:50Z "14 min stalls" and 20:07Z "hooks and ladder son, come the fuck on" (roadmap:326, roadmap:331, cigate:130).
- 2026-10-14 00:38Z "you can't write this shit, you need a spec sent off. You're getting overloaded. We need to halt everything." (roadmap:399, memory architect-sends-specs-off).
- 00:42Z "Why are agents doing shit that has automation" (lineops:4; roadmap:398 timestamps it 00:46Z).

### 5.1 The architect was the hub and the repo was the bus (2026-10-12)

- Two watches copied every record and every seat turn to the architect, one prompt each; after a compaction they replayed stale prompts and the resume notice arrived six minutes late (retro:5-6).
- 2,689 runtime event files queued on one PR, about 80 percent routing, stall and seat noise (retro:15, rtplan:10).
- The architect was the gate for carries, verifies, conflicts, scheduler forwarding, block rulings and records (retro:16).
- Halt was not a command (retro:17); the first halt stopped routing but not the seats (retro:8).
- Retro lessons: "route each record to exactly one consumer", "Runtime output never belongs in git", "write the stop and start before they are needed", "count prompts to the architect; every recurring kind is a missing rule" (retro:37-40).
- Found during the restart and put on the roadmap: seats read records from their own slot and miss them (retro:29), the merger asked the architect twice before merging passed PRs (retro:30, roadmap:98), seat.sh needs the started ticket's branch in a checkout copy that no longer exists (retro:31, roadmap:96), the belt blocks up to 180 seconds per seat waiting for the guard ack (retro:32, roadmap:66).
- Status: the flood cause is fixed (watches retired, records out of git).
  The lesson "every recurring kind is a missing rule" was then not applied to the orchestrator seats, which is the same failure one tier down (5.3).

### 5.2 One herdr server holds every seat and every line process (2026-10-13 03:32Z)

- `herdr-stable.service` core-dumped at 2026-10-13T03:32:18Z after 1d 9h of CPU, status=11/SEGV, memory peak 31.8G of a 36G WSL limit, swap peak 292.6M (work-order 77c0 line 52, `R/work-orders/WO-20261013-16f1/WO-20261013-77c0-*.md`).
- `Restart=on-failure` brought the server back at 03:32:25Z with the pane layout (`systemctl --user show herdr-stable.service`: `NRestarts=1`, `ActiveEnterTimestamp=Tue 2026-10-13 03:32:25 UTC`, read 2026-10-14T02:47Z), but systemd killed every pane shell in the control group, so every seat and every line process died (77c0 Problem).
- The line was dark for about 9.5 hours until the owner noticed at 12:59Z (roadmap:227).
- The dead man's switch did not fire because the patrol's own notes counted as records (crashbrief:9, roadmap:227); bearings, the owner's monitor, ran inside a herdr pane and died too (crashbrief:10).
  The cause is still in the code: `C/watchdog.sh:45` looks for any `*.json` newer than 30 minutes in the checkout `events/2026/10` or in `S/records`, and the patrol writes a record per note (`C/patrol-tick.sh:67`), so a running patrol keeps the switch silent.
  The fix ticket exists (WO-20261013-bf70 "The dead man's switch counts the patrol's own notes as records, so it never fired in a 9.5h outage (re-cut at line/bin/watchdog.sh)") and its status is `ready`, never started.
- The patrol saw eight system processes dead 56 times and queued them only for a dead architect (crashbrief:12).
- Not diagnosed as of 2026-10-14T02:47Z.
  `systemctl --user show herdr-stable.service -p MemoryHigh -p MemoryMax` prints `infinity` for both, and the unit file has no memory line (`~/.config/systemd/user/herdr-stable.service:1-18`).
  The 877 MB dump sits in `S/crash/` with no analysis in any plan file.
  Ticket 77c0 ("herdr-stable dies with a SEGV at 31.8G and nothing brings the seats back: it has no memory ceiling, no core kept, and no restart that resumes each seat by its pane session id") is `status: ready`, never started.
- The test-speed design says "herdr died at 31.8G ... N herdr servers must not repeat it" (testspeed:27).
  That is an inference about test parallelism; no file links the 03:32Z crash to parallel test cases, and parallel cases (PR 115) merged about 17 hours after the crash (roadmap:350-351).

### 5.3 Mechanical steps were given to LLM seats (2026-10-13 all day)

- lineops states the cause in one sentence: "Tonight (2026-10-13 18:00Z to 2026-10-14 00:40Z) nearly every stall came from an agent doing one of these steps late, twice or wrong: duplicate testers, idle orchestrators, records posted with the wrong code, slots returned with live processes, merges through a hold." (lineops:22).
- The route table itself seats a merger agent on review.passed and wakes the architect on merged: `R/factory/config/routes.json:12` and `:15` (confirmed by `sed -n 10,16p` on 2026-10-14T02:46Z; the file is unchanged since commit b87afe2).
- The orchestrator (sched-worker-1, a Sonnet seat) was the single lane for starts, re-routes, downs, cleanup and verify; it sat idle 12 minutes repeatedly and the work stopped (roadmap:360, 378).
- Specific evidence:
  - "four starts reported at 21:39Z never ran (no records)" (roadmap:359).
  - "no build start since 22:06Z" (roadmap:372); "line under-filled (1 builder)" (roadmap:369).
  - Duplicate gate seats at least five times: PR 114 tester (roadmap:307), PR 136 (roadmap:354), PR 158 and PR 157 (roadmap:385), PR 162 (audit:71).
  - "belt missed seating PR 136 reviewer and PR 149 tester within 2 min; hand-seated" (roadmap:367).
  - A merger merged PR 94 onto a red main because "the hold lived in prose" (roadmap:236).
  - A slot was returned with live processes, then `git worktree remove` deleted a treehouse slot (roadmap:370, 395; commit 17df7c9 WO-20261013-a18c).
- Two tiers of the same fault were ruled the same night: architect "rounds" every 1 to 3 minutes (roadmap:211, 216) while the architect also authored designs, which the owner stopped (memory architect-sends-specs-off; roadmap:399).

### 5.4 Test gates were the slowest and least trusted station

- A tester seat starts a suite in a pane and has to notice it ended; Haiku testers polled, forgot, or waited on finished shells, with stalls of 9 to 14 minutes on a lint that takes one (cigate:21, roadmap:325).
- The herdr suite ran about 20 minutes serial; the full suite on verify-main took about 25 minutes (prio:35, roadmap:304, roadmap:338).
- 74 fixed sleeps in 22 herdr case files (testspeed:19).
- Main went red five times from gate or test-plan defects, not from product defects: K5 reland missing fixtures (roadmap:232), case 12 board cap (roadmap:305), case 17 pane-health suite-only failure (roadmap:361), case 12-policy order (roadmap:386), spec-author label (roadmap:389).
- Two architect rulings were wrong and cost a red main or a wrong hold: the K5 plan ruling g4au6 narrowed the plan and missed an events dependency (roadmap:232), and the 17:23Z "flake" ruling was reversed at 17:50Z (roadmap:282).

### 5.5 Capacity and caps blocked work while seats idled

- A reviewer was refused at max_agents 8 and `route-retry` matched only max_seats, so nothing retried (roadmap:160); a merger refused at max_agents left the line idle 17 minutes until the owner asked (roadmap:165).
- Caps summed 4 plus 4 plus 2 against 15 seats and "build tickets locked in ticket PRs" (roadmap:252).
- Tester bottleneck: 8 PRs awaiting test with 1 tester of cap 4 (roadmap:313).
- Treehouse pool full at max_trees 8 (roadmap:321).
- The agent cap itself never moved: see 5.8, item (g).

### 5.6 Reporting noise became the work

- `S/records/2026/10/` holds 3,338 record files: 1,850 are `note` kind (55 percent), 643 `seat` (up/down), only 92 `merged` and 88 `verified`, 37 `blocked` (counts from filename kinds on 2026-10-14T02:47Z).
- The monitor seat wrote 558 of those notes: 350 "PATROL ... idle ... give it work within the minute or down it", 134 "BOTTLENECK ...", 2 "CORRECTION" (grep over `*note-monitor*`).
- The route runner wrote 188 notes, sched-worker seats 145.
- The route table produced 762 route failures by the first halt (runbook:9) and 41 to 72 per digest window later on 2026-10-13, mostly "no route" for note and verified kinds (roadmap:276, 17:33Z; roadmap:335 and 351; roadmap:364, 22:08Z); it was down to 16 by 00:07Z on 2026-10-14 (roadmap:392).
- The researcher report warned this exact trap before the idle rule was built into the patrol: "Do not alert on 'an agent looks idle'; that alarm is what taught an agent to invent busywork" (bestpractices:143, 190).
  The owner's one-minute idle rule (roadmap:203, 02:03Z) came first; the researcher was ordered at 02:12Z (bestpractices:4), so the report could not have prevented it, and patrol IDLE=60s stands at `C/patrol-tick.sh:40`.
  The evidence disagrees with neither party: the rule is the owner's and it did produce 350 idle notes.

### 5.7 Process debt: 51 lettered causes and a ticket flood

- "Cause" tickets are lettered a to z then aa to ay by 2026-10-14T01:43Z (c9b6f9f "cut cause ay", `git show -s`), starting from cause (a) at 13:05Z on 2026-10-13 (roadmap:228): about 50 causes in about 12.6 hours.
  Of 101 commits since 2026-10-13T00:00Z, 37 mention "cause" (`git log --since` on 2026-10-14T02:46Z).
- The ticket backlog itself accumulated duplicates: 155 live tickets, 16 findings, nine duplicate or stale (audit:28-30, 76-83).
  Eight tickets declare `herdr/bin/seat.sh`, 23 unordered pairs (audit:433).
  The live fault the audit found was two testers on PR 162 at that moment (audit:71).
- Every commit subject since 2026-10-12 that I read in `git log` is line tooling, specs, tickets or roles.
  The architect states "game untouched" at 00:34Z (roadmap:396, about two weeks to a self-running line).
  The product has not been worked on by the line.

### 5.8 Where the evidence disagrees with the brief's diagnosis, and what the plans decided but never built

- Brief: "we're using herdr wrong".
  The plans do not support that as the cause of the stalls.
  No retro or cause blames a herdr API misuse.
  What they show is (a) mechanical steps given to LLM seats (lineops:19-22, 5.3), (b) the architect as hub (retro:14-16), (c) the repo as bus (retro:15), (d) bash glue in panes with no supervisor (S/run/patrol and `C` scripts, see (f) below), and (e) one herdr server as a single point of failure (5.2).
  Only (e) implicates herdr itself, and its root cause is undiagnosed (5.2).
- Brief: "we need a system, not agents or humans driving it".
  The plans reached this conclusion three times before the brief did: card C24 (roadmap:178-181), bestpractices:22-27 ("LLMs belong only in the worker slot"), lineops:19-29.
  The conclusion was repeatedly accepted and not built: as of 2026-10-14T02:47Z only two systemd user units exist for the line (`herdr-stable.service`, and `watchdog.timer` driving `watchdog.service`, from `C/watchdog.sh`, outside the repo against the owner's own rule at roadmap:138).
  `systemctl --user list-unit-files` shows no belt, patrol, merge-watch, route-retry, record-bus or hook unit.
  Belt, patrol, merge-watch, route-retry and record-bus are pane processes restarted by an orchestrator agent (roadmap:228, 399-401; `ps` on 2026-10-14T02:47Z shows them all started 00:48Z, the restart in roadmap:400).
- The plans put the first fix after "who drives" in the wrong order twice.
  The runtime-out-of-repo plan (rtplan:38-48) listed nine "agents are never gates" rules, and the first build tickets were state-root plumbing; the router, owner-seat routing and halt commands were Phase 3 and then reshaped into SPEC-17 K1 to K8 (roadmap:94-103, 187).
- The record store design drifted.
  rtplan:23-26 and 43 put test and review verdicts on GitHub checks with auto-merge and no merger seat.
  Card C12 (roadmap:40) reversed that ("keep seats; verdict records live in the state root").
  The CI gate (cigate:128-149, roadmap:326-336) reintroduced GitHub status as the verdict, with webhooks turning it back into state-root records.
  Three different answers to "where does the verdict live" in 24 hours.
- Decided but not built or not live, each checked against the file on 2026-10-14:
  - (f) Roadmap I, "line scripts live in the repo", is half landed, not "never landed" as roadmap:280 and prio:38 say.
    `R/line/bin/` now holds aq.sh, board.sh, digest.sh, flow-table.sh, hook-listener.sh, merge-watch.sh, merge.sh, record-bus.sh, route-retry.sh, seat-queue.sh, start-tickets.sh and verify-main.sh (`ls`), and the running record-bus, route-retry and merge-watch are the `line/bin` copies (`ps`: `bash line/bin/record-bus.sh`, `bash line/bin/route-retry.sh`, `bash line/bin/merge-watch.sh wD7:p4`).
    Still outside the repo and still running or timer-driven: `C/patrol-tick.sh` (pid 3868571), `C/watchdog.sh`; still outside and halted by order: `C/architect-rounds.sh`, `C/flow-tick.sh` (roadmap:401).
  - (g) C27 lever 2, "raise the agent cap from 8 to 16", ruled "all four" at 02:10Z on 2026-10-13 (roadmap:206), is not on main: `R/herdr/config/herdr.json:18` is `"max_agents": 8` and `git log -S'"max_agents": 16'` finds no commit.
    The first ticket WO-20261013-9c50 "Capacity and gate models: max_agents 8 to 16 in the herdr config, ..." was cancelled and superseded by WO-20261013-a1c6 "Capacity: herdr max_agents goes from 8 to 16, pinned by a herdr test case", which is still `status: ready`.
    A decided one-line config change sat unbuilt for about 24 hours while the owner asked "15 seats, why idle" (roadmap:250).
  - (h) The webhook design says "everything is event driven, nothing polls" (cigate:132).
    The listener and its three units are merged (commit 3584b1e, `R/line/units/coq-hook-listener.service`, `coq-hook-forward.service`, `coq-hook-page.service`) but the unit header says "Install once, as the owner or orchestrator: systemctl --user link ..." (`coq-hook-listener.service:2`), and `~/.config/systemd/user/` has no such unit, so nothing feeds the listener.
  - (i) cigate:148 promises "merge-watch reads the PR's `coq/gate` status on its existing 1-minute tick" as the fallback; `grep -c 'coq/gate' R/line/bin/merge-watch.sh` prints 0.
  - (j) `C/architect-rounds.sh:41` counts "records since last" from `$STATE/events`, a directory that does not exist in the state root (`ls S/events` fails; records live in `S/records`), so the figure it prompts the architect with counts only the checkout tree.
    Same drift class as retro:29: two roots, scripts reading the wrong one.

## 6. Waits, polls, sleeps and leases

The first table is every wait the line itself runs, each with a script path and line read on 2026-10-14 (R = repo, C = `~/.cache/coq-watch/`).
The full, line-by-line inventory of the repo scripts is area L01 section 6 (`L01-line-scripts.md`); rows here that repeat an L01 row say so, and the bounds agree with L01.
The second table is waits that only the plans describe, each with the plan line.
Bound "none" means an unbounded loop in a pane or a timer with no attempt cap.

### 6.1 Waits the line runs, with script and line

| Where (file:line) | What it waits on | Bound and value | Plan reference | L01 |
| --- | --- | --- | --- | --- |
| `R/factory/bin/route.sh:341` (`read -r -t "$POLL"`) | the next belt tick | none; `poll_seconds` 10 at `R/factory/config/runner.json:3`; the tick is serial, so one slow route blocks every route behind it | runbook:9, roadmap:368 | same row |
| `R/herdr/bin/seat.sh:778` (`pane wait-output ... --timeout`) | a compaction-guard ACK line no seat prints, inside the belt's serial tick | 15 s (`R/herdr/config/herdr.json:13`), schema cap 30 (`R/herdr/config/herdr.schema.json:96`); was 180 s until commit 3419b86 (diff: `"nudge_wait_seconds": 180` to `15`) | retro:32, roadmap:66 | same row |
| `R/herdr/bin/seat.sh:784` and `:832` | idle poll after the ACK; the claude session file | `nudge_settle_seconds` 10 (`herdr.json:14`), `session_wait_seconds` 10 (`herdr.json:15`), 1 s steps | none | same rows |
| `R/line/bin/route-retry.sh:55` and `:88` (`EVERY=${ROUTE_RETRY_SECONDS:-30}`, `sleep "$EVERY"`) | the next pass over ledger entries marked `failed` | loop interval 30 s; no attempt cap, no age cap, no halt-flag check, no `flock`, and `herdr agent list` at `:59` has no timeout. The only floor is `SINCE` (`:55`, `:61`, default stamp 20261012170000). One clear per free slot per pass (phantom agent `:81`) | runbook:12, roadmap:160, 165 | row `route-retry.sh:88` |
| `R/line/bin/route-retry.sh:67` | which failures it will retry | only a failure note matching `max_seats` or `max_agents`; any other failed route (no branch, bad record) stays `failed` in the ledger for ever, with no card and no timeout | roadmap:160 | not stated |
| `C/route-retry.sh:27` (interim copy, no longer the one running) | same, `sleep 30` | same logic; `max_agents` branch at `:14-23` | roadmap:165 | not stated |
| `R/herdr/bin/unfreeze.sh:9`, `:28`, `:94` | compaction-guard lease release | `--watch` default 30 s, no end | runbook:11 | same row |
| `R/line/bin/merge-watch.sh:41`, `:74`, `:91` | GitHub merged-PR list (`gh pr list`, no timeout) | 60 s; exits on the halt flag (`:73`), after `MAX_AGE` 7 days (`:42`, `:74`) or when its fix ticket merges | roadmap:129-133 | same row |
| `R/line/bin/record-bus.sh:53`, `:107` | slot-to-checkout record copy | 5 s (`interval=5`), copy window 60 min fixed at start (`window=60`, `:78`), no end | runbook:13 | same row |
| `R/line/bin/digest.sh:35`, `:41` | wall clock | 1800 s per architect prompt, no end; `DIGEST_ROUNDS` only for tests | runbook:32, prio:35 | same row |
| `R/line/bin/seat-queue.sh:25`, `:28`, `:29` | the ticket branch on origin; a worker slot | `until` loops with no cap; 15 s and 60 s | none | same rows |
| `R/line/bin/verify-main.sh:51`, `:85` | `gh`/io steps and each suite | 3 attempts, backoff 2 s times attempt; suite timeout 1800 s (`VERIFY_SUITE_TIMEOUT`) | roadmap:324 | same row |
| `R/line/bin/merge.sh:80`, `:107`, `:255` | `gh` calls; a process exit | 3 attempts, 2 s times attempt; 0.1 s times 10 | prio:40 | same row |
| `R/line/bin/hook-listener.sh:56-57`, `:74`, `:87` | handler retries and run time | 3 retries, 1 s apart; handler 300 s (`R/line/config/hook.json:21-25`); the listener is not running (5.8 item h) | cigate:141-148 | same row |
| `R/report/loop/loop.sh:391` and `:382-386` (board watch) | collect pass | `watch_seconds` 10 (`R/report/loop/config/board.json:4`, schema max 25); 3 failed passes in a row post a 500 and end the watch (cause ad, commit for WO-20261013-10d8) | roadmap:376 | not listed |
| `C/patrol-tick.sh:38`, `:40`, `:44`, `:239` | pane screens and the process table | tick 60 s; hung 600 s (`STALL`); idle 60 s (`IDLE`); io stall 1200 s (`IO_STALL`); down retry 180 s; no end, one `flock` (`:195`) | roadmap:199-203 | same row |
| `C/patrol-tick.sh:62` and `:71` | finding dedupe and escalation | one finding per key per 600 s; the third sighting adds an aq.sh item; a finding aimed at a mid-turn target is held (`:73`) | roadmap:199, 260 | not stated |
| `C/patrol-tick.sh:199` | `herdr agent list` | on failure `sleep $INTERVAL; continue`, no card, no counter | none | not stated |
| `C/watchdog.sh:28`, `:45`, `:56-59` and `~/.config/systemd/user/watchdog.timer:6-7` | patrol heartbeat; "any record in 30 min" | timer every 2 min; stale 180 s; quiet 30 min; 3 restart tries, then at most one card per 3600 s; the "any record" test is the 5.2 defect | brief 02:32Z line 7, roadmap:210 | row `watchdog.timer` |
| `C/architect-rounds.sh:12`, `:34-35`, `:53` | wall clock | 180 s; skips while the architect is mid-turn or armed for compaction; halted by order at 00:38Z and not restarted (roadmap:401) | roadmap:211, 213, 216 | not listed |
| `C/flow-tick.sh:20`, `:77` | wall clock | 180 s; halted by order (roadmap:401) | roadmap:222 | not listed |
| `R/factory/bin/claims.sh`, called by `R/bin/wo-start.sh:21`, which `R/line/bin/start-tickets.sh:42` runs | counting declared files of every cut ticket | none; over 2 minutes per start (cause y) | roadmap:356, 373 | not stated |
| `R/treehouse.toml:5` | treehouse pool | `max_trees = 8`; a slot is held until returned by hand or by `merge.sh`; the declared lease TTL for a slot is 14400 s (`R/herdr/config/leases.json:6`) but the releaser is the monitor LLM seat | roadmap:321, audit F2 | row `leases.json` |
| `~/.config/systemd/user/herdr-stable.service:14-15` | crash then restart | `Restart=on-failure`, `RestartSec=5`, `MemoryHigh=infinity`, `MemoryMax=infinity`; a restart does not resume seats | 77c0 line 52 | not stated |

### 6.2 Waits the plans describe that live in agent behaviour, not in a script

| Where | What it waits on | Bound | Evidence |
| --- | --- | --- | --- |
| orchestrator seat turn | one LLM turn at a time | findings held 11 or more minutes behind a single turn; 12-minute idle windows | roadmap:260, 360, 378 |
| tester seat waiting on a test pane | a finished suite | stalls of 9 to 14 minutes; Haiku used a Monitor instead of reading the pane | cigate:21, roadmap:155, 191, 325 |
| herdr serial suite | 27 cases and 74 fixed sleeps | about 20 minutes; per-case budgets introduced in `config/tests.json` | prio:35, testspeed:19, :28 |
| verify-main on the whole suite | full suites on main | about 25 minutes; one run at a time until the coalescing rule at 19:41Z | roadmap:324, 338 |
| `gh webhook forward` listener | GitHub events | none polled by design; the fallback in cigate:148 does not exist in `merge-watch.sh` (5.8 item i) | cigate:141-148 |
| ledger entries | a `done` mark | cleared by hand to force re-routes twice | roadmap:160, 165, `R/specs/SPEC-17-orchestrator-and-agent-health.xml:277` (H09) |
| max_agents and max_seats | seat count under cap | 8 live agents (`herdr.json:18`), per-role caps in `R/roles/*.json:12`; a cap refusal is now retried by `route-retry.sh:67-78`, other failures are not | roadmap:160, 165, 252 |

The correction to the first pass: the earlier text said route-retry had "no wall-clock bound found" and that a cap refusal left "no retry".
Reading the script shows the opposite for cap refusals (they are retried every 30 s once a slot is free, `route-retry.sh:67-80`) and shows the real gap: no attempt cap, no halt awareness, and silent permanence for every non-cap failure (`:67`).

## 7. Decisions an LLM makes that a rule could make

Every row cites the plan evidence for the cost, then names the replacement rule.
Where the plans already decided the replacement, the ticket is named with its title.
Area L13 lists the same decisions from the role and playbook side.

1. Merge when gates pass (merger seat; `R/factory/config/routes.json:12`).
   Cost: the merger asked the architect twice before merging passed PRs (retro:30, roadmap:98); merged onto red main (roadmap:236); the merge lane was "the bottleneck" with four PRs merge-ready at 20:15Z (roadmap:334).
   Rule: `merge.sh` when `review.passed` and `coq/gate` success on the head sha and no hold file (lineops:24-29, 44-51; WO-20261013-3217 "CI gate 3: line/bin/merge.sh keys on the coq/gate status of the head sha plus review.passed, triggered by the GitHub status event, not on a test.passed record" and WO-20261014-d93a "R1 - routes.json run action: review.passed and merged run merge.sh and after-merge.sh, the architect wake on merged deleted"; both `ready`).
2. Verify main after a merge (architect wake, `routes.json:15`; later a verify-main seat).
   Cost: queued verify runs at 20 minutes each, none posted between 16:20Z and 20:34Z (roadmap:335, 341).
   Rule: CI gate 4, push-to-main status posts `verified` or `rejected` and sets the hold (WO-20261013-aff2 "CI gate 4: a green coq/gate status on main posts verified for every merge since the last verified sha, a red one posts rejected and sets the merge hold, triggered by the GitHub status event"; audit-rulings:23).
3. Clean up after a merge: branches, seats down, slot return (orchestrator by hand).
   Cost: slot cleanup exited 4 inside a slot and the merger withheld `merged` (roadmap:166); slots returned with live processes three times (roadmap:370, 395, 387); a slot deleted by `git worktree remove` (roadmap:370).
   Rule: `merge.sh` cleanup without checking out main, refusing a slot with foreign processes (commit 17df7c9 WO-20261013-a18c, landed, put the cleanup inside merge.sh; WO-20261013-48f2 "Post-merge cleanup is code: line/bin/after-merge.sh cleans the branches, downs the ticket's seats and returns their slots, restores the checkout's ticket copies, starts verify-main.sh in an unowned pane and posts one record", still `ready`, `line/bin/after-merge.sh` does not exist; audit F2).
4. Down a seat that posted its result (patrol note then orchestrator).
   Cost: 350 idle notes; seats holding slots after merge (roadmap:184, 189; `R/specs/SPEC-17-orchestrator-and-agent-health.xml:278` H10).
   Rule: route `down:` on the result record, patrol only reports survivors older than 2 minutes (lineops:49; WO-20261014-7f99 "R2 - Result records down their own seat through the route down key and patrol reports survivors as a defect", `ready`).
5. Start the next ready ticket when a slot is free (orchestrator, architect "FILL ORDER" rulings).
   Cost: four starts that never ran (roadmap:359); no build start from 22:06Z to 22:31Z (roadmap:372); under-filled line (roadmap:309, 369).
   Rule: a start loop over ready + depends done + files free + slot free (lineops:50; WO-20261014-3dae "R3 - start-loop.sh with its systemd user unit starts the next ready ticket when depends are done, files are free and a slot is free", `ready`).
6. Re-seat a gate that did not appear; dedup duplicate gates (orchestrator by hand).
   Cost: duplicate gates in five documented incidents (5.3); belt missed seating within 2 minutes (roadmap:367).
   Rule: seat.sh and route.sh refuse a second same-role seat for a PR and sha, and refuse if the result exists (commit 96fc609, landed).
   Longer term the gate seat itself retires (WO-20261013-3eac "CI gate 5: pr.opened routes to the reviewer only; the tester role is retired and its playbook marked retired", `ready`).
7. Choose which suites a PR needs (architect plan rulings).
   Cost: ruling g4au6 narrowed the K5 plan and broke main (roadmap:232); a tester ran the whole herdr suite on a roles-only PR twice (roadmap:362, 371).
   Rule: `suites.sh plan` over a path-to-suite map; the tester only runs what it prints (testspeed:25-26; landed with PR 109 and with WO-20261013-b6f3 "Cause z: a belt-seated tester runs the full suites; its playbook runs factory/bin/suites.sh plan on the PR diff and only the commands it prints", merged in PR 157, roadmap:386).
8. Decide whether a red suite is a flake (architect).
   Cost: wrong flake ruling at 17:23Z, corrected 17:50Z (roadmap:282); case 17 ruled "not a flake" at 22:08Z (roadmap:361).
   Rule: the ladder: three infra retries, one clean rerun on a fresh pod, then a page (cigate:135-139; rung 4 already used by hand at roadmap:361).
9. Pick the seat role and model (architect ruling 2wbaq; Haiku vs Sonnet vs Opus).
   Cost: spec-author seated as worker twice (roadmap:311, 361); `/model` saved Opus as the global default (roadmap:292, C30 at :294-296).
   Rule: seat.sh derives role from the ticket's files and takes `--model` from the role file only (WO-20261013-e880 "Cause 2wbaq, part 2: seat.sh seats a ticket's worker as spec-author when every file of the ticket is under specs/, graph/, roles/ or playbooks/" and WO-20261013-bcba "Cause u: seat.sh has no --model, so the architect cannot start a tester on Sonnet; seat.sh --model is honoured only when the role's model.architect_may_override is true").
10. Judge seat health from the screen (Haiku monitor).
    Cost: OK on every patrol 01:24Z to 01:40Z including a blocked merger (roadmap:200).
    Rule: probes in code (screen hash unchanged, idle with open items, exactly-one-process; landed in `C/patrol-tick.sh:210-237`); an LLM may explain, never close an alarm (bestpractices:145-150).
11. Ordering and file-overlap between tickets (architect "claims" rulings).
    Cost: claims rulings 21:50Z, 21:56Z, 22:39Z (roadmap:356, 358, 374); 23 unordered pairs on seat.sh (audit:433).
    Rule: `depends_on` edges computed from the `files:` field; `claims.sh` as a gate in the starter, no ruling (`R/factory/bin/claims.sh`, `R/bin/wo-start.sh:21`; cause y and aj fix the field).
12. Place a merge hold.
    Cost: the hold lived in prose and a merger merged onto red main (roadmap:236); the hold blocked its own fix PR (roadmap:390).
    Rule: `merge-hold.json` read by `merge.sh`, with a named exempt ticket (WO-20261014-c789 "Cause ah: the merge hold file names the one exempt fix ticket, line/bin/merge.sh honours it, and every merge path (hand or script) goes through merge.sh so the hold applies to all"; roadmap:390, 393).
13. Re-route a stuck record by clearing the ledger by hand (architect).
    Cost: ledger entries cleared by hand twice (roadmap:160, 165).
    Rule: a reconcile loop re-queues an open record with no result (bestpractices:36-39, 196); today only `route-retry.sh:67-80` does it, and only for cap refusals.
14. Answer block 423s that a standing policy could answer (architect).
    Cost: blocks sat 6 minutes unactioned (prio:72); 37 `blocked` records exist (count of `S/records/2026/10/*-blocked-*`).
    Rule: standing policies with deadlines and defaults (WO-20261012-9b2c "Standing policies: an escalation carries a deadline and a default drawn from the owner's locked decisions, so the line takes the default when nobody answers instead of waiting", `done`, audit F7: the active copy was a merged duplicate).
15. Approve designs in the owner's absence (card C29, architect).
    Cost: the architect authored a design while ruling every 2 to 3 minutes and was halted for overload (memory architect-sends-specs-off; roadmap:399).
    Rule: a spec-author seat writes the spec; the owner or a recorded policy approves; the architect only rules (roadmap:399).
16. Write a ruling and then prompt it rather than record it.
    Cost: PR 156 review.changes because the AC-H2 ruling was unrecorded (roadmap:384; memory rulings-gates-check-are-records).
    Rule: rulings are written by event.sh as records first; the gate reads records only.
17. Work the architect queue by reading rounds prompts (the architect).
    Cost: bulk-cleared 11 queue items unread at 22:36Z (roadmap:374); rounds prompts every 1 to 3 minutes (roadmap:211, 216); `architect-rounds.sh:41` counts the wrong tree (5.8 item j).
    Rule: items enter an `aq.sh` list by code and page the architect only on a ruling kind; no rounds loop (bestpractices:174, 205).

## 8. What to carry forward

- bestpractices section 9 as the control-plane shape.
  One record root, level-triggered reconcilers, seats as Jobs with TTL, leases and heartbeats, dead-letter plus one owner card at three attempts, a GC controller keyed on owner record id, a dead man's switch outside the line, systemd as the only supervisor of daemons, LLMs only in the worker slot (bestpractices:192-205).
  Why: it already maps each of the night's failures to a named proven pattern (bestpractices:178-190), and it matches the owner's "cog, not gate" and "no agent drives" wording.
- The status-code map and the one-consumer-per-kind rule (rtplan:40, spec17 s-codes at `spec17.xml:386`, lineops:71-78).
  Why: the owner required codes and maps in every document and the records already carry them (`S/records/2026/10/*.json` field `code`).
- `merge.sh`, `verify-main.sh`, `suites.sh` plus `suites.json`, `test-cases.sh`, the hold file.
  Why: they are already in `line/bin/` and `factory/bin/`, proven on main, and each replaced an LLM decision (section 7 rows 1, 2, 7, 12).
- The CI gate design with its amendments.
  Why: cigate:119-149 fixes the three problems the line keeps hitting (agent noticing a finished run, duplicate gate seats, serial verify queue) with webhooks, pods and a ladder, and the owner endorsed it ("jenkins is free in my k8s cluster with a shared-lib we control", cigate:121).
  Caveat from 5.8 items (h) and (i): two of its pieces (units installed, the `coq/gate` fallback in merge-watch) are specified and not live.
- The coalescing rule for verify (roadmap:324) and the five-rung ladder (cigate:135-139).
- The halt / drain / resume contract and the bring-up DAG (spec17 s-halt at `spec17.xml:291`, s-bringup at `:300`; tickets fd7d, ced5, 8ed9).
  Why: the 2026-10-13 crash restart order was reconstructed by hand and written only in memory (memory herdr-crash-restart-order); the restart must be code.
- The state-root layout (rtplan:103-122) and "scripts live in the project, artifacts outside, documented" (roadmap:136-143).
- The duplicate-audit method: a periodic read-only reviewer pass with a status-code map (audit:28-95).
  Why: it found 16 issues in 9 minutes that the line itself had not noticed; make it a scheduled job, not an owner request.
- The seat lifetime rule "a seat exists only between its input and its output" (bestpractices:92-93, roadmap:205).
- The mechanical patrol probes (blocked text, screen hash, exact-argv0 process count) as library functions for the health reconciler (`C/patrol-tick.sh:54`, `:210`, `:228-237`).
- Rulings-as-records, queue-clear-by-id, and no `/model` in seats as hard constraints (memory notes).
- `route-retry.sh`'s guard design as the model for a reconcile pass: one herdr read per pass, a phantom agent so one free slot clears one entry, and a refusal-only filter (`R/line/bin/route-retry.sh:28-38`, breadcrumb items 1 to 4).
  What it lacks is listed in 6.1: attempt cap, halt flag, lock.

## 9. What to kill

- The architect watches and any per-record copy to an LLM (killed 2026-10-12, retro:21; keep dead).
- The repo as message bus, the records branch, and 3,000-file PRs (killed; rtplan:10).
- The record-bus copier, once nothing reads the checkout `events/` tree.
  Today it still runs from `line/bin` (`ps` 2026-10-14T02:47Z) because `C/patrol-tick.sh:67` and `:103` write to and read the checkout tree and `C/architect-rounds.sh:41` reads it; the audit only moved it into the repo (audit F5, ticket 1637 merged as PR 120, audit:63-64) and did not retire it.
  With one state root and the patrol moved, nothing needs copying; this is an inference from the code, not a plan decision.
- The tester seat (CI gate 5), the merger seat, the verifier seat idea (WO-20261012-72a0 "Verifier seat: a merged record wakes a verifier that checks the merge on main against the ticket's criteria and posts verified or rejected, so no merge waits on the architect", superseded by CI gate 4, audit-rulings:23), the gate-reseat hand work.
  Why: each exists only because a step was not code (lineops:31-42).
- The architect wake on `merged` (`routes.json:15`) and the merger-agent seat on `review.passed` (`:12`) (lineops:36, 42).
- LLM monitors that decide health (the Haiku monitor note stream: 558 notes, 350 idle) (roadmap:200, bestpractices:143-150).
- The 1-minute idle alarm as an alarm.
  Replace with an unseated-record alarm at schedule-to-start over 60 s and a reaper that downs seats when their output record exists (bestpractices:102, 182, 190).
- Architect "rounds" prompts every 1 to 3 minutes and the digest pane (roadmap:211, 216, digest.sh:41); the line should page, not poll the architect.
  Both are already off by order (roadmap:401); keep them off.
- The scripts in `C/` that remain: `patrol-tick.sh`, `watchdog.sh`, `architect-rounds.sh`, `flow-tick.sh` (plus stale copies of aq, digest, flow-table, merge-watch, record-bus, route-retry, seat-queue that `diff -q` shows differ from `line/bin`, so the repo copy is the truth).
  Move the first two into `line/` as units with the dead-man fix, retire the last two (roadmap:136-143; the Roadmap I tickets are partly landed, 5.8 item f).
- Hand-patched queue-clear loops, ledger hand clears, hand merges (roadmap:160, 165, 309, 323).
- The cause-letter workflow (one ticket per incident, 51 so far).
  Replace with a defect record auto-created by the check that found it, batched into a system epic per component (card C31 asks about batching, roadmap:397; no answer recorded).
- Items the audit rulings already approved to cancel or supersede: NATS JetStream ticket 539f superseded by Roadmap L be64 (audit F6, audit-rulings:14), the three duplicate gate-dedup tickets, the two cleanup tickets (audit:31-43).
  The interface-agent chain is the one finding where the rulings file and the owner's current direction may disagree: the rulings keep it because it is Phase 5 of the binding roadmap (audit-rulings:28); whether it survives a rebuild is the owner's call.
- Stale checkout ticket copies and `status: in-progress` residue as a state (audit F9; cause q).
- The `PR file clashes` approach of ruling claims by hand (roadmap:356); compute order from `files:`.

## 10. Open questions for the owner

Only ones that change the design.

1. Is every LLM seat a one-shot Job (input record in, output record out, then gone), including the orchestrator, or does any LLM keep a standing lane?
   The cog wording (roadmap:205, global rules) says Job; SPEC-17 still keeps standing seats (orchestrator, monitor) as "desired state" (spec17 h-desired at `spec17.xml:152`) and lineops:51 keeps "one seat, woken only by a page".
2. Where does a verdict live, state-root records or the forge status?
   Three answers in 24 hours (rtplan:23-26, roadmap:40, cigate:128-149).
   The design needs one source of truth with the other derived.
3. Is the Go scheduler (SPEC-16, "the end state", prio:6) still the engine, or is an off-the-shelf controller or workflow engine to be used?
   bestpractices recommends reconcilers on systemd; the owner brief now says take proven open source.
   This decides whether the 14 SPEC-16 land tickets (roadmap:109, prio:88) and the Go package tickets are carried or killed.
4. Does the product (the game, coq-term) share the line, or is the line frozen to infrastructure until it is self-running?
   Roadmap:396 says game untouched and about two weeks away; no file records the owner's choice.
5. Should herdr remain the host of the line's own processes (belt, patrol, board watch) or only host seats?
   The crash showed one server kills both; the supervision design (spec17 s-supervision U1, `spec17.xml:247`) moves processes to systemd but is unbuilt (5.8).

## 11. Sources

Plans (all under `S/plans/2026/10/`, read on 2026-10-14; line numbers cited are the file's own, confirmed with `cat -n`):
- retro = `20261012222000-retro-architect-flood-and-halt.md` (40 lines; tags 5-8, 10, 14-17, 21, 29-33, 36-40 re-checked).
- roadmap = `20261012212500-roadmap.md` (401 lines).
- rtplan = `20261012210500-runtime-out-of-repo-plan.md` (122 lines).
- runbook = `20261012215500-line-restart-runbook.md` (42 lines).
- prio = `20261013025600-priority-list.md` (93 lines).
- bestpractices = `20261013021500-best-practices-agent-line.md` (260 lines; its source list is in section 10 of that file, web pages dated by the report as 2026-10-13).
- testspeed = `20261013160000-test-speed-design.md` (58 lines).
- cigate = `20261013194800-ci-gate-design.md` (149 lines).
- lineops = `20261014004500-line-ops-are-code-design.md` (89 lines).
- audit = `20261013-duplicate-work-audit.md`; audit-rulings = `20261013235500-duplicate-audit-rulings.md` (34 lines).
- spec17 = `20261013021301-spec17-1-1-0-draft-loops-maintenance-controller.xml` (548 lines; cited as `spec17.xml:NNN`) and `.md`; the accepted SPEC-17 is `R/specs/SPEC-17-orchestrator-and-agent-health.xml`.
- crashbrief = `20261013131747-maintenance-brief-crash-causes.md` (12 lines); the watchdog brief = `20261013023257-maintenance-watchdog-brief.md` (11 lines); also `20261013025139-maintenance-pr86-roles-edit-brief.md`, `20261013162038-brief-sched-worker-2-second-orchestrator.md`.
- Cards: the seven JSON files named in section 3 and 4.1; each was read in full.
- Pointer: `20261014-factory-rebuild-plan.md`.

State and repo (read-only, 2026-10-14):
- `S/crash/README.md`, `S/crash/20261013T033218Z-herdr-stable/` (listing only; the dump was not opened).
- `S/records/2026/10/` (3,338 files on 2026-10-14T02:47Z: 2,850 dated 20261013, 488 dated 20261014; kind counts from filenames), `S/run/patrol/` (finding files).
- `~/.config/systemd/user/herdr-stable.service`, `watchdog.service`, `watchdog.timer`; `systemctl --user show herdr-stable.service -p NRestarts -p MemoryHigh -p MemoryMax -p ActiveEnterTimestamp`; `systemctl --user list-unit-files`; `ps -eo pid,lstart,args` for the running line processes.
- `C/` (route-retry.sh 28 lines, patrol-tick.sh, watchdog.sh, architect-rounds.sh, flow-tick.sh, merge-watch.sh, record-bus.sh, digest.sh, aq.sh, seat-queue.sh), `R/line/bin/` and `R/line/units/`, `R/line/config/hook.json`.
- `R/factory/config/routes.json` lines 12 and 15, `R/factory/config/runner.json`, `R/factory/bin/route.sh:337-341`, `R/factory/bin/claims.sh`, `R/bin/wo-start.sh`, `R/herdr/bin/seat.sh`, `R/herdr/bin/unfreeze.sh`, `R/herdr/config/herdr.json`, `R/herdr/config/herdr.schema.json`, `R/herdr/config/leases.json`, `R/treehouse.toml`, `R/report/loop/loop.sh`, `R/specs/SPEC-17-orchestrator-and-agent-health.xml`.
- Work orders under `R/work-orders/` for 77c0, bf70, 3217, aff2, 3eac, d93a, 7f99, 3dae, 48f2, a1c6, c789, e880, bcba, b6f3, 9b2c and the archived 9c50 (titles and status read from frontmatter).
- `git log` on main in `R` (246 commits; first a5a5880 at 2026-10-10T18:16:43Z; c9b6f9f at 2026-10-14T01:43Z; 3419b86 at 2026-10-14T01:13Z; 96fc609, 17df7c9, 2247679, 3584b1e as cited).
- Memory notes: `~/.claude/projects/-home-luna-projects-coq-jev-herdr-plugin/memory/herdr-crash-restart-order.md`, `three-loops-always.md`, `architect-sends-specs-off.md`, `right-size-agent-models.md`, `architect-queue-clear-by-listed-id.md`, `rulings-gates-check-are-records.md`.
- Other area files for cross-reference: `L01-line-scripts.md` section 6.
- Web: none fetched for L06; the web sources listed inside bestpractices (Kubernetes, Temporal, Step Functions, SRE book and others) are the report's own and were not re-verified here.

Caveats on this file:
- The crash dump and the 77c0 root cause were not analysed; section 5.2 states what the plans know, not a cause.
- The count of 51 lettered causes assumes the lettering ran a to z then aa to ay without gaps; the highest label seen is "ay" (c9b6f9f).
- The gap list from the critic of attempt 1 is closed as follows: retro tags fixed (retro:29 to 33 now match the file), card count corrected to seven, the plans folder listed as 25 files with the pointer included, section 6 now carries script and line for every local wait with an L01 cross-reference per row, route-retry's real loop is stated (30 s, no attempt cap), and section 4.1 gives a per-card line.
  One item cannot be closed from the files: the owner's answer to C31 is not recorded anywhere I could read.
