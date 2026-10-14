# I01 - Production fleets of coding agents

Investigated 2026-10-14 (UTC) by the I01 investigator, step R-01, attempt 2 (attempt 1 was thin; this version closes the critic's seven gaps).
Read-only: the only writes are this file, one shallow clone under `clones/symphony`, and scratch text under the session scratchpad.
All web sources were fetched on 2026-10-14; each source carries its own publication date in section 11.
Where a primary page could not be fetched, the claim is marked "secondary" or "unverified" and names the summary it came from.
Attempt 2 retrieved the OpenAI harness-engineering and Symphony posts from the Wayback Machine, the factory.com Missions post, the Shopify River post, the Ramp post, the Uber uReview post, the Google Jules pages and both GitHub blog pages directly.

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

This file surveys what shops that run many coding agents against one codebase have published about control plane shape, queueing, review, merge and what they measured.
The sample is Anthropic, OpenAI, Cursor, Cognition, Stripe, Spotify, Shopify, Ramp, Uber, Factory, Google and GitHub, with Shopify's River post added in attempt 2, plus OpenAI's open Symphony spec, which I cloned and read line by line.
The finding that matters most is that the shops shipping at volume share one shape: a deterministic control plane (a daemon, a workflow in code, a job runner) hands each unit of work to a disposable per-task sandbox, and the LLM runs only inside that node.
Almost none of them host long-lived agents in terminal panes, and the two that put parallel writers on shared state (Cursor's first attempts, Anthropic's C compiler run) paid for it in locks, conflicts and wasted work.
The field is not unanimous on one point the brief takes as settled: Factory and Cognition keep an LLM orchestrator that assigns work, and OpenAI's Symphony lets the agent move ticket states and run the land step, so "no LLM in the control loop" is the owner's stricter line, not the field's consensus.

## 3. Where it lives

Everything here is web material plus one clone:

- `clones/symphony`, github.com/openai/symphony, shallow clone made 2026-10-14, HEAD be10a1b79df723d6d7612b5651c8522704dafb2e committed 2026-09-15T15:12:07-07:00. `SPEC.md` is 2312 lines. The Elixir reference implementation is under `clones/symphony/elixir/`.
- Anthropic engineering posts: multi-agent-research-system, building-c-compiler, effective-harnesses-for-long-running-agents, managed-agents, redesigning-source-control (URLs in section 11).
- OpenAI: harness-engineering (2026-02-11) and the Symphony announcement (2026-04-27), both read from Wayback snapshots because openai.com returns HTTP 403 to WebFetch and curl.
- Stripe: stripe.dev minions posts, part 1 and part 2.
- Cursor: cursor.com/blog/scaling-agents and cursor.com/changelog/08-19-26.
- Cognition: cognition.com/blog/dont-build-multi-agents, multi-agents-working, devin-can-now-manage-devins.
- Spotify: engineering.atspotify.com Honk parts 1, 2, 3.
- Shopify: shopify.engineering/introducing-roast (2025-06-18) and shopify.engineering/under-the-river (2026-05-28, the River post).
- Ramp: builders.ramp.com "Why we built our background agent" (undated) and the modal.com case study (2026-02-19).
- Uber: Pragmatic Engineer interview (2026-03-10) and Uber's own uReview post (2025-08-12); the Minion platform has no Uber-authored post that I could find.
- Factory: factory.com/news/missions (page metadata says 2025-02-26, see section 11) and the AI Engineer Europe 2026 talk abstract.
- Google Jules: blog.google (2025-05-20), the Google Developers Blog Jules Tools post (2025-10-02), jules.google usage-limits page (undated).
- GitHub: github.blog "Welcome home, agents" (2025-10-28) and "How to orchestrate agents using mission control" (2025-12-01).
- Cross-references to sibling local files: `L04-herdr.md` (crash 2026-10-13), `L13-llms-doing-scheduler-work.md` (record counts), `L01-line-scripts.md` (poll table).

## 4. What works

### 4.1 The fleet table

| Shop | Execution unit | Control plane | Merge and review | What they measured |
| --- | --- | --- | --- | --- |
| Stripe Minions | Pre-warmed devbox, disposable "cattle, not pets", about 10 s to ready, no prod, no internet | "Blueprints": workflows in code that interleave deterministic nodes (lint, push) with agentic nodes (implement, fix CI) | Human reviews every PR; at most 2 CI rounds, then the branch goes back to a human | 1,000+ merged PRs per week (2026-02-09), 1,300+ (2026-02-19), 3M+ tests, ~500 MCP tools |
| OpenAI Symphony | Per-issue workspace, fresh clone, Codex app-server | Deterministic daemon that polls the tracker, dispatches under a concurrency cap, retries with backoff | Agent opens PR; human moves ticket to Merging; agent runs a `land` skill, never `gh pr merge` | "a 500% increase in landed pull requests on some teams", "in the first three weeks" (openai.com Symphony post, 2026-04-27, via Wayback). Self-reported, no baseline or team count, so treat as marketing-grade. 500% increase equals about sixfold |
| OpenAI harness engineering | Per-agent worktree plus local observability stack | Humans steer through prompts; Codex reviews its own changes, requests agent reviews, and loops "until all agent reviewers are satisfied" | "Humans may review pull requests, but aren't required to"; "minimal blocking merge gates"; agents "often squash and merge their own pull requests" (openai.com, 2026-02-11, via Wayback) | "on the order of a million lines", "roughly 1,500 pull requests" in five months, 3 engineers growing to 7, "3.5 PRs per engineer per day" (same post, verified in primary) |
| Cursor | Cloud VM per agent, subagents on their own VMs | Planners create tasks, workers grind on one task, a judge ends each cycle; later, agents subscribe to events and wake | Integrator role dropped: "created more bottlenecks than it solved"; Bugbot reviews | 1M+ line browser in about a week; Solid to React migration over 3 weeks |
| Cognition Devin | One VM per Devin | Manager Devin scopes, assigns child Devins, resolves conflicts | Generator-verifier loop with a clean-context reviewer before a human sees the PR | Devin Review finds ~2 bugs per PR, ~58% severe (2026-04-22) |
| Anthropic C compiler | One Docker container per agent, bare git repo as upstream | Plain bash `while true` loop starting a fresh `claude` session; lock files in `current_tasks/` | Agents resolve merge conflicts themselves; CI added to stop regressions | "nearly 2,000" sessions, "2 billion input tokens", 140M output tokens, "just under $20,000" - all approximate, quoted from the post (2026-02-05) |
| Anthropic internal | Agent sandboxes, session log outside the sandbox | Managed Agents: brain, hands and session decoupled | No merge queue with a global lock: "We haven't been able to effectively replicate the industry standard of a global repository lock on the merge queue, so instead, we've invested in post-merge and pre-deploy automated testing." Never replicated, so never run at this scale. Adversarial Claude review; humans review intent | "around 2,500 code changes merged per day" in May 2026, "over 30,000 per day" as of September (redesigning-source-control, 2026-10-13) |
| Shopify River | Aquifer platform: Postgres-backed append-only session log, disposable harness, disposable sandbox, per-session ephemeral cell | Slack @river in public channels starts a session; profiles (including a PR review profile woken by an external system) are Nix-built bundles on one substrate | Monorepo "World"; "Merge queues became load-bearing" after consolidation; the post does not describe approval or merge policy | 7,000+ people, 59,918 sessions and 3,536 River-coauthored merged PRs in 30 days, "one in eight merged pull requests", median session 19 minutes and 50 tool calls (shopify.engineering/under-the-river, 2026-05-28) |
| Spotify Honk | Container with few binaries, almost no network | Fleet Management jobs wrap an agent; internal CLI can swap agents and LLMs | Same PR review and merge path as before; LLM judge before PR opens | 1,500+ merged PRs (2025-11-06); judge vetoes ~25%, agent recovers ~50% of vetoes |
| Ramp Inspect | Modal Sandbox per session, full-stack services inside | Modal Functions on cron build snapshots, Dicts hold session locks, Queues route prompts; follow-up prompts queue per session; Cloudflare Durable Objects and a per-session SQLite hold state | PR opened with the requesting user's own GitHub token so nobody approves their own change; agent verifies with screenshots, Sentry, Datadog | "roughly half of all merged pull requests" (Modal, 2026-02-19); the earlier undated Ramp post says "~30%"; "hundreds of concurrent sessions" (Modal) vs "no limit" (Ramp). The share grew over time, so cite both with dates |
| Factory Missions | Worker sessions with clean context, commit through git | LLM orchestrator plus "a thin deterministic layer responsible for bookkeeping, validation" (AI Engineer Europe 2026 abstract); orchestrator prompt "roughly 700 lines" (same abstract) | Every milestone ends with a validation phase; "validation contract, written during planning before any implementation exists"; "Serialize code changes and parallelize safe research" | "The median mission runs for about 2 hours"; "14% of missions run longer than 24 hours"; "12x more tokens" than a normal session at the median (factory.com/news/missions, primary) |
| Uber | Minion background-agent platform, grew out of DevPod and CI; Shepard for migrations, Code Inbox for review routing (background-agents.com summit page, 2026-05-07) | Model gateway, MCP gateway, specialised agents (Pragmatic Engineer) | uReview: reviews "more than 90% of roughly 65,000 diffs each week", median review time 4 minutes (Uber blog, 2025-08-12) | "11% of pull requests opened by agents", "AI-related costs are up 6x since 2024" (Pragmatic Engineer, 2026-03-10). A video-summary site claims "more than 70%" of PRs, a conflicting unverified figure. No Uber-authored Minion architecture post found |
| Google Jules | One temporary cloud VM per task: "It clones your codebase into a secure Google Cloud virtual machine" (blog.google, 2025-05-20); "spins up a temporary VM, does the work there, and sends back a pull request" (Google Developers Blog, 2025-10-02) | Task queue behind a plan gate: Jules shows its plan first; per-plan caps of 3, 15 or 60 concurrent tasks (jules.google usage-limits page, undated) | Diff plus plan for the human; Google's post "doesn't describe a merge step" | None published. Daily task caps 15, 100, 300 by plan are quotas, not measurements |
| GitHub Agent HQ and Copilot mission control | Agents run on "your preferred compute, whether that's GitHub Actions or self-hosted runners" (github.blog, 2025-10-28) | Mission control assigns tasks "in parallel" across repos; branch controls gate CI for agent code | Copilot "gets an initial first-line review" before humans see code; humans review PRs; "One-click merge conflict resolution" | None published; the 2025-12-01 post says "The article gives no usage or performance metrics" and estimates agent runs of "a few minutes to an hour" |

Google has published product and usage pages for Jules but no fleet architecture post: no control plane, queue, merge or measurement write-up exists on blog.google, the Google Developers Blog or jules.google as of 2026-10-14.
The Jules row therefore describes a product surface, not a fleet design, and carries no weight in the recurring patterns below except "VM per task".
Two further Google queries (Antigravity, Agent HQ equivalents) returned nothing primary, so Google is closed as "no published architecture".
The OpenAI "Unrolling the Codex agent loop" post (openai.com/index/unrolling-the-codex-agent-loop/) returned HTTP 403 and has no Wayback snapshot; by its title it describes one agent's loop, not a fleet, so its absence does not change any row.

### 4.2 Patterns that recur, with evidence

- A deterministic skeleton with LLM nodes inside it.
  Stripe: "Blueprints are workflows defined in code that direct a minion run", with deterministic nodes "Run configured linters" and "Push changes" (stripe.dev part 2, 2026-02-19).
  Shopify: "Non-determinism is the enemy of reliability", and an AI step is a placeholder to be replaced by deterministic code once the problem is understood (shopify.engineering Roast post, 2025-06-18).
  Shopify River's session is an "Append-only event log. Postgres-backed." while the harness is "cheap to recreate and disposable" (under-the-river, 2026-05-28); the Shopify River post was found in attempt 2 (attempt 1 only found the Roast post and a third-party River summary).
  Symphony: "The orchestrator is the only component that mutates scheduling state" (`clones/symphony/SPEC.md` section 7, line 637).
  Spotify: Fleet Management stays the same and the agent replaces the migration script (Honk part 1, 2025-11-06).
- One disposable sandbox per task, state kept outside it.
  Stripe devboxes are "cattle, not pets" (part 2).
  Anthropic Managed Agents: the original single container "became a pet" and was lost when it failed; the redesign has an append-only session log outside brain and hands and a harness that restarts with `wake(sessionId)` (anthropic.com/engineering/managed-agents, 2026-04-08).
  Ramp and Cursor and Cognition and Jules all give each task its own VM or sandbox.
- A small fixed retry budget, then a human or a record.
  Stripe: "at most two rounds of CI", after which the branch returns to its human operator.
  Spotify homegrown loop: 10 turns per session, three session retries (Honk part 2, 2025-11-24).
  Symphony: failure retries use `min(10000 * 2^(attempt-1), max_retry_backoff_ms)`, default cap 300000 ms (`SPEC.md` section 8.4, lines 790-817).
- Reconciliation against an external source of truth on every tick, so a restart loses nothing important.
  Symphony runs stall detection and a tracker refresh before every dispatch and, by design, keeps no database: "No retry timers are restored from prior process memory ... Service recovers by startup terminal workspace cleanup, fresh polling of active issues, re-dispatching eligible work" (`SPEC.md` sections 7.4, 8.5, 14.3, lines 725-731, 819-839, 1690-1704).
- Verification is a gate written outside the agent.
  Spotify verifiers run via a stop hook so "the PR isn't opened" if one fails, and an LLM judge vetoes about a quarter of sessions (Honk part 3, 2025-12-09).
  Factory writes a validation contract before any code exists: "The central safeguard is the validation contract, written during planning before any implementation exists" (ai.engineer talk abstract, AI Engineer Europe 2026, page undated).
  Anthropic C compiler: "Verifier mistakes lead Claude to solve the wrong problem", so near-perfect tests came first (building-c-compiler, 2026-02-05).
  Anthropic long-running harness: a JSON feature list where the coding agent may only flip `passes` (effective-harnesses, 2025-11-26).
- Writes single-threaded, or partitioned so they cannot touch.
  Cognition: "setups where multiple agents contribute intelligence to a task while writes stay single-threaded" (multi-agents-working, 2026-04-22).
  Factory: the talk section is titled "Serialize code changes and parallelize safe research", and the Missions post says "Serial execution with targeted parallelization has worked better than broad parallelism" (factory.com/news/missions).
  Anthropic C compiler: parallelism worked on independent failing tests, and for the Linux kernel a GCC oracle was used so each agent got a different file subset.
- Event-driven wake instead of agent-side waiting.
  Cursor, 2026-08-19: an agent "subscribes to an event source and wakes when something happens", and cloud agents auto-subscribe to the PRs they open and drive them to completion.
  Cursor's January post listed "planners should wake when their tasks finish" as an open problem, so this is the wake-up problem the owner also has, and Cursor solved it with subscriptions seven months later.
- Humans removed from the per-PR path where the volume demands it.
  Anthropic never replicated the global-lock merge queue at agent scale and relies on post-merge and pre-deploy testing, with humans reviewing intent.
  The exact sentence: "We haven't been able to effectively replicate the industry standard of a global repository lock on the merge queue, so instead, we've invested in post-merge and pre-deploy automated testing" (redesigning-source-control, 2026-10-13).
  The same post says "A proper merge queue, for example, doesn't make much sense at agent scale" and "concurrent changes can conflict, but Claude can typically fix these conflicts".
  OpenAI harness team: "Humans may review pull requests, but aren't required to" and "minimal blocking merge gates" (openai.com, 2026-02-11, Wayback). The post does not say humans "sample post-merge"; that phrase in attempt 1 came from a summary and is withdrawn.
  Stripe and Symphony keep a human review gate, at 1,300 PRs per week and at the Human Review state respectively.
  Shopify points the other way: after consolidating into one monorepo "Merge queues became load-bearing" (shopify.engineering/under-the-river, 2026-05-28). Two large shops, opposite merge-queue outcomes; the owner's merge step is a queue by another name, so this is an open design choice and not a settled field norm.

## 5. What broke and why

- Cursor, flat self-coordination with a shared file and locks: "Twenty agents would slow down to the effective throughput of two or three"; locks were held too long or never released; agents crashed holding locks (cursor.com/blog/scaling-agents, 2026-01-14).
  Optimistic concurrency was simpler but still left agents risk-averse and churning.
  The integrator role was dropped because "Workers were already capable of handling conflicts themselves".
  Mechanism: shared mutable coordination state plus equal-status agents.
- Cognition 2025: parallel subagents hold conflicting implicit decisions (Flappy Bird background and bird mismatched), so decisions get dispersed (dont-build-multi-agents, 2025-06-12).
  The same author's 2026-04-22 post still calls unstructured swarms "mostly a distraction" and lists failures of the narrower patterns: review loops that keep finding new issues, child agents that "assume they share state with their children when they don't", and no default cross-agent messaging.
  Mechanism: shared-state assumptions that do not hold.
- Anthropic research system: early versions spawned 50 subagents for simple queries, searched endlessly, and distracted each other; "Synchronous execution bottlenecks the system" because the lead cannot steer subagents and they cannot coordinate (multi-agent-research-system, 2025-06-13).
  The same post states "most coding tasks involve fewer truly parallelizable tasks than research", so multi-agent is a weaker fit for code.
  Cost: agents use about 4x chat tokens and multi-agent about 15x.
- Anthropic C compiler: 16 agents on the Linux kernel were "stuck solving the same task"; merge conflicts were frequent; late features broke existing code until CI was added; one agent ran `pkill -9 bash` and killed its own loop; Claude "can't judge elapsed time" and spent hours on tests (building-c-compiler, 2026-02-05).
  Mechanism: no partition of work, no regression gate, no bounded task time.
- Spotify: open-source agents (Goose, Aider) "didn't reliably produce mergeable PRs at scale"; the homegrown loop exhausted its turn limit on cascading multi-file edits and forgot the task when context filled (Honk part 2, 2025-11-24).
  The worst failure class is "a PR that passes CI but is functionally incorrect", which erodes trust (Honk part 3).
- OpenAI harness (primary, openai.com 2026-02-11 via Wayback snapshot 20261012001826): "our bottleneck became human QA capacity"; "Codex replicates patterns that already exist in the repository - even uneven or suboptimal ones", which drifts and needed a recurring "garbage collection" cleanup; AGENTS.md "(roughly 100 lines) ... serves primarily as a map"; "That Slack discussion that aligned the team on an architectural pattern? If it isn't discoverable to the agent, it's illegible".
  The post also says the end-to-end autonomy "depends heavily on the specific structure and tooling of this repository and should not be assumed to generalize".
  The "bullied authors" and "nothing above P2" claims in attempt 1 are NOT in the primary post (grep for bully, P2, bias found nothing); they came from ZenML and theneuron summaries and are unverified. They are withdrawn from section 9.
  The primary does show a loop with no stated bound: iterate "until all agent reviewers are satisfied" (a "Ralph Wiggum Loop").
- Symphony primary (openai.com 2026-04-27, Wayback snapshot 20261010211815) names the problem the owner has: "most people could comfortably manage three to five sessions at a time before context switching became painful ... We'd forget which session was doing what, jump between terminals to nudge agents back on track".
  This is a field statement that supervising agent sessions in terminals does not scale past a handful per human.
- Shopify River: consolidating into the World monorepo broke things: "CI had to scale by an order of magnitude, almost overnight", "The build cache became a product", "Dozens of scattered team-level assumptions had to be undone" (under-the-river, 2026-05-28).
- Anthropic Managed Agents: one container holding session, harness and sandbox became a pet whose failure lost the session (managed-agents, 2026-04-08).
- Claude Code agent teams, the closest shipped analogue to the owner's pane-and-records design, is documented by Anthropic as experimental with these limits: no session resumption for in-process teammates, "Task status can lag: teammates sometimes fail to mark tasks as completed, which blocks dependent tasks", one team per session, no nested teams, and teammates "may stop after encountering errors instead of recovering" (code.claude.com/docs/en/agent-teams, fetched 2026-10-14).
  Its coordination is file based: a mailbox JSON file per agent and file locking for task claims.
- Cost and productivity caution: METR's 2025 randomised trial found experienced developers 19% slower with AI tools while believing they were 20% faster; METR's 2026 follow-up changed its design because the data became hard to interpret (secondary, letsdatascience and particula summaries).
  Uber: AI-related costs up 6x since 2024 (Pragmatic Engineer, 2026-03-10).
- Where the evidence disagrees with the brief:
  - The brief says no agent should assign work.
    Stripe, Symphony, Spotify and Roast agree for dispatch, retry and merge.
    Factory (orchestrator Droid, "roughly 700 lines of text governing feature decomposition and failure handling" plus "a thin deterministic layer responsible for bookkeeping, validation", both quotes from the ai.engineer talk abstract; the factory.com Missions post itself contains neither phrase, it says "An orchestrator breaks large projects into milestones"), Cognition (manager Devin) and Cursor (planners) all use an LLM to decompose a goal into work items inside a run.
    The line that holds across the field is: a system dispatches and retries units of work, an LLM may decompose a goal into those units.
  - The brief says "we're using herdr wrong".
    I found no published fleet that hosts its agents in terminal-multiplexer panes.
    The only pane-based shipped design is Claude Code agent teams in split-pane mode, which Anthropic labels experimental and which needs an interactive session (agent teams doc: in `-p` headless mode "Claude doesn't spawn teammates").
    So the field evidence supports "panes are the wrong substrate for an unattended fleet" (see `L04-herdr.md` section 2 for the owner's own 9.5 hour crash), but does not say herdr is misused for interactive supervision.
  - OpenAI's Symphony is the nearest published match to the owner's goal and it is not LLM-free: the scheduler is deterministic, but ticket state changes, PR comments and the land loop are done by the agent through tools (`SPEC.md` section 1 "Important boundary"; `elixir/WORKFLOW.md` lines 105, 249-255).
    The owner's records plus `merge.sh` (see `L13-llms-doing-scheduler-work.md` section 4) already take the land decision out of the agent, which is stricter than Symphony.

## 6. Waits, polls, sleeps and leases

This is an internet area, so the local table is not applicable.
For comparison, these are the blocking points the field publishes and their bounds:

| Where | What it waits on | Bound |
| --- | --- | --- |
| Symphony poll loop (`SPEC.md` 8.1; `elixir/WORKFLOW.md` polls Linear every 5 s) | Next tick | `polling.interval_ms`, no unbounded inner wait |
| Symphony stall detection (`SPEC.md` 8.5) | Agent activity | `codex.stall_timeout_ms`, kills and re-queues |
| Symphony retry (`SPEC.md` 8.4) | Backoff timer | 1 s after clean exit; failure backoff capped at 300000 ms |
| Symphony turn loop (`SPEC.md` 7.1) | Agent turns | `agent.max_turns` |
| Stripe CI loop | CI result | At most 2 rounds |
| Stripe devbox start | Pre-warmed pool | About 10 s target |
| Spotify homegrown loop | Agent turns | 10 turns per session, 3 session retries |
| Ramp snapshots | Cron build of repo snapshots | Snapshots at most 30 minutes old |
| Cursor agents | Event subscription | Wake on PR, thread or schedule event, no poll in the agent |
| Anthropic C compiler | Task claim | Lock file in git; losing agent picks another task |
| Claude Code agent teams | Task claim | File lock; teammate idle hooks `TeammateIdle`, `TaskCompleted` can reject with exit code 2 |

The pattern: every wait has a timer or an event, and the waiter is a daemon or a hook, never an LLM sitting idle.

## 7. Decisions an LLM makes that a rule could make

This is an internet area, so I list the field's version: where a published fleet still uses an LLM for something a rule could do.

- Symphony ticket transitions and PR handling.
  The agent moves Todo to In Progress to Human Review and runs the `land` skill (`elixir/WORKFLOW.md` lines 105, 244-255).
  Rule that would replace it: a state machine keyed on PR and check status from GitHub, which is what `merge.sh` already does locally.
- Claude Code agent teams, plan approval.
  "Claude Code approves the plan in the lead's session as soon as the request arrives, without the lead reviewing it", so the approval step is nominal.
  Rule: skip the step, or gate on a deterministic check of the plan against a schema.
- Team size and task slicing by the lead.
  Anthropic's own advice is "Start with 3-5 teammates" and 5-6 tasks per teammate, which is a constant a scheduler can hold.
- Factory orchestration kept in prompts.
  The ai.engineer abstract describes a prompt of "roughly 700 lines of text governing feature decomposition and failure handling" plus "a thin deterministic layer responsible for bookkeeping, validation"; the stated reason for keeping orchestration in the prompt (it improves as models improve) is my reading of the model-agnostic argument in factory.com/news/missions, not a quoted sentence.
  Rule: keep the thin layer, and move any bookkeeping found in the prompt into it.
- Spotify LLM judge.
  Rule cannot fully replace it, since the failure is scope creep against the prompt, but it runs after deterministic verifiers and only before the PR opens, never in the dispatch path.
- Stripe is the cleanest counter-example: git operations, linters and pushes are deterministic nodes, and only "implement" and "fix CI failures" are agentic.

## 8. What to carry forward

- The blueprint shape (Stripe): a workflow in code with named deterministic and agentic nodes and a hard CI-round limit.
  It maps directly onto the owner's "every node is input to output" DAG rule and can be run by Argo Workflows or a Make-driven runner (see `S01-argo.md`).
- The Symphony control loop as a reference algorithm.
  `SPEC.md` sections 7, 8, 14 and 16 (poll, reconcile, dispatch, stall timeout, capped backoff, restart recovery from the tracker with no database) are a complete, tested-by-matrix design of the thing the owner calls "a system, not agents".
  Section 2.2 states it is not a "General-purpose workflow engine", so it is a pattern to copy, not a substitute for Argo.
  OpenAI says "Tell your favorite coding agent to build Symphony in a programming language of your choice" (`README.md`), so the spec is meant to be reimplemented.
- Disposable per-task sandboxes with state outside (Stripe, Anthropic Managed Agents, Ramp).
  Seat identity should be a record, not a pane.
- Event subscription instead of polling by a model (Cursor 2026-08-19).
- Reconciliation each tick against an external truth (Symphony), which removes the need for any process to be a single point of failure.
- Verification written before the work and kept out of the agent's reach (Factory validation contract, Spotify verifiers behind a stop hook, Anthropic JSON feature list).
- Small, conditional context files: Stripe scopes rules to subdirectories, OpenAI shrank AGENTS.md to about 100 lines pointing at `docs/`.
- Do not build a global-lock merge queue first (Anthropic says it "haven't been able to effectively replicate" one at agent scale; Shopify says merge queues "became load-bearing"): the owner's own merge step should stay a pure function of records and heads, with conflict repair by a fresh seat, and the queue question stays open until volume forces it.
- Reviewer-agent loops need a bound the loop itself cannot lift; OpenAI's "until all agent reviewers are satisfied" loop has none stated in the primary.
- Per-plan concurrency caps as a published contract (Jules: 3, 15 or 60 concurrent tasks) show a vendor choosing a hard cap over best effort.
- Cost discipline: a token budget per run and a per-run concurrency cap (Anthropic 15x tokens for multi-agent; Uber AI cost 6x).

## 9. What to kill

- Parallel writers sharing mutable coordination state (Cursor's lock file, equal-status agents).
- Any integrator or gatekeeper agent in the merge path (Cursor dropped it; Anthropic never got a global-lock queue to work at agent scale).
- A long-lived named agent that holds state in its context window or pane (Anthropic's "pet" container, 2026-04-08).
- Agent-side waiting loops that exist to compensate for a missing system action (the field replaced them with event subscription or a daemon tick).
- Unstructured swarms and many-subagent fan-out for code (Anthropic: weaker fit; Cognition: "mostly a distraction").
- Treating a terminal multiplexer as the production substrate for an unattended fleet; the field's unattended runs use containers, VMs or Modal sandboxes (Stripe, Ramp, Anthropic C compiler used plain Docker plus a bash loop).
- Review loops with no convergence rule (Cognition's endless review loops; OpenAI's loop "until all agent reviewers are satisfied", which the primary does not bound).

## 10. Open questions for the owner

1. Where does the human sit, if anywhere?
   Stripe and Symphony keep a human review gate before merge; Anthropic relies on post-merge testing and OpenAI's harness team says humans "aren't required" to review.
   The answer sets whether the control plane has a hold state at all.
2. Is the intake source of truth a tracker polled by the daemon (Symphony: Linear board, state names in `WORKFLOW.md`) or the existing JSON records?
   Symphony recovers by re-reading the tracker; the owner's records give the same property only if the records are the single store.
3. May an LLM decompose a goal into tickets, as Factory, Cognition and Cursor do, or must tickets arrive already cut?
   This is the one place the field and the brief's "no agent assigns work" diverge.

## 11. Sources

Primary pages fetched on 2026-10-14 (publication date in brackets):

- Anthropic, "How we built our multi-agent research system" [2025-06-13] - https://www.anthropic.com/engineering/multi-agent-research-system
- Anthropic, "Effective harnesses for long-running agents" [2025-11-26] - https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents
- Anthropic, "Building a C compiler with a team of parallel Claudes", Nicholas Carlini [2026-02-05] - https://www.anthropic.com/engineering/building-c-compiler
- Anthropic, "Scaling Managed Agents: Decoupling the brain from the hands" [2026-04-08] - https://www.anthropic.com/engineering/managed-agents
- Anthropic, "Redesigning source control at Anthropic" [2026-10-13] - https://www.anthropic.com/engineering/redesigning-source-control
- Anthropic, Claude Code docs, "Orchestrate teams of Claude Code sessions" [fetched 2026-10-14] - https://code.claude.com/docs/en/agent-teams
- Stripe, "Minions: Stripe's one-shot, end-to-end coding agents" [2026-02-09] - https://stripe.dev/blog/minions-stripes-one-shot-end-to-end-coding-agents
- Stripe, "Minions ... Part 2" [2026-02-19] - https://stripe.dev/blog/minions-stripes-one-shot-end-to-end-coding-agents-part-2
- Cursor, "Scaling long-running autonomous coding", Wilson Lin [2026-01-14] - https://cursor.com/blog/scaling-agents
- Cursor changelog, "Cloud Agents and Cursor Harness Improvements" [2026-08-19] - https://cursor.com/changelog/08-19-26
- Cognition, "Don't Build Multi-Agents", Walden Yan [2025-06-12] - https://cognition.com/blog/dont-build-multi-agents
- Cognition, "Multi-Agents: What's Actually Working" [2026-04-22] - https://cognition.com/blog/multi-agents-working
- Cognition, "Devin can now Manage Devins" [2026-03-19] - https://cognition.com/blog/devin-can-now-manage-devins
- Spotify, Honk part 1 [2025-11-06] - https://engineering.atspotify.com/2025/11/spotifys-background-coding-agent-part-1
- Spotify, Honk part 2 [2025-11-24] - https://engineering.atspotify.com/2025/11/context-engineering-background-coding-agents-part-2
- Spotify, Honk part 3 [2025-12-09] - https://engineering.atspotify.com/2025/12/feedback-loops-background-coding-agents-part-3
- Shopify, "Introducing Roast", Obie Fernandez [2025-06-18] - https://shopify.engineering/introducing-roast
- Modal, "How Ramp built a full context background coding agent on Modal" [2026-02-19] - https://modal.com/blog/how-ramp-built-a-full-context-background-coding-agent-on-modal
- Gergely Orosz, "How Uber uses AI for development", Pragmatic Engineer [2026-03-10, numbers updated 2026-03-11] - https://newsletter.pragmaticengineer.com/p/how-uber-uses-ai-for-development
- Luke Alvoeiro, Factory, "The Multi-Agent Architecture That Actually Ships", AI Engineer Europe 2026 talk abstract [page shows no date] - https://ai.engineer/talks/ow1we5PzK-o-production-multi-agent-architecture (fetched 2026-10-14; source of the 700-line and thin-deterministic-layer quotes)
- Factory, "Introducing Missions" [page dateline and metadata read 2025-02-26 but the footer reads 2026 and the search result said 2026-02-26; I treat the year as unresolved] - https://factory.ai/news/missions redirects (HTTP 307) to https://factory.com/news/missions, fetched 2026-10-14
- Shopify, "Under the River", Burke Libbey, Javier Moreno and River [2026-05-28] - https://shopify.engineering/under-the-river
- Ramp, "Why we built our background agent" [undated] - https://builders.ramp.com/post/why-we-built-our-background-agent
- Uber, "uReview" [2025-08-12] - https://www.uber.com/blog/ureview/
- Uber Minion session page [recorded 2026-05-07] - https://background-agents.com/summit/sessions/nikhil-ramakrishnan/
- Google, "Build with Jules, your asynchronous coding agent", Kathy Korevec [2025-05-20] - https://blog.google/technology/google-labs/jules/
- Google Developers Blog, "Meet Jules Tools" [2025-10-02] - https://developers.googleblog.com/en/meet-jules-tools-a-command-line-companion-for-googles-async-coding-agent/
- Google Jules docs, usage limits [undated, fetched 2026-10-14] - https://jules.google/docs/usage-limits/ and https://jules.google/docs
- GitHub, "Welcome home, agents" [2025-10-28] - https://github.blog/news-insights/company-news/welcome-home-agents/
- GitHub, "How to orchestrate agents using mission control", Matt Nigh [2025-12-01] - https://github.blog/ai-and-ml/github-copilot/how-to-orchestrate-agents-using-mission-control/
- OpenAI, "Harness engineering: leveraging Codex in an agent-first world", Ryan Lopopolo [2026-02-11] - https://openai.com/index/harness-engineering/ (HTTP 403 live; read from Wayback snapshot http://web.archive.org/web/20261012001826/https://openai.com/index/harness-engineering/)
- OpenAI, "An open-source spec for Codex orchestration: Symphony" [2026-04-27] - https://openai.com/index/open-source-codex-orchestration-symphony/ (HTTP 403 live; Wayback snapshot http://web.archive.org/web/20261010211815/https://openai.com/index/open-source-codex-orchestration-symphony/)
- OpenAI, Symphony repository, SPEC.md, README.md, elixir/WORKFLOW.md [HEAD committed 2026-09-15] - https://github.com/openai/symphony, local copy `clones/symphony`

Secondary sources (summaries; primary not retrieved):

- ZenML and theneuron summaries of the OpenAI harness post (https://www.zenml.io/llmops-database/extreme-harness-engineering-building-production-software-with-zero-human-written-code and https://www.theneuron.ai/explainer-articles/openais-harness-engineering-playbook-how-to-ship-1m-lines-of-code-without-writing-any/): now superseded by the primary; their "bullied" and "P2" claims are unverified and withdrawn.
- Tessl summary of Symphony (https://tessl.io/blog/openai-open-sources-symphony-a-spec-for-orchestrating-codex-agents): superseded by the OpenAI primary, which gives the date 2026-04-27 and the exact wording "500% increase in landed pull requests".
- Video-summary claim that more than 70% of Uber PRs are agent-opened (openclawdatabase.com, 2026-08-21): unverified, conflicts with the 11% figure.
- Cursor cloud agents launch [2026-02-24 per search result, third-party only] - https://bex.co/blog/2026/07/18/ai-ide-background-agents-deploy-gap
- METR 2025 trial and 2026 follow-up - https://letsdatascience.com/blog/developers-thought-ai-made-them-faster-the-data-said-otherwise and https://particula.tech/blog/metr-reversed-19-percent-slower-ai-coding-study
- The Register on the Anthropic source control post [2026-10-13] - https://www.theregister.com/devops/2026/10/13/anthropic-reinvents-source-control-as-claude-floods-the-world-with-code/5302943

Not found or not reachable: Stripe merge mechanics (not described in either post), Cursor primary figure for share of internal PRs (conflicting third-party numbers, omitted), OpenAI "Unrolling the Codex agent loop" (HTTP 403, no Wayback snapshot, single-agent topic), Google Antigravity (no results), Devin fleet migrations (no results), a Google-authored fleet architecture post (none exists as far as three searches and four direct fetches show), an Uber-authored Minion architecture post (not found), queueing and retry mechanics inside Shopify Aquifer (the post says nothing on them).

Attempt 2 gap closure, one line per critic gap:

- Anthropic wording: reworded in 4.1, 4.2, 5, 8, 9 to "never replicated"; quote in 4.2.
- OpenAI primaries: read via Wayback; harness figures verified (about a million lines, roughly 1,500 PRs, 3 to 7 engineers); the "humans stopped pre-merge review" claim was corrected to "Humans may review pull requests, but aren't required to"; the bullying and P2 claims are withdrawn as unverified.
- Google: primaries fetched; no fleet architecture exists; the Jules row now cites blog.google, the Developers Blog and the usage-limits page.
- Symphony number: dated 2026-04-27, wording "500% increase in landed pull requests on some teams" and "in the first three weeks", marked self-reported.
- Factory, Uber, Ramp: factory.com read; the 700-line and thin-layer quotes are in the ai.engineer abstract not in the Missions post, and 4.2 and section 7 now say so; Uber has an Uber-authored uReview post and a summit page, Minion architecture remains secondary; Ramp has its own undated post.
- Shopify: River post found at shopify.engineering/under-the-river and added as a table row; attempt 1 searched for it in the wrong form.
- C compiler figures: marked approximate in the table, with the post's wording "nearly 2,000", "2 billion", "just under $20,000".

Local cross-references: `L04-herdr.md` sections 2 and 5.1; `L13-llms-doing-scheduler-work.md` sections 2 and 4; `S01-argo.md` section 2.
