# 00 - Inventory: every factory job, what exists, what to do

Lead deliverable of step R-01 of the Factory Rebuild investigation.
Finished 2026-10-14T03:17Z (UTC) by the merge seat; revised 2026-10-14T03:45Z to close the completeness critic's gaps (rows J27 to J30, sections 4 and 5 added).
One row per factory job, for the owner and the architect to go through row by row.
Area files are cited by id (L01 is `L01-line-scripts.md`, and so on); RC numbers are in `01-ROOT-CAUSES.md` and D numbers in `03-DECISIONS.md`.

## Contents

1. Recommendation codes
2. The table
3. Row notes
4. LLM decisions mapped to jobs (L13 D01 to D25)
5. Build items named by this inventory (BI01 to BI09)
6. Sources

## 1. Recommendation codes

| Code | Meaning | Who acts |
| --- | --- | --- |
| KEEP | Works and is evidenced; carry forward unchanged | Nobody; it moves into the new design as is |
| WIRE | The code exists and is tested; it has no trigger; give it one | The rebuild build tickets |
| BUILD | Small new code in the rebuild, specified by the design | The rebuild build tickets |
| ADOPT | Take a shelf tool or field pattern in place of owner code | The rebuild design, after the named decision |
| KILL | Delete or retire; the evidence says it costs more than it gives | The rebuild cleanup ticket |
| DECIDE | Blocked on an owner decision in `03-DECISIONS.md` | Owner, one card at a time |

A row may carry two codes, for example WIRE plus KILL, when one part is kept and another removed.
In the Evidence column, `s5` means section 5 of the cited area file and `F3` means its finding F3.

## 2. The table

