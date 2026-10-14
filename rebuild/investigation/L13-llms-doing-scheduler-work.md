# L13 - LLMs doing scheduler work

Investigator: R-01 area L13, written 2026-10-14T02:50Z by a Sonnet investigator.
Scope: the architect, orchestrator and acting-orchestrator roles, the prompts the line sends to seats, the scheduler specs, and every decision an LLM makes that a rule, a timer or a state machine could make.
Mode: read-only.
Nothing was run, no pane was touched, no record was written.
Git commit times in this file are converted to UTC (git log prints them at -05:00).
Record times are UTC as stored.

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

The line is declared as "a table plus scripts", but its last hop is almost always "type a sentence into an LLM seat and wait for it to do a mechanical step".
Eleven roles exist in roles/*.json, and of them only worker, spec-author and reviewer do work that needs judgement.
The architect, orchestrator, monitor, compliance-officer, tester, merger and interface-agent roles, plus two acting orchestrators (sched-worker-1 and sched-worker-2) that are defined only by prompt briefs outside the repository, each perform steps that are a pure function of records, exit codes or the process table.
Between 2026-10-13T00:42Z and 2026-10-14T02:34Z the state root holds 3334 records.
In that window an LLM seat, not a script, posted 43 of 92 merged 200 records, all 66 verified 201 records and 18 rejected 422 records.
This file inventories every such decision, prices it from the record store and the owner's retros, and says which rule replaces it.

## 3. Where it lives

- Roles and playbooks: /home/luna/projects/coq-jev-herdr-plugin/roles/*.json (11 files) and playbooks/*.md (rendered from them by roles/bin/render-playbook.sh).
- The routing table and runner: factory/config/routes.json, factory/bin/route.sh, factory/config/runner.json.
- The prompts the line types into seats: roles/bin/brief.sh, factory/bin/route.sh (act_primary), herdr/bin/seat.sh (nudge_text), herdr/bin/patrolwatch.sh, turnwatch.sh, recwatch.sh, line/bin/digest.sh, line/bin/merge-watch.sh, factory/bin/policy.sh, herdr/bin/break-glass-lib.sh, herdr/bin/unfreeze.sh, line/bin/board.sh.
- Watches still declared in herdr/config/monitors.json slots 4.1.1 (turnwatch) and 4.1.2 (recwatch).
- Scheduler specs: specs/scheduler/SPEC-16-scheduler-overview.xml and SPEC-16.G-config-schema.xml; the Go skeleton in scheduler/ (3804 lines, 2336 of them generated protobuf); specs/SPEC-17-orchestrator-and-agent-health.xml (63 KB).
- Acting-orchestrator duties: ~/.local/state/coq/coq-jev-herdr-plugin/plans/2026/10/20261013162038-brief-sched-worker-2-second-orchestrator.md and the priority list, not any file in the repository.
- Owner retros read for cost: plans/2026/10/20261012222000-retro-architect-flood-and-halt.md, 20261013-duplicate-work-audit.md, 20261013235500-duplicate-audit-rulings.md, 20261013021500-best-practices-agent-line.md, 20261013025600-priority-list.md, 20261013194800-ci-gate-design.md, 20261014004500-line-ops-are-code-design.md, 20261013131747-maintenance-brief-crash-causes.md, 20261012212500-roadmap.md.
- Evidence store: ~/.local/state/coq/coq-jev-herdr-plugin/records/2026/10/ (3334 JSON records) and run/patrol/ (489 files).
- GitHub: open issues 76, 77, 78 (and 67, 72, 73) on the repository; open PR 35 (design spec v2.0).

## 4. What works

- The routing core is already a rules engine.
  factory/bin/route.sh:2-4 states that it applies the table and nothing else, and factory/config/routes.json holds 33 first-match rows (routes.json:6-36).
- Rule scripts exist for most of what the LLM seats are still asked to do.
  - gate.sh decides head_current and heads_match from records and git (factory/bin/gate.sh:2-13).
  - claims.sh refuses two tickets on one file (factory/bin/claims.sh:2-14).
  - suites.sh plans the test suites from the diff (factory/bin/suites.sh).
  - merge.sh squash-merges when review.passed 201 and test.passed 201 name the newest head, posts merged 200, runs cleanup, and "the decision is a function of records and the head, so no seat makes it" (line/bin/merge.sh:1-5).
  - verify-main.sh decides verified or rejected from suite exit codes (line/bin/verify-main.sh:1-7).
  - policy.sh gives an unanswered escalation a deadline and a default answer (factory/config/policies.json:14, deadline_seconds 1800).
  - flow-table.sh computes the bottleneck from records "by code, no model judgement" (line/bin/flow-table.sh:5-7).
  - board.sh gives lanes, pull leases and a nudge that carries no content (line/bin/board.sh:1-13, line/config/board.json: lease_seconds 1800, nudge_seconds 60).
- The retry ladder (3 attempts, then a record) is implemented in code in merge.sh (MERGE_RETRIES, line/bin/merge.sh:36-37) and verify-main.sh (exit 4 after three failed steps).
- CI as a gate has landed in part.
  WO-20261013-8573 (CI gate 1, test image and pods, PR 156), WO-20261013-ab25 (CI gate 2, coqGate() posts coq/gate, PR 179) and WO-20261013-ca2a (CI gate 6, webhook listener, PR 177) are done (work-orders frontmatter, status done).
- The designs agree on the principle in four places: "No LLM in routing, health, retry or cleanup" (SPEC-16 l-llm, specs/scheduler/SPEC-16-scheduler-overview.xml:40), "LLMs do work and rulings only; no LLM sits in routing, health, retry or cleanup" (best-practices file, section 9 item 12, line 205), "An agent exists only for judgement: writing code and judging a diff" (line-ops-are-code design, Rule), and AGENTS.md "Law: agents are never gates" (AGENTS.md:125-132).
- A seat that is told to only run listed commands behaves: after WO-20261013-b6f3 (cause z) the tester brief carries the exact plan (roles/bin/brief.sh:49).

## 5. What broke and why

Findings are ordered by weight.
All counts come from the 3334 records in the state root (2026-10-13T00:42Z to 2026-10-14T02:34Z) unless a document is named.

### 5.1 Three designs put the LLM in three different places, and none is built

- SPEC-16 (accepted as "the engine and end state", ruling 2026-10-13T02:50Z) says no LLM in routing, health, retry or cleanup (SPEC-16 l-llm, line 40, and p-end, line 31).
- SPEC-17 s-orchestrator (specs/SPEC-17-orchestrator-and-agent-health.xml:84-100) hands seven line operations O1 to O7 to an LLM orchestrator seat "by rule": refused seat, finished seat, cleanup, verify outcome, capacity, stale state, re-route.
- The line-ops-are-code draft of 2026-10-14T00:38Z reverses SPEC-17: "An agent exists only for judgement" and "The merger seat, the tester seat, the gate re-seating hand work, the architect wake on merged, and most of both orchestrator seats" retire.
- Build state: scheduler/internal/cli registers one subcommand, version (scheduler/internal/cli/version.go); no loop, reconciler or executor exists in Go.
  Of the SPEC-16 tickets, 28 are ready, 11 done, 1 in progress (work-orders frontmatter count).
- The retiring tickets are all ready and unstarted: WO-20261014-d93a (R1 routes run action), WO-20261014-7f99 (R2 result records down their seat), WO-20261014-3dae (R3 start loop), WO-20261013-3217 (CI gate 3), WO-20261013-aff2 (CI gate 4), WO-20261013-3eac (CI gate 5), WO-20261013-48f2 (after-merge.sh), WO-20261013-612d (merged route row).
- Why it matters: the build of the replacement must flow through the very LLM-driven line it replaces, so the line is its own bottleneck.

### 5.2 The acting orchestrators are the real scheduler, and they are defined outside the repository

- roles/orchestrator.json:70-75 lists four duties (validate, enqueue, route, escalate).
  The seats actually working as orchestrator (sched-worker-1, sched-worker-2) take their lanes from a brief in the plans tree: merges, starting tickets, seating gates, patrol findings, downs, cleanup, verify-main (20261013162038-brief-sched-worker-2-second-orchestrator.md lines 17-24).
- Output of those two seats in the state root: 96 and 441 records.
  - Merges: of 92 merged 200 records, merge-script posted 44, sched-worker-1 posted 43 (38 notes say "hand merge" or "hand merged"), the merger seat posted 5.
  - Verify: sched-worker-2 posted all 66 verified 201, 19 verified 200, 18 rejected 422, 10 pr.opened 200 and 8 work.started 200.
- Two priority-list lines name the cost: "The orchestrator is one LLM seat; blocked findings sat 6 minutes unactioned (xpg8e)" (priority-list.md:72) and "Orchestrator downs finished seats", "Orchestrator cleans up and verifies main after every merge" in the hand-fix table (priority-list.md:81,83).
- The owner's reaction at 2026-10-13T16:19Z, message m-20261013161912217-3d6g0 ("15 seats available, why idle"), produced three max_seats edits by hand: roles/orchestrator.json 1 to 2, roles/reviewer.json 2 to 4, roles/worker.json 4 to 6 (breadcrumbs at roles/orchestrator.json:87, reviewer.json:92, worker.json:105).
  The idle capacity was a missing start loop (R3, unbuilt), not a missing cap.

### 5.3 Wake-by-typing is the dispatch mechanism and has no acknowledgement

- Every work order to a seat is `herdr agent prompt <seat> "<text>"` typed into a TUI (factory/bin/route.sh:205 and 223; line/bin/merge-watch.sh:84; herdr/bin/patrolwatch.sh:35; line/bin/digest.sh:54).
- SPEC-16 p-wakes says it plainly: "a wake is one herdr prompt; when it fails the record becomes a 500 and nothing tries again, and a prompt typed into a seat inside its quiet window is lost with the compaction" (specs/scheduler/SPEC-16-scheduler-overview.xml:26, id p-wakes).
- Open issue 78: a merge wake sent to the one busy merger is lost, the belt downs the merger after its gate record and the queued PR is never merged.
- Open issue 76: route.sh never retries a failed route.
  Open issue 73: seat.sh promises a queue that does not exist.
  Open issue 67: route.sh waits on seat.sh, which waits up to 180 s for a guard ACK line, so every record behind a seat-up waits.
- The route runner is serial and blocks on each seat-up (factory/bin/route.sh header lines 95-96: "the runner is serial, so a bring-up (prompt 15 s, agent start 30 s, the brief) holds every later record").

### 5.4 The router addresses LLM seats that do not exist, 786 times

Of 799 note-500 records, 786 are written by the route runner.
Breakdown by cause (the first id of each class is the evidence):

- 394 "no route for <kind> <code>": the table had no row for records the LLM seats themselves write.
  379 of them were before row fixes of 2026-10-13T22:59Z (commit b87afe2); 200 were for note 200, which sched-worker-2 writes as its report notes (first id 20261013T153025Z-500-w3pdo).
  Only 15 occur after the fix.
  This is a rule gap, but the gap was created by an LLM seat free-writing record kinds.
- 89 plus 43 seat.sh refusals "ticket has no branch yet" or "no ticket under work-orders" (first ids 20261013T153056Z-500-44yof, 20261013T164509Z-500-d8ul2): state bugs in code, not LLM decisions.
- 88 "herdr agent prompt architect-wo-<id> failed" on every merged 200: routes.json:15 wakes a per-ticket architect seat that is never created (first id 20261013T153015Z-500-w7v04, last 2026-10-14T01:59Z).
- 75 "herdr agent prompt interface failed" on verified 201: routes.json:17 notifies an interface-agent seat that is not running (first id 20261013T162455Z-500-9t1a6).
- 45 other prompts to seats that were gone; 17 treehouse lease failures; 5 "seat needs a ticket".
- Disagreement with the brief's diagnosis, stated plainly: this class is not "agents driving".
  It is the system side being wrong about which seats exist.
  A system-driven rebuild that keeps seat-per-ticket addressing and typed prompts reproduces it.

### 5.5 The architect became a gate, more than once

- 2026-10-12 retro: "The architect built a watch that copied everything to itself, which made it the hub of the line" and "had become the gate for carries, verifies, conflicts, scheduler forwarding, block rulings and records" (retro-architect-flood-and-halt.md lines 13-17).
  Lesson in the retro: "An agent that receives a copy of everything becomes the bottleneck" (line 37).
- Cause was a script fanning out to an LLM, not an LLM choosing to do mechanical work: the fix that worked was removing the fan-out, and the architect then received a 30-minute digest.
- The two flooding watches are still declared in committed config: herdr/config/monitors.json slots 4.1.1 turnwatch and 4.1.2 recwatch, and herdr/config/herdr.json watches.record_kinds.
  herdr/bin/bringup.sh (lines 84-119) repairs any reserved pane that monitors.sh health reports FAILED by monitors.sh take, so a bring-up or supervisor cycle can re-arm both unless the runtime halt flag is set.
  Whether they run now was not checked (herdr is out of bounds); the owner memory note says they were stopped by hand, which is runtime state, not config.
- 238 of 238 non-draft tickets carry approval via "override" (work-orders frontmatter count); none was approved through the owner page.
  roles/architect.json:87 makes approval "yours alone".
  The approval step adds a turn per ticket and decides nothing a lint does not (see D01).

### 5.6 Gate seats cost latency and a failure class of their own

- Seat-ups in 26 hours: tester 119, reviewer 110, worker 81, merger 14 (kind seat.up counts by seat prefix).
- Latency between records, first record of each kind per PR (n and medians approximate, re-pushes inflate them): pr.opened to test.passed median 18.7 min (n 52, p90 48.8); test.passed to review.passed median 6.8 min (n 62, p90 47.9); review.passed to merged median 7.0 min (n 68, p90 34.2); merged to verified 201 median 28.1 min (n 65, p90 65.5).
- The owner's own diagnosis in the CI gate design: "Models are bad at waiting: Haiku testers polled, forgot, or waited on finished shells, with stalls of 9 to 14 minutes on a lint that takes one (records 2026-10-13 18:56Z to 19:44Z)" (ci-gate-design.md Problem).
- The merger seat took about fifteen minutes per merge "though the merge is mechanical" (breadcrumb in line/bin/merge.sh, ticket WO-20261013-f6ae, owner 03:02Z "I hate bottlenecks").
- routes.json:8, :9 and :12 still seat a tester, a reviewer and a merger; the retiring tickets above are unmerged.

### 5.7 Monitoring is an LLM chain with relays

- The patrol brief makes a Haiku monitor read 20 lines of every pane each minute, post a record, prompt sched-worker-1 or sched-worker-2, and "if the same finding is still open 5 minutes later, prompt architect" (run/patrol-brief.md).
  Result in run/patrol/: 172 finding.idle files plus 330-odd screen snapshots.
- The compliance officer role replaced it with 13 finding codes, each a pattern a script can test: a menu string, a denial string, an "API Error" last line, an unchanged pane for ten minutes, a process count by argv0 (playbooks/compliance-officer.md steps 5-10, 18-30).
  Its own playbook says the closed list exists because model judgement drifted ("trouble that is not on the list is not reported").
- WO-20261013 cause (b): "The dead man's switch never fired because the patrol's own notes counted as records" (maintenance-brief-crash-causes.md line 9).
  Cause (e): the patrol saw 8 system processes dead 56 times during the outage but only queued them for a dead architect (same file, line 11).

### 5.8 Duplicate work from LLM-cut tickets

The duplicate-work audit (20261013-duplicate-work-audit.md) found sixteen findings, nine of them duplicates or stale scope, including three tickets for one gate-seat dedup (F1), two post-merge cleanup scripts (F2), four owners for "verify main after a merge" (F3), a record bus built twice (F5), and a NATS ticket against a locked decision (F6).
Of the last 101 commits to main (since 2026-10-13T00:00Z local), 10 are tickets-only "cut" or sweep PRs and 34 mention "cause <letter>", the fix-the-line pattern.

## 6. Waits, polls, sleeps and leases

Only those on LLM-facing paths are listed, with their bound.

- Route runner poll: 10 s (factory/config/runner.json:3), belt stale at 60 s (runner.json:15); the runner is serial and blocks on each seat.sh call.
- Seat bring-up: prompt wait 15 s (herdr/config/herdr.json:7), agent start wait 30 s (herdr.json:8), guard ACK nudge wait 15 s (herdr.json:13; was 180 s until WO-20261013-7af7, commit 3419b86), retire poll 10 s (herdr.json:12).
- Prompt to a seat: no acknowledgement, no receipt; failure is a note 500 and no retry (route.sh:223).
- route-retry.sh: pass every 30 s (line/bin/route-retry.sh:55), retries only the max_seats refusal.
- seat-queue.sh: waits for the ticket's branch on origin every 15 s and retries seat.sh every 60 s, unbounded (line/bin/seat-queue.sh:25-28).
- Patrol tick: 60 s (herdr/config/herdr.json:69); a tick is skipped while the officer is busy (patrolwatch.sh:33-34), so a hung officer is silent.
- Merge watch: 60 s (line/bin/merge-watch.sh:41), 7-day backstop, prompts the acting orchestrator once per batch.
- Architect digest: 1800 s (line/bin/digest.sh:35; line/config/board.json digest_seconds 1800).
- Standing policy: deadline 1800 s for a blocked 423, one default per ticket (factory/config/policies.json:14, limit_per_ticket 1); poll 15 s.
- Flow watch: poll 15 s, stall 90 s, busy grace 1800 s (factory/config/flow.json:3-5).
- Board: lease 1800 s, nudge 60 s (line/config/board.json).
- Idle watch on a seat: none that downs it; the owner rule is "no agent sits idle for more than one minute" and the patrol only reports (compliance-officer.md step 17 ends the turn, never acts).
- Capacity wait: a refused seat at max_agents 8 (herdr.json:18) waits for route-retry or a human; records show 21 note 429 refusals ("9 agents live, max_agents 8", first id 20261013T181000Z-429-vnwzh).
- Every timer above is a hand-set constant in config; none is derived from a queue depth or a measured duration.

## 7. Decisions an LLM makes that a rule could make

Format: id, who, where, the rule that replaces it, and what it costs now.

### Architect

- D01 Approve a ticket.
  Where: roles/architect.json:87 ("approval is yours alone"); work-order.sh approve --reason 'architect: ...'.
  Rule: approve when make lint passes, claims.sh set has a files field, graph.sh find shows no contradicted DEC node, every acceptance criterion has an evidence method, and the DAG input and output are declared; the ticket frontmatter already carries the data.
  Cost: 238 of 238 approvals are overrides, so the step is a stamp and a turn.
- D02 Choose model and runtime per ticket.
  Where: roles/architect.json:33-36 and must line 88; spec-author.json purpose already keys the role off the files touched.
  Rule: a table from ticket type and files globs to role, model and effort in config; owner memory rule "right-size agent models" is already such a table in prose.
- D03 Verify every 201 against the acceptance criteria before "verified".
  Where: roles/architect.json:90.
  Rule: verify-main.sh and CI gate 4 (WO-20261013-aff2) post verified or rejected from exit codes; criteria that are not machine-checkable become the reviewer's job, once.
  Cost: 66 verified 201 were posted by an LLM seat, median 28 min after merge.
- D04 Split or re-scope on a worker 423.
  Where: roles/architect.json:89.
  Rule: keep as judgement but trigger it only after the third attempt; the first two go to policy.sh default (already a rule, factory/config/policies.json).
- D05 Wake on merged to verify.
  Where: factory/config/routes.json:15.
  Rule: delete; run verify-main.sh or the main gate on the merged record.
  Cost: 88 failed prompts to a seat that does not exist.

### Orchestrator role

- D06 Validate a request against its schema (roles/orchestrator.json:71): JSON-schema validation in the intake script, exit 3 naming the key.
- D07 Enqueue with a priority (orchestrator.json:72): already a route row (routes.json:6) and queue.sh.
- D08 Route factory records through the decision table (orchestrator.json:73): route.sh already does it; the role duplicates the runner.
- D09 Second 423 becomes owner_needed (orchestrator.json:74): already routes.json:20-21.

### Acting orchestrators (sched-worker-1, sched-worker-2)

- D10 Start the next ready ticket.
  Where: prompts to sched-worker-1; line/bin/start-tickets.sh is the mechanism.
  Rule: R3 start loop (WO-20261014-3dae): ready, depends_on done, claims.sh start free, slot free, system slots reserved.
  Cost: "15 seats available, why idle" (owner 2026-10-13T16:19Z) and three hand cap edits.
- D11 Merge a PR with both gate records.
  Where: sched-worker-1.
  Rule: merge.sh on review.passed or coq/gate success (R1 WO-20261014-d93a, CI gate 3 WO-20261013-3217).
  Cost: 43 of 92 merges by hand even though merge.sh existed from 2026-10-13T14:53Z.
- D12 Verify main after a merge and post verified or rejected.
  Where: sched-worker-2 brief line 24; 178 verify-flavoured records.
  Rule: verify-main.sh exit code, or the main gate (WO-20261013-aff2).
- D13 Post-merge cleanup: delete branch, down the ticket's seats, return the slot.
  Where: brief line 24; merge.sh now does the branch and slot part (cause ag, commit 17df7c9).
  Rule: after-merge.sh on merged (WO-20261013-48f2).
- D14 Down a seat that posted its result.
  Where: brief line 22; routes.json already has a `down` key on gate rows.
  Rule: enforce `down` on every result record (R2, WO-20261014-7f99); report survivors as a defect.
- D15 Re-seat a gate that did not appear, or re-run a refused seat.
  Where: orchestrator hand work; route-retry.sh covers only max_seats.
  Rule: level-triggered reconciler: open record with no seat and no result gets a seat on the next tick (best-practices file section 2.5).

### Monitor, patrol, compliance officer

- D16 Prompt a waiting seat on status change (monitor.json step 2).
  Rule: board.sh nudge, no content (line/config/board.json nudge_seconds 60).
- D17 Read panes for a hung, refused, waiting or looping seat (compliance-officer.md steps 4-10).
  Rule: per-seat checks C1 to C5 of SPEC-17 s-health: pane text hash unchanged for N minutes, regexes for the menu, denial and API-error strings, `ps` argv0 counts.
  Cost: a Haiku read of every pane each minute; 172 idle findings, 5 io, 1 proc in run/patrol/.
- D18 Escalate a finding up the chain (patrol-brief.md): a deterministic ladder: record, lane, owner card after three sightings (cause e in maintenance-brief-crash-causes.md).

### Gate seats

- D19 Tester: run the printed commands in order and report the exit codes (roles/tester.json must lines 3-8; brief.sh:49).
  Rule: CI pods (WO-20261013-ab25) post coq/gate; retire the role (WO-20261013-3eac).
- D20 Merger: run the merge, clean up, post merged (roles/merger.json must).
  Rule: merge.sh; the seat remains only for conflict resolution, which is already a worker 409 route (routes.json:16).
- D21 Reviewer, mechanical half: files stay in the ticket's paths, no em dash, contents list present, UTC, config not literals (roles/reviewer.json must lines 3-5).
  Rule: gate.sh pr-files plus lint rules; the semantic half (acceptance criteria evidenced, design fit) stays an LLM judgement.
- D22 Worker close-out chain: evidence, retro note, commit, push, gh pr create, work-order submit, done, archive move, post pr.opened (roles/worker.json must last line).
  Rule: a `close-out.sh` triggered by the worker's "ready" record; the LLM's turn ends at the commit.
- D23 Interface agent relays a factory record to a one-line page reply (roles/interface-agent.json).
  Rule: a template per record kind posted by a script; routes.json:17 currently prompts a seat that is absent (75 failures).

### Other prompts the line types

- D24 Break-glass instruction (break-glass-lib.sh:166) is an intended LLM step; keep, it is owner-gated.
- D25 Compaction prompt (bin/step.sh:54) and guard resume (unfreeze.sh:76): rule-driven already, correct to leave to the guard.

## 8. What to carry forward

- The routes table as data, first match wins, a record with no row is loud (routes.json, route.sh).
  Why: it is the Argo/Make-like declarative core the owner likes, and it already exists.
- Exit-code deciders: gate.sh, claims.sh, suites.sh, merge.sh, verify-main.sh.
  Why: each already replaces a seat; wire them as route actions instead of seating.
- The `run` action proposed in the line-ops-are-code design (R1): `{ do: run, cmd: ... }` executed under the retry ladder with the exit code mapped to a record.
- The closed list of 13 compliance codes as a script's pattern list, with GOOD and NEVER cases as its tests.
- SPEC-17 s-health checks C1 to C5 and the s-codes status map as the reconciler spec.
- board.sh pull model with leases and a content-free nudge.
- policy.sh: deadline plus default answer, so an unanswered escalation never waits.
- The best-practices file (section 9, twelve rules) as the architecture brief: level-triggered reconcilers, seats as Jobs, one record root, dead-man switch, LLMs only in the worker slot.
- Records with a status code and one writer (event.sh), because every investigation above was possible only because the records were typed and dated.
- Breadcrumb discipline: it made this inventory cheap; the cost is that the breadcrumb prose is longer than the code it explains.

## 9. What to kill

- Acting-orchestrator LLM seats (sched-worker-1, sched-worker-2) and the orchestrator role as a routing hop: they duplicate route.sh and cost 537 records and 43 hand merges.
- The architect approve step and the architect "verify every 201" step: replace with lint-based approval (D01) and exit-code verification (D03).
- The merger seat and the tester seat (routes.json:8, :12), once CI gate 3, 4 and 5 and R1 land.
- The monitor (Haiku) and compliance-officer seats as readers of panes: replace with scripted C1 to C5 probes.
- Typed-prompt dispatch as the only wake path, and per-ticket seat-name addressing (architect-wo-<id>, interface): both caused 163 route failures.
- turnwatch.sh, recwatch.sh, digest.sh, merge-watch.sh as LLM-facing fan-outs, and their reserved slots in monitors.json (4.1.1, 4.1.2).
- SPEC-17 s-orchestrator O1 to O7 as LLM duties: keep the seven operations, delete the seat that performs them.
- The "hand fix, then a note" pattern: AGENTS.md Law "three loops" already says a hand fix without a ticket is a defect, which is evidence the pattern is common.

## 10. Open questions for the owner

1. Is a gate that needs judgement (the reviewer, ticket splitting after a third failure) still a long-lived TUI seat woken by a typed prompt, or an ephemeral job that receives its brief and returns one record (for example a headless Claude run in a pod)?
   This changes the control plane from "panes and typed prompts" to "jobs and records".
2. Should the architect remain an interactive seat at all in the steady state, or should rulings be owner cards with policy.sh defaults, with the architect reserved for design work sent to a spec-author seat?
3. Is the reviewer's pass a required gate or an advisory check beside CI?
   Records show 85 review.passed and 25 review.changes in 26 hours; whether those 25 were substantive was not measured.

## 11. Sources

All local, read 2026-10-14T02:00Z to 02:50Z, no web sources.

Repository (/home/luna/projects/coq-jev-herdr-plugin, main at ae0140e, 2026-10-14T01:59Z):
- roles/architect.json, orchestrator.json, merger.json, monitor.json, reviewer.json, tester.json, worker.json, spec-author.json, interface-agent.json, player.json, compliance-officer.json; roles/bin/brief.sh.
- playbooks/architect.md, orchestrator.md, merger.md, monitor.md, compliance-officer.md.
- factory/config/routes.json, runner.json, policies.json, flow.json; factory/bin/route.sh, gate.sh, claims.sh, policy.sh.
- line/bin/merge.sh, merge-watch.sh, digest.sh, aq.sh, board.sh, start-tickets.sh, seat-queue.sh, route-retry.sh, flow-table.sh, verify-main.sh; line/config/board.json.
- herdr/bin/patrolwatch.sh, turnwatch.sh, recwatch.sh, monitors.sh, bringup.sh, seat.sh, break-glass-lib.sh, unfreeze.sh; herdr/config/herdr.json, monitors.json.
- specs/SPEC-17-orchestrator-and-agent-health.xml (sections s-chain, s-orchestrator, s-health, s-inventory); specs/scheduler/SPEC-16-scheduler-overview.xml (l-llm, p-wakes, p-end); scheduler/internal/cli/*.go.
- AGENTS.md laws: agents are never gates, three loops, chain of command.
- work-orders/**/*.md frontmatter (263 tickets): approval.via counts; statuses of d93a, 7f99, 3dae, 3217, aff2, 3eac, 48f2, 612d, ca2a, ab25, 8573.
- GitHub issues 58 to 78 (gh issue list, 2026-10-14); open PR 35.
- Commit ids: 3419b86, 17df7c9, b87afe2, ae0140e, 5ad1996.

