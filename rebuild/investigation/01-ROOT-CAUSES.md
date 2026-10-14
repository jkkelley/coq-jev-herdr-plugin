# 01 - Root causes: what is holding the factory back now

Lead deliverable of step R-01 of the Factory Rebuild investigation.
Finished 2026-10-14T03:17Z (UTC) by the merge seat from the 24 area files in this directory; revised 2026-10-14T03:45Z to close the completeness critic's gaps.
Every claim cites the area file it comes from; the area file holds the file, line, record or URL.
Area files are cited by id: L01 is `L01-line-scripts.md`, S03 is `S03-make-and-durable-queues.md`, and so on.

## Contents

1. How this list is ordered
2. The answer in five lines
3. Root causes RC1 to RC9
4. Hypotheses that did not survive the evidence
5. Hypotheses that did survive
6. Area status and gaps
7. Sources

## 1. How this list is ordered

The order is by measured cost to the line today (failed routes, stalls, hand operations, dark time) and by how many other causes depend on it.
Each root cause has four parts: the claim, the evidence lines, the single mechanism behind it, and a pointer to the decision in `03-DECISIONS.md` that removes it.
Codes used in section 4: SUPPORTED, PARTLY, NOT SUPPORTED, WITHDRAWN.

## 2. The answer in five lines

The deterministic code for most line jobs already exists, but nothing starts it, so an LLM seat is the trigger for every mechanical step (RC1).
Every trigger is a line of text typed into an interactive pane, with no acknowledgement, no durable pending state and no retry owned by the system (RC2, RC4).
State sits in many disagreeing copies joined by polling scripts and by hand (RC3).
The build itself is incident-driven, so each stall becomes a lettered patch and the replacement must be built by the line it replaces (RC5).
herdr is not the root cause of the stalls; it is misused as the service host, bus and supervisor, which made one crash total (RC6).

## 3. Root causes

### RC1. The code exists, nothing starts it, so an agent is the trigger

Claim: merge, verify, ticket start, post-merge cleanup, the owner lane, the CI gate and the supervisor are all built, and every one of them is started by an LLM seat or by hand.

Evidence:

- `line/bin/merge.sh` has no caller on main; `routes.json:12` still seats a merger agent and its wiring ticket has 0 commits (L05 section 5 item 11; L01 F4).
- Of 92 `merged 200` records, the acting orchestrator LLM `sched-worker-1` posted 43 by hand, `merge.sh` 44 and the merger seat 5 (L13 section 5.2).
- `sched-worker-2` posted all 66 `verified 201` records, a median 28 minutes after the merge, although `verify-main.sh` exists (L13 sections 5.2 and 5.6).
- The first half of the seat lifecycle has no driver: 0 `ticket.cut` records in the state root, `routes.json:7` never fired, and `start-tickets.sh` is typed by an LLM (L01 F12).
- Starting one ticket costs 4.4 to 8 minutes, and 13 starts failed with `FAIL ... start (claims or status)` and were dropped until someone re-ran them (L11 F4; L05 section 5 item 12).
- The webhook listener units and the supervisor timer are merged and not installed; only `herdr-stable.service` and `watchdog.timer` exist for the whole line (L01 F5; L06 section 5.8 item h; L04 section 5.2).
- `line/bin/board.sh` (Roadmap K1, done) is called by nothing and the owner lane it feeds is dark because `config/bearings.json` has no `owner_board` key (L02 section 5 item 9; L08 section 5 item 2).
- The CI gate merged without its Jenkins library, job type or webhook, so every build since fails in under two seconds (L10 section 5.2; S02 B2).
- A decided one-line change, `max_agents` 8 to 16 (card C27, 2026-10-13T02:10Z), was still 8 about 24 hours later (L06 section 5.8 item g).
- The fix for the dead man's switch that hid a 9.5 hour outage is ready and unstarted (L06 section 5.2).
- It is still happening during the hold: between 2026-10-14T02:49:57Z and 03:19:13Z the line typed a `MERGE WATCH ... as acting orchestrator` prompt and 7 `PATROL FINDING ddwdh` prompts into the acting-orchestrator LLM session (`~/.claude/history.jsonl` lines 21024 to 21057, project `~/.cache/wt-sched-w2`, session `d5bef816`), asking it to "give it work within the minute or down it" for `sched-worker-1`, idle 4,579 s by 03:17:01Z, and reporting `digest.sh` missing for the 15th time (read by the merge seat at 03:35Z).
  The patrol keeps handing mechanical work to an LLM after the owner's halt, because no halt flag is something it reads (RC3) and its ladder ends in a prompt, not a terminal state (D17, BI08 in `00-INVENTORY.md`).