| Job | What the owner built | What the shelf has | What the field does | Recommendation | Evidence |
| --- | --- | --- | --- | --- | --- |
| J01 Intake (owner request to work) | Bearings messages typed into the architect's pane; cards only from `make ask` by an agent | Argo `suspend` with resume inputs; tracker states | Slack, tracker or issue starts a session; a daemon polls the tracker (Symphony, Shopify River) | DECIDE D12; BUILD message routing by rule; KILL agent-only reader | L08 s5 items 1, 3; S01 s8; I01 s4.1 |
| J02 Design and spec | 10 XML specs, 109 graph nodes, roadmap, SPEC-17 inventory; lint for spec XML; designs rewritten after incidents | none needed | Validation contract written before work (Factory); small AGENTS.md as a map (OpenAI) | KEEP spec toolchain and SPEC-17 H01 to H26 as acceptance; DECIDE D14, D24 (repo spec book is the truth, Drive gets published copies); KILL phantom and stub specs | L03 s4.2, 5.1, 5.4, 9; I01 s4.2 |
| J03 Ticket cut and approval | `work-order` skill, cut PRs, approval stamp (238 of 238 overrides), carry branches | none | LLM may decompose a goal; system validates and schedules (Factory, Cognition, Cursor) | DECIDE D16, D04; BUILD validator approval (acceptance run on main, files declared); KILL Lavish approve clause and cut PRs | L11 F3, F4; L05 s5, 9; L09 s7; I01 s5 |
| J04 Ordering and start (which ticket runs next) | `start-tickets.sh` typed by an LLM; `claims.sh` file-overlap check; `queue.sh dequeue` unused; four-in-flight cap is prose | Argo semaphores and parallelism; Kubernetes Job; Kueue (unsupported on 1.32) | Daemon dispatches eligible work under a concurrency cap each tick (Symphony); tracker order, no LLM | WIRE `claims.sh` and `wo-start.sh` into the reconciler (D01 B); KEEP claims; KILL hand start loop | L01 F12; L05 s5 item 12; L13 D10; S02 s8; I03 s7 |
| J05 Routing and wake | `routes.json` first-match table plus claim ledger; wake is `herdr agent prompt` to a derived name; 391 failures | JetStream pull consumers; Argo Events sensors | Doorbell versus mail: wake carries a lane and count, work is pulled; reconcile before dispatch | KEEP table and ledger; BUILD address check and bounded retry in the reconciler; KILL typed-prompt wake and architect or interface rows | L01 F1, F2, s8, s9; S03 F3, s8; I03 F3 |
| J06 Seat bring-up | `seat.sh` 848 lines: shell prompt wait, typed env line, trust file, ACK nudge, session wait, serial inside the belt | `claude -p`, `claude --bg`, Agent SDK; Agent Sandbox CRD | Disposable sandbox per task, about 10 s to ready (Stripe); harness starts a run, no typing | DECIDE D02; ADOPT headless launcher; KILL nudge, trust writer, typed brief | S04 s5, 8, 9; L04 s5.5; L11 F10 |
| J07 Seat work (the worker contract) | Interactive TUI; role JSON with prose `must`; result self-posted via `event.sh` | `--json-schema`, `--max-turns`, `--max-budget-usd`, `ResultMessage`; mini-swe-agent limits | Harness returns result, cost, turns, terminal state; limits enforced in launcher | ADOPT seat result schema returned by harness; KEEP role files as the render source | S04 s4.1, 8; I02 s4.7; L09 s8 |
| J08 Test gate | Tester seats polling panes (9 to 14 min stalls); `suites.sh` diff planner; CI gate `coqGate()` merged but never run | Kubernetes Job `podFailurePolicy`; Argo `retryStrategy`; Jenkins pods | Deterministic verifiers before the PR; CI as a machine verdict | WIRE CI gate (D07 A); KEEP planner, pod spec, ladder; KILL tester seat (D11) | L07 s4, 5, 8; S02 B1 to B7; L06 s5.4 |
| J09 Review gate | Reviewer seat; mechanical half (paths, em dash, contents) done by an LLM | LLM judge after verifiers (Spotify) | Clean-context reviewer sees the diff only (Cognition) | KEEP reviewer for semantics as one-shot run; BUILD mechanical checks as lint and `gate.sh pr-files` | L13 D21; I02 s4.2; L11 s3.2 |
| J10 Merge | `merge.sh`: records plus head, 3 retries, `--match-head-commit`, hold file; no caller; 43 of 92 merges by an LLM by hand | GitHub branch protection required checks; Argo mutex | Deterministic land step; global-lock merge queue is an open question in the field | WIRE `merge.sh` (D01 B); DECIDE D05 (key on `coq/gate`); KILL merger seat | L05 s4, 5 item 11; L13 s5.2; I01 s4.2 |
| J11 Verify main and post-merge cleanup | `verify-main.sh` with coalescing and hold file; cleanup inside `merge.sh`; both triggered by LLM prompts | Argo exit hooks; CI on push to main | Post-merge and pre-deploy tests (Anthropic) | WIRE on the merged record or CI on main (D05, D07); KILL architect wake on merged | L01 F4; L13 D12, D13; L06 s7 |
| J12 Retry and escalation | Declared three times (3, 5, 3), enforced nowhere in the runner; `route-retry.sh` greps prose; standing policies with deadline and default | Argo `retryStrategy`; Kubernetes `backoffLimit`; JetStream max deliver | Bounded retry then a record or a human; no field-wide count; owner rule is 3 | BUILD one retry key read by the reconciler; KEEP `policy.sh` defaults; KILL `route-retry.sh` | L01 F2; L06 s6.1; I02 s7; S01 s4 |
| J13 State: record log | One file per record, exclusive-create writes, schema with status code map | Postgres append-only log (Shopify River) | Append-only session log outside the sandbox | KEEP; KILL repo copy and `record-bus.sh`; BUILD the record contract in J29 | L02 s4, 8, 9; I01 s4.2 |
| J14 State: tickets, seats, leases, halt | Status in git front matter; legacy and stray state roots; dead seat records; unenforced slot TTL; four halt flags | SQLite WAL with atomic claim; etcd via operator | One authoritative store; tracker as truth (Symphony); Gas Town's fix was one store | DECIDE D04; BUILD one store and one halt flag; KILL legacy root and copies | L02 s5 items 1 to 8; S03 s8 item 6; I02 s5.3 |
| J15 Queue and leases | `queue.sh` (racy, no caller), `board.sh` (correct, unused), `aq.sh`; `seat-queue.sh` unbounded loops | JetStream; SQLite; OpenHands lease with pid probe; Optio CAS lease | Lease with renew at a third of its length; failed read is its own state | KEEP `board.sh` contract; DECIDE D10; KILL `queue.sh`, `seat-queue.sh` | S03 F1, F2, s8 item 4; S04 s8 item 7; I03 s6 |
| J16 Monitoring and health | 36 monitor panes; Haiku monitor and compliance officer reading screens; mechanical probes in `patrol-tick.sh` (outside the repo) | herdr `events.subscribe`, `pane.report_agent`; OpenHands stuck detector | Stall timeout per run, kill and requeue (Symphony); probes, not opinions | KEEP probes as reconciler checks; ADOPT hook-reported state; KILL LLM monitors and idle alarm (D17) | L04 s5.4, 8; L06 s5.3, 5.6; L13 D17; S04 s8 item 6 |
| J17 Supervision and crash recovery | Supervisor script correct but uninstalled; watchdog in `~/.cache`; resume off; 9.5 h dark on 2026-10-13 | systemd units; Argo controller restart; Kubernetes restarts | Restart is a non-event: recover from the store and re-dispatch (Symphony, firstmate) | BUILD repo-owned systemd units with memory limits; WIRE resume by session id; DECIDE D08 | L04 s5.2, 9; L06 s5.2; I01 s4.2; L09 s4.6 |
| J18 Halt, drain, resume | USERHALT done by hand; K4 cancelled and split into four ready tickets | Argo suspend; Kubernetes cordon | Halt as a flag every loop reads | BUILD one halt flag read by the reconciler and gates; KEEP SPEC-17 B1 to B10 bring-up order | L03 s5.2; L02 s5 item 8; L06 s8 |
| J19 Owner surface | Bearings page (works, median reply 32 s); owner lane merged and dark; idle shutdown; board froze six hours | none needed | Machine verdicts and status pages, no agent relay | DECIDE D12, D20 (one surface), D21 (push transport); WIRE owner lane; KILL idle shutdown on stable; BUILD the requested Factorio-style view over board data | L08 s4, 5, 8, 9; history line 21029 |
| J20 CI executor and trigger | Jenkins pod gate merged, library unregistered, no webhook, lint aborted 54 times unseen | Argo Workflows; Tekton; ARC runners | Status on the head sha as the verdict channel | DECIDE D06, D07, D22 (host or pod), D23 (namespace and quota); WIRE Jenkins as code (JCasC, multibranch, Longhorn) | L07; L10 s5.1, 5.2, 5.3; S02 |
| J21 Deploy and gitops | Argo CD app-of-apps, AppProject fence, one tag bump, auto-sync; Jenkins imperative | Argo CD (installed, 12 apps healthy) | git as the only write path | KEEP; BUILD Jenkins under Argo CD | L10 s4, 8, 9; S01 s8 |
| J22 Governance and seat configuration | Nine rule stores, contradictions, 44k-token preamble, AutoMem leak, prettier rewrite, build mode as a memo; role-rendered seat settings with `cmp` check | `--settings`, `--setting-sources`, `--strict-mcp-config`, `--bare` | Small conditional context files; seats load only what the role names | DECIDE D13; KEEP rendered settings and playbooks; KILL user layer in seats | L11 F1 to F17, s8, s9 |
| J23 Capacity and cost limits | `max_agents` 8 (16 decided, not landed); per-role caps edited by hand; no spend cap | `--max-budget-usd`; Argo parallelism; Kueue | Concurrency cap and per-run budget in config; RAM per agent sizing | BUILD caps as reconciler config; WIRE the ruled 16 cap; DECIDE D03 | L06 s5.8 item g; S04 s5 item 6; I02 s5.6 |
| J24 Cleanup and retention | 34 remote branches, 88 worktrees, no retention job, 837 MB core dump, stranded roots | Argo `ttlStrategy`, Kubernetes `ttlSecondsAfterFinished` | Disposable workspaces per task | BUILD retention and branch cleanup on a timer; see `04-UNLANDED.md` | L05 s9; L02 s5 item 13 |
| J25 Testing of the line itself | Real herdr per case in Podman (20 to 25 min serial, 74 fixed sleeps); test pods proven 30 of 31 | software-factory-reliability drills via `make` | Failure-mode drills; fake clock and fake executor | KEEP pod-per-case and the scheduler testkit; ADOPT drills as acceptance; KILL the full herdr suite as a per-PR gate | L04 s9; L07 s4; I03 s8 item 3; L14 s8 |
| J26 Owner terms and rulings | Rulings sometimes only prompted, not recorded; "forgeo" read two ways in 70 s | none | none found | BUILD a term registry and rulings as records first | L12 s7; L06 s7 item 16 |
| J27 Model and runtime choice per ticket | The architect picks role, model and effort per ticket from prose (`roles/architect.json:33-36`, must line 88); the owner's "right-size agent models" rule is a prose table | `--model` and `--effort` per run; per-run budget flags | The harness launches a configured model per task type | BUILD a config table from ticket type and file globs to role, model and effort, read by the launcher; KILL the architect step | L13 s7 D02; S04 s4.1 |
| J28 Rework after a worker failure (423) | The architect splits or re-scopes on a worker 423 (`roles/architect.json:89`); `policies.json` already defaults the second 423 to owner_needed | Kubernetes `backoffLimit`; Argo `retryStrategy` | Bounded retry, then a human or a planner (Symphony, I02 s7) | BUILD the ladder: attempts 1 and 2 by `policy.sh` default with no LLM, a split run (spec-author, one shot) only after the third failure; KEEP the judgement for the split itself | L13 s7 D04, D09; L06 s6.1; I02 s7 |
| J29 Record contract: kind, code and route agree | `event.sh:95-97` checks the code is in the enum and the sha is present, never that the kind's code matches its table row, so `test.passed 100` is accepted (issue 77); `event.sh:68` still lists the legacy kinds `gate`, `test`, `review` and `merge` (issue 57); `verify-main.sh:4` posts `verified 200` while `routes.json:17` routes only 201, leaving 22 `verified 200` records and 21 "no route for verified 200" notes | JSON Schema with a per-kind code constraint | none found in the area files | BUILD BI01, BI02, BI03: one kind table that `event.sh`, `routes.json` lint and every posting script read | L01 F3; L05 s5 (issues 57, 64, 77); RC2 |
| J30 Entry points and the line DAG (Make) | Make is an entry-point list (help, images, lint, test, step, `bearings-%`); nothing expresses start a ticket, seat a worker, merge, verify main or bring the line up as targets with prerequisites; `scheduler/Makefile` targets call subcommands that do not exist | Make with `.DELETE_ON_ERROR:`; stamp files; a sense step that writes an observation only when it changed (toy M7: zero rebuilds when nothing changed) | Make is a common thin entry layer (22 of 61 cloned repos); not a scheduler: no lease, retry or durable state | BUILD BI04: line targets with real prerequisites, called by the owner and by the reconciler alike; retry, timeout and lease stay in the reconciler (D01 B) | L01 F9, F14; S03 s4 item 1, F6, s8 item 1; brief s1 ("i love driving automation with make files") |

