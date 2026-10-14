# I02 - Post-mortems and abandonment

Investigator: area I02, Factory Rebuild step R-01, attempt 2.
Written 2026-10-14 UTC (attempt 2 finished after 2026-10-14T02:53Z, per `date -u`).
Method: extended web research on 2026-10-14, a direct re-read of every owner line cited as an owner match, and page-metadata date checks for every web source.
Attempt 2 changes against attempt 1 are listed in section 12 so a reader can see what was closed and what could not be.

Source reliability key used throughout:
- P = primary page or primary repo file read on 2026-10-14.
  For web pages I read them both through the fetch tool and as raw HTML converted to text with a local script, so every quotation marked P was checked against page text, not only a model summary.
- A = archive copy: a Wayback Machine raw capture of a primary page that returned HTTP 403 live.
  The capture date is given with each A.
- S = secondary write-up or search-result snippet only.
  The primary was not read.
- X = claim that could not be verified, or sources conflict.
  Nothing marked X is carried into sections 8, 9 or 10.

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
12. Attempt 2 change log and gaps that cannot be closed

## 2. What it is

I02 collects what the field has published about multi-agent and many-agent coding systems failing, and what people dropped and replaced.
The failure modes found fall into eight groups: lost or degraded context at handoff, agents that must coordinate through each other, agents as gatekeepers (integrator, orchestrator or lead roles), verification that verifies nothing or never ends, review and merge capacity as the new bottleneck, runaway cost and loops, context exhaustion inside one agent, and the lead or orchestrator LLM doing bookkeeping that code should do.
The replacements the field converged on are consistent in direction, though not unanimous in detail: a single writer, planner and worker roles with no peer coordination, work claimed through files or a tracker and not through conversation, code owning ticket state, claiming, stall detection and retry, typed receipts instead of prose handoffs, independent reviewers with clean context, fresh sessions with file-based progress artifacts, and enforced (not observed) budgets and loop bounds.
The one place the field is not unanimous is how tightly agents are boxed inside steps: a typed state machine with agents at leaf steps (dev.to account, section 4.5) against OpenAI's own finding that rigid state-machine nodes limited Codex and that objectives work better than strict transitions (section 5.9).
Against the brief, the evidence agrees with the owner's framing "no cog should hold up the system, so we need a system" and disagrees with the narrower diagnosis "we're using herdr wrong": the field failure modes are about who drives control flow, not about the terminal multiplexer (section 5.9).

## 3. Where it lives

This is an internet-track area.
There is no local code under study here.
All evidence is at URLs, listed with the date I read each one and the date the page itself carries in section 11.
Repos read: `clones/symphony` (origin github.com/openai/symphony, HEAD be10a1b, 2026-09-15, cloned earlier in this investigation by another area; I verified the remote and read SPEC.md directly) and `clones/gastown` (origin github.com/gastownhall/gastown, listed but not used for any claim here).
Owner-side files re-read directly for this attempt, under `~/.local/state/coq/coq-jev-herdr-plugin/`:
- `plans/2026/10/20261012212500-roadmap.md` (cited as roadmap:N, line N).
- `plans/2026/10/20261013025600-priority-list.md` (prio:N).
- `plans/2026/10/20261013194800-ci-gate-design.md` (cigate:N).
- `plans/2026/10/20261013021500-best-practices-agent-line.md` (bestpractices:N).
- `plans/2026/10/20261012222000-retro-architect-flood-and-halt.md` (retro:N).
- `records/2026/10/*.json` (3338 record files, counted read-only on 2026-10-14).
- Main checkout `~/projects/coq-jev-herdr-plugin` read with `git show -s` and `git log` only; no branch switch.
Cross-reference only: `L06-owner-retros-and-plans.md` in this investigation root, whose section numbers I cite as "L06 5.x".
Nothing was cloned for this area by me.

## 4. What works

What the field reports as working, each with evidence.
Items are ordered by how directly they replace something the owner currently does with an LLM seat.

### 4.1 Single writer; other agents add intelligence, not actions

- Cognition, 2026-04-22: "writes stay single-threaded and the additional agents contribute intelligence rather than actions" is the thread across everything that worked (P, cognition.com/blog/multi-agents-working; page metadata datePublished 2026-04-22).
- The same post says parallel-writer swarms "still rarely work" and unstructured swarms negotiating with each other are "mostly a distraction" (P, same URL).
- Ten months earlier the same author argued for a single-threaded linear agent as the default (P, cognition.com/blog/dont-build-multi-agents, datePublished 2025-06-12, dateModified 2026-03-15).
- Anthropic's multi-agent research post, published 2025-06-13: "some domains that require all agents to share the same context or involve many dependencies between agents are not a good fit for multi-agent systems today. For instance, most coding tasks involve fewer truly parallelizable tasks than research, and LLM agents are not yet great at coordinating and delegating to other agents in real time." (P, anthropic.com/engineering/multi-agent-research-system, page text).
- Claude Code docs, read 2026-10-14 (page undated): for "sequential tasks, same-file edits, or work with many dependencies, a single session or subagents are more effective", and "Two teammates editing the same file leads to overwrites. Break the work so each teammate owns a different set of files." (P, code.claude.com/docs/en/agent-teams).

### 4.2 Independent reviewer with clean context (generator-verifier)