Mechanism: the build ends at merged code, and the step that makes code run (a unit file installed, a timer, a route row, a Jenkins setting) is either a manual host step labelled "human criteria" or a separate unstarted ticket, so the system has no driver and an agent fills the gap.

Removed by: D01, D11, D07 in `03-DECISIONS.md`.

### RC2. Dispatch is a typed, one-shot prompt to a derived name, with no acknowledgement and no system-owned retry

Claim: the route runner's only actuator is `herdr agent prompt` into a seat whose name is derived from a role, and a failure is recorded once and never retried.

Evidence:

- 391 `route failed` notes between 2026-10-13T15:29Z and 2026-10-14T02:22Z: 89 seat refused because the ticket had no branch yet, 88 wakes to `architect-wo-<ticket>` (a seat nobody starts), 75 to the absent `interface` seat, 43 no ticket file, 42 prompt failed to a gone seat, 19 slot, 18 capacity, 11 other, 6 no ticket on the record (L01 F1; recomputed identically by S03 F3).
- Only 74 of 880 records that wanted an action completed (8 percent, a floor), 373 ended `failed` and 394 `unrouted` (L02 section 5 item 4).
- The retry limit is declared three times (`routes.json:4` 3, `scheduler.json:29` 5, `:47` 3) and read by no running code (L01 F2).
- `route-retry.sh` greps the prose of a note and retries only capacity refusals, with no attempt cap and no halt check (L01 F2; L06 section 6.1).
- The runner is serial and blocks on each seat bring-up for up to about 50 seconds; issue 67 stays open for that reason (L01 F6).
- `seat.sh:532` says "the queue holds the ticket" and nothing enqueues or dequeues it (issue 73; L01 F11).
- A merge wake typed into the busy shared merger was lost (issue 78; L01 F4).
- herdr's own manual says `agent.prompt` proves delivery, not that a turn started (L04 section 5.3).
- The bearings wait loop marks an owner message delivered before the prompt that carries it can fail (L08 section 5 item 6).
- The record contract is not enforced at write, so a record the router cannot route is accepted and then dropped: `event.sh:95-97` checks that a code is in the enum and that a gate kind has a sha, never that the kind's code is the one its table row expects, so `test.passed 100` is accepted (issue 77); `event.sh:68` still lists the legacy kinds `gate`, `test`, `review` and `merge` (issue 57); `verify-main.sh:4` posts `verified 200` while `routes.json:17` routes `verified` only at 201, which left 22 `verified 200` records and 21 "no route for verified 200" notes beside 66 `verified 201` (L01 F3).

Mechanism: a wake is text typed into a pane, the address is a name nobody checks, and the only memory of a failed wake is a 500 note.
A durable broker alone would not fix it: 212 of the 391 are addressing errors that a queue would store for a consumer that never comes (S03 F3).
What is missing is an address check, a bounded retry owned by the system, a record contract checked at write (kind, code and route agree; inventory row J29), and a level-triggered reconcile that compares open work with live workers on every tick (S03 F3; I03 F3).

Removed by: D01, D02, D10.

### RC3. State lives in many copies with no authority, joined by polling and by hand

Claim: for the facts that matter (ticket state, routed state, seat liveness, slot lease, halt) there are four to eight copies and no declared authority.

Evidence:

- 21 stores, two state roots; `herdr.json` points seats at the legacy root, which holds 426 seat directories while the canonical root holds 3 (L02 sections 3 and 5 item 1).
- Verdict records stranded in three stray roots were never seen by the merger and were copied by hand (L02 section 5 item 2).
- 5,812 untracked record copies sit in the owner checkout because the A4 cut-over never ran and `record-bus.sh` bridged copies until 00:35Z (L02 section 5 item 3; L05 section 5 item 5).
- Ticket status is a git front-matter field read from the main checkout, which produced 132 seat refusals ("no branch yet" 89, "no ticket" 43) and five hand clean-ups of start residue in 24 hours (L02 section 5 item 5; L01 F1).
- 11 of 12 open seat records name an agent that does not exist; a slot lease is 30 hours old against a 4 hour TTL nothing enforces; four halt-flag paths exist (L02 section 5 items 6 to 8).
- Three file queues exist; one has a check-then-write race that let 10 to 12 of 12 toy holders claim one item, one is correct and unused (S03 F1, F2).
- GitHub carries no verdict at all: PRs 177 to 181 merged with zero statuses and main protection requires no checks (L02 section 5 item 11; L05 section 5 item 8).

