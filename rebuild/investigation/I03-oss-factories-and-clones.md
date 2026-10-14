# I03 - Open-source software factories and the clone wave

Investigator: I03 (Factory Rebuild, step R-01).
Written 2026-10-14 UTC; revised in attempt 2 on 2026-10-14 to close the critic's six gaps (each fix is marked in the text with the evidence method).
Read-only on every repo, directory, page and pane.
Clones are under `/home/luna/.local/state/coq/coq-jev-herdr-plugin/rebuild/2026/10/investigation/clones/`.
Nothing cloned was built or run; every claim about a project comes from reading its README, docs, spec, code layout and git history.
Web sources carry their date.
Star, fork and issue counts were read with `gh api repos/<owner>/<repo>` at 2026-10-14T02:54:35Z to 02:54:36Z, and are given rounded where they matter, because they change by the hour (the same two repos read 0.3 percent apart across one earlier read the same night).

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

This area answers two things.
First, which open-source projects already do the factory's jobs (take work in, run an agent in isolation, gate it, merge it, recover when something is lost), and which of them match the owner's stack of Kubernetes, Jenkins, Argo, Make and gitops.
Second, what the owner's two verbatim references mean: "the reverse engineer anything repo on github" and "adobe has been completely copied" (owner message, 2026-10-14T02:21:34Z, session transcript `e31510a1-4a15-4377-9c1c-8f1088f67bed.jsonl`).

Plain answers up front.
"Reverse engineer anything" is `morluto/rea`, an MCP server and CLI that lets an agent analyse binaries, Electron apps, websites and similar targets.
It is a research tool for understanding someone else's software.
It has no factory function (no queue, no seats, no gates, no merge) and nothing in it is usable as a factory component.
"Adobe has been completely copied" refers to the ArtCraft project (GitHub org `storytold`), which built Rust apps in the shape of Photoshop, Illustrator, Premiere, Lightroom, After Effects, InDesign and Acrobat, and since then Word, Excel, PowerPoint, Pro Tools, AutoCAD and Figma.
The claim of "completely" is false on the project's own numbers: PhotoCraft states it is alpha and about 45 percent ready for real work.
The apps themselves are not usable by this factory.
What is usable is how that project runs its agent workload: a measured oracle, a generated scorecard with ratchet floors, and AGENTS.md as a gate contract.
Those patterns are listed in section 8.

For "agentic software factory" projects, the field has 63 open-source entries in the "Open-source factories" section of one curated list (`varun1505/awesome-software-factories`, CC0, pushed 2026-10-12, clone at `33d8520`).
Count method: the section is `README.md` lines 39-107 (heading at line 39, next heading "Ticket-to-PR pipelines" at line 107); `sed -n 39,106p README.md | grep -c '^- '` returns 63, and the 63 GitHub URLs in those lines are all distinct (`grep -o 'https://github.com/[^/)]*/[^/)]*' | sort -u | wc -l` returns 63), so there are 63 projects and no repeats.
Measured on 2026-10-14T02:56Z with `gh api` on each of the 63: 23 have under 100 stars, 47 have under 1,000, 15 were created on or after 2026-08-01, and the list itself flags 5 as `unmaintained` (`grep -c unmaintained` over lines 39-106).
The three with over 10,000 stars are `garrytan/gstack` (136,320, a Claude Code setup, not a runtime), `openai/symphony` (27,666) and `gastownhall/gastown` (18,363).
So the section is a long tail: most entries are small, and star count says nothing about being a runtime (gstack is a skill bundle).
A small number are serious and match the owner's needs: OpenAI Symphony (a spec), Optio (Kubernetes), Sortie (single Go binary), Bernstein (zero-LLM scheduler), Archon and Fabro (declared graphs), and the `software-factory-reliability` pattern set.
No open-source factory found is built on Argo Workflows or Jenkins (section 5, finding F9).

## 3. Where it lives

Clones made for this area, all under `clones/`, with the commit read:

- `rea` - https://github.com/morluto/rea at `d901561` (full history fetched).
- `photocraft` - https://github.com/storytold/photocraft at `583425b4` (full history fetched).
- `awesome-software-factories` - https://github.com/varun1505/awesome-software-factories at `33d8520`.
- `symphony` - https://github.com/openai/symphony at `be10a1b`.
- `optio` - https://github.com/jonwiggins/optio at `a6a047e0`.
- `sortie` - https://github.com/sortie-ai/sortie.
- `bernstein` - https://github.com/sipyourdrink-ltd/bernstein.
- `Archon` - https://github.com/coleam00/Archon.
- `fabro` - https://github.com/fabro-sh/fabro.
- `gascity` - https://github.com/gastownhall/gascity at `49937c8f0`.
- `gastown` - https://github.com/gastownhall/gastown.
- `software-factory-reliability` - https://github.com/sjarmak/software-factory-reliability at `b150a8c`.
- `machinist`, `esf`, `zeroshot`, `NEEDLE`, `super-simple-software-factory`, `factory` (addyosmani), `agentic-orchestrator` (DoorDash), `centaur` (Paradigm), `sample-autonomous-cloud-coding-agents` (AWS), `another-orchestrator`, `orchestrator` (c9r-io, archived), `attractor` (StrongDM spec).
- `forgeo` was already present from area L12 (`lucaGazzola/forgeo`); I read its README only.

Project facts read from git on 2026-10-14 (commits, distinct authors, first and last commit, top author share):