- Cognition: Devin Review catches an average of 2 bugs per PR on PRs written by Devin, about 58 percent severe; the technique "works best when the coding and review agents do not share any context beforehand" (P, cognition.com/blog/multi-agents-working, 2026-04-22; the bug rate is the vendor's own measurement).
- The reviewer sees the diff only and re-discovers context, which avoids the coder's accumulated context rot (P, same URL).
- MAST (arXiv 2503.13657, submitted 2025-03-17, v3 last revised 2025-10-26): adding a high-level task-objective verification step gave the largest measured gain, +15.6 percent task success on ChatDev/ProgramDev, versus +9.4 percent for better role specification (P).
- Caveat in the same paper: many verifiers do only superficial checks such as "does it compile" or "any TODO left", so a verifier that exists is not enough (P).

### 4.3 Planner and worker roles, workers never coordinate with each other

- Cursor, 2026-01-14 (page metadata datePublished 2026-01-14T12:00Z): final design is planners that create tasks, workers that take assigned tasks, finish them without coordinating with other workers, and push, and "a judge agent determined whether to continue, then the next iteration would start fresh" (P, cursor.com/blog/scaling-agents, page text line "At the end of each cycle, a judge agent determined whether to continue").
- Result reported by Cursor itself: agents ran "close to a week, writing over 1 million lines of code across 1,000 files" building a browser (P, same URL; vendor claim, not independently verified).
- Cognition reports the "map-reduce-and-manage" shape (a manager splits, child agents run, manager synthesises) is live in Devin (P, cognition.com/blog/multi-agents-working, 2026-04-22).

### 4.4 Work claimed through files, git or a tracker; code owns claiming, stall and retry

- Anthropic C compiler experiment, page date Feb 05, 2026 (metadata datePublished 2026-02-05, author Nicholas Carlini): 16 agents, "nearly 2,000 Claude Code sessions", 2 billion input tokens and 140 million output tokens, "a total cost just under $20,000", producing a roughly 100,000-line Rust compiler (P, anthropic.com/engineering/building-c-compiler).
- The harness is a `while true` shell loop that "spawns a new Claude Code session in a fresh container, and the cycle repeats"; the author says "I don't use an orchestration agent" (P, same URL, the page's only orchestration sentence).
  Tasks are claimed by writing a text file to `current_tasks/`; "If two agents try to claim the same task, git's synchronization forces the second agent to pick a different one" (P, same URL).
  Attempt 1 put the phrase "There is no orchestrator" in quotation marks; that string is not on the page and is withdrawn.
  The same paragraph calls the setup "a very early research prototype" with no process for managing high-level goals, so it is evidence that a loop plus git can work for a two-week experiment, not evidence of a production control plane.
- OpenAI Symphony, announced April 27, 2026 (A, openai.com/index/open-source-codex-orchestration-symphony/, Wayback raw capture 2026-10-10; live page returned HTTP 403): Symphony "is an agent orchestrator that turns a project-management board like Linear into a control plane for coding agents"; "If an agent crashes or stalls, Symphony restarts it"; "We built our workflow based on ticket statuses, using the task manager Linear as a state machine."
  The post's headline number is "a 500% increase in landed pull requests on some teams" (the post says "in the first three weeks" for some teams; vendor-sourced, not independently measured).
  OpenAI says the reason for building it was human attention: "most people could comfortably manage three to five sessions at a time before context switching became painful."
- Symphony's open-source spec read directly (P, `clones/symphony/SPEC.md`, origin github.com/openai/symphony, HEAD be10a1b committed 2026-09-15, repo first commit 2026-03-04, Status "Draft v1"):
  - Poll the tracker on a fixed cadence, default `polling.interval_ms` 30000 (SPEC.md:616; poll loop 8.1 at :735).
  - Stall detection: "If `elapsed_ms > codex.stall_timeout_ms`, terminate the worker and queue a retry", default `stall_timeout_ms` 300000 (5 minutes), disabled when <= 0 (SPEC.md:489-491, :631-633, :823-829).
  - Retry delay: fixed 1000 ms after a clean exit, and `min(10000 * 2^(attempt - 1), max_retry_backoff_ms)` after failure, cap default 300000 (SPEC.md:797-801).
  - Per-run bounds: `agent.max_turns` default 20 (SPEC.md:624), `codex.turn_timeout_ms` default 3600000 (:631), `agent.max_concurrent_agents` default 10 (:623).
  - Durability: "Current design is intentionally in-memory for scheduler state"; after restart no retry timers or running sessions are restored and the service recovers by re-polling the tracker and reusing workspaces (SPEC.md:1692-1703).
  - A grep of SPEC.md for max_attempts, max_retries, retry limit and give up found nothing, so I found no cap on the number of failure retries; absence is not proven.
- Claude Code agent teams: "Task claiming uses file locking to prevent race conditions", tasks have three states (pending, in progress, completed) and dependent tasks unblock automatically (P, code.claude.com/docs/en/agent-teams, read 2026-10-14).
  The same page marks the feature experimental and lists task-status lag and early lead exit as known limitations (section 5.2).

### 4.5 Deterministic state machine for control flow, agents at the leaves (with a counter-finding)

- Anthropic, 2024-12-19 (metadata datePublished 2024-12-19, modified 2026-08-10): "Workflows are systems where LLMs and tools are orchestrated through predefined code paths"; recommends "the simplest solution possible, and only increasing complexity when needed" (P, anthropic.com/engineering/building-effective-agents).
- One team replaced a supervisor LLM with a typed state machine, posted 2026-09-23T15:22:04Z (dev.to API published_at; the page shows only "Sep 23", the year comes from the API): token use down 71.4 percent across multi-step runs, median completion 44.8 s to 16.2 s, infinite-loop faults 8.2 percent to 0 percent, "500+ complex multi-step tasks"; leaf agents return a schema-validated `AgentReceipt` (stepId, agentName, status, durationMs, tokensConsumed, result, nextTrigger, artifactHashes; statuses COMPLETED, FAILED, NEEDS_HUMAN, RETRYABLE_ERROR); the repair guard is `context.repairCount >= 3`, "max 3 repair attempts before escalating to human" (P, dev.to/anasbuilds997/how-we-cut-70-of-multi-agent-token-waste-by-replacing-supervisor-llms-with-typed-state-machines-4alk).
  Caveat: the authors describe migrating their own production workflows and recording telemetry, not a controlled benchmark.
  A single-team, unreplicated account, so none of the percentages is used as a conclusion below; the receipt shape and the escalation terminal state are used as design illustrations only.
- Counter-finding from the Symphony post (A, OpenAI, April 27, 2026): "We also learned that treating agents as rigid nodes in a state machine doesn't work well. Models get smarter and can solve bigger problems than the box we try to fit them in." OpenAI moved "toward giving agents objectives instead of strict transitions".
  So the field evidence supports code owning ticket-level state, claiming, stall detection and retry, and does not support code micro-sequencing what happens inside a ticket (section 5.9).
- Anthropic's research system pairs agent adaptability with "deterministic safeguards like retry logic and regular checkpoints" and resumes from the point of failure; subagents are fresh and return lightweight references to externally stored output (P, anthropic.com/engineering/multi-agent-research-system, 2025-06-13).
- Durable execution engines (Temporal, Restate, DBOS, Inngest) sell the journal-and-resume guarantee; vendor blogs argue a plain job queue re-pays for every LLM call already made on rerun (S, vendor blogs from the 2026-10-14 search, vendor bias; not carried into sections 8 to 10).

### 4.6 Fresh session per unit, progress in files

- Anthropic, 2025-11-26 (metadata datePublished 2025-11-26): initializer agent plus a coding agent per later session; handoff artifacts are `init.sh`, `claude-progress.txt`, a JSON `feature_list.json` of 200+ features all initially failing where agents may only flip the `passes` field, and git history (P, anthropic.com/engineering/effective-harnesses-for-long-running-agents).
- Each session begins with a standard startup routine: check directory, read git log and progress notes, run a basic end-to-end test before new work (P, same URL).
- C compiler post: "each agent is dropped into a fresh container with no context", so the author asked for "extensive READMEs and progress files that should be updated frequently with the current status" (P, building-c-compiler, 2026-02-05).

### 4.7 Enforcement, not observation, for cost and loops

- Anthropic wrote scaling rules by query complexity after early agents made errors like "spawning 50 subagents for simple queries, scouring the web endlessly for nonexistent sources, and distracting each other with excessive updates" (P, multi-agent-research-system, 2025-06-13).
- Anthropic auto mode (published 2026-03-25, modified 2026-05-27): "If a session accumulates 3 consecutive denials or 20 total, we stop the model and escalate to the human" (P, anthropic.com/engineering/claude-code-auto-mode, page text).
- The "$47K loop" case: "The team had observability. They did not have enforcement." (P as to what the Vectara case-study file says, `vectara/awesome-agent-failures` docs/case-studies/langchain-a2a-47k-infinite-loop.md line 41; X as to the dollar figure and the incident itself, see 5.6).

## 5. What broke and why

Each subsection names the failure, the evidence, and the owner-side match.
Every owner line cited below was re-opened directly in this attempt; the line number is the line of the named plan file in section 3.

### 5.1 Handoffs lose decisions, and conversation-level handoffs are the weakest kind

- MAST taxonomy: 1,642 analysed traces, 7 frameworks, 14 failure modes in three groups (P, arxiv.org/abs/2503.13657, submitted 17 Mar 2025, last revised 26 Oct 2025).
- Prevalence from the paper's Figure 1 caption: step repetition 15.7 percent; reasoning-action mismatch 13.2 percent; unaware of termination conditions 12.4 percent; disobey task specification 11.8 percent; incorrect verification 9.1 percent; no or incomplete verification 8.2 percent; task derailment 7.4 percent; fail to ask for clarification 6.8 percent; premature termination 6.2 percent; loss of conversation history 2.8 percent; conversation reset 2.2 percent; ignored other agent's input 1.9 percent; disobey role specification 1.5 percent; information withholding 0.85 percent (P, arxiv.org/html/2503.13657v3, as read in attempt 1; not re-read in attempt 2).
- The three groups are reported in secondary summaries as roughly 42 / 37 / 21 percent (S; not carried into conclusions).
- The authors' own conclusion: tactical fixes (better role specs, a final-say agent, a verifier) gave gains "but task completion rates remained low, so more structural changes are needed" (P, same paper).
- Cognition, 2025-06-12: subagents given only the task, or even prior messages, build incompatible parts because "Actions carry implicit decisions, and conflicting decisions carry bad results" (P, dont-build-multi-agents).
- Cognition, 2026-04-22: "Communication is the bottleneck": children do not surface discoveries to siblings and context transfer can overwhelm the receiver (P).
- Anthropic's harness post, 2025-11-26: a session that ran out of context mid-feature left features half-built and undocumented, "so the next session had to guess what happened" (P).
- A practitioner X post on about 1,700 sessions reporting decisions lost at handoff is known only from a search snippet (HTTP 402); marked X and not used.
- Owner match, re-read: "four starts reported at 21:39Z never ran (no records)" (roadmap:359); and the records themselves: of 3338 record files only 245 (7.3 percent) carry a non-empty `evidence` list, and by kind that is `test.passed` 19 of 105, `review.passed` 6 of 85, `merged` 0 of 92, `verified` 75 of 88, `rejected` 18 of 18 (python3 count over `records/2026/10/*.json`, 2026-10-14, read-only).
  Attempt 1 claimed records carry "only a kind and a code"; that is wrong, the schema has `evidence` and `observations` fields (sample `records/2026/10/20261013010322-test-passed-pr-83-wo-20261012-7e13.json`), they are mostly left empty.
  The owner's handoff weakness is therefore unused receipt fields, not a missing receipt schema.

### 5.2 Agents coordinating through each other: locks, shared state, integrators

- Cursor tried three coordination shapes before the planner/worker design (P, cursor.com/blog/scaling-agents, 2026-01-14):
  - Equal-status agents with locks: "Agents would hold locks for too long, or forget to release them entirely... Twenty agents would slow down to the effective throughput of two or three, with most time spent waiting."
  - Optimistic concurrency control: simpler, but without hierarchy no agent took responsibility for hard problems, so work churned.
  - An integrator role: "We initially built an integrator role for quality control and conflict resolution, but found it created more bottlenecks than it solved. Workers were already capable of handling conflicts themselves."
- Anthropic C compiler: when compiling the Linux kernel, "Every agent would hit the same bug, fix that bug, and then overwrite each other's changes"; the fix was a known-good oracle (GCC) so agents worked on disjoint failures (P, building-c-compiler, 2026-02-05).
- Claude Code docs (read 2026-10-14): "Task status can lag: teammates sometimes fail to mark tasks as completed, which blocks dependent tasks"; "The lead can stop early too, deciding the team is finished before all tasks are actually complete"; "Teammates may stop after encountering errors instead of recovering"; "No session resumption with in-process teammates" (P, code.claude.com/docs/en/agent-teams).
- Owner match, re-read: "'you are the gate, you are the problem'. sched-worker-1 ... is ACTING ORCHESTRATOR" (roadmap:193) and "'do their job and go', 'nobody is a gate'" (roadmap:204).
  The field removed the integrator for the same reason the owner named.

### 5.3 The orchestrator or manager LLM is the bottleneck and the largest source of lost work

- Gas Town (Steve Yegge; Mayor, Witness, Refinery, Deacon, polecats) is the closest public analogue to the owner's line.
- Yegge's own history, "Welcome to Gas Town", Jan 1, 2026 (P, steve-yegge.medium.com/welcome-to-gas-town-4f25ee16dd04, read through the r.jina.ai text mirror because Medium returns HTTP 403 directly; mirror metadata Published Time 2026-01-01T21:07:32Z): "in August I started building my own orchestrator... Eventually it failed, and I threw it out and started over on v2, which also failed, but we got Beads out of it. Then v3 (Python Gas Town), which lasted a good six or eight weeks."
  The same post: "Gas Town is also expensive as hell" and "Do not use Gas Town if you care about money."
- Yegge's own v1.0 post, "Gas Town: from Clown Show to v1.0", Apr 3, 2026 (P, steve-yegge.medium.com/gas-town-from-clown-show-to-v1-0-c239d9a407ec, same mirror, Published Time 2026-04-03T05:08:04Z): the early months included "serial killer sprees, viciously taking out random workers mid-job" (the Deacon) and "the 22-nose Clown Show, where the Mayor scored a new clown nose every time it had massive data loss, which went on for weeks"; Gas Town "has largely been in maintenance mode since the Dolt migration finished" and users are being nudged to the successor Gas City.
  Cause of the data-loss era, in his words about Beads v0.x: "the inherent fragility of the v0.x Beads architecture, with its bidirectional sync, 3-way merge, two sources of truth, race conditions, and tombstone hell"; the fix was moving storage to Dolt (P, same post).
  This is a lesson for the owner's state stores: the author's stabilising move was one authoritative store, not more watchers.
- DoltHub, "A Day in Gas Town", 2026-01-15 (P, dolthub.com/blog/2026-01-15-a-day-in-gas-town, metadata datePublished 2026-01-15): the author closed all four PRs as unusable; Gas Town merged one PR autonomously "despite the integration tests failing"; a colleague had to `reset --hard`; the Mayor said all bugs were fixed when only two PRs existed and some work sat unpushed; the roughly 60 minute session cost about 100 US dollars, "about 10X the cost of a normal Claude Code session per unit time".
  Fairness note: this is a one-day account from January 2026, three months before the 1.0 release that Yegge describes as stable, so it is evidence about the early version, not about Gas Town today.
- Maggie Appleton, "Gas Town's Agent Patterns, Design Bottlenecks, and Vibecoding at Scale", 2026-01-23 (metadata datePublished 2026-01-23): she quotes an unnamed commenter, "The number of overlapping and ad hoc concepts in this design is overwhelming", and quotes Yegge that Gas Town "churns through implementation plans so quickly that you have to do a LOT of design and planning to keep the engine fed" (P, maggieappleton.com/gastown, page text).
- Anthropic research system: the lead waits on each batch of subagents synchronously, "the lead agent can't steer subagents, subagents can't coordinate, and the entire system can be blocked while waiting for a single subagent to finish searching" (P, multi-agent-research-system, 2025-06-13).
- Not carried (dropped from conclusions): a "three mayors and 141 orphaned Claude Code processes" one-week report (S, search snippet only; a targeted search on 2026-10-14 found no source, so it is X); a reviewer's reading that merge-queue and monitoring roles dominate Gas Town's engineering (S); a dev.to post attributing "orchestration, not reasoning" to an unnamed 2026 IEEE paper (X, probably MAST misattributed, no title or DOI).
- Owner match, re-read: the orchestrator seat idle for 12 minutes, "w1 idle 12 min again" (roadmap:360) and "sched-worker-1 idle 12 min again" (roadmap:378); "belt missed seating PR 136 reviewer and PR 149 (58c9) tester within 2 min; hand-seated" (roadmap:367); the merger merged PR 94 onto a red main because "the hold lived in prose" (roadmap:236); and a merger refused at max_agents "left the line idle 17 min until the owner asked" (roadmap:165).
  DoltHub's autonomous merge on red tests is the same failure class as roadmap:236.

### 5.4 Verification that verifies nothing, or never terminates

- MAST: no or incomplete verification 8.2 percent, incorrect verification 9.1 percent, premature termination 6.2 percent, unaware of termination conditions 12.4 percent (P).
- Anthropic harness, 2025-11-26: Claude marked features complete "without proper testing", and a later agent saw existing progress and declared the project finished (P).
- Anthropic C compiler: "it's important that the task verifier is nearly perfect, otherwise Claude will solve the wrong problem" and "it is easy to see tests pass and assume the job is done, when this is rarely the case" (P, 2026-02-05).
- The "$47K loop": an Analyzer and a Verifier loop ran 264 hours because the Verifier kept asking for "further analysis"; no termination predicate, no per-agent budget, no maximum-rounds counter (P as to what the Vectara file says, case-studies file lines 31, 35, 55).
  X as to the incident and the dollar figure: the Vectara file itself dates the incident to November 2025 and calls the post-mortem March 2026, yet a TechStartups URL in its own source list is dated 2025/11/14 and the Waxell dev.to retelling is dated 2026-04-15T15:08:49Z (dev.to API); the incident is vendor-retold, not independently confirmed.
  Reliable on the shape of the failure, not used for any number.
- Owner match, re-read: "the Haiku monitor answered OK on every patrol 01:24Z to 01:40Z, including 'OK merger' after the merger said it was blocked" and "things are being reported ok when they are not" (roadmap:200); the monitor seat wrote 558 note files today (the L06 read said 556), of which 350 match `PATROL.*idle` (L06 counted 349 with a stricter pattern, 274 contain the exact phrase "give it work within the minute"), 134 match BOTTLENECK, 2 match CORRECTION (grep over `records/2026/10/*note-monitor*`, 2026-10-14).

### 5.5 Review and merge capacity is the new bottleneck

- Faros AI Engineering Report 2026 (datePublished 2026-04-12, dateModified 2026-09-23, telemetry from 22,000 developers across 4,000+ teams, vendor-collected): median time to first PR review up 156.6 percent, median time in review up 441.5 percent, PRs merged with no review up 31.3 percent, incidents-to-PR ratio up 242.7 percent, work restarts up 13.8 percent, tasks idle seven or more days up 26 percent (P as read in attempt 1, faros.ai/blog/ai-acceleration-whiplash-takeaways; figures not re-read in attempt 2; the page was modified after publication so the numbers may have moved).
- Carnegie Mellon and Stanford, arXiv 2607.01904, submitted 2 Jul 2026, one mid-sized company, 802 developers, 196,212 pull requests (January 2024 to April 2026): per-capita throughput reached 2.09x the pre-mandate baseline, per-reviewer load roughly doubled, "automated review overtook human review, while merge and revert rates held steady" (P, arxiv.org/abs/2607.01904, abstract text).
- Semgrep's article about it (S, semgrep.dev/blog/2026/end-is-nigh-for-code-review; the page carries no date of its own, the URL path says 2026 and it cites the 2 Jul 2026 paper, so it is after that date; attempt 1's "July 2026" is unverified): PR volume 3.1x, reviewer pool 1.5x, share of PRs with written human feedback fell from 39 to 21 percent, "people didn't review harder. They approved more, and said less."
  The paper abstract reports stable merge and revert rates, so the two sources do not agree on the quality impact.
- Anthropic, 2026-03-25: "Claude Code users approve 93% of permission prompts", the stated reason for building auto mode; the classifier has a published "17% FNR" (false-negative rate) on real overeager actions (P, claude-code-auto-mode, page text).
  An approval seat that approves nearly everything is a cost with no filter value.
- Merge-queue sizing guides from bunnyshell.com and tianpan.co are unverified vendor blogs (S, not carried).
- Owner match, re-read: "Tester bottleneck: 8 PRs await test, 1 tester of cap 4" (roadmap:313, 2026-10-13T19:00Z); "Herdr suite ~20 min serial today" (prio:35) and "Verify 8b1b6cf still in serial herdr suite (case 33, no fails yet), 25 min" (roadmap:338, the 20:26Z entry); and "Haiku testers polled, forgot, or waited on finished shells, with stalls of 9 to 14 minutes on a lint that takes one" (cigate:21).
  Attempt 1 cited "full suite 25 minutes (prio:35)"; prio:35 says about 20 minutes and the 25 minute figure is roadmap:338, so the two lines are two measurements, not one.
  The owner's bottleneck is test gating and seat capacity, not human review volume; the field's human-review finding applies to the owner only if the factory ever feeds the owner's own review queue.

### 5.6 Cost blowups and runaway loops

- Anthropic: agents use about 4x the tokens of chat, multi-agent about 15x; "token usage by itself explains 80% of the variance" in BrowseComp; multi-agent only pays when task value covers the cost (P, multi-agent-research-system, 2025-06-13).
- Anthropic C compiler: "nearly 2,000 Claude Code sessions", "2 billion input tokens", "140 million output tokens", "a total cost just under $20,000" over two weeks (P, 2026-02-05).
- Gas Town: about 100 US dollars for a sixty-minute session, about 10x a normal session (P, DoltHub, 2026-01-15).
- Claude Code agent teams: "Token costs scale linearly" with teammates; "Start with 3-5 teammates for most workflows" (P, code.claude.com docs, read 2026-10-14).
- Weakly sourced and not used: a 31,000-retry tool loop costing 4,700 US dollars (X), SatGate's modeled median incident (X).
- Gartner, press release dated June 25, 2025, read from a Wayback capture of 2026-10-03 (A; live page returns HTTP 403): "Over 40% of agentic AI projects will be canceled by the end of 2027, due to escalating costs, unclear business value or inadequate risk controls"; the release also estimates "only about 130 of the thousands of agentic AI vendors are real".
  This is an analyst forecast, not a measured rate.
- Owner match, re-read: no dollar data exists in the owner files; the cost signals are the 15-seat fleet "why idle" (roadmap:250), the cap arithmetic "caps sum 4+4+2" (roadmap:252), and the monitor seat's 558 notes above.
  Cap enforcement exists partly, but "route-retry only matches max_seats, so it never retried" the reviewer refused at "8 agents live, max_agents 8" (roadmap:160), an enforcement gap of the kind the field describes.

### 5.7 Context exhaustion inside one agent

- Chroma, "Context Rot", July 14, 2025 (P, trychroma.com/research/context-rot, page text; 18 LLMs evaluated): models "do not use their context uniformly"; performance degrades as input length grows even on simple tasks.
- Anthropic harness, 2025-11-26: one-shotting ran the model out of context mid-implementation (P).
- Anthropic research system, 2025-06-13: "if the context window exceeds 200,000 tokens it will be truncated", so the lead saves its plan to memory first (P).
- Cognition, 2026-04-22: a long coding session fills context with clutter, which is why the reviewer is kept clean (P).
- Cursor, 2026-01-14: "We still need periodic fresh starts to combat drift and tunnel vision." (P, page text).
- Owner match, re-read: the owner halt "you're getting overloaded. We need to halt everything" (roadmap:399, 2026-10-14T00:38Z) and the compaction-guard wait inside seat bring-up, committed as "Belt frozen 180s per seat bring-up: seat.sh waits 15s for a compaction-guard ACK no seat prints" (commit 3419b86, `git log`).
  The field remedy is a fresh session per unit with file artifacts, not a guard that prompts a long-lived seat to compact.

### 5.8 Frameworks that were dropped or collapsed

- AutoGen (P, github.com/microsoft/autogen via the GitHub API on 2026-10-14): the README first gained a notice in commit 84f21a08 dated 2025-10-02 saying "if you are new to AutoGen, please checkout Microsoft Agent Framework. AutoGen will still be maintained and continue to receive bug fixes and critical security patches"; commit 027ecf0a dated 2026-04-06 ("Update maintenance mode banner in readme") produced the current text: "AutoGen is now in maintenance mode. It will not receive new features or enhancements and is community managed going forward."
  The repository's last push is 2026-04-15T11:59:09Z and it is not archived.
- Microsoft Agent Framework (P, github.com/microsoft/agent-framework releases API): tags `python-1.0.0` published 2026-04-02T16:16:18Z and `dotnet-1.0.0` published 2026-04-02T16:43:20Z.
  Its README describes "graph-based workflows supporting sequential, concurrent, handoff, and group collaboration patterns; includes checkpointing, streaming, human-in-the-loop, and time-travel" and links a migration guide from AutoGen, so the move from conversational group chat to graph workflows with checkpointing is stated by the vendor, not inferred.
- Cognition's 2025 post named OpenAI Swarm and AutoGen as examples of the multi-agent pattern it argued against (P, dont-build-multi-agents, 2025-06-12).
- The Swarm-to-Agents-SDK replacement was not confirmed from sources read; not claimed.
- Gas Town itself moved to maintenance mode with Gas City as successor (P, Yegge 2026-04-03, section 5.3).
- Klarna's reversal surfaced in search but is a customer-service story and is not used.
- Direction of travel from the primary sources: conversational peer-to-peer multi-agent to roles with a fixed graph, a tracker-driven loop, or a single authoritative store (Cursor, Symphony, Microsoft Agent Framework, Anthropic workflows, Beads on Dolt).

### 5.9 Where the evidence disagrees with the brief's diagnosis

- Brief: "we're using herdr wrong".
  Nothing in the field failure record is about a terminal multiplexer.
  The field failures are about who drives control flow and about handoffs.
  The owner-side L06 evidence agrees (L06 5.8): mechanical steps were given to LLM seats.
  The one pane-specific analogue is Claude Code's own agent teams limitations, "No session resumption with in-process teammates" and "Split panes require tmux or iTerm2" (P, code.claude.com docs), i.e. a pane-based fleet loses state when the host process dies; Yegge's Gas Town also runs on tmux and its data-loss era was about its store, not the multiplexer (P, 2026-01-01 and 2026-04-03 posts).
- Brief: "no cog should hold up the system, so we need a system, not agents or humans driving it".
  The field agrees on direction: Cursor removed its integrator, the Anthropic compiler experiment ran with "I don't use an orchestration agent", Symphony puts ticket state, claiming, stall timeout and retry in a service and the tracker.
  The wording "there is no orchestrator" attributed to Anthropic in attempt 1 was wrong; the page says the author did not use an orchestration agent, while his bash loop and lock-file protocol are an orchestrator in code.
- Where the field disagrees with a strong reading of "agents are the problem": Cognition and Anthropic both still use agents in a lead or manager role for decomposition (manager Devin, an Opus lead), and Cursor keeps a judge agent per cycle.
  The supportable claim is "code owns sequencing, claiming, stall, retry, budgets and gating; an agent may still decompose, write and review", not "no agent decides anything".
- Where the field disagrees with a typed-state-machine-everywhere design: OpenAI reports that "treating agents as rigid nodes in a state machine doesn't work well" and moved to objectives per ticket (A, Symphony post).
  A design that makes the line a DAG of tickets with code-owned transitions is supported; a design that scripts the steps inside a ticket is not supported by the strongest primary source.
- Where the field disagrees with the owner's idle rule: one-minute idle alarms manufactured work (bestpractices:143 "that alarm is what taught an agent to invent busywork"; 350 PATROL idle notes above); Symphony alarms on no event for `stall_timeout_ms` per run, default 5 minutes, and then restarts (SPEC.md:823-829), and the field's post-mortems recommend iteration, cost and wall-clock caps.
- The field also does not support the idea that more roles help: Cursor removed a role, and Gas Town's critic calls its concept count overwhelming (P, maggieappleton.com/gastown).
- Fairness caveat the other way: Gas Town reached a stable 1.0 on its Mayor-and-roles design by April 2026 after a store rewrite (P, Yegge 2026-04-03), so "role-heavy fleets cannot work" is also not supported; what the evidence supports is that stability came from the store and from months of fixing, which is the owner's lettered-cause pattern at larger scale.

## 6. Waits, polls, sleeps and leases

Local-track section; not applicable to this internet-track area.
For comparison, these are the waits and bounds the field uses, so the rebuild can adopt bounds from practice and not from invention.
A row that says "none stated" means I read the cited page for a bound and the page names none; the absence is the finding.

| Field system | What blocks | Bound | Source |
| --- | --- | --- | --- |
| Symphony | Tracker poll | default 30 s (`polling.interval_ms`) | P, clones/symphony/SPEC.md:616 |
| Symphony | Agent stalled (no event) | default 300000 ms (5 min), then terminate and queue retry; <= 0 disables | P, SPEC.md:489-491, :823-829 |
| Symphony | One agent turn | `turn_timeout_ms` default 3600000 (1 h) | P, SPEC.md:631 |
| Symphony | Failure retry delay | `min(10 s * 2^(attempt-1), 5 min)`; clean-exit continuation 1 s | P, SPEC.md:797-801 |
| Symphony | Turns per run, concurrency | `max_turns` 20, `max_concurrent_agents` 10 | P, SPEC.md:623-624 |
| Symphony | Number of failure retries | none found in the spec | P, SPEC.md grep, absence not proven |
| Anthropic auto mode | Classifier blocks | 3 consecutive or 20 total denials, then human or terminate | P, claude-code-auto-mode, 2026-03-25 |
| Typed state machine write-up | Repair loop | 3 attempts, then NEEDS_HUMAN | P, dev.to/anasbuilds997, 2026-09-23 |
| Anthropic research system | Lead waits on subagent batch | none stated; page names the synchronous wait as a limitation ("the entire system can be blocked while waiting for a single subagent") | P, multi-agent-research-system, 2025-06-13 |
| Anthropic research system | Context window | truncated at 200,000 tokens, plan saved to memory first | P, same URL |
| Claude Code teams | Teammate shutdown | none stated; "teammates finish their current request or tool call before shutting down, which can take time" | P, code.claude.com agent-teams Limitations |
| Claude Code teams | Task claiming | file lock, no timeout stated | P, same page |
| Claude Code teams | Idle teammate display | idle rows hide 30 s after the whole panel goes idle (display only, not a kill) | P, same page |
| Cursor scaling agents | Locks held too long | no bound; the design dropped locks entirely; "Agents occasionally run for far too long" | P, cursor.com/blog/scaling-agents |
| Anthropic C compiler | Agent time sinks | `--fast` sampling option; test output kept to a few lines; "Claude can't tell time and, left alone, will happily spend hours running tests" | P, building-c-compiler |
| Kubernetes Job | Pod failure retries | `backoffLimit` default 6, exponential delay 10 s, 20 s, 40 s capped at 6 minutes | P, kubernetes/website job.md:512 and :518 (GitHub main, read 2026-10-14) |
| Temporal | Activity retries | Maximum Attempts default unlimited; initial interval 1 s, coefficient 2.0, max interval 100 x initial; Workflow Executions do not retry by default | P, docs.temporal.io/encyclopedia/retry-policies (undated page, read 2026-10-14) |
| Post-mortem fixes | Loops | termination predicate, iteration cap, wall-clock watchdog, pre-call budget caps | P as to what the Vectara file recommends (lines 97, 109, 111); X on the incident |

## 7. Decisions an LLM makes that a rule could make

Local-track section; not applicable to this internet-track area.
For comparison, these are decisions the field moved from an LLM into code, each with the replacement rule.

- Which agent runs next and when the work is done: LLM supervisor replaced by a typed state machine with transition guards (dev.to/anasbuilds997, 2026-09-23, single-team) at the ticket level, and by tracker states as the state machine in Symphony (A, OpenAI 2026-04-27); inside a ticket OpenAI gives the agent an objective.
- Whether a task is claimed: LLM negotiation replaced by file lock plus git sync (P, building-c-compiler) or a tracker state plus a single poller (P, SPEC.md:50, :735).
- Whether a stalled agent is restarted: a timeout in the orchestrator (P, SPEC.md:823-829), not an agent noticing.
- Whether an action is allowed: classifier plus counters (P, auto mode), not a human approving 93 percent of prompts.
- Whether to continue another cycle: a judge at cycle end in Cursor (an LLM decision, kept, bounded to one per cycle) and an iteration cap in code for verification loops (Vectara file recommendation).
- How many subagents to spawn: scaling rules written into the prompt by Anthropic after the 50-subagent failure (P); a code-side concurrency cap is the stronger form and is what Symphony's `max_concurrent_agents` is (SPEC.md:623).
- Handoff content: free text replaced by a schema-validated receipt (dev.to/anasbuilds997) and by progress and feature-list files that agents may edit in only one field (P, effective-harnesses).
- Retry count: there is no field-wide number.
  Sources side by side: the dev.to guard allows 3 repair attempts then escalates; Anthropic auto mode stops at 3 consecutive or 20 total denials (denials, not retries); Kubernetes Jobs default to 6 failures with capped exponential delay (job.md:512, :518); Temporal Activities default to unlimited attempts with capped exponential delay (docs.temporal.io retry policies); Symphony uses capped exponential backoff and I found no attempt cap in its spec (SPEC.md:797-801).
  The owner's "3 retries then recover and report" is the owner's own global rule (`~/.claude/CLAUDE.md`, "Automation and accountability" paragraph) and matches the dev.to account, not an industry standard.
  Attempt 1 wrote that the field matches the number 3; that overstated it.
  What the field does agree on is that a retry is bounded in time or count, escalates to a human or a terminal state, and is enforced by the system and not by the agent.

## 8. What to carry forward

Each item is something the field validates that the owner either has or has started.
Items resting only on S or X evidence are not listed.

- Merge as code, verify as code, mechanical probes in place of an LLM monitor: the field removes gate agents (Cursor integrator, P) and Symphony runs stall detection in the service (P, SPEC.md:823).
  The owner side is the patrol-tick v2 with mechanical probes (roadmap:200).
  Keep and extend.
- Schema-validated receipts, and actually fill them: the owner's records have `evidence` and `observations` fields but 92.7 percent of records leave `evidence` empty and `merged` records never carry it (records count, 5.1).
  The typed `AgentReceipt` shape in the dev.to account and Anthropic's single-writable-field `feature_list.json` (P, effective-harnesses) show the pattern; make a seat's result one receipt with required evidence and nothing else.
- A protected acceptance list the worker cannot edit: Anthropic's harness allows only the `passes` field of `feature_list.json` to be changed (P), matching the owner's per-ticket acceptance criteria.
- Independent reviewer with no shared context: the owner already seats a separate reviewer; the field says keep it clean and give it the diff only (P, Cognition 2026-04-22).
- Fresh seat per unit and "do their job and go": the owner's rule (roadmap:204) is the field's fresh-session-per-unit with file artifacts (P, Anthropic harness 2025-11-26, Cursor "the next iteration would start fresh").
- Tracker as the durable store, scheduler memory disposable: Symphony keeps scheduler state in memory and recovers by re-polling the tracker and reusing workspaces (P, SPEC.md:1692-1703); Yegge's stabilisation came from one authoritative store (P, 2026-04-03).
- Per-run stall timeout, turn timeout, backoff cap and concurrency cap as config with defaults (Symphony defaults, section 6) in place of an idle alarm.
- Known-good oracle and nearly perfect verifier (P, building-c-compiler): a gate is only as good as its tests; the owner's red-main cause (l) was a hold living in prose (roadmap:236).
- Count the prompts and failures as the design signal: "Count prompts to the architect; every recurring kind is a missing rule" (retro:40) is the same discipline as Anthropic's evaluation habit.
- Enforcement before the call: budget, iteration and time caps enforced inside the system before the model call, because alerts lag (P as to the Vectara file's recommendation; the principle is also what auto mode and Symphony implement).
- Small tickets, one concern each: Anthropic recommends tasks "self-contained units that produce a clear deliverable" for teams (P, code.claude.com agent-teams "Size tasks appropriately"); matches the owner's small-ticket rule.

## 9. What to kill

- Peer coordination between agents through messages or shared locks (Cursor tried and removed it, P).
- Any LLM integrator, gate, merger-by-judgement or lead whose job is sequencing: Cursor removed the integrator (P), DoltHub's Gas Town merged on failing tests (P, early version), and the owner's own "you are the gate" ruling matches (roadmap:193).
- LLM monitors and idle alarms as a control mechanism: replaced by stall timeouts and caps.
  The owner's 350 PATROL idle notes are the local evidence (grep above) and bestpractices:143 already says so.
- Long-lived seats that accumulate context and then need compaction guards: fresh seat per unit is the field's remedy (5.7); the 15 s compaction-ACK wait in seat bring-up (commit 3419b86) is the local cost.
- Prose handoffs and prose holds ("the hold lived in prose", roadmap:236): replace with typed receipts and flag files.
- Unbounded verifier loops with no iteration cap or termination predicate (5.4).
- Parallel writers on overlapping files (Claude Code docs; Cursor): the owner's own ruling "one file, one in-flight ticket" is the same rule and should be enforced by the scheduler, not by memory.
- Adding roles to fix incidents: a lettered cause ticket per incident (L06 5.7 counts 51 letters from cause (a) at roadmap:227-228, 2026-10-13 13:05Z, to cause ay at commit c9b6f9f, committed 2026-10-14T01:43:48Z, about 12.6 hours) is the pattern Gas Town's critic describes as ad hoc concepts piling up (P, Appleton quoting a commenter).
- Not killed on the strength of the field: the dev.to percentages, the Gas Town orphaned-process report, the durable-engine marketing, and any dollar figure from the $47K story.

## 10. Open questions for the owner

Only questions that change the design.

- Which stages may still contain an LLM decision at all: decomposition (planner), writing (worker), review (clean-context reviewer), and what else?
  The field keeps those three and puts sequencing, claiming, stall, retry, budgets and merge in code.
  A "no LLM anywhere except worker" rule is stricter than any published system, including Cursor's judge and Cognition's manager.
- Does the factory script the steps inside a ticket (a full state machine) or give the worker an objective and verify the result mechanically?
  OpenAI's finding is that rigid nodes limited Codex and objectives worked (A, Symphony post); the dev.to account argues the opposite for supervisor routing.
  This changes how big a ticket can be and how much the DAG has to know.
- Is a human review queue part of the factory output, or does the factory merge on machine verdicts alone?
  The field data shows review capacity, not generation, is the limiting resource once agents multiply PRs.
  If the owner reviews, the factory needs a throttle on PRs in review; if the owner does not, the verifier quality bar must be far higher (Anthropic's "nearly perfect" verifier).
- What per-ticket token or dollar budget is acceptable?
  The published costs (about 100 US dollars per hour for a Gas Town style session, about 20,000 US dollars per two-week 16-agent project) set the order of magnitude, and enforcement caps need a number.

## 11. Sources

All read on 2026-10-14 UTC unless stated.
"Page date" is the date the page itself carries (visible date or page metadata); where a page shows none, that is said.

Primary web pages:
- P - Cheng et al., "Why Do Multi-Agent LLM Systems Fail?", arXiv 2503.13657, submitted 2025-03-17, v3 revised 2025-10-26 (arXiv listing page). https://arxiv.org/abs/2503.13657 and https://arxiv.org/html/2503.13657v3
- P - Walden Yan (Cognition), "Don't Build Multi-Agents", page datePublished 2025-06-12, dateModified 2026-03-15. https://cognition.com/blog/dont-build-multi-agents
- P - Walden Yan (Cognition), "Multi-Agents: What's Actually Working", page date 2026-04-22. https://cognition.com/blog/multi-agents-working
- P - Anthropic, "How we built our multi-agent research system", page date Published Jun 13, 2025 (metadata modified 2026-01-06). https://www.anthropic.com/engineering/multi-agent-research-system
- P - Nicholas Carlini (Anthropic), "Building a C compiler with a team of parallel Claudes", page date Feb 05, 2026. https://www.anthropic.com/engineering/building-c-compiler
- P - Anthropic, "Effective harnesses for long-running agents", page date 2025-11-26. https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents
- P - Anthropic, "How we built Claude Code auto mode", page date 2026-03-25 (modified 2026-05-27). https://www.anthropic.com/engineering/claude-code-auto-mode
- P - Anthropic, "Building effective agents", page date 2024-12-19 (modified 2026-08-10). https://www.anthropic.com/engineering/building-effective-agents
- P - Wilson Lin (Cursor), "Scaling long-running autonomous coding", page date 2026-01-14. https://cursor.com/blog/scaling-agents
- P - Tim Sehn (DoltHub), "A Day in Gas Town", page date January 15, 2026. https://www.dolthub.com/blog/2026-01-15-a-day-in-gas-town/
- P - Steve Yegge, "Welcome to Gas Town", Jan 1, 2026 (mirror metadata 2026-01-01T21:07:32Z), read via https://r.jina.ai/ because Medium returns HTTP 403. https://steve-yegge.medium.com/welcome-to-gas-town-4f25ee16dd04
- P - Steve Yegge, "Gas Town: from Clown Show to v1.0", Apr 3, 2026 (mirror metadata 2026-04-03T05:08:04Z), same method. https://steve-yegge.medium.com/gas-town-from-clown-show-to-v1-0-c239d9a407ec
- P - Maggie Appleton, "Gas Town's Agent Patterns, Design Bottlenecks, and Vibecoding at Scale", page datePublished 2026-01-23. https://maggieappleton.com/gastown
- P - Claude Code docs, "Orchestrate teams of Claude Code sessions", page undated, read 2026-10-14. https://code.claude.com/docs/en/agent-teams
- P - Hao He et al., "AI Writes Faster Than Humans Can Review", arXiv 2607.01904, submitted 2 Jul 2026. https://arxiv.org/abs/2607.01904
- P - Faros AI, "AI Engineering Report 2026: The Acceleration Whiplash", datePublished 2026-04-12, dateModified 2026-09-23 (vendor telemetry). https://www.faros.ai/blog/ai-acceleration-whiplash-takeaways
- P - Chroma, "Context Rot", July 14, 2025. https://www.trychroma.com/research/context-rot
- P - anassBld, "How We Cut 70% of Multi-Agent Token Waste by Replacing Supervisor LLMs with Typed State Machines", dev.to, published_at 2026-09-23T15:22:04Z (dev.to API; the page shows only "Sep 23"; single-team account). https://dev.to/anasbuilds997/how-we-cut-70-of-multi-agent-token-waste-by-replacing-supervisor-llms-with-typed-state-machines-4alk
- P (summary page, secondary in nature) - Vectara awesome-agent-failures, "LangChain A2A $47K infinite loop"; file's last commit 2026-04-30T21:40:02Z. https://github.com/vectara/awesome-agent-failures/blob/main/docs/case-studies/langchain-a2a-47k-infinite-loop.md
- P - Kubernetes docs source, Job concept page, `content/en/docs/concepts/workloads/controllers/job.md` lines 512 and 518. https://raw.githubusercontent.com/kubernetes/website/main/content/en/docs/concepts/workloads/controllers/job.md (also the local copy `investigation/k8s-docs/job.md`).
- P - Temporal docs, "Retry Policies", undated. https://docs.temporal.io/encyclopedia/retry-policies

Primary repos (GitHub API and clones):
- P - OpenAI Symphony repository, SPEC.md "Draft v1", HEAD be10a1b 2026-09-15, first commit 2026-03-04. https://github.com/openai/symphony (local: `investigation/clones/symphony`)
- P - microsoft/autogen README history: commit 84f21a08 2025-10-02, commit 027ecf0a 2026-04-06, last push 2026-04-15. https://github.com/microsoft/autogen
- P - microsoft/agent-framework releases `python-1.0.0` 2026-04-02T16:16:18Z and `dotnet-1.0.0` 2026-04-02T16:43:20Z, and README. https://github.com/microsoft/agent-framework
- Not used for claims: `investigation/clones/gastown` (origin github.com/gastownhall/gastown, HEAD 2026-07-23).

Archive copies:
- A - OpenAI, "An open-source spec for Codex orchestration: Symphony", April 27, 2026, by Alex Kotliarskyi, Victor Zhu and Zach Brock; Wayback raw capture 2026-10-10T21:18:15Z. Live https://openai.com/index/open-source-codex-orchestration-symphony/ returned HTTP 403. Capture: http://web.archive.org/web/20261010211815id_/https://openai.com/index/open-source-codex-orchestration-symphony/
- A - Gartner press release, "Gartner Predicts Over 40% of Agentic AI Projects Will Be Canceled by End of 2027", SYDNEY, June 25, 2025; Wayback raw capture 2026-10-03T06:10:29Z. Live page returned HTTP 403. Capture: http://web.archive.org/web/20261003061029id_/https://www.gartner.com/en/newsroom/press-releases/2025-06-25-gartner-predicts-over-40-percent-of-agentic-ai-projects-will-be-canceled-by-end-of-2027

Secondary or unverified:
- S - Simon Willison on the Anthropic research system, URL date 2025-06-14, page og:updated_time 2025-06-14T22:00:52Z. https://simonwillison.net/2025/Jun/14/multi-agent-research-system/ (read for date only; no claim rests on it).
- S - Semgrep, "AI Code Review and the End of Reviewing Every Change", page carries no own date; URL path 2026; cites the 2 Jul 2026 paper. https://semgrep.dev/blog/2026/end-is-nigh-for-code-review/ (the 39 to 21 percent and 3.1x figures were read in the page text, but remain the vendor's reading of the paper).
- S - Symphony press coverage from attempt 1 (Help Net Security 2026-04-28, InfoWorld, Tessl): superseded by the archive copy and the SPEC; not cited.
- S - Durable execution vendor blogs (zylos.ai, reactify-solutions.com, traversaal.ai, cohesivity.ai), 2026, found by search 2026-10-14; not carried.
- S - Merge-queue and review-bottleneck guides: bunnyshell.com, tianpan.co, codex.danielvaughan.com; not carried.
- X - Shijie Xie X post on about 1,700 sessions (HTTP 402). https://x.com/world_0618/status/2107848503305113972
- X - dev.to/alex_aslam post citing an unnamed IEEE paper. https://dev.to/alex_aslam/non-deterministic-agents-in-deterministic-workflows-the-state-machine-pattern-that-makes-53go
- X - CACM "The Hidden Token Trap of Agent Orchestration" (HTTP 403, snippet only). https://cacm.acm.org/blogcacm/the-hidden-token-trap-of-agent-orchestration/
- X - Gas Town "three mayors and 141 orphaned processes" report; no source found on 2026-10-14.
- X - the $47K loop dollar figure and dating (see 5.4); Waxell retelling https://dev.to/waxell/the-47000-agent-loop-why-token-budget-alerts-arent-budget-enforcement-389i, published_at 2026-04-15T15:08:49Z (dev.to API).
- X - METR 2025 trial and reported 2026 follow-up; METR pages were not read; not used.

Owner-side files (all under `~/.local/state/coq/coq-jev-herdr-plugin/`, re-read directly in attempt 2):
- `plans/2026/10/20261012212500-roadmap.md` lines 160, 165, 193, 200, 204, 227, 228, 236, 250, 252, 313, 338, 359, 360, 367, 378, 399.
- `plans/2026/10/20261013025600-priority-list.md` line 35.
- `plans/2026/10/20261013194800-ci-gate-design.md` line 21.
- `plans/2026/10/20261013021500-best-practices-agent-line.md` line 143.
- `plans/2026/10/20261012222000-retro-architect-flood-and-halt.md` line 40.
- `records/2026/10/*.json` (3338 files) and `records/2026/10/*note-monitor*` (558 files), counted 2026-10-14.
- Main checkout `git show -s c9b6f9f` (committed 2026-10-13T20:43:48-05:00 = 2026-10-14T01:43:48Z) and commit 3419b86 message.
- `~/.claude/CLAUDE.md` "Automation and accountability" paragraph (retry rule).
- L06 area file `L06-owner-retros-and-plans.md`, sections 5.1 to 5.8, for section numbers cited as "L06 5.x" and the "51 lettered causes" count.

## 12. Attempt 2 change log and gaps that cannot be closed

Closed, with evidence:
- The "There is no orchestrator" quotation is removed from 4.4, 5.9 and 9; the real sentence is "I don't use an orchestration agent." (building-c-compiler, page text).
- The prio:35 citation is fixed: prio:35 says "Herdr suite ~20 min serial today"; the 25 minute figure is roadmap:338 (5.5).
- Exact page dates now given for the Anthropic research post (Jun 13, 2025), the C compiler post (Feb 05, 2026), the dev.to typed state machine post (2026-09-23T15:22:04Z, year from dev.to API), Maggie Appleton (2026-01-23), Gartner (June 25, 2025, via archive), Simon Willison (2025-06-14), Yegge's two Medium posts (2026-01-01 and 2026-04-03 via text mirror), OpenAI Symphony (April 27, 2026, via archive), Cognition, Cursor, DoltHub, Chroma, Faros, arXiv and Anthropic harness and auto mode pages.
- OpenAI Symphony is now sourced from the primary page (archive copy) and the primary spec (`clones/symphony/SPEC.md`, with line numbers).
  Reading it produced a counter-finding that attempt 1 missed: OpenAI itself says rigid state-machine nodes did not work well (5.9, 10).
- AutoGen and Microsoft Agent Framework are now sourced to GitHub commits and releases (5.8); attempt 1's "notice dated 2025-10-02" was correct for the first notice but the "maintenance mode, community managed" text dates from 2026-04-06.
- Yegge's two failed versions are now primary (2026-01-01 post).
  The "141 orphaned processes" claim could not be sourced and is dropped from conclusions (5.3).
- Owner-match lines for roadmap, prio, cigate, bestpractices and retro were re-opened and checked; one error found and fixed (prio:35), one over-claim removed ("records carry only a kind and a code"), one loose citation tightened (bestpractices:143, not 143-144), and counts re-run (350 PATROL-idle files against L06's 349; 558 monitor notes against 556).
- The bounds table now carries a source and a bound for every row, or states that the cited page names none.
- The retry-count claim now has six sources and a corrected conclusion: there is no field-wide number (section 7).

Cannot be closed:
- The MAST per-mode percentages (5.1) and the Faros figures (5.5) were read in attempt 1 and not re-read in attempt 2; the arXiv abstract page and Faros metadata were re-checked, the numbers were not.
- The OpenAI Symphony 500 percent claim and Cognition's Devin Review bug rate are vendor claims; no independent measurement exists in what I read.
- Gas Town's current reliability after v1.0 (April 2026) is only described by its author; no independent post-1.0 report was found.
- The date of the Semgrep article has no on-page value; only a lower bound (2 Jul 2026) can be given.
- The $47K loop cannot be confirmed independently; it stays X on the number and the timeline.
- The Claude Code agent teams page is undated and the feature is experimental, so its limitations may have changed after 2026-10-14.