Mechanism: each script made its own copy for its own reader, no store is named authoritative per fact, and the joins are timers chosen by hand (5, 10, 15, 30, 60, 1800 s).
The one store with no drift is herdr's live state, because it is queried and never copied (L02 section 5 item 12).

Removed by: D04, D05, D10.

### RC4. Seats are long-lived interactive TUIs, so the system types to them, reads their screens, and trusts their self-report

Claim: every seat is an interactive Claude Code session in a pane, so bring-up, liveness and completion all depend on typing and screen-reading, and the result is whatever the seat chooses to post.

Evidence:

- The brief is typed into the pane; a trust-dialog writer, an ACK-memo nudge and a 180 s (now 15 s) ACK wait exist only because the seat is interactive (S04 section 5 items 1 and 2; L04 section 5.5).
- The ACK is never printed because no coq seat binds a compaction-guard role: 897 of 1,104 guard alerts are `GOV-130 no schema resolved` (L11 F10).
- Liveness is a regex over the Claude Code footer every 15 s, and herdr logged 4,671 errored API requests in 71 minutes, 98 percent pane reads and process-info calls (L04 section 5.4).
- Tester seats polled panes and stalled 9 to 14 minutes on a one-minute lint; one tester session made 14 tool calls of which 8 were sleeps or pane reads (L06 section 5.4; L11 F13).
- `herdr/bin/seat.sh` is 848 lines and was touched by 19 of 248 commits (L05 section 5 item 1).
- Only 7.3 percent of records fill their `evidence` field, and no `merged` record does (I02 section 5.1).
- Each seat carries about 44k tokens of fixed preamble before it reads its ticket (L11 F6).
- The role schema has no field for turns, spend or wall clock; "at most 3 attempts" is a sentence the model is trusted to count (S04 section 5 item 4).
- Every surveyed worker harness (claude -p, Agent SDK, codex exec, Devin, Copilot, mini-swe-agent) returns result, cost, turns and terminal state from the harness, not from the model (S04 section 2).

Mechanism: the seat contract is a conversation, so the system must drive a TUI, and limits and results live in prose.

Removed by: D02, D03, D13.

### RC5. The build is incident-driven: nothing turns the designs into a machine-ordered build

Claim: there is more design than build, the build is driven by lettered "Cause" tickets, and the system that is meant to replace the agents is built through the agents.

Evidence:

- `specs/` had 5 commits since 2026-10-10 against 47 for `herdr/`, 17 for `factory/` and 14 for `line/` (L03 section 5.1).
- About 51 lettered causes (a to ay) were cut in about 12.6 hours; 37 of 101 commits since 2026-10-13T00:00Z mention a cause (L06 section 5.7).
- 28 of the last 60 commits change only `work-orders/` and `changelog/`; 0 of 60 touch the product (L05 section 4).
- The 33 live children of the system-maintenance epic have no implementing commit and 53 unticked acceptance boxes (L05 section 5 item 4).
- SPEC-17's eight build tickets were cut, four cancelled and split into 17 tickets that are all ready (L03 section 5.1).
- Five Go control-plane designs in 28 days, none running (L14 section 2); "the Go core has never been built by a system that does not need the Go core" (L14 section 5.3).
- The architect issued line operations by prompt until the owner halt at 2026-10-14T00:38Z (L03 section 5.1 fact 3).
- The same pattern ran in every earlier iteration: rime merged 32 loop fixes against 17 product tickets (L09 section 5.2), and the Drive shows one argument made six times while each build put an LLM or bash loop in the control seat (L15 section 2).

Mechanism: the design layer never schedules the build, so for each design item the agent stays the executor until an incident ticket replaces it, and every system hour goes to incident tickets.

Removed by: D01, D14, D19, and by building the rebuild through the rebuild's own deterministic workflow (brief section 2) rather than through the old line.

### RC6. One herdr server hosts every seat, every line process and the owner page

Claim: a single pane-owning process is the terminal, the service host and the supervisor, under one cgroup, with recovery switched off and the supervisor uninstalled.

Evidence:

- herdr 0.9.0 segfaulted in `memcpy` at 2026-10-13T03:32:18Z and the line was dark for about 9.5 hours until the owner noticed (L04 sections 5.1 and 5.2; L06 section 5.2).
- 36 monitor panes run the belt, bearings, watchers and HTTP servers as pane children, so they died with it (L04 section 5.6).
- `resume_agents_on_restore = false`, the supervisor timer is not installed, and the dead man's switch counted the patrol's own notes as liveness (L04 section 5.2; L06 section 5.2).
- The stable bearings server shuts itself down after 240 idle minutes, and nothing restarts it (L08 section 5 item 4).
- The unit has no `MemoryMax`; seats, Podman tests and shells share its cgroup (L04 section 5.1).
- The 0.9.0 pin exists for `pane.graphics.*`, which upstream removed on purpose in 0.9.2; 0.9.0 predates the upstream memory-corruption fix (L04 section 5.7).
- The owner's September iteration already solved this shape with a script-only central monitor that starts first (L04 section 5.2; L09 section 5.3).

Mechanism: herdr is used as service host and supervisor, so the failure domain of the terminal is the failure domain of the factory.

Removed by: D08, D12.

### RC7. The CI verdict path is dark end to end, and nothing said so

Claim: no CI verdict has ever reached GitHub, and the old lint job was red for 31 hours unnoticed.

Evidence:

- Builds 39 to 92 (54 in a row, about 31 hours) were aborted by a 15-minute timeout while one serial suite held one Pi core (L10 section 5.1; S02 B1).
- The old job never posted any GitHub status, green or red (L10 section 5.1).
- Since PR 179, builds fail at "Could not find any definition of libraries [coq-ci]" every 10 minutes from the poll that PR 179 believed it removed (L10 section 5.2; S02 B2).
- The repository has no webhook and Jenkins is on a LAN address GitHub cannot reach (L07 section 5 item 1; S02 B3).
- The handlers `ci/bin/pr-gate-hook.sh` and `main-gate.sh` do not exist, and `merge-watch.sh` has no `coq/gate` fallback (L07 section 5 item 4; L06 section 5.8 item i).
- The planned `lint` unit runs `make lint`, which needs podman the pod image does not have, so the first live run would go red on valid pull requests (L07 section 5 item 6; S02 B7).
- Jenkins is a pet: floating `lts`, `JENKINS_HOME` on a CIFS share from the owner's Windows PC, service account `cluster-admin` (L10 section 5.3; S02 B5).

Mechanism: an instance of RC1 with a second fault: setup steps outside the repository were left as human steps, and no check watches the CI outcome.

Removed by: D05, D06, D07.

### RC8. The governance layer is contradictory prose that nothing retires, and "build mode" is a memo

Claim: rules live in nine stores, contradict each other, and are kept by the model rather than the system; hooks are not the problem.

Evidence:

- Hooks are cheap: zero hook errors in 682 transcripts, about 85 ms per guard call (L11 section 4).
- Build mode exists only as a private memory note, and the guard denied the rebuild session's own write 70 seconds after it was bound by hand (L11 F1, F17).
- Eight contradictions between the global file, the project file, skills and tooling, for example lavish forbidden yet run at every start and required by `work-order.sh approve` (L11 F2).
- 238 of 238 ticket approvals were overrides; the approval gate approves everything (L11 F3).
- The work-order skill assumes one human and one checkout, which forces cut PRs and start residue (L11 F4).
- Seats receive the architect's private memory, a global prettier hook rewrites whole files, and the tester fence produced 237 denials that seats read as "no shell" (L11 F7, F8, F9).
- `AGENTS.md` grew from 209 to 365 lines in three days; each owner order becomes a law, a ticket, a gate and a lint step, and nothing retires a rule (L11 F16).

Mechanism: rules accumulate as prose across stores loaded by every seat, with no single source and no retirement.

Removed by: D13.

### RC9. The owner's page has exactly one reader, and it is an LLM

Claim: the page transport works, but every owner message is typed into the architect's pane and every card exists only if an agent remembered to write it.

Evidence:

- 142 owner messages, median reply 32 s, p90 151 s: the transport is fine (L08 section 4).
- `bearings.sh wait` forwards each message whole into one pane (L08 section 5 item 1); the owner named the effect: "you are the gate, you are the problem" (L06 section 5).
- The only producer of cards is `make ask` run by an agent; the one open card was written at 2026-10-14T00:32Z (L08 section 5 item 3).
- The board froze for six hours and then reported "17 lines" when far fewer ran, and the owner, not a check, found both (L08 section 5 item 5; L02 section 5 item 14).