| Project | License | Commits | Authors | First | Last | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| openai/symphony | Apache-2.0 | 47 | 9 | 2026-03-04 | 2026-09-15 | spec plus Elixir reference, 27,666 stars |
| jonwiggins/optio | MIT | 1232 | 15 | 2026-03-19 | 2026-10-13 | 1121 commits by one author |
| sortie-ai/sortie | Apache-2.0 | 2925 | 7 | 2026-03-17 | 2026-10-13 | 2856 commits by one author |
| sipyourdrink-ltd/bernstein | Apache-2.0 | 5897 | 122 | 2026-03-28 | 2026-10-14 | README says "beta, solo-maintained" |
| coleam00/Archon | MIT | 3558 | 93 | 2025-11-09 | 2026-10-14 | 23,684 stars |
| fabro-sh/fabro | MIT | 5494 | 33 | 2026-02-19 | 2026-10-13 | 4638 commits by one author |
| gastownhall/gascity | MIT | 7065 | many | 2026-02-22 | 2026-10-14 | rewrite of Gas Town as an SDK |
| gastownhall/gastown | MIT | 7770 | many | 2025-12-16 | 2026-10-08 | 18,363 stars |
| owainlewis/machinist | MIT | 448 | 3 | 2026-07-18 | 2026-09-23 | early access |
| mitkox/esf | MIT | 30 | 3 | 2026-09-19 | 2026-10-06 | Machinist fork, Temporal |
| the-open-engine/zeroshot | MIT | 681 | 21 | 2025-12-25 | 2026-10-13 | |
| jedarden/NEEDLE | MIT | 3307 | 3 | 2026-03-20 | 2026-10-12 | 3263 commits by one author |
| disler/super-simple-software-factory | MIT | 1 | 1 | 2026-08-02 | 2026-08-02 | a skill, not a runtime |
| addyosmani/factory | MIT | 17 | 1 | 2026-08-18 | 2026-08-18 | reference operating model |
| lucaGazzola/forgeo | MIT | 329 | 4 | 2026-07-31 | 2026-09-30 | 35 stars |
| sjarmak/software-factory-reliability | MIT | 64 | 2 | 2026-08-09 | 2026-08-29 | patterns plus drills |

Evidence for these numbers: `git rev-list --count HEAD`, `git log --format=%an` run in each clone, and `gh api repos/<owner>/<repo>` on 2026-10-14.

## 4. What works

### 4.1 Reverse Engineer Anything (REA) - what it is and is not

- It is `morluto/rea`, created 2026-04-14T00:51:32Z as "betterBinaryMCP", MIT, TypeScript, about 211.6k stars and about 52.0k forks (211,577 and 51,983 at 2026-10-14T02:54:35Z), last push 2026-10-14T02:40:53Z (`gh api repos/morluto/rea`).
- Its first commit message is "Initial commit: betterBinaryMCP - Enhanced MCP server for Hopper Disassembler", dated 2026-04-14 (`git log --reverse` in `clones/rea`).
- It is one MCP server and CLI for analysing native binaries (Hopper, Ghidra, IDA), JavaScript and Electron apps, .NET assemblies, Android APKs, websites, packet captures, firmware, WASM and crashes (README.md; `docs/index.md`).
- It returns findings with evidence and limitations, and keeps observation, derivation, inference and unknown separate (`AGENTS.md` first section).
- It has six guided MCP prompts, including `investigate_feature`, `compare_application_versions` and `verify_reconstruction` (`docs/mcp-prompts.md`).
- It has a "reconstruction obligation ledger" that closes a reconstruction claim only when a unique owner, case fixtures and a passing verifier exist, and otherwise stays open or failed (`docs/reconstruction-obligation-ledgers.md` lines 1-17).
- It has a CLI with JSON output, so it can be scripted (`docs/cli.md`).
- Its own `DISCLAIMER.md` says the project will not help with "copying proprietary software or reproducing its protected code and assets", and will not help circumvent DRM or license checks.
- Press coverage on 2026-10-11 says the same: Geeky Gadgets (Julian Horsey, 2026-10-11 11:00) says REA "does not recover original source code" and that it reconstructs logic and behaviour.
- A trending post (International Cyber Digest on X, id 2108699960782774733) calls it the number one trending GitHub repo; I could not open the post (HTTP 402), so that is from the search result text only.
- Beware copies: `NabilRFG12/Reverse-Engineer-anything` reuses the description and README, and the REA README warns that a similar name does not establish an official download.

Verdict for the factory: REA is a sensor for understanding a third-party target.
It does no scheduling, queueing, isolation, gating or merging.
Its design ideas (evidence provenance, explicit unknown, closure only with a verifier) are worth reading, and are covered in `software-factory-reliability` in a form aimed at factories.

### 4.2 The Adobe "clone wave" - ArtCraft (org `storytold`)

What it is, with evidence:

- The author is Brandon Thomas (git author of 272 of the commits in `photocraft`; GitHub login `echelon` in `contributors/people.toml`).
- Seven Adobe-shaped apps were announced around 2026-10-08: PhotoCraft, VectorCraft, FilmCraft, LightCraft, PrintCraft, EffectCraft, DesignCraft (HotHardware, published 2026-10-08 10:22 EDT).
- By 2026-10-14 the org has about 25 relevant repositories and also Word, Excel, PowerPoint, Pro Tools, AutoCAD and Figma shaped apps (`gh repo list storytold`: wordcraft, gridcraft, deckcraft, soundcraft, cadcraft, figcraft, pdfcraft).
- PhotoCraft was created 2026-09-30T13:37:48Z, Apache-2.0, about 58.2k stars and about 9.9k forks (58,248 and 9,859 at 2026-10-14T02:54:35Z; `gh api repos/storytold/photocraft`).
- The first commits are "init repo" at 2026-09-30T02:12:04-04:00 and "one-shot" at 05:02:08-04:00 the same day (`git log --reverse`).
- The repo has 2152 commits in 14 days and 70 distinct commit authors in the last day (`git log --since=2026-10-13 --format=%an | sort -u | wc -l`).
- Commit trailers show the agent work: `Co-Authored-By: Claude Opus 5.5` appears 989 + 860 + 139 + 69 times, and `Co-authored-by: Copilot` 53 times (`git log --format=%B | grep -i co-authored-by`).