## 3. Row notes

- J05 and J12 are the same fix seen twice: the reconciler owns the address check and the retry, and every other component stops retrying on its own (D01).
- J08, J10 and J11 depend on one choice: whether `coq/gate` on GitHub is the verdict (D05); if it is, `merge.sh` keys on it and the tester seat and the architect wake both go.
- J16 and J17 are where herdr changes role (D08): hooks and `events.subscribe` give seat state, systemd gives process supervision, and the pane is only a view.
- J19: the owner asked on 2026-10-14 for the line view in a Factorio style, wireframed and approved through dev, uat and stable (`~/.claude/history.jsonl` lines 21029, 21033, 21037); this row treats that view as a render of the board data, which is the same data the owner lane needs.
- No row recommends adopting an open-source factory whole: none is built on Argo or Jenkins, most are single-author or skill bundles (I03 F7, F8, F9).
- J30 ownership: the Make target graph is designed in the rebuild design document (D14 D), written by a spec-author run and ruled by the owner, and built by rebuild tickets cut from it; the architect rules on it and does not write it (owner order 2026-10-14, "architect never authors designs or specs").
  The targets are the human and system entry; Make does not retry, time out, lease or remember (S03 F6), so those stay in the reconciler.
- J29 is a root cause in miniature: a record whose kind and code disagree is written, routed nowhere, and recorded once as a 500 note (RC2).