State root (/home/luna/.local/state/coq/coq-jev-herdr-plugin):
- records/2026/10/*.json, 3334 files, 2026-10-13T00:42:27Z to 2026-10-14T02:34:02Z (counts computed by a read-only script).
  Cited ids: 20261013T153025Z-500-w3pdo, 20261013T153056Z-500-44yof, 20261013T164509Z-500-d8ul2, 20261013T153015Z-500-w7v04, 20261013T162455Z-500-9t1a6, 20261013T181000Z-429-vnwzh, 20261013T155804Z-200-y1zy9.
- run/patrol/ (489 files), run/patrol-brief.md, run/README.md.
- plans/2026/10/: 20261012222000-retro-architect-flood-and-halt.md, 20261013-duplicate-work-audit.md, 20261013235500-duplicate-audit-rulings.md, 20261013021500-best-practices-agent-line.md, 20261013025600-priority-list.md, 20261013194800-ci-gate-design.md, 20261014004500-line-ops-are-code-design.md, 20261013131747-maintenance-brief-crash-causes.md, 20261013162038-brief-sched-worker-2-second-orchestrator.md, 20261012212500-roadmap.md.
- Owner message ids quoted inside those files: m-20261013161912217-3d6g0 (2026-10-13T16:19Z), m-20261013194434026-yz0ob (19:44Z).