Is "Adobe completely copied" true?
No, by the project's own measurement.

- `ROADMAP.md` line 3: "Stage: alpha", next is beta, "~1,100-1,800 h away".
- `ROADMAP.md` headline table: ready for real work "~45% (40-50%)", essentials user "~61%", feature breadth "~76%", performance "25% (3/25 budgets met, measured)".
- `ROADMAP.md` line 43: "users of 0.5/0.6 have 579 open issues, 22 of 25 performance budgets are missed, and PSDs we write are not yet reliably accepted by Photoshop (#1281, #2469)".
- `docs/target-app-parity.md` lines 25-31: the earlier estimate of "82% 'of the way', 140-220 agent-hours to 95%" is called "far too optimistic"; about 1,230 issues were filed since the first release.
- The estimate moved from 140-220 hours to 2,300-4,100 hours (`docs/target-app-parity.md` lines 22-26).
- The claim "only 2 of the 7 apps are usable by the project's own estimate" from attempt 1 is not supported, so it is dropped.
  I searched for it on 2026-10-14 and found no source that says it.
  The nearest source, psdraw.app ("Updated Oct 11, 2026"), says only that two apps are labelled "early alpha" (PhotoCraft, PdfCraft) and five "in development"; it is a third-party site, and its table is out of date against the repositories.
- The repositories' own `ROADMAP.md` files, read with `gh api repos/storytold/<app>/contents/ROADMAP.md` on 2026-10-14T02:56Z, show a different picture: "Stage: alpha" for photocraft (line 3), vectorcraft (line 7), filmcraft (line 6), pdfcraft, lightcraft and effectcraft, and "Stage: pre-alpha" for designcraft.
  Ready-for-real-work estimates in those files: PhotoCraft about 45 percent, VectorCraft about 62 percent, FilmCraft about 56 percent (line 20), PdfCraft 49 percent, DesignCraft about 47 percent.
  So six of seven are alpha by their own label and every estimate is below 75 percent.