## 4. LLM decisions mapped to jobs (L13 D01 to D25)

Every decision L13 section 7 found an LLM making today, the job row it belongs to, and the rule or timer that replaces it.
Status: EXISTS (the rule is code on main), DESIGNED (a ticket or spec holds it, unbuilt), NEW (named here, build item in section 5), KEEP-LLM (judgement stays with a one-shot run).

| L13 id | Decision | Made by today | Job row | Replacing rule or timer | Status |
| --- | --- | --- | --- | --- | --- |
| D01 | Approve a ticket | Architect (238 of 238 approvals are overrides) | J03 | Validator: lint passes, files declared, no contradicted DEC node, every criterion has an evidence method, input and output declared | NEW (D16 B) |
| D02 | Choose model and runtime per ticket | Architect | J27 | Config table: ticket type and file globs to role, model, effort | NEW (BI06) |
| D03 | Verify every 201 against the acceptance criteria | Architect; `sched-worker-2` posted all 66 `verified 201` | J11 | `verify-main.sh` exit code and CI gate 4 on main; non-machine criteria go to the reviewer once | DESIGNED (WO-20261013-aff2) |
| D04 | Split or re-scope on a worker 423 | Architect | J28 | Attempts 1 and 2 by `policy.sh` default; a one-shot split run after the third failure | NEW (BI07) plus KEEP-LLM for the split |
| D05 | Wake on merged to verify | `routes.json:15` wakes `architect-wo-<ticket>` (88 failed prompts) | J11 | Delete the row; the reconciler runs `verify-main.sh` on the merged record | DESIGNED (WO-20261013-612d), superseded by D01 B |
| D06 | Validate a request against its schema | Orchestrator role | J01 | JSON Schema validation in the intake script, exit 3 naming the key | NEW (part of D12 B message routing) |
| D07 | Enqueue with a priority | Orchestrator role | J04 | `routes.json:6` and the board | EXISTS |
| D08 | Route factory records through the table | Orchestrator role, duplicating `route.sh` | J05 | `route.sh` and the routes table, run by the reconciler | EXISTS |
| D09 | Second 423 becomes owner_needed | Orchestrator role | J28 | `routes.json:20-21` | EXISTS |
| D10 | Start the next ready ticket | `sched-worker-1` | J04 | Reconciler start action: ready, depends done, `claims.sh` free, slot free, system slots reserved | DESIGNED (WO-20261014-3dae), superseded by D01 B |
| D11 | Merge a PR with both gates | `sched-worker-1` (43 of 92 merges) | J10 | `merge.sh` on green `coq/gate` plus `review.passed` | EXISTS (script), DESIGNED (trigger WO-20261014-d93a, WO-20261013-3217) |
| D12 | Verify main after a merge | `sched-worker-2` | J11 | `verify-main.sh` or the main gate | EXISTS (script), DESIGNED (trigger) |
| D13 | Post-merge cleanup | `sched-worker-2`; branch and slot part now in `merge.sh` | J11, J24 | `after-merge.sh` as a reconciler action | DESIGNED (WO-20261013-48f2) |
| D14 | Down a seat that posted its result | `sched-worker-2` | J06 | One-shot runs end at their result (D02 B); until then the `down` key on every result row | DESIGNED (WO-20261014-7f99), superseded by D02 B |
| D15 | Re-seat a gate that did not appear, re-run a refused seat | Orchestrator by hand; `route-retry.sh` covers only capacity | J05, J12 | Level-triggered reconcile: open record, no live run and no result gets a run on the next tick, bounded by the retry key | NEW (D01 B) |
| D16 | Prompt a waiting seat on status change | Monitor role | J16 | No waiting seat exists under D02 B; until then `board.sh` nudge with no content (`nudge_seconds` 60) | EXISTS (`board.sh`, unwired) |
| D17 | Read panes for a hung, refused, waiting or looping seat | Compliance officer (a Haiku read of every pane each minute) | J16 | Stall timeout per run in the reconciler; until D02 B, SPEC-17 checks C1 to C5 (pane hash, regexes, `ps` counts) | DESIGNED (SPEC-17 s-health), superseded by D17 B |
| D18 | Escalate a finding up the chain | Patrol | J12, J16 | Ladder: record, then lane, then owner card after three sightings | NEW (part of BI08 reconciler escalation) |
| D19 | Tester: run the printed commands and report exit codes | Tester seat | J08 | CI pods post `coq/gate`; retire the role | DESIGNED (WO-20261013-ab25 merged, WO-20261013-3eac ready) |
| D20 | Merger: run the merge, clean up, post merged | Merger seat | J10 | `merge.sh`; conflicts go to a worker through the 409 row (`routes.json:16`) | EXISTS (script and row), trigger DESIGNED |
| D21 | Reviewer, mechanical half (paths, em dash, contents, UTC, config not literals) | Reviewer seat | J09 | `gate.sh pr-files` plus lint rules; the semantic half stays a one-shot review run | NEW (wire `pr-files`) plus KEEP-LLM |
| D22 | Worker close-out chain (evidence, commit, push, PR, submit, archive, `pr.opened`) | Worker seat | J07 | The launcher's close-out after the run's structured result; the LLM's turn ends at the commit | NEW (part of D02 B launcher) |
| D23 | Relay a factory record to a one-line page reply | Interface agent (absent; 75 failures) | J19 | A template per record kind, posted by a script into the owner lane | NEW (part of D12 B) |
| D24 | Break-glass instruction | Owner-gated LLM step | J22 | Keep; it is owner-gated by design | KEEP-LLM |
| D25 | Compaction prompt and guard resume | `bin/step.sh:54`, `unfreeze.sh:76` | J22 | Already rule-driven; disappears for one-shot runs under D02 B | EXISTS |