Mechanism: the page has one consumer and one producer, both agents, while the system lane meant to replace them is merged and unwired.

Removed by: D12, D20, D21.

## 4. Hypotheses that did not survive the evidence

| Id | Hypothesis (source) | Verdict | Evidence |
| --- | --- | --- | --- |
| H01 | "We're using herdr wrong" is the root cause (brief section 1) | PARTLY | True for herdr as bus, state store, screen scraper and service host (L04 sections 5.3 to 5.6; S04 section 2; I03 F5). Not the cause of the stalls: those come from who drives control flow (L06 section 5.8; L09 section 5.2; L13 section 5.4; I02 section 5.9), and herdr is the one store with no drift (L02 section 5 item 12). |
| H02 | herdr died at 31.8G (brief, roadmap, and ticket WO-20261013-77c0 - herdr-stable dies with a SEGV at 31.8G and nothing brings the seats back: it has no memory ceiling, no core kept, and no restart that resumes each seat by its pane session id) | NOT SUPPORTED | 31.8G is the cgroup peak; the herdr core maps about 0.9 GB (L04 section 5.1). |
| H03 | Parallel test cases caused the crash (test-speed design) | NOT SUPPORTED | The parallel runner merged about 17 hours after the crash (L04 section 5.1; L06 section 5.2). |
| H04 | Capacity refusals are the main route failure (issue 76 framing) | NOT SUPPORTED | 18 of 391 (4.6 percent) (L01 F1). |
| H05 | A durable queue makes sure a wakeup is never lost (brief S03) | PARTLY | 212 of 391 failures are addressing errors a broker would store (S03 F3); GitHub does not redeliver webhooks, so a reconciler is needed anyway (S01 section 5). |
| H06 | Merge is already code (first L05 draft) | PARTLY | The script is code; its trigger is an agent (L05 section 2 and section 5 item 11). |
| H07 | Ticket status lags merges systematically | NOT SUPPORTED | No ticket on main has an implementing commit with a not-done status; 5 of 98 done tickets needed a hand close (L05 section 5 item 4). The real cost is the git-resident status read from the checkout (L02 section 5 item 5). |
| H08 | The old governance is off in build mode (brief section 6) | NOT SUPPORTED | Nothing makes it true; the guard bit the rebuild session (L11 F1, F17). |
| H09 | There is no design and one must be written | NOT SUPPORTED | Ten spec files, 109 graph nodes, 15 laws, a roadmap, a 26-row hand-fix inventory (L03 section 5.6). |
| H10 | software-factory is the base to build on (brief L09) | PARTLY | A sound contract and vocabulary; no executor, queue, store or trigger; DONE needs no evidence (L09 section 5.1). |
| H11 | "forgeo" is the software-factory repo under another name (brief L12) | NOT SUPPORTED | It is Forgejo; the owner confirmed at 2026-10-14T03:02:11Z (`~/.claude/history.jsonl` line 21040; `L12-addendum-owner-confirmed-forgejo.md`). |
| H12 | "Forgeo is the Go gRPC design" (architect, 02:46:30Z) | WITHDRAWN | An unconfirmed reading told to the owner and to investigator L14 as fact (L12 section 2); superseded by the owner's answer (addendum). |
| H13 | rime's loop failed and the owner stopped it (common reading) | NOT SUPPORTED for 2026-10-06 | 10 product merges in 10h57m ending at the halt, its best rate; no reason is recorded (L09 section 5.2). |
| H14 | The field runs with no LLM assigning work | PARTLY | Field code owns dispatch, claim, stall, retry and merge; Factory, Cognition and Cursor still let an LLM decompose a goal (I01 section 5; I02 section 5.9). |
| H15 | Three retries is the field standard | NOT SUPPORTED | Kubernetes Jobs default 6, Temporal unlimited, Symphony no cap found; 3 is the owner's own rule (I02 section 7). |
| H16 | "Adobe has been completely copied"; the reverse-engineering repo is usable | NOT SUPPORTED | The apps are alpha at about 45 to 62 percent ready by their own roadmaps; REA has no factory function (I03 F1, F2). |
| H17 | Tests already run as pods through the CI gate | NOT SUPPORTED | The gate has never run; only the lint pod and hand-run proof pods ever ran (L07 section 2; S02 section 2). |
| H18 | The lint outage was missed because ABORTED is not FAILURE | NOT SUPPORTED | The job never posted any status at all (L10 section 5.1). |
| H19 | Records carry only a kind and a code | NOT SUPPORTED | Evidence and observation fields exist; 92.7 percent leave them empty (I02 section 5.1). |
| H20 | An LLM monitor can judge seat health | NOT SUPPORTED | The Haiku monitor answered OK on every patrol including a blocked merger (L01 section 4 item 5; L06 section 5.3). |
| H21 | The Go scheduler failed as a design | NOT SUPPORTED | It was starved, not refuted: 14 build tickets never started (L03 section 5.6; L14 section 5.1). |