- Mezha (published 8 October 2026, https://mezha.ua/en/news/artcraft-adobe-photoshop-clone-315969/, opened 2026-10-14) gives a parity figure of 25-35 percent with no named source.
  That disagrees with PhotoCraft's own `ROADMAP.md` (about 45 percent ready for real work) and I did not use it.
- OMG Ubuntu (2026-10, "Updated Saturday") calls PhotoCraft "a superficial facsimile with pronounced flaws" after testing v0.3.0.
- GitHub reports 1,547 open issues plus PRs on `storytold/photocraft` at 2026-10-14T02:54:35Z (`gh api` `open_issues_count`; that field includes open pull requests; an earlier read the same night gave 1,537, so the figure rises by roughly ten in under an hour).

Method, with evidence (the part that matters to the factory):

- The target is a real installed app used as the oracle: "Adobe Photoshop 2026, version 27.11.0 ... installed at /Applications/Adobe Photoshop 2026 ... Inspected without launching it: Info.plist document types, the file-format plug-ins' PiPL read/write flags, .lproj ..." (`docs/target-app-parity.md` lines 44-48, revision row at line 576 says "installed bundle inspected").
- Real Photoshop-authored test files are the correctness oracle: repo `storytold/photocraft-corpus` ("Test data for photocraft", `AGENTS.md` section 1 table, last row).
- A generated, measured scorecard decides what to do next: `docs/scorecard.md` (generated by `cargo xtask scorecard`, CI checks it is current) and `docs/parity-checklist.md` (generated list of every Photoshop menu item, live or missing) (`AGENTS.md` sections 1 and 5).
- Progress is a ratchet: "When parity rises, raise FLOOR in crates/ui-egui/src/parity.rs (never lower it)" (`AGENTS.md` section 4).
- Every feature is a command with an id taken from the target's own menu catalog, so "done" is checkable per item (`AGENTS.md` golden rule 1; `docs/contributing.md` "Adding a command").
- The app is drivable by agents through a token-authenticated JSON-line TCP control channel, a headless CLI and an MCP server (`docs/control-protocol.md`; `AGENTS.md` section 2, `apps/photocraft-cli`).
- The architecture is enforced mechanically: `cargo xtask layers` fails the build when a crate depends on a higher layer (`AGENTS.md` section 2).
- A fuzz test (`panic_hunt`) tries every command with adversarial parameters and must stay green (`AGENTS.md` rule 9).
- Handoff is a log plus a green tree: "Sessions can end abruptly (crashes, context limits), so the dev log plus a green tree is how the next agent picks up" (`AGENTS.md` section 5).
- Parallel agents get explicit rules: separate `CARGO_TARGET_DIR`, edit only files you own, new commands in a new module, atomic manifest writes, "wait and retry; don't fix their files" (`AGENTS.md` section 6).
- The calibration is from its own history: about 2-4 agent-hours per merged PR, "the repository has sustained 10-20 concurrent agents" (`docs/target-app-parity.md` lines 206-221).
- The labor model is open contribution: 70 authors in one day bringing their own agent, with CI as the only gate (`.github/workflows/ci.yml`; commits list in `git log`).

Verdict for the factory: the apps are not usable.
The workload design is a good example of a factory whose queue, oracle, gate and progress meter are all machine-generated files in the repository.
See section 8.

Risk to flag plainly: the project calls its work "clean-room" (`AGENTS.md` rule 3), but the parity doc says the installed Photoshop bundle was inspected and a catalog of 628 menu items and shortcuts was reproduced.
Whether that is clean-room is a legal question I cannot settle from the repository.
The reporting disagrees on method: ArtCraft says "clean-room reimplementation", MindStudio (2026-10-11) says an agent "ran a local copy of Photoshop, clicked through its tools and panels, and recorded what each action did", and HotHardware (2026-10-08) says Opus 5.5 was used "reverse-engineering Adobe's suite".
No source I could open shows that REA was used to build ArtCraft (search of 2026-10-14 found only a co-occurrence in time).

### 4.3 Open-source factories that match the owner's needs

Each item says what it is, what is evidenced, and fit to Kubernetes, Argo, Jenkins and Make.

**OpenAI Symphony (spec, Apache-2.0).**
- A 2,312-line `SPEC.md` defines a long-running service that reads work from a tracker, makes an isolated workspace per issue and runs a coding agent in it (`SPEC.md` lines 18-20).
- The orchestrator is a scheduler and tracker reader only; ticket writes are done by the agent through provider tools (`SPEC.md` lines 36-40 and 1310-1322).
- Internal claim states are `Unclaimed`, `Claimed`, `Running`, `RetryQueued`, `Released` (`SPEC.md` lines 645-660).
- Reconciliation runs before dispatch on every tick, with stall detection and tracker refresh (`SPEC.md` lines 733-749 and 819-839).
- Recovery has no durable orchestrator database: "Restart recovery is tracker-driven and filesystem-driven" (`SPEC.md` line 730).
- Retry: continuation 1000 ms, failure `min(10000 * 2^(attempt-1), max_retry_backoff_ms)`, default cap 300000 ms (`SPEC.md` lines 799-801; cap default at line 625).
- Fit: it is a spec, not a runtime, so it ports to any stack, including Argo or a Go service.
- Maturity: 47 commits, last 2026-09-15; the Elixir reference is not meant as the product.
- InfoQ (2026-05) and Help Net Security (2026-04-28) report the release date as 2026-04-27; the 500 percent landed-PR claim is an unverified internal OpenAI figure reported by TUN.

**Optio (MIT, Kubernetes).**
- Self-hosted orchestration on Kubernetes: a pod per run, repo worktrees, fourteen trigger types: manual, schedule, webhook, ticket, GitHub, GitLab, Slack, Linear, Jira, Pylon, PagerDuty, Sentry, Alertmanager and Datadog (`README.md` line 34; the table of work types is lines 23-32).
- A reconciliation control plane: observe, pure decision function, one typed action, compare-and-swap (`docs/reconciliation.md` lines 3 and 22-45).
- Its own stated reason is the owner's problem: "Lost events left rows stuck.
  A dropped websocket message or a crashed subscriber could strand a task in provisioning forever" (`docs/reconciliation.md` line 11).
- Runs outlive the API process through a lease: renewed every 20 s, lasts 60 s, every write is a CAS on the holder (`docs/reconciliation.md` line 101).
- Stall threshold default 900000 ms (15 min) (`docs/reconciliation.md` line 146).
- Auto-merge, auto-review and auto-resume on review feedback are decided by the reconciler, not an LLM (`docs/reconciliation.md` lines 58-68).
- Fit: Kubernetes native (Helm, pods), uses PostgreSQL and Redis/BullMQ, so it duplicates Argo's job and brings its own database.
- Caveat: "The combined API/web deployment currently requires one replica" (`README.md` line 90).
- Caveat: 1121 of 1232 commits are by one author.

**Sortie (Apache-2.0, Go).**
- Single binary that turns tracker tickets into agent sessions with retries, stall detection and cleanup (`README.md`).
- It states it is derived from the Symphony spec and persists to SQLite (`docs/architecture.md` line 3; `docs/README.md` lines 52 and 61).
- Fit: smallest deployable unit for the owner's cluster (one container plus a volume); it is not a pod-per-run design.
- Caveat: 2856 of 2925 commits by one author.

**Bernstein (Apache-2.0, Python).**
- "No LLM in the coordination loop.
  Scheduling is plain Python, so a run is reproducible end to end" (`README.md` line 46).
- A YAML file declares phases, roles, dependencies and conditions, and "nothing in the file is a prompt" (`README.md`).
- Each coding task gets its own git worktree behind merge gates and the backlog is "claimed atomically" (`README.md`).
- Maturity statement: "Status: beta.
  Solo-maintained" (`README.md` line 38), although git shows 122 authors.
- Fit: very close to "no cog should hold up the system", but it is a local file-state tool and not Kubernetes native.

**Archon (MIT, TypeScript) and Fabro (MIT, Rust).**
- Both put the process in a declared graph and the agent in bounded nodes.
  Archon uses YAML (`.archon/workflows/*.yaml`, nodes with `depends_on`, `loop`, `fresh_context`), Fabro uses Graphviz DOT with human gates and CSS-like model routing (`README.md` of each; Fabro `README.md` lines 53 and 97).
- Fabro commits every stage to a Git branch for resume and revert; Archon gives each run its own worktree.
- Fit: the owner already said "DAG, MERMAID, we have it" (see L12); these are runnable proof that the DAG-as-file approach is mainstream.

**Machinist / ESF (MIT, Go, Temporal).**
- ESF routes a task through Temporal into isolated microVM sandboxes with deterministic verification gates: "agent success alone is not factory success" (`esf/README.md`).
- Fit: Temporal is a durable queue and timer service, answering "a wakeup is never lost"; heavy to add if Argo is already the engine.

**Gas City / Gas Town (MIT, Go).**
- A controller and supervisor loop reconciles desired state to running state, with runtime providers tmux, subprocess, exec, ACP, Kubernetes and herdr (`gascity/README.md` lines 37-40).
- The herdr provider is opt-in, tmux stays default and fallback (`docs/reference/herdr-provider.md` lines 5-10; `README.md` lines 66-67).
- Herdr cannot be chosen per agent: the provider doc says the selector is city-wide `[session] provider` or process-wide `GC_SESSION`, and "herdr cannot be selected for individual agents" (`docs/reference/herdr-provider.md` lines 56-59, repeated under the heading "Per-agent / per-rig" at lines 74-78).
- The Gas City `README.md` contradicts its own provider doc: lines 66-69 say herdr can be enabled "per-agent, per-rig, or city-wide".
  The provider doc is the more specific page and states the limit twice, so I take it as authoritative; the README sentence looks stale or loose.
  I did not run it to settle which is true.
- Its docs warn that herdr's CLI surface changed in minor releases 0.7.4, 0.7.5 and 0.8.0, that one change made nudge delivery surface an error, and that "nothing in the build or the default test suite went red" (`docs/reference/herdr-provider.md` lines 24-34).
- Fit: heavy (Dolt, `bd`, ICU libraries) and expert-oriented; useful as evidence about herdr, not as a base.

**software-factory-reliability (MIT, Python) - patterns, not a product.**
- Sixteen failure-boundary patterns, each with a drill that fails when the pattern is broken (`patterns/README.md`).
- The central rule: "Events make it fast; reconciliation makes it true" (`patterns/reconciliation.md` line 6).
- It documents a factory whose "event lane wedged and the scan lane carried the factory" on 2026-07-14 (`patterns/reconciliation.md` Observed failure).
- It documents a capacity decision on 2026-08-07 that disarmed 42 scheduled orders in one commit, two of which were the level-triggered safety scans (same file).
- It lists patterns that map to the owner's observed failures: stable work identity, fenced authority, start-or-attach, explicit unknown state, verify before publish, durable intent.
- It has a `Makefile` with `make demo`, `make drill DRILL=... MODE=unsafe|protected`, `make check` (`Makefile` lines 13-34: `demo` at 13, `drill` at 16, `drills` at 28, `check` at 34), and a `factory-check` that reads a YAML description of a factory against `schemas/factory.schema.json`.
- This matches "i love driving automation with make files too" directly.
  I did not run it.

**Others read and rated lower fit.**
- `forgeo` (lucaGazzola): scheduled, serial, JSON backlog, commits to main; one task at a time (`README.md`).
  See L12 for the name question.
- `addyosmani/factory`: an operating model over GitHub Issues and scheduled agents; 17 commits by one author on 2026-08-18; humans own every merge.
- `DoorDash agentic-orchestrator`: gated phases, desktop app; macOS-first.
- `Paradigm centaur`: Slack-driven, Kubernetes sandboxes, durable workflows; license NOASSERTION.
- `AWS ABCA`: AWS-specific; its README says it is "in maintenance mode" and V2 is coming.
- `gh-aw` (GitHub, MIT): compiles markdown workflows to locked-down GitHub Actions; fits only if the pipeline lives in Actions.
- `super-simple-software-factory`: "Deterministic Python owns the graph.
  Coding agents are bounded nodes" (`README.md` line 4); one commit, a pattern, not a runtime.

## 5. What broke and why

Findings, ordered by importance to the rebuild.
Where the evidence disagrees with the brief, it says so.

- F1 - "Completely copied" is false on the project's own numbers (section 4.2).
  The brief's framing that a clone wave proves anyone can copy anything quickly is only half true: breadth came in days, depth did not.
  ROADMAP.md line 43 reports 22 of 25 performance budgets missed and 579 open issues.
  The honest lesson for a factory is that an unmeasured "done" was off by an order of magnitude (140-220 hours versus 2,300-4,100 hours, `docs/target-app-parity.md` lines 22-31).
- F2 - REA is not a factory tool (section 4.1).
  The brief wonders whether anything there is usable; plainly, no component is.
  The reconstruction ledger is an idea about evidence closure, nothing to adopt as code.
- F3 - The projects that survive contact all reconcile against authoritative state and treat events as a speed-up.
  Symphony: reconcile first on every tick (`SPEC.md` lines 729 and 742-744).
  Optio: a reconciler replaced worker-owned transitions because lost events stranded tasks (`docs/reconciliation.md` lines 3 and 11). sjarmak: "Events make it fast; reconciliation makes it true".
  This is the same family as the owner's lost-wakeup and idle-seat problems described in L01, L06 and L13.
- F4 - The serious orchestrators keep the LLM out of scheduling.
  Bernstein: "No LLM in the coordination loop" (`README.md` 46). another-orchestrator: an LLM planner writes JSON, a deterministic state machine dispatches, and "they never call each other directly" (`README.md`).
  Symphony: the orchestrator is a scheduler; the agent writes tickets.
  The owner's architect-and-orchestrator LLM roles do the opposite (see L13).
- F5 - herdr is a session host in the field, never the control plane.
  Gas City ships it as an opt-in backend behind tmux, pinned by version, with default tests running against a fake because herdr's CLI changed in minor releases 0.7.4, 0.7.5 and 0.8.0 (`docs/reference/herdr-provider.md` lines 24-34).
  This supports the owner's remark that herdr is being used wrong.
  It does not, by itself, show that herdr is bad as a terminal for people.
- F6 - Fast generators of code outrun their gates.
  Horthy's "Why Software Factories Fail" (HumanLayer, July 2026) argues lights-off factories degrade the codebase and cites a Faros AI report of more PRs merged with no review and more incidents; the owner's I02 file covers this in depth.
  In ArtCraft the same pattern shows as about 1,540 open issues and PRs after 14 days (1,547 at 2026-10-14T02:54:35Z).
- F7 - Single-maintainer risk is the norm: Optio 91 percent one author, Sortie 98 percent, NEEDLE 99 percent, Fabro 84 percent, Bernstein calls itself solo-maintained.
  Anything adopted should be pinned, vendored and wrapped, or taken as a spec and re-implemented.
- F8 - Many "software factory" repositories are prompt or skill bundles.
  `super-simple-software-factory` has 1 commit, `addyosmani/factory` has 17 commits by one author, `i-soumya18/AgentSDLC` has 0 stars.
  The term does not imply a runtime.
  Noah Mitchem's "Nobody Has Actually Built a Software Factory" (Medium, published 2026-08-31, read in full on 2026-10-14 through the author's RSS feed because the page itself returns HTTP 403) reviewed "at least 21 programs from Stripe to Meta to Ramp" and found that "every 'factory' is the same thing: agents, running in parallel, on the process the company already had." The attempt 1 file gave the author as Nicolas; the feed and the awesome list (`README.md` line 602) both say Noah.