Count by primary status: 8 EXISTS, 7 DESIGNED, 9 NEW, 1 KEEP-LLM (break glass); D04 and D21 also keep an LLM for their judgement half only (the split after a third failure, the semantic review).
L13 section 7 counts 21 of 25 with "an existing or designed rule" because it counts the rules it proposes; this table counts as DESIGNED only rules already in a ticket or spec.

Tickets named in this table, with their titles (from the ticket files; also in `04-UNLANDED.md` section 9):

- WO-20261013-3217 - CI gate 3: line/bin/merge.sh keys on the coq/gate status of the head sha plus review.passed, triggered by the GitHub status event, not on a test.passed record
- WO-20261013-3eac - CI gate 5: pr.opened routes to the reviewer only; the tester role is retired and its playbook marked retired
- WO-20261013-48f2 - Post-merge cleanup is code: line/bin/after-merge.sh cleans the branches, downs the ticket's seats and returns their slots, restores the checkout's ticket copies, starts verify-main.sh in an unowned pane and posts one record
- WO-20261013-612d - Route row: merged 200 runs line/bin/after-merge.sh instead of waking the architect to verify
- WO-20261013-ab25 - CI gate 2: coqGate() plans the suites from the diff, runs them as pods and posts coq/gate on the head sha (merged as PR 179)
- WO-20261013-aff2 - CI gate 4: a green coq/gate status on main posts verified for every merge since the last verified sha, a red one posts rejected and sets the merge hold, triggered by the GitHub status event
- WO-20261014-3dae - R3 - start-loop.sh with its systemd user unit starts the next ready ticket when depends are done, files are free and a slot is free
- WO-20261014-7f99 - R2 - Result records down their own seat through the route down key and patrol reports survivors as a defect
- WO-20261014-d93a - R1 - routes.json run action: review.passed and merged run merge.sh and after-merge.sh, the architect wake on merged deleted