## 5. Hypotheses that did survive

- Agents hold up the line: SUPPORTED at merge, verify, start, cleanup and owner contact (RC1, RC9; L05 section 5 items 11 and 12; L13 section 5.2).
- "We need a system, not agents or humans driving it": SUPPORTED, and the owner's own files reached it three times before the brief and did not build it (L06 section 5.8; L15 section 2).
- The pane is the wrong transport for system actions: SUPPORTED (L01 F7; L04 section 5.3; S04 section 5 item 7).
- The field shape is a deterministic control plane with disposable per-task workers: SUPPORTED (I01 section 4.2; I03 section 7).

## 6. Area status and gaps

All 24 area files exist in the template: L01 to L15 (with L05b and the L12 addendum), S01 to S04, I01 to I03.
L07 is partial: it had no Jenkins access, and S02 B1 to B3 and L10 sections 5.1 and 5.2 close its unverified items.
Open gaps that no area could close from files: the root cause of the herdr SEGV (unsymbolised core, L04 section 5.1); the reason NATS was dropped in C15 (S03 F5, section 10 question 2), now asked of the owner inside D10 in `03-DECISIONS.md`, where the recommendation is shown to hold either way while the control plane is on the host; the reason for the 2026-10-06 rime halt (L09 section 5.2, dropped as not design-relevant); steady-state Argo footprint on the Pis (S01 section 11); whether GitHub can reach the cluster (S01 section 10); the answer to card C31 (L06 section 4.1); whether `--setting-sources` and `--bare` drop the user hook layer in a seat as documented (L11 F1, untested).
Area questions that change the design and had no decision entry in the first draft now have one: the owner surface (L08 question 1, L11 question 2, L11 F2) is D20, the page transport (L08 question 3) is D21, the host and pod boundary (S01 question 3) is D22, pod isolation on the shared cluster (L10 question 3) is D23, Drive as source of truth (L15 question 1) is D24, the product-or-infrastructure freeze (L06 question 4) is D19, and the cleanup's place against the GOFACTORY hold is D25.
Three are recorded as assumptions with the event that reopens them, in `03-DECISIONS.md` section 28: the Claude plan type (S04 question 2), a private repository (L07 question 4), and cloning a commercial product (I03 question 2).

## 7. Sources

Area files in this directory, all written 2026-10-14 between 02:40Z and 03:02Z: `L01-line-scripts.md`, `L02-state-stores.md`, `L03-design-vs-built.md`, `L04-herdr.md`, `L05-git-state.md`, `L05b-worktrees-and-dirty-checkout-snapshot.md`, `L06-owner-retros-and-plans.md`, `L07-ci-and-pods.md`, `L08-bearings-owner-surface.md`, `L09-earlier-factory-iterations.md`, `L10-cluster-and-gitops.md`, `L11-governance-layer.md`, `L12-forgeo.md`, `L12-addendum-owner-confirmed-forgejo.md`, `L13-llms-doing-scheduler-work.md`, `L14-go-grpc-control-plane.md`, `L15-google-drive-designs.md`, `S01-argo.md`, `S02-k8s-jobs-tekton-jenkins.md`, `S03-make-and-durable-queues.md`, `S04-agent-frameworks-seat-contracts.md`, `I01-production-agent-fleets.md`, `I02-postmortems-and-abandonment.md`, `I03-oss-factories-and-clones.md`.
Owner message verified by the merge seat: `~/.claude/history.jsonl` line 21040, "yah i was say it wrong lol", 2026-10-14T03:02:11Z.
Line prompts read by the merge seat at 03:35Z: `~/.claude/history.jsonl` lines 21024, 21031, 21034, 21041, 21043, 21053, 21054, 21057 (fields `project` and `sessionId` checked).
