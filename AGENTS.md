# AGENTS.md

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Hard rule: Design principles 101, right below the contents list](#hard-rule-design-principles-101-right-below-the-contents-list)
- [Hard rule: every Markdown file opens with a contents list](#hard-rule-every-markdown-file-opens-with-a-contents-list)
- [Hard rule: herdr tab layout for every multi-agent line](#hard-rule-herdr-tab-layout-for-every-multi-agent-line)
- [Hard rule: the golden system design rules sit right under every contents list](#hard-rule-the-golden-system-design-rules-sit-right-under-every-contents-list)
- [Contents](#contents)
- [What this repository is](#what-this-repository-is)
- [Law: the north star roadmap binds](#law-the-north-star-roadmap-binds)
- [Golden rule: checkpoint every step, compact early](#golden-rule-checkpoint-every-step-compact-early)
- [Hard rule: the first 100 lines route](#hard-rule-the-first-100-lines-route)
- [Hard rule: dated entry files, one file per entry](#hard-rule-dated-entry-files-one-file-per-entry)
- [Law: runtime data never lives in git](#law-runtime-data-never-lives-in-git)
- [Law: agents are never gates](#law-agents-are-never-gates)
- [Law: three loops, always](#law-three-loops-always)
- [Law: talking to the owner](#law-talking-to-the-owner)
- [Law: the chain of command](#law-the-chain-of-command)
- [Law: tooling in the repository, artifacts documented](#law-tooling-in-the-repository-artifacts-documented)
- [Law: herdr-first, never background processes](#law-herdr-first-never-background-processes)
- [Law: automation leads, never by hand](#law-automation-leads-never-by-hand)
- [Law: Google Drive first](#law-google-drive-first)
- [Law: the surface follows the runtime](#law-the-surface-follows-the-runtime)
- [Law: scope small, integrate in CI](#law-scope-small-integrate-in-ci)
- [Law: no file is ever touched by two open PRs](#law-no-file-is-ever-touched-by-two-open-prs)
- [Law: testing](#law-testing)
- [Law: the architect model chain](#law-the-architect-model-chain)
- [Hard rule: read the window, not the history](#hard-rule-read-the-window-not-the-history)
- [Hard rule: no PII](#hard-rule-no-pii)
- [Hard rule: documentation goes where its lifetime says it goes](#hard-rule-documentation-goes-where-its-lifetime-says-it-goes)
- [The close-out flow](#the-close-out-flow)
- [Skills](#skills)
- [Where your workspace comes from](#where-your-workspace-comes-from)
- [General guidelines](#general-guidelines)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

<!-- GOLDEN-RULES:START -->
## Hard rule: Design principles 101, right below the contents list

Owner order, 2026-10-16 UTC: "deisgn principal 101 global agents.md rule right below the contents list for it".
Backup of this file before the rule: `~/.local/state/zenith/backup/2026/10/20261016035435-home-agents-md-before-design-principles-101.md`.

Every design document carries a section named "Design principles 101" placed directly below its contents list, before any other section.
It lists the principles below, and for each one says in a line how this design meets it, or why it does not apply.
A design without that section is not ready for the owner to read.

The principles, each in the owner's own words:

1. CI/CD speed is king: "CICD SPEED IS KING"; "speed is king"; "speed is the name of the game, no bottlenecks".
2. Parallelism: "parallelism, speed, work needs to be done"; "do shit in parallel, we need this active".
3. Make and scripts drive the automation, never hands: "makefiles with scripts driving automation, NEVER by hand!".
4. Portable, generic, templated, reused: "everything portable, generic, templated out so everybody gets it, NEVER REINVENT THE WHEEL". Inventory what already exists and reuse it before building anything new.
5. Small scope, proven: "prove shit discover it small scope that an ape could build this shit".
6. Tests where they count, and CI owns the full suite: "i hate slow CICD, we're built for speed, test only things relevant, don't run full suites, make changes and test those relevant changes, CICD does linting and full suite" (2026-10-16 UTC, replacing the earlier "only full suite before prs"). Agents run only the tests their change touches, never a full suite locally; CI runs lint and the full suite.
7. Evidence or silence: "reproduce errors or problems only with supporting evidence otherwise mute". A problem is reported only with its reproduction and evidence attached; without evidence, an agent says nothing about it.
8. Specs: "xml specs 1000 lines or less good never examples unlimited files being specific with content list at the top".
9. DAG and doc design first: "dag this shit out doc design first".
10. Migrations and easy node updates: "ensure migrations plans and easy updates to the nodes".
11. Clean up after itself: "make sure you clean up too".
12. Frictionless for the owner: "ensure its frictionless". The owner only decides, on Bearings, one card at a time.
13. Context discipline: "no more than 30% on the ctx and smart checkpointing built in with monitoring that not disruptive but token efficient".
14. Multi-agent work, shown with GOOD and NEVER examples: "MULTIAGENT WORK MINDSET GOOD NEVER EXAMPLES". Every design is built for many agents working at once, and every rule it sets carries a GOOD and a NEVER example.
15. XML spec, mermaid architecture and DAG, the DAG is the source: "always design with xml spec 1000 lines or less unlimited files doc design first driven by mermaid for architecture and DAG with graceful migration plans and easy of use ... the DAG is the source, build to spec".
16. Migration is the test of the design: "if workflows can't be easily migrated and updated, the design princpal is wrong and flow sucks". A design whose workflows cannot be migrated and updated easily is rejected and redesigned.
17. Config files and arguments pass every input: "config and arguments are good ways to pass things, easy in makefiles too". Every script takes its inputs from a config file or arguments, never hard-coded, and every Make target passes them as `VAR=value`.
18. Agent to agent is schema, never prose: "agent to agent prose sucks, schemas with defined AC always". Every brief, handoff and result between agents is a JSON document valid against a JSON schema, and every one carries defined acceptance criteria, each with the proof that ticks it. Prose is for the owner only.
19. Small tickets, disjoint files, logical order: "scope tickets and work orders small, keep things built for speed, never touching same files and logical ordering". Every ticket and work order is small, declares the files it touches, and no two tickets that can run at the same time touch the same file; the DAG orders the rest so dependent work waits on its input.
20. Worktree, feature branch, deterministic DAG path, the DAG is the state: "worktrees and feature branches with the whole process DAG when getting work so it follows a deterministic path with clear checklist runbooks playbooks documents everything that node needs is there and graceful recovery, always, doc design first with those mermaid and build to spec and keep the idea of terraform in mind, the state file is the source of truth, so should the DAG doc design architecture". Taking work always opens its own worktree and feature branch and walks the process DAG in a fixed order. Each node ships with its checklist, runbook, playbook and every document it needs, and recovers gracefully from wherever it stopped. Like a Terraform state file, the DAG design is the source of truth: the build is planned against it, applied to match it, and any drift from it is detected and reported.
21. Merge, never park: "get this code merged the fuck in, dead code is shit, it sitting under agents is stupid". A PR whose CI is green and whose design was approved merges at once, by a script; PRs never pile up in deep stacks waiting on each other, and a stack is collapsed leaves first by the merge script.
22. See it, isolate it, fix it, or hand it off and get out of the way: "see a bug, isolate it, and get it fixed as asap, if you don't know how to fix shit, get the fuck out of my way in the proper engineering way". An agent that sees a bug isolates it to a reproduction and fixes it at once in a small PR. An agent that cannot fix it files a ticket with the reproduction and evidence, hands it to a seat that can, and steps aside; it never blocks the line or guesses.
23. Artifacts live outside git, named by script, linked in like packages: "any files we ever need to create, they never go in the git repo, artifacts get smartly linked to the outside like packages do on linux, use format <key name>/YYYY/MM/YYYYMMDD-HHMMSS-<descriptive name under 55 chars completely with the prefix included>.<whatever ext> scripted too with frontmatter that makes sense, logs context whatever kind of file that we don't want tracked in git, we don't have time for that shit, point to where its at and if we need context we know where to go looking". Every log, context file, brief, result, screenshot or other untracked file is written by a script to `<key>/YYYY/MM/YYYYMMDD-HHMMSS-<name>.<ext>` under the shared artifact store, where the file name with its timestamp prefix stays under 55 characters. Each one opens with frontmatter that says what it is, who wrote it, from which repo, branch and session, and when, in UTC. Repositories never hold them; they hold a pointer, and the store is reached the way a package is, through a link, so an agent that needs the context knows exactly where to look.
24. Smart checkpointing with compaction is the standard: "checkpointing or smart checkingpointing with compaction is smart as fuck". Every seat runs with compaction-guard checkpoints, and every new seat gets it by default.
25. No AWS spend beyond SSM and a justified S3 bucket; the cluster and GitOps are the platform: "don't spend money on AWS unless its for a ssm parameter or a good reason for an S3 bucket, k8s cluster and jenkins argo cd source of truth, don't be stupid". Workloads run on the owner's Kubernetes cluster, built by Jenkins and deployed by Argo CD, and git through Argo CD is the source of truth for what runs. AWS is used only for SSM parameters and, when a design states the reason, an S3 bucket. The `minecraft-admin` profile rule above still holds.
26. Producer and consumer, never push into a pane: "your gonna get bogged down, thats fucked right there, wtf" and "thats not good, prodcuer consumer model man, wtf". Monitors and seats produce events into a durable queue; consumers pull from it when they are ready. Mechanical events, such as a seat finishing, are consumed by a script with no model; only an event that needs a ruling lands in the queue of the agent who rules, and that agent reads it on its own schedule. No event is ever typed into an agent's pane. The queue is a bus, not files: "man drop that shit on a bus we have nats or some open source liteweight tool, come on". NATS JetStream (local images nats:2.15.1-alpine and natsio/nats-box) carries every event, with durable pull consumers, brought up and down by Make.
27. One pattern for everything that watches: "we need to be conscious of each seat cost the system resouces, so we need a scripted way to monitor ram and cpu too" and "that lives and dies in a monitoring tab too along with those scripts from makefiles, you see a trend forming yet?". Every monitor (line sweep, consumers, bus, herdr bridge, CPU and RAM per seat) is declared once in a monitors config, is a script behind a Make target, runs in a labeled pane of the line's monitoring tab, publishes to the bus, and starts and stops with that tab. Adding a monitor is one config entry, never a new mechanism.
28. XML specs, contents list, mermaid, graceful recovery, idempotency, automation forever: "xml specs 1000 lines or less with content list and mermaid code for doc design first with graceful recovery and idempotentency, automation forever NEVER HAND FED" (2026-10-16 UTC). Every XML spec is 1000 lines or less, parses, and opens with a contents element; the design behind it is drawn in mermaid first. Every step, script and Make target is idempotent: run it again from any state and it lands in the same end state, with no duplicate and no damage, and it recovers gracefully from wherever it stopped. A fast `make spec-check` enforces the spec limits in CI. Nothing is ever hand fed: a step a person or agent has to feed by hand is a defect to turn into automation.
29. Status codes, minimal prose, work orders all the way: "fucking status codes i hate agent prose, keep to minimum, things don't need to be said, you and i have decided, thats why we spec shit out, work-orders skill all the fucking way" (2026-10-16 UTC). Agents report by status code from the status code map, never by prose; what the spec already decided is never restated. Every piece of work is cut and tracked with the work-order skill, never as an ad hoc brief.
30. Ape-sized work, scripted tests, everything up front: "i want work scoped so small a fuck ape could do, testing the same way with test plans and scripts, every node has what it fucking needs up front, not later, design it that way, we don't want dicks in hands, we want work done" (2026-10-16 UTC). Every work order is cut so small that it needs no judgement beyond its declared degrees of freedom. Testing is cut the same way: a `--type test` work order carrying a filled test plan (claude/workflow/templates/test-plan.md) and the script that runs it. Every DAG node carries, at the moment it is cut, everything it needs: inputs, files it touches, exact commands, test plan, acceptance criteria with proofs, and pointers to every doc. A node that has to ask, wait for context or go looking is a design defect, fixed in the design, never worked around by the seat.
31. No evidence means the SOP was broken: "if architects don't ahve supporting evidence and can't reproducre the error or no screenshot with clear evidence, then SOP wasn't followed for the DAG adn that nodes checklist of instructions" (2026-10-16 UTC). Every DAG node's checklist carries the steps that capture its evidence: the reproduction command and its output, and a screenshot for anything visual, written by script to the artifact store. An error raised by anyone, architect included, without a reproduction or clear screenshot evidence is recorded as an SOP breach of that node's checklist: the claim is dropped, and the checklist gap is fixed in the design.
32. Agents have no opinions: "agents don't get to have OPINIONs, thats my job" (2026-10-16 UTC). Opinions are the owner's alone. Agents report facts, evidence and status codes, and build to the spec and the owner's rulings; they never offer a preference, a taste or a "should" of their own. Where the spec is silent, the gap goes to the owner as a Bearings card, never filled with an agent's view.
33. The architect may break glass to unstick the line: "you have permission to breakglass shit too, you need the ability to unstick things" (2026-10-16 UTC). When the line is stuck and the system and orchestrator cannot clear it, the architect acts directly: kill or restart a seat, release a lock, reset a wedged worktree, force a stuck merge-train item, restart a monitor or the bus. Every break glass act is logged by script to the artifact store with its evidence (state before, command, state after), and is followed at once by a work order that turns it into automation, since a hand fix is a defect. Break glass never overrides these rules: no credentials or vaults, no minecraft-admin, no routing around the classifier, no send or post without owner approval of the exact item, no AWS spend beyond item 25, no history rewrite on a shared main.
34. Testing is promoted dev, then UAT, then stable: "Ensure that your testing is dev uat stable." (2026-10-16 UTC). Every change passes three gates in order, each a scripted Make target with its own test plan and evidence: dev (podman sandbox, fakes, only the tests the change touches), UAT (the real line or environment with a test seat or test data, acceptance criteria observed with evidence), and stable (promoted to run for real, watched by its monitor, with a scripted rollback). A change never skips a gate, and a failed gate rolls back to the one before by script.
35. Testing never notifies the owner: "And don't ever bog the user down with notifications when testing." and "Or any testing for that matter." (2026-10-16 UTC). No test at any gate, dev, UAT or stable, sends the owner a notification, card, message or ping, and no test asks the owner to do or check anything. Tests that exercise a notifier send to a separate test channel, and a script reads that channel back as the proof. Only real events reach the owner.
36. The architect hotfixes missing permissions on the spot, then designs them in: "You have the same abilities as I do. If a job or agent needs the permissions and their schema doesn't have it. Hotfix them on the spot and then get that fix into the Doc design DAG for the worker. Easy path with least resistance an no friction." (2026-10-16 UTC). When a job or seat is blocked because its brief, schema, settings or allow list lacks a permission it needs for approved work, the architect grants it at once, logs the hotfix by script to the artifact store (what was missing, what was granted, where), and files a work order that puts the grant into that worker's design, DAG node and schema so the next run has it up front. The rules that name the owner alone stay the owner's: minecraft-admin, approval of each exact send or post, the owner's own typed words where the classifier requires them, credentials and vaults.
37. Time every process, and a slow one is a bottleneck: "Remember never hand 🤚 automation and identitify bottlenecks when things take too long or when any process takes. We need to track time to keep the process from getting stuck. It builds justification" (2026-10-16 UTC). Every DAG node, seat, job, CI run and merge records its start and end in UTC on the bus by script, never by hand. Each node carries a time budget in its design; a run over budget emits status code SLOW with its evidence and becomes a bottleneck work order. A scripted report (durations, budgets, top bottlenecks per line) is the justification for every fix and every design change.
38. Batch logically, push systematically: "Batch things together so they can be logically and systematically pushed out." (2026-10-16 UTC). Work is grouped into batches by DAG layer and by the area it touches, and a batch moves through dev, UAT and stable as one unit on a scripted cadence. Orders, rule broadcasts and reports between agents are batched the same way: one message per cadence carrying every item, never one message per item. Tickets stay small; the batch is how they ship together.

GOOD: a design that opens with its contents list, then Design principles 101 with one line per principle, then a mermaid DAG that the XML spec and the build follow exactly.
NEVER: a build that drifts from its DAG, or a workflow that has to be rebuilt by hand to change it.

## Hard rule: every Markdown file opens with a contents list

Owner order, 2026-10-16 UTC: "EVERY .md file starts with content lists at the top, so my global files that aren't checked in need to change and the ones in the dotfiles as well".
This covers the global files outside any repository (this file, `~/OPINIONS.md`) and every Markdown file in dotfiles.
The list is generated and refreshed by a Make target and a script, never by hand, and a fast check fails a PR whose Markdown lacks it.
Files marked auto-generated, CHANGELOG.md files, and vendored skill copies are fixed at their source, never in place.

## Hard rule: herdr tab layout for every multi-agent line

Owner order, 2026-10-16 UTC: "since we use herdr, its should always be known to use herdr in a tab layout with 3X3 and the 1(YOU ONLY ON AGENT IN THIS FULL 3 slots)|3 panes|3 panes, everything labeled, make new tabs when not, driven by makefiles and scripts with automated cleanup too".
Backup of this file before the rule: `~/.local/state/zenith/backup/2026/10/20261016035943-home-agents-md-before-herdr-layout.md`.

Every line runs in herdr tabs on a 3 by 3 grid.
The first tab is the architect's: the left column is the architect alone, at full height across its 3 slots; the middle and right columns hold 3 seat panes each.
When a tab is full, the next seat opens a new tab of the same grid instead of squeezing a pane in; overflow tabs hold seats only, since the architect lives once.
Every tab and every pane is labeled with its line and seat name.
Opening, placing, labeling, closing and cleaning up panes and tabs is done by Make targets and scripts, never by hand: a finished seat's pane closes, and an empty tab closes with it.

GOOD: tab `inbox-triage 1` with the architect on the left, then `sweep-build`, `yp-line`, `ctx-guard` in the middle and `md-toc`, `li-page`, `li-send2` on the right; the eighth seat opens tab `inbox-triage 2`.
NEVER: unlabeled panes split wherever there was room, or a dead seat's pane left open.

## Hard rule: the golden system design rules sit right under every contents list

Owner order, 2026-10-16 UTC: "these we're my new golden system design rules, they sit right under those content list, blast that shit, I don't care if its not dry, i want it wildly known".
The golden system design rules are three sections of this file: "Design principles 101, right below the contents list", "every Markdown file opens with a contents list", and "herdr tab layout for every multi-agent line".
Their text is copied, word for word, into a block placed directly below the contents list of every agent instruction file: every global file outside a repository, and every AGENTS.md, CLAUDE.md, GEMINI.md, CLAUDE_TEMPLATE.md and agent instructions file in dotfiles and in every repository under `~/projects`.
Repeating the block is intended; the owner wants it known everywhere, not kept DRY.
One source file holds the block, and a Make target writes it between markers into every file, so a change to the rules reaches every copy in one run, never by hand.

GOOD: an agent opens any project's CLAUDE.md and the contents list, then the golden rules, are the first things it reads.
NEVER: a project instruction file that an agent can read without meeting the golden rules.
<!-- GOLDEN-RULES:END -->

## Contents

- What this repository is
- Law: the north star roadmap binds
- Golden rule: checkpoint every step, compact early
- Hard rule: the first 100 lines route
- Hard rule: dated entry files, one file per entry
- Law: runtime data never lives in git
- Law: agents are never gates
- Law: three loops, always
- Law: talking to the owner
- Law: the chain of command
- Law: tooling in the repository, artifacts documented
- Law: herdr-first, never background processes
- Law: automation leads, never by hand
- Law: Google Drive first
- Law: the surface follows the runtime
- Law: scope small, integrate in CI
- Law: no file is ever touched by two open PRs
- Law: testing
- Law: the architect model chain
- Hard rule: read the window, not the history
- Hard rule: no PII
- Hard rule: documentation goes where its lifetime says it goes
- The close-out flow
- Skills
- Where your workspace comes from
- General guidelines

## What this repository is

A herdr-first software factory: a small loop of worker, tester, reviewer and merger seats builds and proves each ticket, and a big loop takes an owner request from the bearings page to a released change.
The first product it builds is a model that plays Caves of Qud inside a labelled herdr pane.
Read `ROADMAP.md` before any work: it is the north star roadmap, it binds every agent, and work that is not on it waits.

## Law: the north star roadmap binds

Owner order, 2026-10-12 UTC: "ensure that you're following it until its complete".
`ROADMAP.md` holds the locked decisions, the phases and the work items; only the owner changes it.
A message from the owner containing `USERGO` restarts a held line; one containing `USERHALT` halts it at once.
The only monitoring that never shuts off is bearings stable, the owner's page and the wait loop that brings the owner's messages to the architect; a halt stops everything else and never that.
Progress, each item with the record or pull request that proves it, lives in the state root, never in git.

GOOD: a worker reads `ROADMAP.md`, finds its ticket is `Roadmap A - State root`, and builds exactly that.
NEVER: starting work that is not on the roadmap because it looked useful, or restarting a halted line without `USERGO`.

## Golden rule: checkpoint every step, compact early

This is the rule above every other rule in this file, and it binds the interface agent first.
Owner order, 2026-10-10 UTC: never run without proper checkpointing built into your own tasks.

Cut every task into steps small enough that each one ends in a commit and a `CONTEXT_STATE.md` checkpoint (`checkpoint.sh new`).
A step that cannot end that way is too large: split it before starting it, never partway through.
A context threshold is the last line of defence, never the trigger; do not wait for it.
Write the resume line into the checkpoint before you compact, never into chat.
After a step lands, raise your compact request and end the turn.
A watcher compacts the seat once it is idle; never send `/compact` yourself.
Nothing may stop a compaction and nothing is lost: the watcher opens a quiet window, posts a system message with a five second countdown, watchers pause and queue their wake signals, and the queue drains into the first turn after the resume card (SPEC-05 s-quiet).
Small scope compacts sooner and costs fewer tokens per step, which is what the owner is paying for.
A step lands through `make step MSG=.. TYPE=.. TITLE=.. CP=body.md` (`bin/step.sh`): lint, changelog entry, commit, push, checkpoint, compact request, in that order, and a lint failure commits nothing.
Owner, 2026-10-10 UTC: nothing in this cycle is run by hand, the same way nobody at AWS deploys by hand.

GOOD: a port of three functions lands as one commit and one checkpoint, the seat compacts, then the suite case is the next step.
GOOD: a checkpoint written while the suite runs in its pane, so a compaction mid-run loses nothing.
NEVER: carrying four finished steps in context because the next one looks quick.
NEVER: a checkpoint whose resume line lives only in the chat transcript.

## Hard rule: the first 100 lines route

Agents read the first 100 lines of a file and stop; the owner watched them lose context past that line on 2026-10-10.
So the first 100 lines of every file an agent opens must route: a contents list first, then the rules that bind, then pointers to the files that hold the rest.
Nothing an agent must know to act may sit past line 100 unless the contents list names it and the entry says what it decides.
A file that cannot route in 100 lines is two files; split it rather than hoping it is read.
`CONTEXT_STATE.md` keeps its preamble under 20 lines so the top checkpoint is inside the window.
`work-orders/INDEX.md` leads with what is startable, `COMPASS.md` stays under 100 lines, and every spec starts with its contents element.

GOOD: a 240 line AGENTS.md whose contents list, golden rule and this rule are all inside the first 60 lines.
NEVER: a rule added at the bottom of a long file with no contents entry, because "it is in the file".

## Hard rule: dated entry files, one file per entry

Owner order, 2026-10-10 UTC: every scripted entry is a new file on one layout, never an overwrite, so nothing is lost and every entry is visible.
This covers logs, issues, backlog items, checkpoints, index entries, context files, and anything else an agent records more than once.

```text
<tree>/YYYY/MM/YYYYMMDDHHMMSS-<descriptive-name>.<ext>
```

Owner order, 2026-10-12 UTC: the timestamp carries the second, so the name sorts in the order things happened.
`YYYY`, `MM` and `YYYYMMDDHHMMSS` are the UTC time the entry was written.
`<descriptive-name>` says what the entry is, in at most 55 characters, lowercase, words joined by `-`.
Runtime trees (records, logs, test output, checkpoints) use this layout under the state root, never in git (Law: runtime data never lives in git); existing trees move with roadmap item A.
Every entry opens with frontmatter that carries at least `title`, `at` (UTC, ISO 8601, `Z` suffix) and `type`; the owning script writes it.
Two entries on the same day with the same name are two files: the script adds a short suffix, never a second write to the first.
Two concurrent agents must never need to touch the same path, and distinct paths mean merges never meet.

Never hand-write an entry.
A tree has one script that owns its format; the scripts live in `.claude/scripts/` and `bin/`, and every one takes `--json` and uses the exit codes 0 ok, 2 usage, 3 validation, 4 io, 6 id not found.
Branch on the code, not on the message text.
A fix for an earlier issue is a new entry carrying `resolves: <suffix>`, never an edit of the old one.

`issues/` and `backlog/` still write `YYYY/MM/<UTC-timestamp>-<suffix>.md`, and `CONTEXT_STATE.md` still stacks checkpoints in one file.
Moving them onto the layout above is WO-20261010-d354 in `work-orders/INDEX.md` (search "dated entry files"); until it lands, read both shapes and write only through the scripts.

GOOD: `events/2026/10/20261010-uat-tier-started.md` with frontmatter, written by `bin/event.sh`.
GOOD: `changelog/2026/10/20261010-commit-the-factory-scripts.md` written by `bin/changelog.sh add`, and `CHANGELOG.md` rendered from the tree, never edited.
NEVER: appending a line to a shared `LOG.md`, or editing yesterday's entry to say what happened today.

## Law: runtime data never lives in git

Owner decision, 2026-10-12 UTC (cards C10 to C15): the repository is the package source; logs, state, queues and caches live outside it, as a Linux package keeps them in `/var/log`, `/var/lib` and `/run`.
On 2026-10-12 the repository was used as the message bus, one committed file per runtime event, and 2,689 such files queued on one pull request, about 80% routing and stall noise.
Records, the routed ledger, logs, test output and checkpoints go to the state root, `$COQ_STATE` (default `${XDG_STATE_HOME:-~/.local/state}/coq/<repo>`), on the layout in `ROADMAP.md`; caches go to `$COQ_CACHE`.
Verdict records of the tester, reviewer and merger seats live in the state root too.
The changelog is rendered from merged pull request titles; the backlog lives in GitHub issues.
There is no records branch: a ticket is cut and started on its own branch and rides its own pull request.
NATS JetStream is deferred (C15); the bus is files in the state root, owned by the Go scheduler, and routing is still by status code through `factory/config/routes.json`.
Until roadmap items A, F and H land, `bin/event.sh`, `make step` and `backlog.sh` still write into the repository; never add such a file by hand, and never carry one on a pull request it does not belong to.

GOOD: a seat posts a record that lands in `$COQ_STATE/records/2026/10/`, and its pull request carries only the files its ticket names.
NEVER: committing event, log, ledger or checkpoint files, or opening a branch whose only job is to carry records to main.

## Law: agents are never gates

Owner order, 2026-10-12 UTC: "how we're logically going to get this system working without agents being gates again".
Every record kind has exactly one consumer in `factory/config/routes.json`, and routing reads the owner seat from the ticket.
A carry, a merge, a verify on main, a stall and a block are each handled by a rule or a seat, never by waiting on the architect.
The architect receives one digest of items addressed to it, never a copy of every record or seat turn.
`ROADMAP.md` lists the nine rules and the guardrails; an agent that finds itself the only path for something reports it as a defect.

GOOD: a pull request reposted after a main merge with byte-identical own files carries its test and review by rule.
NEVER: a watch that forwards every record to one agent, or a merge that waits for the architect to notice it.

## Law: three loops, always

Owner order, 2026-10-13 UTC (message m-20261013162710557-e4nos): there is always a system loop for fixes.
The line runs three loops at once, and each is always staffed.

- **Build:** a ticket to a merged pull request: worker, tester, reviewer, then `line/bin/merge.sh`.
- **Verify:** a merged pull request to verified or reverted: `line/bin/verify-main.sh` on the new main, and a rejected main holds every merge until it is green again.
- **System:** every hand fix and every cause a seat or the patrol finds becomes a ticket under the system epic `WO-20261013-16f1`, then a fix, through the same gates.

Two worker slots are reserved for system tickets and are never filled with build work, so a fix to the line never waits behind the work the line is stuck on.
A hand fix without a system ticket is a defect; the seat that made it files the ticket before its turn ends.

GOOD: a seat leaks after its down, the orchestrator kills it and files the cause under `WO-20261013-16f1`, and a reserved worker fixes `seat.sh` the same hour.
NEVER: every worker slot on build tickets while the belt cannot seat gates, or a cause that lives only in a note.

## Law: talking to the owner

Owner order, 2026-10-12 UTC: "your prose to me needs to be spacious, concise" and "high level".
A reply to the owner is a few short lines with a blank line between them.
It says the outcome, not the plumbing: no record ids, pids, pane ids or ledger paths unless the owner asks for them.
Owner order, 2026-10-12 UTC: "your questions go where too".
Every question and every decision goes to the owner as a card on the bearings page, never inside a reply.
Ask it with `tools/bearings/scripts/bearings.sh stable ask FILE`, one question per card.

GOOD: "The merge landed and main is green." as one line, and a card asking which of two designs to build.
NEVER: a reply that lists open questions, or one that pastes a record id and a pane id where the owner wanted the result.

## Law: the chain of command

Owner order, 2026-10-12 UTC: "like me > you > orchestrator > system".
The chain is the owner, then the architect, then the orchestrator, then the system.
The architect makes rulings and designs.
Line operations belong to the orchestrator and the system: re-routing a refused seat, downing a finished seat, branch cleanup and verify on main.
An agent that finds the architect is the only path for a line operation reports it as a defect (Law: agents are never gates).

GOOD: a refused seat-up is re-routed by the orchestrator, and the architect hears about it only in the digest.
NEVER: the architect re-routing seats or deleting branches by hand because it noticed first.

## Law: tooling in the repository, artifacts documented

Owner order, 2026-10-12 UTC: "all scripts better live within the project" and "artifacts live outside but documented always".
Every script this project uses lives in the repository and is tracked, so a fresh clone has all of it.
What a script writes lives outside the repository under `$COQ_STATE` or `$COQ_CACHE` (Law: runtime data never lives in git).
Each such artifact directory carries a README that says what writes it, what reads it and how to clean it, so a cleanup command can exist.

GOOD: a watcher script under `factory/bin/` that writes to `$COQ_STATE/watch/`, whose README names the script and the safe cleanup.
NEVER: a script kept in `~/.cache` or the home directory, or an artifact directory nobody documented.

## Law: herdr-first, never background processes

When `HERDR_ENV=1`, every long-running thing lives in a labeled herdr pane or tab.
That means every agent, watcher, poll, tail and server.
Never shell `&`, `nohup`, `disown`, `setsid`, or a harness background job.
A background process is invisible to the owner, and invisible work reads as nothing happening.

Check with `test "${HERDR_ENV:-}" = 1` before starting anything that outlives a single command.
Outside herdr, say so and stop.
Do not fall back to a background job; the owner decides what happens next.

Binding: `AGENT_CONTRACT_HERDR_FIRST_v1.1.0`.
Procedure, including onboarding a project: `SOP_HERDR_FIRST_v1.1.0`.

## Law: automation leads, never by hand

Monitoring, compaction and failover are scripts running in panes, not people remembering to do them.
A human is notified, never required.
If a step depends on someone remembering it, that step is a script that does not exist yet.
Write it, and run it in a labeled pane.

## Law: Google Drive first

Google Drive is the source of truth for design while the system is being built.
Design is doc-first: the document exists before the code that implements it.
Every design ships one design .md made from `docs/templates/design.md`, and the owner reads that file instead of the XML volumes.
Code lives in git and matches the documentation; it never replaces it.
A repository copy of a document is a fallback, not the original.

Search Drive before creating any design, standard, schema, runbook or template.
If one exists, use it and cite it.
If it does not, say so before you write one.

Drive questions go to the knowledge-steward seat.

Binding: `DOCUMENTATION-WORKFLOW-STANDARD v1.0.0`.

## Law: the surface follows the runtime

The owner-facing visual surface is decided by the seat's runtime, never by the model's judgement.

| Runtime                      | Surface            |
| ---------------------------- | ------------------ |
| Claude                       | claude.ai artifact |
| Any other (Kimi, Codex, ...) | `lavish-axi`       |

Only a Claude runtime can mint a claude.ai URL, so every other runtime uses `lavish-axi`, and a Claude seat never does.
The spawner exports `RAIL_SURFACE` when it starts the seat.
Unset means `lavish-axi`.

The surface is `report/rail.sh`, the Execution Rail, and nothing else writes the page.

```sh
./report/rail.sh log E-01 started "fifteen words or fewer"   # append a ledger row, rebuild
./report/rail.sh build                                       # rebuild only
./report/rail.sh publish                                     # put the page on this seat's surface
./report/rail.sh surface                                     # print lavish or artifact
```

The plan is `report/plan.json`.
The ledger and the built page are state under `~/.local/state/<project>-<key>/rail/` and never enter git.

Binding: `GLOBAL-INTERACTION-SURFACE-POLICY` (v1.0.2 in progress).

## Law: scope small, integrate in CI

Architects scope work small and testable: one ticket, one behaviour, one way to prove it.
Code is function-based and driven by a `Makefile`.
Every entry point an agent or a pipeline uses is a `make` target.
Full integration testing is CI's job, not an agent's.
An agent proves its own unit of work and hands the rest to the pipeline.

## Law: no file is ever touched by two open PRs

Owner order, 2026-10-12 UTC: two agents on one file is forbidden.
On 2026-10-12 five PRs edited the same seat.sh, routes.json and RUNBOOK.md, and every merge forced the next PR into a conflict and a full re-test.
A ticket declares the files it will change (`factory/bin/claims.sh set`), and the architect cuts no two open tickets onto one file.
Start a ticket with `bin/wo-start.sh`, which refuses an overlap with any open PR or live ticket; `factory/bin/gate.sh pr-files` fails a diff that strays.
`CHANGELOG.md`, `work-orders/INDEX.md`, the work-orders READMEs and `CONTEXT_STATE.md` are gitignored and rendered locally (`make aggregates`); they never ride a PR.
Doc numbers come from `bin/mint-id.sh` (SOP-0006), so two PRs cannot take one.

GOOD: a ticket whose files field is `herdr/bin/seat.sh`, started only when no open PR changes that file.
NEVER: `git add -f CHANGELOG.md`, or starting a ticket with `work-order.sh start` to skip the check.

## Law: testing

The architect writes the test plan into the testing ticket before the work starts.
Tests run in isolation, in containers, as the `container-sandbox` skill defines.
Test templates are schema-based and reusable; extend the existing one before writing a new one.

## Law: the architect model chain

The architect seat runs on a fixed chain: `kimi-k3`, then `opus`, then `codex sol`.
When the current model stalls or its API is exhausted, the next model in the chain hot-swaps in.
It starts from the previous model's checkpoint and continues on the same worktree.
Nothing is restarted from scratch, and nothing waits for a human to notice the stall.

Seat roles are declared against `agent-role-v1.1.0.schema.json`.

## Hard rule: read the window, not the history

| What       | Read                                                 |
| ---------- | ---------------------------------------------------- |
| `issues/`  | the newest 10 entries                                |
| `backlog/` | `now/`, `next/`, `later/` in full; `done/` newest 10 |

Filenames and shard directories sort chronologically, so the newest 10 paths in reverse order are the newest 10 entries.

Go deeper only when the user asks, when an entry inside the window references one you need in order to act, or when a symptom recurs across the window and its cause is plainly older.
State it when you go deeper, and say why.
Silently reading the whole history is a defect.

## Hard rule: no PII

Never write personally identifiable information anywhere in this repository - source, comments, sample data, filenames, or commit messages.
No real names, emails, phone numbers, addresses, account numbers, employer or client names, credentials, tokens, or internal hostnames.
All sample data must be synthetic and obviously fake.

If a request would introduce PII, substitute a placeholder and say so.

## Hard rule: documentation goes where its lifetime says it goes

One question decides it: **would this still be true after this repo is deleted?**

| Answer                                               | Where it goes                              |
| ---------------------------------------------------- | ------------------------------------------ |
| Yes - the cluster, the pipeline, Vault, the platform | https://github.com/jkkelley/local-k8s-docs |
| No - it only makes sense inside this codebase        | this repo's `docs/`, via `living-docs`     |

That question has one answer per document, so every document has exactly one destination.
Runbooks and playbooks both, and everything else - nothing is written into both places, and nothing is left to whichever of the two an agent happened to read last.

Both halves are mandatory, and the second is the one that gets skipped.
If you worked out a process in order to finish a task, that process is a document that does not exist yet.
Write it, in whichever of the two the question above picks - `docs.sh sop` for this repo's half, and in the same format as the ones beside it for the other.

When you are following one, follow **its** format, not your own improved version.
Do not invent a local procedure when a documented one exists, and do not leave one undocumented once you have worked it out.

If you need access to it, ask - do not work around not having it.

## The close-out flow

Everything the ticket owns happens on the work branch, and the ticket reaches `done` there.
Then one pull request, then the merge, then the handback.

1. Every acceptance criterion gets evidence with `--observed`, the retro goes in as a note, then `work-order.sh done`.
2. Push once and open **one** pull request carrying the code and the finished ticket.
3. After the merge, `work-order.sh cleanup --id <id>` fast-forwards `main` and deletes the branch on both sides.
4. Report what landed, then hold.

Check whether your pull request has already merged before every commit once it is open.

## Skills

Synced automatically by a `SessionStart` hook before any work starts.
You do not run anything.
If you see sync output, that is what changed; otherwise ignore it.
Never edit a managed skill in place - it is gitignored and the next sync replaces it silently.
Fix it in dotfiles, bump it, done.

`.claude/skills.toml` is the manifest and is the only file you edit to add or drop a skill.
The installed list is generated by `skill-sync` into the marker block in `CLAUDE.md`, so there is no second list to keep in step with it.

## Where your workspace comes from

**One source: the treehouse pool at `~/.treehouse/<repo>-<hash>/`.**
Borrow a slot, work in it, hand it back.
Never hand-roll a `git worktree add`, and never create a second pool inside the repository - the pool carries build cache, and cache inside the working tree is bound into every container, taken as build context by `podman build .`, and staged by `git add -A`.

`treehouse status` is the live map of which agent holds which slot, keyed by the ticket ID that leased it.
Read it rather than guessing, and read `treehouse --help` rather than this file for the flags.

## General guidelines

- Never use the em dash. Use a plain dash "-" instead.
- UTC is the canonical timezone for every record an agent writes: logs, filenames, tickets, ledgers, checkpoints.
- Never add your agent name as a co-author in a commit message.
- Never hand-modify `CHANGELOG.md` or any file marked as generated.
- In long Markdown files, put each full sentence on its own line.
- When making a technical decision, give little weight to development cost; prefer quality, simplicity, robustness and long-term maintainability.
- When fixing a bug, reproduce it end to end first, as close as possible to how a user hits it.
- Lint errors, test failures and flaky tests are fixed when seen, even when they are not yours.