## 5. Build items named by this inventory

These are inputs to the rebuild design document (D14 D), not tickets; the design cuts tickets from them.

| Id | What | Closes or replaces | Job row | Evidence |
| --- | --- | --- | --- | --- |
| BI01 | One kind table in config gives every record kind its allowed codes; `event.sh add` refuses a kind and code pair the table lacks, and checks the observation count the schema caps at 5 | Issues 77 and 64 | J29 | L01 F3; L05 s5 (issue 64 verdict) |
| BI02 | Remove the legacy kinds `gate`, `test`, `review`, `merge` from `event.sh:68` and from the kind enum at `events/schema/event.schema.json:14` | Issue 57 | J29 | L01 F3; L05 s5 |
| BI03 | One code for `verified`: the kind table picks it, `verify-main.sh:4` and `routes.json:17` both read it, and a routes lint fails when any posting script uses a pair with no route row | The 22 `verified 200` records and 21 "no route" notes | J29, J05 | L01 F3 |
| BI04 | Make targets with real prerequisites for the line: `line-up` (units installed, checks green), `ticket-start T=`, `seat-worker T=`, `merge PR=`, `verify-main`, `reconcile`; `.DELETE_ON_ERROR:`; stamps under the state root; each recipe calls the existing script; the reconciler calls the same targets | The hand-typed `start-tickets.sh` chain and the dead `scheduler/Makefile` targets; it absorbs the ready WO-20261013-8ed9 - make line-resume: the preflight judges open items by rule, the system comes up B1 to B10 in order and stops at the first FAILED, seats one at a time, line.resumed 100, flags removed last (SPEC-17 T09; K4 part 3 of 4) | J30, J04 | L01 F9, F12, F14; S03 F6, s8 item 1 |
| BI05 | Routes lint: every row's target is a seat or action the system can start, so a wake to `architect-wo-<ticket>` or `interface` fails lint before it fails 163 times at run time; one routes schema copy, not two | Issue 66; the 88 and 75 dead-address failures | J05 | L01 F1; L03 s5 (routes lint unbuilt); L05 s5 (issue 66) |
| BI06 | Model and runtime table per ticket type and file globs | L13 D02 | J27 | L13 s7 |
| BI07 | Rework ladder after a worker 423 | L13 D04 | J28 | L13 s7; L06 s6.1 |
| BI08 | Reconciler escalation ladder with one retry key (3 attempts, the owner's rule), then a record, then an owner card after three sightings | `route-retry.sh`; L13 D15, D18; issue 76 | J12 | L01 F2; L13 s7; I02 s7 |
| BI09 | Cleanup script generated from the `04-UNLANDED.md` tables, dry-run first, three attempts per step then a record | The 28 branch deletions, 73 worktrees, issue closures and file moves in `04-UNLANDED.md` | J24 | `04-UNLANDED.md` sections 3 to 12; D25 |

## 6. Sources

All area files in this directory (list in `01-ROOT-CAUSES.md` section 7), written 2026-10-14 between 02:40Z and 03:02Z.
Owner messages: `~/.claude/history.jsonl` lines 21029, 21033, 21037, read 2026-10-14T03:05Z.
Owner order on who writes designs: auto-memory note `architect-sends-specs-off.md` (owner 2026-10-14, "architect never authors designs/specs; a spec-author seat does"), indexed in the project's `MEMORY.md`.