- F8a - Mitchem's essay supplies the one test that separates a factory from a parallel-agents setup, and it applies to the owner's rebuild: "Ask which number the agent is allowed to fail, and who owns it." Where correctness is a number the agent can read but not change (Meta KernelEvolve bitwise checks, Baseten latency, Carlini's C compiler test suites), the loop closes and the human leaves; where correctness is a review, the loop ends at a person.
  He also notes that zero of 13 operators changed the codebase the agents write into, and that an agent writing its own tests is the failure (exe.dev's Maisem Ali: "the agent was still grading its own work").
  Source: https://medium.com/@NMitchem/nobody-has-actually-built-a-software-factory-77ffdc0c3efc, feed read 2026-10-14T02:55Z, feed `pubDate` Mon, 31 Aug 2026 15:18:56 GMT.
  This is one essayist's reading of public write-ups, not a measurement, and some quoted numbers (PostHog 1,441 to 4,725 merged PRs, Stripe 1,300 PRs a week) are his citations that I did not trace to their origin.
- F9 - No open-source coding-agent factory built on Argo Workflows, Tekton or Jenkins exists at any maturity I could find.
  Searches on 2026-10-14: a web search for Argo plus Claude Code factories returned only Argo and Claude skill listings, and GitHub repository searches for "argo workflows coding agent" returned two repositories with 1 and 0 stars (`heetgoti22-bit/argos-ai-agents`, `gusmendez99/agentic-sdlc-poc`).
  Kubernetes-operator hits are 0-6 stars.
  The nearest Kubernetes-native option is Optio.
  That means the owner's Argo and Jenkins path is novel work, with Symphony and the reliability patterns as design inputs and no code to reuse.
- F10 - Legal exposure for clone work.
  REA's own disclaimer excludes "copying proprietary software or reproducing its protected code and assets".
  ArtCraft's clean-room claim is asserted, not shown.
  If the factory is ever pointed at cloning a commercial product, that decision belongs to the owner and is not a technical question.

## 6. Waits, polls, sleeps and leases

This section is marked for local areas; as a comparison, here is every bound in the projects most relevant to the rebuild, so the owner's own waits (see L01) can be set against the field.

| Project | Wait or lease | Bound | Evidence |
| --- | --- | --- | --- |
| Symphony | poll tick | 30000 ms default | `SPEC.md` line 616 (`polling.interval_ms`) |
| Symphony | stall timeout | 300000 ms default; skip if zero | `SPEC.md` line 633 (`codex.stall_timeout_ms`), rule at lines 825-829 |
| Symphony | turn timeout | 3600000 ms default | `SPEC.md` line 631 (`codex.turn_timeout_ms`) |
| Symphony | request/response timeout at startup | 5000 ms default | `SPEC.md` line 632 (`codex.read_timeout_ms`) |
| Symphony | hook timeout | 60000 ms default | `SPEC.md` line 622 (`hooks.timeout_ms`) |
| Symphony | retry after clean exit | 1000 ms fixed | `SPEC.md` line 799 |
| Symphony | retry after failure | `min(10000 * 2^(n-1), 300000)` ms | `SPEC.md` line 800, cap default at line 625 |
| Symphony | concurrent agents | 10 default | `SPEC.md` line 623 |
| Optio | attachment lease | renewed every 20 s, expires after 60 s | `docs/reconciliation.md` line 101 |
| Optio | queue lock and stalled interval | 60 s and 30 s | `docs/reconciliation.md` line 123 |
| Optio | stall threshold | 900000 ms | `docs/reconciliation.md` line 146 |
| Optio | failed read | defer with exponential backoff | `docs/reconciliation.md` line 68 (`deferWithBackoff`) |
| sjarmak | failed lookup | returns `LOOKUP_FAILED`, never "absent" | `patterns/reconciliation.md` line 11 |

Lessons:
- Every wait has a number and a named owner; none of these systems blocks on "the agent will say something".
- Liveness is a lease with a renew interval a third of the lease length (Optio 20 s renew, 60 s lease).
- A failed read is its own state; it defers, and never concludes the thing is gone.
- A poll is acceptable as the correctness path as long as an event path can make it faster.

## 7. Decisions an LLM makes that a rule could make

Marked for local areas; here is where the field puts the line, for use against L13.

| Decision | Field practice | Evidence |
| --- | --- | --- |
| What runs next | tracker order and priority sort, no LLM | Symphony `SPEC.md` lines 771-775 |
| Whether to retry | exponential backoff rule | Symphony `SPEC.md` lines 797-801 |
| Is a seat stalled | elapsed time since last event | Symphony `SPEC.md` lines 823-829; Optio `docs/reconciliation.md` line 146 |
| Is work merged | reconciler action `autoMergePr` when approved and CI green | Optio `docs/reconciliation.md` line 64 |
| Did the agent finish | deterministic gate; "agent success alone is not factory success" | ESF `README.md` |
| Sequencing of phases | declared graph the agent cannot change | Bernstein, Archon, Fabro, super-simple-software-factory |
| Planning what to build | the LLM, but as a producer of files a state machine reads | another-orchestrator `README.md` |
| Concurrency and capacity | a number in config | Symphony `SPEC.md` line 623 (`agent.max_concurrent_agents`, default 10) |

Where an LLM is still used in the field: planning and decomposition of a goal into tickets, writing code, and review.
Nobody in this set gives an LLM the dispatch, retry, stall, or merge decision.

## 8. What to carry forward

In order of value to the rebuild:

1. Take Symphony's `SPEC.md` as the control-plane contract, then decide where it runs.
   Claims, run attempts, reconcile-before-dispatch, stall timeout and backoff are all specified, with normative language, in 2,312 lines.
   It is a design input, Apache-2.0, and not tied to Elixir or Linear.
2. Adopt the reconciliation rule as a design law: events are optional accelerators; a level-triggered scan against authoritative state is the correctness path (`software-factory-reliability/patterns/reconciliation.md` line 6; Optio `docs/reconciliation.md` lines 3 and 11).
3. Adopt the `software-factory-reliability` drills as acceptance tests for the rebuild, driven by `make`.
   Sixteen patterns and thirteen drills (`drills/`: event-is-lost, worker-dies-agent-survives, stale-writer-completes, retry-storm, and others) correspond to failures already in the owner's history.
   This fits the stated preference for Make-driven automation.
   Needs a run in the pod sandbox before trusting.
4. If a runnable Kubernetes control plane is wanted without writing one, evaluate Optio first: pod per run, reconciler, leases, auto-merge, Helm.
   Cost: PostgreSQL and Redis, one API replica, single-author project.
   The alternative is Sortie for a small single-binary start.
5. Copy the ArtCraft workload design, not its code:
   - a checklist generated from the target (their menu catalog, here the factory's job list),
   - a measured scorecard regenerated in CI,
   - ratchet floors that only rise,
   - an `AGENTS.md` whose "Before you finish a task" section is a list of exact `make` targets,
   - a dev log and a green tree as the only handoff,
   - a rule that an agent never fixes another agent's in-progress file.
6. Keep process as a declared graph with the agent as a bounded node (Bernstein, Archon, Fabro).
   Mermaid or DOT is acceptable; the owner's "DAG, MERMAID" matches Fabro's DOT approach.
7. Gas City's herdr provider notes are the best external evidence on herdr's interface stability; use them in the herdr decision (L04).
   Note the Gas City `README.md` and its provider doc disagree on per-agent selection (section 4.3), so read the provider doc.
8. Make the gate a machine verdict the seat can read but not edit (F8a, Mitchem; the same shape as ArtCraft's generated scorecard and ratchet floor, and ESF's "agent success alone is not factory success").
   This is the nearest outside statement of the owner's "no cog should hold up the system": the gate is a number, not a person or an LLM.

## 9. What to kill

- Any plan to use REA or the Adobe-shaped apps in the factory.
  There is no function for them.
- The assumption that an open-source "software factory" can be installed and run as is.
  Most are skills, prompts or single-author tools (F7, F8).
- LLM seats that decide dispatch, retry, stall, or merge.
  No project in the set does this (section 7).
- Dependence on events alone for state progress (F3).
- Treating a count of generated features as completion.
  ArtCraft's reset from "82 percent" to "45 percent" is the cautionary case (F1).
- Adopting Gas Town or Gas City whole.
  Both bring Dolt, `bd` and a large role vocabulary, and herdr is only a backend there.

## 10. Open questions for the owner

1. Should the control plane be an existing Kubernetes-native project (Optio), a Symphony-spec service the owner writes on Argo and Jenkins, or a small single binary (Sortie)?
   This changes where state lives and how many moving parts the rebuild has.
   The shelf track (S01, S02) and L07 and L10 findings should be read with this.
2. Is cloning a third-party commercial product ever a factory workload?
   If yes, the legal and clean-room posture needs an owner decision before any such ticket is cut; if no, nothing about REA or ArtCraft needs more attention.

## 11. Sources

Local files read (all under `/home/luna/.local/state/coq/coq-jev-herdr-plugin/rebuild/2026/10/`):
- `briefs/20261014-brief-B-investigation.md` (sections 1, 3, 4 area I03, 6).
- Owner message with the two references: `/home/luna/.claude/projects/-home-luna-projects-coq-jev-herdr-plugin/e31510a1-4a15-4377-9c1c-8f1088f67bed.jsonl`, timestamp 2026-10-14T02:21:34.952Z, promptIndex 6.
- `investigation/L09-earlier-factory-iterations.md` and `investigation/L12-forgeo.md` (cross-reference only).
- Clone files cited by path in sections 3 to 8, under `investigation/clones/<name>/`.

Web sources, with access dates (all fetched or searched 2026-10-14) and the publication date where the page gave one:
- REA repository: https://github.com/morluto/rea (stars and dates from `gh api`, 2026-10-14).
- REA site named in the repo: https://rea.tools (not fetched).
- Geeky Gadgets, "REA GitHub Repository Lets AI Reverse Engineer Apps", Julian Horsey, published 2026-10-11 11:00: https://www.geeky-gadgets.com/reverse-engineer-anything-github-repo/
- International Cyber Digest post (not readable, HTTP 402): https://x.com/IntCyberDigest/status/2108699960782774733
- Medium, "Viral Github Repo to Reverse Engineer Anything": https://medium.com/data-science-in-your-pocket/viral-github-repo-to-reverse-engineer-anything-cf02560b2b80 (listing only).
- PhotoCraft repository: https://github.com/storytold/photocraft (cloned 2026-10-14, HEAD `583425b4`).
- ArtCraft org repositories: https://github.com/storytold (listing by `gh repo list`, 2026-10-14).
- HotHardware, published 2026-10-08 10:22 EDT: https://hothardware.com/news/dev-uses-ai-to-build-clones-of-photoshop-and-entire-adobe-suite-for-free
- MindStudio, published 2026-10-11: https://www.mindstudio.ai/blog/ai-recreated-photoshop-software-moat
- OMG Ubuntu, October 2026 ("Updated Saturday"): https://www.omgubuntu.co.uk/2026/10/artcraft-free-photoshop-ai-clone
- Search-result listings only (not opened): Vice "Everything We Know About the Free Adobe Clones Built With AI. Do They Actually Work?" https://www.vice.com/en/article/everything-we-know-about-the-free-adobe-clones-built-with-ai-do-they-actually-work/ ; innFactory https://innfactory.ai/en/blog/ai-rebuilt-photoshop-word-reverse-engineering/ ; Notebookcheck https://www.notebookcheck.net/Photoshop-Premiere-more-Experienced-Rust-developer-recreates-Adobe-suite-with-AI-assistance-as-open-source.1419230.0.html ; madrobot.blog https://madrobot.blog/2026/10/10/artcraft-photocraft-free-adobe-photoshop-alternatives-built-with-claude-opus/
- Curated list of factories: https://github.com/varun1505/awesome-software-factories (CC0, pushed 2026-10-12; clone at `33d8520`; 63 entries counted at `README.md` lines 39-106; the descriptions in it are secondary and were checked against the repositories only for the projects named in section 4.3).
- Noah Mitchem, "Nobody Has Actually Built a Software Factory", Medium, published 2026-08-31: https://medium.com/@NMitchem/nobody-has-actually-built-a-software-factory-77ffdc0c3efc (direct fetch HTTP 403 on 2026-10-14; full text read from the author feed https://medium.com/feed/@NMitchem at 2026-10-14T02:55Z; also found by web search the same day, which lists a Chinese repost at https://www.hubwiz.com/blog/nobody-has-actually-built-a-software-factory/ that I could not open, HTTP 502).
- psdraw.app, "Adobe Clone: ArtCraft's 7 AI-Built Free Adobe Apps Explained", "Updated Oct 11, 2026": https://psdraw.app/adobe-clone (opened 2026-10-14; third-party and out of date against the repositories; used only to show where the "2 of 7" idea may have come from).
- Mezha, published 8 October 2026: https://mezha.ua/en/news/artcraft-adobe-photoshop-clone-315969/ (opened 2026-10-14; the 25-35 percent figure has no named source and was not used).
- ArtCraft per-app roadmaps read through `gh api repos/storytold/<app>/contents/ROADMAP.md` on 2026-10-14T02:56Z: vectorcraft, filmcraft, pdfcraft, lightcraft, effectcraft, designcraft.
- Star, fork and creation figures for the 63 listed projects: `gh api repos/<owner>/<repo>` on 2026-10-14T02:56Z, saved only in the investigator scratch area.
- OpenAI Symphony: https://github.com/openai/symphony ; announcement coverage InfoQ 2026-05 https://www.infoq.com/news/2026/05/openai-symphony-agents/ and Help Net Security 2026-04-28 https://www.helpnetsecurity.com/2026/04/28/openai-symphony-codex-orchestration-linear/ ; TUN (500 percent claim, unverified) https://www.tun.com/home/openai-releases-symphony-an-open-source-coding-agent-orchestrator/
- Optio: https://github.com/jonwiggins/optio
- Sortie: https://github.com/sortie-ai/sortie
- Bernstein: https://github.com/sipyourdrink-ltd/bernstein
- Archon: https://github.com/coleam00/Archon
- Fabro: https://github.com/fabro-sh/fabro
- Gas City and Gas Town: https://github.com/gastownhall/gascity , https://github.com/gastownhall/gastown
- Machinist and ESF: https://github.com/owainlewis/machinist , https://github.com/mitkox/esf
- software-factory-reliability: https://github.com/sjarmak/software-factory-reliability
- Why Software Factories Fail, Dex Horthy, HumanLayer, July 2026: https://github.com/humanlayer/advanced-context-engineering-for-coding-agents/blob/main/wsff.md
- Other repositories read at README level: https://github.com/coleam00/ai-software-factory , https://github.com/addyosmani/factory , https://github.com/doordash-oss/agentic-orchestrator , https://github.com/paradigmxyz/centaur , https://github.com/aws-samples/sample-autonomous-cloud-coding-agents , https://github.com/github/gh-aw , https://github.com/linuxlewis/another-orchestrator , https://github.com/disler/super-simple-software-factory , https://github.com/lucaGazzola/forgeo , https://github.com/jedarden/NEEDLE , https://github.com/the-open-engine/zeroshot
- GitHub searches for Argo or Kubernetes coding-agent factories, run with `gh api search/repositories` on 2026-10-14, results quoted in finding F9.
