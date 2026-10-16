# tools/bearings - the owner's decision page

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Hard rule: Design principles 101, right below the contents list](#hard-rule-design-principles-101-right-below-the-contents-list)
- [Hard rule: every Markdown file opens with a contents list](#hard-rule-every-markdown-file-opens-with-a-contents-list)
- [Hard rule: herdr tab layout for every multi-agent line](#hard-rule-herdr-tab-layout-for-every-multi-agent-line)
- [Hard rule: the golden system design rules sit right under every contents list](#hard-rule-the-golden-system-design-rules-sit-right-under-every-contents-list)
- [Contents](#contents)
- [What this is](#what-this-is)
- [Tiers](#tiers)
- [Run it](#run-it)
- [Phone on the tailnet (front door)](#phone-on-the-tailnet-front-door)
- [Ask, wait, reply](#ask-wait-reply)
- [The factory board](#the-factory-board)
- [The SITREP panel](#the-sitrep-panel)
- [Test it](#test-it)
- [Promote a change: dev to uat to stable](#promote-a-change-dev-to-uat-to-stable)
- [Config and variables](#config-and-variables)
- [GOOD examples](#good-examples)
- [NEVER examples](#never-examples)
- [Files](#files)

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

- What this is
- Tiers
- Run it
- Phone on the tailnet (front door)
- Ask, wait, reply
- The factory board
- The SITREP panel
- Test it
- Promote a change: dev to uat to stable
- Config and variables
- GOOD examples
- NEVER examples
- Files

## What this is

The owner decides from a local page, never from chat.
A card is one decision: About, Decide, 2 to 4 options with what happens, the recommended one marked, the owner's own words, Queue answer.
The owner can also message the agent from the page, and the agent replies there.
Only the interface agent runs this tool; no other seat gets a page or an owner channel (owner, 2026-10-10 UTC).

Vendored from the owner's bearings skill (`~/.claude/skills/bearings`, Sep 2026 snapshot) into this repo so it has tiers, tests, config and an upgrade path.
The page markup and theme are the owner's and are not changed here without an approved sample (SKILL.md rule).

## Tiers

| Tier   | Runs from                               | Page name                    | Port             | Who looks at it                          |
| ------ | --------------------------------------- | ---------------------------- | ---------------- | ---------------------------------------- |
| stable | the `main` checkout                     | `<project>-stable`           | fixed            | the owner, every day                     |
| uat    | a treehouse slot on the PR branch       | `<project>-uat-<ticket>`     | first free range | the owner or a verifier seat, before merge |
| dev    | a treehouse slot on the feature branch  | `<project>-dev-<ticket>`     | first free range | the builder and the test suite           |

Every value in that table comes from `config/bearings.json`.
Each tier has its own state directory under `state_root`, its own port, its own page and its own labelled herdr panes, so a dev page can never touch the owner's stable page.
A second start of a running tier is refused with exit 3 and the live url.

## Run it

Always through the Makefile, always inside herdr.

```sh
make serve TIER=dev TICKET=WO-20261010-ba08     # server in pane "bearings-dev-WO-20261010-ba08"
make wait  TIER=dev TICKET=WO-20261010-ba08     # wait loop in pane "...-wait"; prints the pane id
make url   TIER=dev TICKET=WO-20261010-ba08
make stop  TIER=dev TICKET=WO-20261010-ba08     # stops the server; both panes become OPEN slots again, none is closed
make serve TIER=stable                          # stable has no ticket
```

`TICKET` defaults to the current branch name with `feat/` stripped.

Where the panes go: the server and the wait take a pane of the caller's own tab whose label starts with `open_label_prefix` (the tool grid's `OPEN - any tool` cells) and relabel it.
Nothing is split inside a seat layout, so the architect column never moves.
A caller with no seat (`COQ_SEAT` unset) and no OPEN cell in its tab gets its own pane split once; a seat in that position is refused with exit 3 naming the tab.
`stop` relabels each pane with the label it had before (kept as `open_slots` in `server.json`) and closes nothing.
Outside herdr (`HERDR_ENV` unset) every verb that starts a process refuses; only the test harness passes `--no-herdr`.

## Phone on the tailnet (front door)

`server.mjs` listens on 127.0.0.1 only.
`scripts/front-door.mjs` is a dependency-free forwarder that binds the box's Tailscale IPv4 on the tier's own port and pipes every connection to the loopback server, so the owner's phone on the same tailnet opens the page with no root and no `tailscale serve`.
It does not touch headers: the Host the phone sends passes `scripts/lib/host.mjs` as it is.

```sh
make front-door TIER=stable        # pane "bearings-stable-front-door" (config tiers.stable.front_door_pane_label); prints the bind and pid
make front-door-stop TIER=stable   # explicit; the pane becomes an OPEN slot
```

Phone URLs (the key is on the page's `server.json`, never written down):

```text
http://whoadudette-1:44900/?key=<key>
http://100.122.200.108:44900/?key=<key>
```

- The bind address is `tailscale ip -4`, else `front_door.bind` in `config/bearings.json`, else `--bind` / `BEARINGS_FRONT_DOOR_BIND` overrides both.
- `~/.bearings/<page>/front-door.json` holds `{pid, bind, port, at}` while it runs; a second start refuses; the bind is retried 3 times 2 s apart, then exit 4.
- `make stop` never stops it: stable never stops, and the front door only forwards.
- Cost: plain HTTP inside the encrypted tailnet, one more process, and a restart when the Tailscale IP changes.
- Later alternative with root, which also gives port 80 and needs no front door process: `sudo tailscale serve --bg --http=80 http://127.0.0.1:44900`.

## Ask, wait, reply

```sh
make ask TIER=stable Q=/path/questions.json      # replaces the cards; ids never change once shown
```

`questions.json` is `{ "title": "...", "items": [ { "id", "about", "decide", "options": [ { "label", "then" } ], "rec" } ] }`.

The wait pane prints one line per event and loops until the server stops:

```text
ANSWER Q1 - <decide> -> <label> | words: <owner's words>
MESSAGE m-... - <text>
STOPPED <reason> at <UTC>
```

Read the wait pane with `herdr pane read <pane>` or arm a monitor on it.
A `MESSAGE` is the owner talking: answer it first, on the page:

```sh
scripts/bearings.sh stable reply --to m-20261010182008718-2ewk9 "text"
```

## The factory board

Every tier also serves the factory board (WO-20261011-616c) behind the same key and cookie.
`GET /board` is the page report/loop builds, and `GET /board/data.json` is the data it polls.
Both are read from `board_dir` in the config (relative to the repository root), which must equal `out_dir` in `report/loop/config/board.json`; `make -C report/loop lint` checks that.
A board that was never built answers 503 `board not built`; a config with no `board_dir` answers 404.
Run `report/loop/loop.sh watch` in a labelled herdr pane to keep it built (`report/loop/RUNBOOK.md`).

## The SITREP panel

A reply whose text is `#SITREP/v1#` and one JSON object draws as a colored status card on the page (WO-20261012-668a); the same text typed by the owner is a bubble, and so is a payload that does not parse.
It is how an agent gives the owner a briefing: five fixed blocks, at most two items each, one sentence of 15 words or fewer per item, the ticket on its own line with its full title.
Build it from records, check it, send it; never type the figures:

```sh
make sitrep-build TIER=stable OUT=/tmp/briefing.txt     # tickets, events and open PRs -> payload; exit 3 if it breaks the standard
make sitrep-check PAYLOAD=/tmp/briefing.txt             # exit 1 and one VIOLATION line per broken rule
make sitrep TIER=stable PAYLOAD=/tmp/briefing.txt       # check, then reply to the owner's newest message; refuses on a violation
```

The rules are `standards/STD-owner-sitrep-001.json` and `standards/STD-owner-comms-001.json`, the format is `standards/SITREP-PAYLOAD.md`, the limits are `config/sitrep.json`, the sentences are `config/sitrep.template.json`.
Everything else, including moving this to another repository, is in `RUNBOOK.md`.

## Test it

```sh
make test     # Podman, --network=none, image localhost/coq-bearings-test:1 built from tests/Containerfile
make lint     # config against the JSON schema, bash -n, node --check
```

The suite starts real servers inside the container, drives the page with Playwright, queues an answer, and checks it lands in `answers.jsonl` and that `wait.mjs` reports it.
Run `make test` from a labelled herdr pane, never backgrounded under an agent: `herdr pane run <pane> "make test"` then `herdr pane wait-output <pane> --regex 'tests: .* failed'`.
`tests/debug-probe.sh` prints the probe's full JSON for one page when a browser case fails.

## Promote a change: dev to uat to stable

1. Lease a slot for the ticket (`slot.sh acquire --holder <WO-ID>`), work on `feat/<slug>` there, `make test` green.
2. `make serve TIER=uat TICKET=<WO-ID>` from the slot, `make ask TIER=uat Q=<card asking the owner to confirm>`, give the owner the url.
3. The owner confirms on the uat page; record it with `work-order.sh evidence`.
4. PR, merge to `main`.
5. From the `main` checkout: `make upgrade` (stops stable, pulls main, serves stable again). `page.html` is re-read per request, so a markup-only change needs no restart.
6. `make stop TIER=uat TICKET=<WO-ID>`, release the slot.

State never moves with code: `make migrate TIER=stable FROM=<old page dir>` copies questions, answers, messages and delivered into stable only while stable is stopped, and refuses if stable already holds answers (`FORCE=1` to override).

## Config and variables

`config/bearings.json`, validated by `config/bearings.schema.json` at `make lint` and by `scripts/lib/config.mjs` at every start.
Strings may use `${HOME}`, `${project}`, `${tier}`, `${ticket}`, `${ENV:NAME}`; an unknown variable fails with exit 3 naming it.
No absolute path, hostname or port lives in a script: the file is meant to be lifted into S3 unchanged.
`open_label_prefix` is the label prefix that marks a free tool-grid cell; `pane_split` is used only for the no-seat fallback above.
`BEARINGS_CONFIG=<path>` points every script at another file (the suite does this).

## GOOD examples

- `make serve TIER=uat TICKET=WO-20261010-ba08` from the slot, then the url goes to the owner on the old page as a card: "Confirm the new page?".
- Adding a port range for a new tier: edit `config/bearings.json`, run `make lint`, run `make test`, nothing else changes.
- A seat needs the owner's answer: it writes `questions.json` through `make ask` and reads the wait pane; it never polls `answers.jsonl` itself.
- A browser case fails: run `tests/debug-probe.sh` in the test pane and read the `errors` array before touching code.

## NEVER examples

- `node scripts/server.mjs ... &` in an agent's shell. A process under an agent is invisible and blocks compaction; it goes in a labelled pane.
- Editing `page.html` to add a feature without an owner-approved sample; the look is the owner's theme.
- Sending a briefing by hand-typing its figures, or around `make sitrep`; the check is what keeps it short.
- Hardcoding `44900` or `~/.bearings` in a script or test; both belong to the config.
- Starting stable from a feature branch or a slot; stable runs the `main` checkout only.
- Copying `answers.jsonl` by hand between tiers; `make migrate` copies and verifies with `cmp`.
- A second wait loop for one tier; one wait per page, or events are delivered twice.

## Files

| Path                         | Role                                                                    |
| ---------------------------- | ----------------------------------------------------------------------- |
| `Makefile`                   | the only entry point agents use                                         |
| `scripts/bearings.sh`        | tier resolution, herdr panes, every verb                                |
| `scripts/server.mjs`         | the page server; reads the page files on every request                  |
| `scripts/wait.mjs`           | blocks for one delivery, prints it, exits; looped by `bearings.sh wait` |
| `scripts/reply.mjs`          | appends the agent's reply to `messages.jsonl` (capped at `max_reply_chars`) |
| `scripts/sitrep-build.mjs`   | fills `config/sitrep.template.json` from tickets, events and open PRs   |
| `scripts/sitrep-check.mjs`   | measures a SITREP payload against the standard; exit 1 on a violation   |
| `scripts/lib/sitrep.mjs`     | the SITREP rules, shared by the checker, builder and sender             |
| `config/sitrep.json`         | SITREP limits, ticket id patterns and build sources                     |
| `config/sitrep.template.json`| the shape and sentences of a briefing                                   |
| `standards/`                 | STD-owner-sitrep-001, STD-owner-comms-001 and the payload format        |
| `RUNBOOK.md`                 | build, check, send and port the SITREP panel                            |
| `scripts/lib/session-sync.mjs` | server-side timer that rewrites `session.json` from the seat's transcript (model, started, last active, ticket, herdr pane, context); `working_on` stays hand-written |
| `scripts/lib/config.mjs`     | loads, validates and interpolates the config; resolves a tier           |
| `assets/page.html`           | the owner's page (vendored, one null-guard breadcrumb at the list handler) |
| `assets/theme.css`           | the owner's theme                                                       |
| `config/bearings.json`       | every tunable                                                           |
| `config/bearings.schema.json`| the contract for that file                                              |
| `tests/`                     | Containerfile (digest-pinned), run-tests.sh, inside.sh, probe.mjs, debug-probe.sh |
| `VERSION`                    | this tool's version, bumped on promotion                                |
