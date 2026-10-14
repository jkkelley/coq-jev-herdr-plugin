# L03 - Design documents versus what was built

Investigator: area L03, attempt 3, step R-01 of the Factory Rebuild.
Read-only on every repo; all repo reads were of the main checkout `~/projects/coq-jev-herdr-plugin` at local `main` `5ad1996` (2026-10-14T01:44Z, working tree includes 5,812 untracked event files), with `origin/main` read through git objects only (`b7a3c5d`, 2026-10-14T02:49Z).
Attempt 3 started 2026-10-14T02:51Z (`date -u`); PR 35 was read at 02:53Z.
Attempt 3 replaces the previous file, which had the L01 text pasted over sections 1 to 5; nothing of L01 is kept here.

## 1. Contents

1. Contents
2. What it is
3. Where it lives
4. What works
   - 4.1 Verdict by target (one line per named target)
   - 4.2 specs/
   - 4.3 factory/
   - 4.4 playbooks/ and roles/
   - 4.5 docs/
   - 4.6 AGENTS.md, ROADMAP.md, COMPASS.md
   - 4.7 PR 35
   - 4.8 Designs held only in the state root
5. What broke and why
   - 5.1 The one mechanism: laws and designs are written faster than they are built, and the build is patched without them
   - 5.2 Designs that exist but were not followed (ledger)
   - 5.3 Where the build ran ahead of any design (ledger)
   - 5.4 Designs that contradict each other
   - 5.5 Per-target breakage: specs, factory, playbooks and roles, docs, AGENTS.md, ROADMAP.md, COMPASS.md, PR 35
   - 5.6 Where the brief's diagnosis is and is not supported by this area
6. Waits, polls, sleeps and leases
7. Decisions an LLM makes that a rule could make
8. What to carry forward
9. What to kill
10. Open questions for the owner
11. Sources

## 2. What it is

L03 compares every design document the owner and the agents wrote for the factory against the code that now runs.
The design artifacts in this project are: eight XML specs on main (SPEC-00 to SPEC-05, SPEC-15, SPEC-17) plus two scheduler specs (SPEC-16 overview, SPEC-16.G), 109 design-graph nodes, the binding `ROADMAP.md`, the `AGENTS.md` laws, 11 role files and 11 rendered playbooks, the `factory/RUNBOOK.md` family of runbooks, five SOPs, and a set of designs that live only in the state root (the CI gate design, the line-ops-are-code design, the SPEC-17 1.1.0 side draft, the factory rebuild plan) plus the unmerged PR 35 export spec.
The finding is that the designs are good and mostly self-consistent, but they are not what drives the build: the build is driven by incident tickets ("Cause a" to "Cause ay"), and the designs are rewritten after the fact, so at any moment three to five descriptions of the same machine disagree.
Where a design was built as written, it worked (the routes table, the queue, the board, the spec and playbook lint, the CI gate).
Where it was not built (SPEC-04 event subscriptions and lease sweeps, SPEC-17 health watch, halt and resume, the Go scheduler, the roles contract in SPEC-02), the gap is exactly where the line still stalls, and an agent still does the job.

## 3. Where it lives

Repository `jkkelley/coq-jev-herdr-plugin`, main checkout `~/projects/coq-jev-herdr-plugin` (246 commits since 2026-10-10T18:16Z, `git rev-list --count main`).

| Artifact | Path | Size (lines) | Last relevant commit |
| --- | --- | --- | --- |
| Spec index | `specs/SPEC-00-index.xml` | 51 | `2026-10-12T21:56Z` (5 commits touch `specs/` in total) |
| Conventions, DAG, herdr, compaction | `specs/SPEC-01`, `-03`, `-04`, `-05` | 85, 78, 82, 54 | created in `bec8276` (PR #1, 2026-10-10T14:48-05:00) |
| Stub specs | `specs/SPEC-02-roles-and-permissions.xml`, `specs/SPEC-15-sdlc-end-to-end.xml` | 12, 12 | stubs since 2026-10-10 |
| Line operating model | `specs/SPEC-17-orchestrator-and-agent-health.xml` | 367 | `d3e5c6a`, 2026-10-12T21:56-05:00 (WO-20261013-1031) |
| Go scheduler specs | `specs/scheduler/SPEC-16-scheduler-overview.xml`, `SPEC-16.G-config-schema.xml`, `bin/check.sh`, `schema/scheduler-spec.xsd` | 283, 180 | `630fd89` 2026-10-13T13:41-05:00; `c62f739` 15:21-05:00 |
| Design graph | `graph/nodes/*.json` (109 nodes: 58 locked, 51 proposed), `graph/INDEX.md`, `graph/GRAPH.mmd`, `graph/bin/graph.sh` | 109 files | |
| Route runner | `factory/` (`bin/` 7 scripts 1,182 lines, `config/`, `schema/`, `tests/cases` 27 cases, `RUNBOOK.md` 400 lines) | | 17 commits |
| herdr layer | `herdr/` (`bin/` 18 scripts, `config/`, `layouts/`, `systemd/`, `tests/` 45 files, `RUNBOOK.md` 135) | | 47 commits |
| Line scripts | `line/` (`bin/` 12 scripts, `config/`, `units/`, `tests/` 20 files) | | 14 commits |
| Roles and playbooks | `roles/*.json` (11), `roles/schema/role.schema.json`, `roles/bin/render-playbook.sh`, `playbooks/*.md` (11) | | 18 commits |
| Docs | `docs/README.md` (27), `docs/runbooks/backlog.md` (146), `docs/sops/SOP-0001,0002,0003,0005,0006` (51, 67, 78, 56, 49) | | |
| Orientation | `AGENTS.md` (365), `ROADMAP.md` (231), `COMPASS.md` (41), `CLAUDE.md` (16) | | `AGENTS.md` 7 commits, `ROADMAP.md` 3 commits |
| Scheduler | `scheduler/` Go module, 3,804 lines of which 2,336 are generated protobuf (`scheduler.pb.go` 1,904 and `scheduler_grpc.pb.go` 432), so 1,468 hand-written lines | | |

Open pull request 35: `https://github.com/jkkelley/coq-jev-herdr-plugin/pull/35`, branch `feat/factory-design-spec-v2-0-every-agent-workflow-ru`, head `9b293ec`, read with `gh pr view 35` on 2026-10-14T02:53Z.

State root, outside git (`~/.local/state/coq/coq-jev-herdr-plugin/plans/2026/10/`):

| File | What it is |
| --- | --- |
| `20261012212500-roadmap.md` | the architect's progress ledger for `ROADMAP.md` (401 lines; line 3 says "This file tracks progress only") |
| `20261012222000-retro-architect-flood-and-halt.md` | retro of the 2026-10-12 flood |
| `20261013021301-spec17-1-1-0-draft-loops-maintenance-controller.{md,xml}` | SPEC-17 1.1.0 side draft, frozen out of PR 84 by card C27 |
| `20261013194800-ci-gate-design.md` (149) | CI gate design with two amendments |
| `20261014004500-line-ops-are-code-design.md` (89) | line ops are code, status DRAFT (line 3) |
| `20261013-duplicate-work-audit.md` (563) and `20261013235500-duplicate-audit-rulings.md` (34) | 16 findings of duplicated tickets |
| `20261014-factory-rebuild-plan.md` (6) | pointer to `rebuild/factory-rebuild-plan.xml`, landed on `origin/main` as `b7a3c5d` (#182) |

Google Drive (owner's account, searched 2026-10-14 via the Drive connector): see 5.5, "AGENTS.md".

## 4. What works

### 4.1 Verdict by target

| Target | Visited | Verdict | Main evidence |
| --- | --- | --- | --- |
| `specs/` | all 10 XML files read in full | mixed: SPEC-03, SPEC-17 and SPEC-16 are real designs; SPEC-02, SPEC-15 are empty stubs; SPEC-00 points at nine specs that do not exist | 4.2, 5.2 |
| `factory/` | config, schema, `RUNBOOK.md`, `bin/` listing, routes, runner, flow and policy configs read; `route.sh`, `flow.sh` headers | the best-matched design and build pair in the repo | 4.3 |
| `docs/` | `README.md`, runbook, SOP headers | accurate but tiny; router promises directories that do not exist | 4.5 |
| `playbooks/` | architect, orchestrator, merger, tester, compliance-officer read; rest by lint | rendered by machine, in sync, but describe roles the line no longer uses as written | 4.4 |
| `roles/` | `orchestrator.json` in full, all 11 summarised | schema-valid and linted; contents lag SPEC-17 | 4.4 |
| `ROADMAP.md` | read in full | strong rules, stale work-item table | 4.6 |
| `COMPASS.md` | read in full | an unfilled scaffold template | 4.6, 5.5 |
| `AGENTS.md` | read in full | the real operating spec; two laws contradict the build | 4.6, 5.5 |
| PR 35 | `gh pr view 35`, branch file read through `git show` | a 1,166-line export spec, unmerged, 114 commits behind | 4.7 |

### 4.2 specs/

- SPEC-03 (`specs/SPEC-03-dag-and-node-contract.xml`) was built, almost literally, as `factory/config/routes.json` plus `factory/bin/route.sh`.
  The spec says the orchestrator "matches it against routes.json top to bottom and performs the first row's action" (SPEC-03:28); `factory/RUNBOOK.md` states "No line in the script reads a kind, a code or a note except to match a row" (RUNBOOK.md:18-19) and the table is `routes.json:5-37`, 31 rows.
  The build grew the action set from SPEC-03's four (enqueue, wake, escalate, notify_owner) to eight (`factory/config/routes.schema.json:12`: enqueue, wake, seat, escalate, notify_owner, break-glass, ignore, none) and added `when`, `down`, `supersede` (`routes.schema.json:14-17`).
  27 test cases cover it (`factory/tests/cases/`, 27 files).
- SPEC-03 s-locks (`SPEC-03:64-68`) was built as `queue/bin/queue.sh` (64 lines): "enqueue is a write, dequeue is a rename, a lease is a field with a deadline", priority p0..p3, dependency check through `work-order.sh next` (`queue/bin/queue.sh:1-13`).
- SPEC-04 s-bringup (`SPEC-04:17-29`) was built as `herdr/bin/bringup.sh` (123 lines, header lines 3-9: herdr, control plane, guard, monitors grid, monitor seat) and the rule "seat.sh refuses while the monitor seat is down" is enforced at `herdr/bin/seat.sh:526`.
  `herdr/bin/recover.sh` (186) matches RUN-recover, `herdr/bin/retire.sh` matches RUN-retire, `herdr/bin/monitors.sh` (275) and `herdr/config/monitors.json` match the monitors tab group, and `herdr/bin/supervisor.sh:7` calls `bringup.sh`.
  `seat.sh:519-520` refuses a Claude seat without compaction-guard, which is SPEC-05 s-install's sensor rule.
- SPEC-17 (`specs/SPEC-17-orchestrator-and-agent-health.xml`) is the best design document in the repo: a status code map (`:246-265`), an inventory of all 26 hand fixes of 2026-10-12 with the system that replaces each (`:267-295`), a cross-walk to the Go scheduler (`:297-314`), 15 named test cases (`:326-343`) and eight build tickets K1 to K8 (`:345-355`).
  Four of the eight were built: K1 board WO-20261013-f268 - Roadmap K1 - Board: one board in the state root is the single intake, with a lane per role, leases, pull, done, sweep, digest and ... (`done`, PR 91, `line/bin/board.sh` 241 lines, cases `line/tests/cases/board-t01,t02,t03,t14`); K5 WO-20261013-f298 - Roadmap K5 - The writer refuses a gate record without its sha and any code outside the SPEC-17 status code map, and the schema gains the halt, drain and resume kinds (`done`, PR 145, commit `7e114c9`, after a revert `964e464`); K6 WO-20261013-b221 - Roadmap K6 - The owner lane on the page: bearings renders owner-lane items as cards and the health line from the board's health fi... (`done`, PR 92); K8 WO-20261013-89c7 - Roadmap K8 - The factory board shows the live line: ticket status read from open pull requests and ticket branches (or the SPEC-1... (`done`, PR 93).
- The spec toolchain is enforced by machine: `lint/lint.sh:9-27` validates every `specs/SPEC-*.xml` against `specs/schema/spec.xsd`, caps each at 1,000 lines, forbids the em dash, resolves every `<ref>` to an existing spec section or graph node, and runs `graph.sh check` and `sync-specs`; `specs/scheduler/bin/check.sh` does the same for SPEC-16 and additionally proves each routes row and status code is owned by exactly one domain spec (`SPEC-16:244-246`).
- The status-code map (`STC-http-shaped`, SPEC-01:43, SPEC-17:246-265) is used by `events/schema/event.schema.json` (code enum, 33 kinds) and has survived every iteration.

### 4.3 factory/

- `factory/RUNBOOK.md` (400 lines) is a runbook that matches its scripts: the action table (`RUNBOOK.md:24-33`) lists the same eight actions as `routes.schema.json:12`; the state-root table (`RUNBOOK.md:62-67`) matches `factory/config/runner.json:6-9` (`${tree:records}`, `${tree:ledger}`, `${tree:run}`).
- The route runner is configuration, not code: every tunable is in `factory/config/runner.json`, `flow.json`, `policies.json` with a `*.schema.json` beside it, as `DEC-no-hardcode-config-s3` (SPEC-01:32) requires.
- Roadmap A1 and A2 (runtime data to the state root) were built as designed: WO-20261012-7e13 - Roadmap A1 - State root: event.sh writes records under the state root with timestamped descriptive names, and ... (`done`, PR 83) and WO-20261012-0229 - Roadmap A2 - The belt reads the state root: route.sh, flow.sh, gate.sh and policy.sh read records and keep the... (`done`, PR 88); `factory/config/runner.json:6-9` uses `${tree:...}`, and `bin/state-root.sh` resolves the root.
- The standing-policy idea (ROADMAP rule 5) exists: `factory/config/policies.json:11-33` (POL-blocked-land-it, `deadline_seconds` 1800 at line 14, limit 1 per ticket) and `factory/bin/policy.sh` (184 lines).
- The claims gate for "no file touched by two open PRs" (AGENTS.md:255-265) is built: `factory/bin/claims.sh` (162), `factory/bin/gate.sh` (159), `bin/wo-start.sh`, and test cases 15 and 16.
- `factory/bin/suites.sh` (131) plans the suites from the diff and is the input of `coqGate()` (Jenkinsfile BREADCRUMB 1, `Jenkinsfile:10-12`).

### 4.4 playbooks/ and roles/

- Playbooks are generated, never hand-written: `roles/bin/render-playbook.sh:2-3` ("a diff in CI means someone edited a playbook by hand") and `lint/lint.sh` step "roles: schema + playbooks in sync" fail on drift.
  All 11 roles validate against `roles/schema/role.schema.json`.
  The playbook's fixed shape (Who you are, Runtime and model, Permissions, Steps, Records you emit, What wakes you, Forbidden; `playbooks/orchestrator.md:64-120`) is a seat contract: input, output, limits.
- The role files carry breadcrumbs (4 roles have none, 7 have 1 to 2), for example `roles/orchestrator.json:87` records that `max_seats` went from 1 to 2 on 2026-10-13 because one orchestrator was a single point of routing.
- Model policy is declared per role (`architect`: opus-5-5 or codex; `worker`, `tester`, `reviewer`, `merger`, `orchestrator`, `interface-agent`: sonnet-5-5; `monitor`, `compliance-officer`, `player`: haiku-5-5), `read_only` and `permission_mode` per role.

### 4.5 docs/

- `docs/README.md:6-18` is a Diataxis router with two enforceable rules (mode and review date; a decision is superseded, never edited).
- The five SOPs and the backlog runbook each carry mode, last-reviewed date, Contents, Steps and Verification (SOP-0003 lines 1-15 shows the format) and match the code they describe (SOP-0003 describes `herdr/bin/supervisor.sh`, `docs/runbooks/backlog.md:1-12` describes Roadmap H, which is `done`, PR 81).
- SOP numbers are minted by `bin/mint-id.sh` (`:9-14` breadcrumb, WO-20261012-0677), so two PRs cannot take one number; the gap at SOP-0004 is consistent with the breadcrumb's stated cost, "an abandoned PR leaves a gap in the series" (`bin/mint-id.sh:15`); on 2026-10-12 PR 31 and another PR both took SOP-0003 (`bin/mint-id.sh:9-11`).

### 4.6 AGENTS.md, ROADMAP.md, COMPASS.md

- `AGENTS.md` is the real operating specification (365 lines, 15 laws and 6 golden or hard rules; contents list at `:3-30`, golden rule `:49`, the 100-line routing rule `:70-80`).
  Its laws map one-to-one to incidents and are repeated in code: "no file is ever touched by two open PRs" (`:255`) is `claims.sh`; "runtime data never lives in git" (`:111`) is Roadmap A1/A2; "three loops, always" (`:136-149`) is the system epic WO-20261013-16f1; "agents are never gates" (`:125`) is the ROADMAP rules 1 to 9.
- `ROADMAP.md` has the strongest sentences in the repository.
  The nine "agents are never gates" rules (`ROADMAP.md:105-115`) and the guardrails (`:117-126`: no records branch, at most four tickets in flight, files declared at cut) are specific, testable and cited by the build (SPEC-17 `:74`, `:321`).
  The locked decisions table (`:50-71`, cards C9 to C24) is a decision log: each row is an owner answer with a date.
  The architect's own ledger says phases 0 and 1 are done and phase 2 mostly done (`plans/.../20261012212500-roadmap.md:396`, 2026-10-14T00:34Z); work items A1, A2, G, H, K are `done` (ticket statuses read from `work-orders/**/WO-*.md` frontmatter, 2026-10-14).
- `COMPASS.md` works only as an example of the scaffold format (it is the `project-scaffold` template; see 5.5).

### 4.7 PR 35

- PR 35 (WO-20261012-fd87 - Factory design spec v2.0: every agent, workflow, runbook, SOP, schema and status code of the small loop and the software factory, generic and portable) is a generated-style export: `specs/exports/factory-spec.xml` v2.0.0 with 10 sections S1 to S10, 381 rules, 1,058 elements, each under 240 characters and each citing a source file (PR body "What"; `git show origin/feat/factory-design-spec-v2-0-every-agent-workflow-ru:specs/exports/factory-spec.xml` lines 1-12 and 123, 210, 290, 382, 413, 460, 505, 850, 936, 1060).
- It ships its own checker (`specs/bin/export-check.sh`, 154 lines; `specs/config/export.json` and schema) that fails on a home path, key, email, host, ticket id or em dash, and a `coverage` mode that proves all 26 required source files are cited (PR body, AC-H2: "covers 26 of 26 required files").
- It is the only document that lists every role, route row, flow gate, SOP step and schema field in one place with PowerShell 5.1 port notes (S6), which is why the Windows-side agent asked for it (memory: xml-specs-request-from-windows-agent).
- Five divergences it recorded on main at the time are now fixed or partly fixed: S2-060 (`work.started` had no routes row) is fixed at `factory/config/routes.json:26`; S2-049 (board read `factory/state/runner.json`) is fixed by WO-20261013-89c7 (`report/loop/loop.sh:257` breadcrumb); S5-044 (stale second routes schema) is now byte-equal content in both `factory/schema/routes.schema.json` and `factory/config/routes.schema.json` (a duplicate remains); S10-002 (204, 400, 409 not in the locked code node) is fixed in SPEC-17 `:251-254` but `graph/nodes/STC-http-shaped.json` still lists only nine codes; S1-041 and S3-023 (COQ_EVENTS_ROOT) are moot after A1.

### 4.8 Designs held only in the state root

- The CI gate design (`20261013194800-ci-gate-design.md`) is the one design that was built event-driven and within hours: gate 1 test image `db1a95c` (2026-10-14T00:14Z), gate 6 webhook listener `3584b1e` (01:07Z), gate 2 `coqGate()` `2247679` (01:18Z), all `done` (WO-20261013-ab25 - CI gate 2: the shared-library step coqGate() plans the suites from the diff, fans them out as pod containers, and posts ..., WO-20261013-ca2a - CI gate 6: a webhook listener turns GitHub status, check_run and pull_request events into records, fed by gh webhook forw...).
  `Jenkinsfile:10-29` carries a six-point breadcrumb and `ci/README.md:154-156` carries the ladder.
- The line-ops-are-code design (`20261014004500-line-ops-are-code-design.md`) states the governing sentence of the whole rebuild at line 26: "An agent exists only for judgement: writing code (worker, spec-author) and judging a diff (reviewer). Every other step is a script triggered by a record or a GitHub event, with the ladder".

## 5. What broke and why

### 5.1 The one mechanism

Three facts, each with evidence, add up to one mechanism.

1. The designs are rewritten, not followed.
   `specs/` has been touched by 5 commits since 2026-10-10 while `herdr/` has had 47, `factory/` 17, `line/` 14 and `roles`/`playbooks` 18 (`git log --format=%h -- <dir> | wc -l`, 2026-10-14).
   The CI gate design changed tool twice in one hour: the original decision was a GitHub Actions self-hosted runner (`ci-gate-design.md:28`, "Tool: a GitHub Actions self-hosted runner on this WSL host"), then the owner said "jenkins is free in my k8s cluster" and the file was amended in place four times inside 20 minutes ("Jenkins, not GitHub Actions" at line 102, "in the cluster, through the shared library" at 119, "hooks and ladder" at 128, "the webhook listener" at 141; timestamps 20:00Z, 20:04Z, 20:07Z, 20:20Z).
2. The build is driven by incident tickets, not by the designs.
   33 of the 263 tickets are titled "Cause <letter>" (frontmatter scan of `work-orders/**/WO-*.md`, 2026-10-14; Cause a to Cause ay), 50 of 246 commit subjects on main match cause, fix, broke or stall, and 83 commits landed on 2026-10-13 UTC (`git log --since=2026-10-13T00:00Z --until=2026-10-14T00:00Z main`); the duplicate-work audit found 16 defects in the ticket queue itself, nine of them duplicates or stale scope (`20261013-duplicate-work-audit.md:28-30`).
3. The control loop that the designs say must not exist is the one that drives the line.
   `plans/2026/10/20261012212500-roadmap.md` (the architect's progress ledger) shows the architect issuing line operations by prompt long after ROADMAP rule 4 and AGENTS.md:125-134 forbade it: line 378 "sched-worker-1 idle 12 min again; told to loop over open PRs, merge 153 + start 10d8" (2026-10-13T22:56Z), line 389 "Ruling recorded: P0 fix forward seated --role spec-author" (23:44Z), line 399 "OWNER HALT ('you can't write this shit, you need a spec sent off. You're getting overloaded. We need to halt everything.')" (2026-10-14T00:38Z).
   The line-ops design opens with the same diagnosis: "Tonight nearly every stall came from an agent doing one of these steps late, twice or wrong" (`line-ops-are-code-design.md:22`).

The single mechanism: the project has a design layer (laws, specs, graph, roadmap) that tells agents what must be rule-driven, and a build layer that implements a rule only after an incident, so for each design item the agent stays the executor until a "Cause" ticket replaces it.
The design layer never schedules the build: SPEC-17's eight tickets were cut (`3643adf`, 2026-10-13T02:56Z), four were cancelled and split into 17 smaller tickets that are all `ready` today (see 5.2), and the roadmap's own work-item table still names the cancelled originals.

### 5.2 Designs that exist but were not followed (ledger)

| Design item | Where designed | Status in code (main `5ad1996`) | Evidence |
| --- | --- | --- | --- |
| Monitor subscribes to herdr events, "nothing polls, seats are woken" | `SPEC-04:45` (s-monitors), `SPEC-04:80` (NEVER: a seat that polls), `SPEC-03:76` | not built; every watch polls files every 10 to 15 s; no herdr subscription anywhere | `grep -rn subscribe herdr/bin factory/bin line/bin` returns nothing; poll values in section 6 |
| Expired leases are released by the monitor, which wakes the queue | `SPEC-04:50`, `SPEC-03:66`, `herdr/config/leases.json:3` | not built: nothing reads `herdr/config/leases.json`; `queue.sh sweep` and `board.sh sweep` are called by no script | `grep -rn 'leases\.json'` finds only specs and the schema; `grep -rn sweep herdr line factory queue config` finds only break-glass and the scripts' own definitions |
| Failure record must carry `repro` and one observation, "or event.sh refuses it with exit 3" | `SPEC-03:23`, node `SCH-factory-record` | not built: `factory/schema/record.schema.json` (the schema SPEC-03 names, with `repro` and `role`) is read by no script; `events/bin/event.sh:19` validates against a different schema `events/schema/event.schema.json` that has no `repro` | `grep -n repro events/bin/event.sh` returns nothing; schema property lists differ (record: 15 properties incl. `repro`, `role`; event: 18 incl. `to`, `pane`, `action`, `answer`, `policy`) |
| Two record schemas | one in SPEC-03/SPEC-16 `l-records` (`SPEC-16:36`) | both exist; SPEC-16 `c-record` (`:198`) cites both | the contract in the spec is not the contract the writer enforces |
| `slot.sh acquire/release` | `SPEC-04:50`, `playbooks/merger.md:25` (allowed command), merger step 3 | `slot.sh` does not exist in the repo | `find . -name slot.sh` returns nothing; slots are leased by `treehouse` from `seat.sh:633` and returned by `merge.sh` |
| `herdr/bin/breakglass.sh` | `SPEC-04:65` | replaced by `seat.sh --break-glass` plus `break-glass-guard.sh` and `-lib.sh` | `ls herdr/bin` |
| SPEC-17 K2 health watch (checks C1 alive, C2 stuck, C3 context, C4 capacity, C5 exactly-one) | `SPEC-17:102-128`, `:348` | not built: `line/config/health.json` does not exist; ticket K2 WO-20261013-ba44 - Roadmap K2 - Health watch: the system checks every agent each tick, alive, stuck, out of context and at capacity, with three retri... is `cancelled` | `ls line/config` shows only board and hook configs |
| SPEC-17 K3 orchestrator seat running O1 to O7 | `SPEC-17:84-100`, `:349` | not built: K3 WO-20261013-14f9 - Roadmap K3 - Orchestrator seat: the fixed seat runs the line by rule, re-routes refused seats, downs finished seats, cleans up aft... `cancelled`; `roles/orchestrator.json:29` still says "The gate between the interface agent and the factory ... never does the work", read_only true, no `seat.sh` command | `roles/orchestrator.json:29,34,45-49`; replacement WO-20261013-a91a - Orchestrator role and playbook: the seat rules on the findings the code raises; the line duties O1 to O7 are named as the schedule... `ready` |
| SPEC-17 K4 halt, drain, resume, line-check | `SPEC-17:152-159`, `:350`; ROADMAP item C | not built: no `make line-halt`; K4 WO-20261013-f52a - Roadmap K4 - Halt, drain, resume and line-check: make line-halt, line-drain, line-resume and line-check with the flags in the stat... and Roadmap C WO-20261012-e970 - Roadmap C - make line-halt and make line-resume: the halt flag the supervisor honours, USERHALT, and bearings... are `cancelled`; split tickets WO-20261013-fd7d - make line-halt and line-drain: the halt and drain flags in the state root's run directory with reason and time, line.halted 503 to..., WO-20261013-8ed9 - make line-resume: the preflight judges open items by rule, the system comes up B1 to B10 in order and stops at the first FAILED, s..., WO-20261013-ced5 - make line-check: the bring-up checklist B1 to B8 read-only, one line per node ok or FAILED, exit 1 on any FAILED (SPEC-17 T13; K4 ... and WO-20261013-8e0c - The supervisor keeps only bearings stable alive while the halt flag exists, and the runbook says how the owner's USERHALT and USER... all `ready` | `ls line/bin`; the owner's USERHALT on 2026-10-14T00:38Z was again executed by hand (ledger line 399: "Done: run/line.halted + merge-hold.json set; Escape to every seat") |
| ROADMAP rule 1: "lint fails a kind with no route" | `ROADMAP.md:107` | not built: WO-20261013-44aa - Routes lint: a check fails a record kind with no routes row, a kind with two rows for one attempt and a SPEC-17 code with no row, naming it (SPEC-17 T15; K7 part 1 of 4) `ready`; no routes check in `lint/lint.sh` | `grep -n routes lint/lint.sh` returns nothing |
| ROADMAP rule 2 and D: owner seat read from the ticket | `ROADMAP.md:108` | partly built: WO-20261013-9b21 - Cause aa: route.sh derives the ticket from the PR head branch when a record has a pr but no ticket; a PR carrying two tickets uses the first `done` (PR 158); Roadmap D WO-20261012-da1e `cancelled` | `routes.json:7` still wakes the role `worker`, not an owner seat |
| ROADMAP rule 4, C18: merger verifies on main, no merge waits on the architect | `ROADMAP.md:65,110` | not built: `routes.json:15` still wakes the architect on `merged 200`; `merge-watch.sh:84` prompts a second LLM ("Verify main and do the post-merge cleanup") | WO-20261013-612d - Route row: merged 200 runs line/bin/after-merge.sh instead of waking the architect to verify and WO-20261013-bed2 - Routes rows: 429 and 500 to the orchestrator lane, merged 200 to the merger only, the architect row on merged 200 deleted, and the owner seat read fro... both `ready` |
| ROADMAP rule 7: stall wakes the owing seat, retries, then escalates | `ROADMAP.md:113`, `SPEC-16 p-stall` | not built: WO-20261013-a7e6 - The stall policy in flow.sh wakes the seat that owes the next record, retries, then hands the item to the maintenance lane; owner ... `ready` | `factory/bin/flow.sh` only notes a stall |
| ROADMAP Phase 2 A4: `events/` and `factory/state` leave git | `ROADMAP.md:190`, `AGENTS.md:111-123` | not done: WO-20261012-99d6 - Roadmap A4 - events/ and factory/state leave git: cut over under USERHALT, records copied to the state root, m... `ready`; 179 event files and 340 changelog files are still tracked and 5,812 untracked event files (2026-10-12T17:17Z to 2026-10-14T00:35Z) sit in the main working tree | `git ls-files events \| wc -l` 179; `git ls-files changelog \| wc -l` 340; `git status --porcelain --untracked-files=all` |
| Roadmap L: mark NATS deferred in the graph | `ROADMAP.md:194` | not done: `graph/nodes/DEC-nats-jetstream-grpc.json` is still `status: locked` (and carries a `supersedes REQ-locks-and-queues` edge); L WO-20261012-be64 - Roadmap L - Decision nodes for the locked roadmap decisions in the design graph, the NATS decision marked defe... `ready` | `graph/nodes/DEC-nats-jetstream-grpc.json:5` |
| SPEC-16 Go scheduler, waves 0 to 3 | `SPEC-16:249-259` | wave 0 skeleton only: `core`, `testkit`, `cli`, protobuf, configs; no `intake`, `routes`, `seat`, `job`, `policy`, `health`, `executor`, `observe`, `cutover` package; 10 of 11 domain specs (A to F, H to K) are not on disk | `ls scheduler/internal` shows cli, core, testkit; `ls specs/scheduler`; WO-20261012-fa36 - Scheduler cut-over: shadow mode and its decision files, the parity report and subcommand, going active with th... `ready` |
| `docs.sh verify` "fails the build" | `docs/README.md:23` | not wired: no `docs.sh` call in `lint/lint.sh`, `Makefile` or `Jenkinsfile` | `grep -rn docs.sh lint Makefile Jenkinsfile` finds only a comment in `bin/mint-id.sh` |
| Docs router promises tutorials/, how-to/, reference/, explanation/, decisions/ | `docs/README.md:8-15` | only `sops/` and `runbooks/` exist (runbooks is not even in the table) | `ls docs` |

### 5.3 Where the build ran ahead of any design

The following components have no mention in any `specs/*.xml` or `specs/scheduler/*.xml` file (`grep -l <name> specs/*.xml specs/scheduler/*.xml`, 2026-10-14), and their first commit is after the specs were written (2026-10-10).

| Component | Role in the line | First commit | Note |
| --- | --- | --- | --- |
| `herdr/bin/belt.sh` | serial bring-up belt, frozen 180 s per seat until WO-20261013-7af7 - Belt frozen 180s per seat bring-up: seat.sh waits for a compaction-guard ACK line no seat prints, inside the belt's seri... | `55e799e` 2026-10-12T12:04-05:00 (WO-20261012-b800 - Supervisor ...) | not in any spec |
| `herdr/bin/patrolwatch.sh`, `roles/compliance-officer.json`, `playbooks/compliance-officer.md` (97 lines, the longest playbook) | a Haiku seat that reads panes every minute | `02eec23` 2026-10-12T21:57-05:00 (WO-20261013-5b33) | the word "compliance" appears in no spec, no ROADMAP, no graph node |
| `line/bin/verify-main.sh` | verify on main | `9b3d105` 2026-10-13T15:21-05:00 | designed in ROADMAP C18/SPEC-17 O4 as a merger duty, built as a script, then a CI gate 4 ticket re-owns it |
| `line/bin/merge-watch.sh`, `route-retry.sh`, `record-bus.sh`, `seat-queue.sh`, `start-tickets.sh`, `digest.sh` | the Roadmap I script move | `1b58d05`, `83ced7b`, `104658b`, `1ef911b`, `f31bf7d`, `8b1b6cf` on 2026-10-13 | SPEC-17 cites `digest` only; the rest of the names are absent from every spec; `record-bus.sh` was closed by card C17 and rebuilt anyway (audit F5, `duplicate-work-audit.md:196`) |
| `line/bin/hook-listener.sh` (184 lines), `line/units/*.service`, `ci/`, `Jenkinsfile` coqGate | CI webhook and gate | `3584b1e` 2026-10-13T20:07-05:00 | designed only in the state-root CI gate design |
| `line/bin/merge.sh` (388 lines) | the squash merge | `c2ae440` 2026-10-13T09:53-05:00 (WO-20261013-f6ae) | SPEC-17 mentions the word; SPEC-03 and SPEC-15 say a merger seat merges |
| `factory/bin/suites.sh`, `bin/test-cases.sh` | suite planning | `2c11986` 2026-10-13T14:58-05:00 | no spec |
| `herdr/bin/turnwatch.sh`, `recwatch.sh` | the two watches that flooded the architect (retro, `retro-architect-flood-and-halt.md:5-9`) | `55e799e` | named only in SPEC-16 (as things to retire) and SPEC-17 |

Duplicate-work evidence for "built without checking designs": the audit found a record bus built twice (F5), a NATS bus ticket against a locked decision (F6, `duplicate-work-audit.md:217`), four owners of "verify main after a merge" (F3, `:145`), two ticket rewrites of the same routes row (F4, `:172`).

### 5.4 Designs that contradict each other

| Topic | Description A | Description B | Evidence |
| --- | --- | --- | --- |
| Who verifies main | ROADMAP C18 and SPEC-17 O4/n-verify: the merger | `routes.json:15`: the architect; the CI gate design: Jenkins gate 4 on push to main (`ci-gate-design.md`); `line-ops` design: CI gate 4 | `ROADMAP.md:65`; `routes.json:15`; `line-ops-are-code-design.md:37` |
| Do tester and merger seats exist | ROADMAP C12 (locked, `ROADMAP.md:59`): "The tester, reviewer and merger seats stay" | CI gate design and line-ops design: tester retired (WO-20261013-3eac - CI gate 5: pr.opened routes to the reviewer only; the tester role is retired and its playbook marked retired), merger retires (`line-ops-are-code-design.md:89`) | no owner card retires them; C12 remains in the binding file |
| The bus | SPEC-16 `l-bus` (`:37`): state-root files, NATS deferred | graph node `DEC-nats-jetstream-grpc` locked; PR 35 rule S2-051 "Bus decided: NATS" | graph node status; `pr35.xml:257` |
| The engine | SPEC-16 p-end (`:31`): the Go scheduler is "the engine and the end state" and every bash watcher is interim | CI gate design: "a few lines of Go in the scheduler later"; line-ops design: more bash (`start-loop.sh`, `after-merge.sh`) and `systemd --user` units | `line-ops-are-code-design.md:46-50` |
| What an orchestrator is | `roles/orchestrator.json:29`: a read-only gate that validates requests and routes records | SPEC-17 s-orchestrator: a seat that runs the line (O1 to O7); in practice `sched-worker-2` is prompted by `merge-watch.sh:84` | role file vs SPEC-17:84-100 |
| Supervisor and halt | ROADMAP guardrail (`:123`): supervisor stays uninstalled until item C | `herdr/systemd/coq-supervisor.{service,timer}.in` and SOP-0003 exist; C is cancelled | `ls herdr/systemd`; ticket e970 `cancelled` |
| Where processes live | `AGENTS.md:184-196` herdr-first: "Never shell &, nohup ... every agent, watcher, poll, tail and server" in a herdr pane | `line/units/*.service` and `herdr/systemd/*` run units under systemd; SPEC-16 `sh-unit` (`:105`) says one systemd user unit | `AGENTS.md:186-189`; `line/units/coq-hook-listener.service:16` |
| Quantities | SPEC-16 `w-size` (`:251`): tickets of five files and 300 lines | ROADMAP (`:121`): at most four in flight; AGENTS.md (`:145`): two reserved system slots | three numbers for the same limit |
| SPEC-17 version | file on main: 1.0.1 `proposed` (`SPEC-17:2`) | state-root side draft 1.1.0 (two loops, maintenance worker, controller model, systemd units, patrol), frozen out of PR 84 by card C27 | `20261013021301-spec17-1-1-0-draft-loops-maintenance-controller.md:3-4` |

### 5.5 Per-target breakage

#### specs/

- Nine pointer entries are phantoms: `specs/SPEC-00-index.xml:15` names SPEC-06 control plane, 07 SITREP, 08 player, 09 game adapters, 10 game hosts, 11 pane renderer and 11.B, 12 delivery, 13 testing, 14 skills.
  None exists in `specs/`; they are plain text so `lint.sh:12-26` (which only checks `<ref>`) cannot see them.
- SPEC-02 (roles and permissions) and SPEC-15 (SDLC end to end) are 12-line stubs whose three sections read "Draft. Filled by its ticket; pointers from other specs already resolve here" (`SPEC-02:9-11`, `SPEC-15:21-23`).
  SPEC-17 refs both (`SPEC-17:40,98,240-241`), so the SDLC DAG and the role contract are in SPEC-03 and `roles/schema/role.schema.json` instead.
- SPEC-01, 03, 04, 05 are `status="proposed"` (`SPEC-03:2`, `SPEC-04:2`) although they have driven the build for four days; SPEC-17 is also `proposed` while four of its tickets are merged.
  A status that never changes tells no agent what is in force.
- SPEC-04 s-monitors (event subscription, wake on status change) and s-leases (sweep) are the two ideas that would remove the polling in section 6; both are unbuilt (5.2).

#### factory/

- Route table and ledger are the strongest part, and also where the stalls were: 762 `route failed` notes for a nonexistent seat name (SPEC-17 H06, `SPEC-17:274`), 391 "route failed" notes from 2026-10-13T15:29Z to 2026-10-14T02:22Z (L01 section 4), because a failed route is never retried by the runner (issue 76: route.sh never retries a failed route) and a separate `route-retry.sh` polls every 30 s.
- `routes.json` has 31 rows but the roadmap-required invariant "every kind exactly one row, lint enforced" (ROADMAP rule 1) is not enforced (44aa `ready`), so each new kind is a possible 500.
- `factory/config/flow.json:21` still lists `merged 200` with `role: architect` as a gate, i.e. the stall watch encodes the architect-verifies design that the roadmap overturned.
- The runbook (`RUNBOOK.md:15-16`) and `route.sh` agree, but both rely on a poll (`poll_seconds` 10, `runner.json:3`) and a belt freshness window (`stale_seconds` 60, `runner.json:15`).

#### playbooks/ and roles/

- Playbooks describe the Opus-era design: `playbooks/architect.md:32` ("approval is yours alone") and `:36` ("verify every 201 from the reviewer ... before posting verified 201") make the architect a gate for ticket approval and verification, the exact pattern ROADMAP rule 4 and AGENTS.md:125 forbid; `routes.json:15` wakes the architect for the same step.
- `playbooks/merger.md:25` allows `gh pr merge --squash` and `slot.sh release` while the real merge is `line/bin/merge.sh`.
- `roles/orchestrator.json:29,34,45-51` and `playbooks/orchestrator.md:78-90` describe a read-only router that may run only `event.sh`, `graph.sh get|find` and `queue.sh`, while the live orchestrators (`sched-worker-1`, `sched-worker-2`) are worker-role seats running `seat.sh`, `gh`, `treehouse` by prompt (`merge-watch.sh:84`, `MERGE_WATCH_TO` default).
- The tester playbook (`playbooks/tester.md:13-45`) is 9 steps for a seat that polls a test pane with `herdr pane read`; the CI gate design (`ci-gate-design.md` Problem) records the cost: Haiku testers "polled, forgot, or waited on finished shells, with stalls of 9 to 14 minutes on a lint that takes one".
- 11 playbooks are machine-rendered but there is no playbook for the roles SPEC-17 and the line-ops design need (a start loop, a gate runner), because those are meant to be scripts.

#### docs/

- Total documentation volume is small relative to the code: 7 files under `docs/` (474 lines) against 26,592 lines of tracked `.sh`, `.go`, `.js`, `.mjs`, `.groovy` and `.py` files; the actual runbooks live next to the code (`factory/RUNBOOK.md` 400, `herdr/RUNBOOK.md` 135, `scheduler/RUNBOOK.md` 184, `ci/README.md` 202), outside the `docs/` router, so `docs/README.md` is not the entry point it claims to be.
- No SOP exists for the processes the incidents were about: restart after a halt (it is a state-root file, `20261012215500-line-restart-runbook.md`), merge hold, red main, or the CI gate ladder (`ci/README.md` only).
- `AGENTS.md:195-196` binds the herdr-first law to Drive documents "AGENT_CONTRACT_HERDR_FIRST_v1.1.0" and "SOP_HERDR_FIRST_v1.1.0"; the repo has no copy, so an agent cannot read the binding text from the checkout.

#### AGENTS.md

- It is 365 lines against its own "first 100 lines route" rule (`AGENTS.md:70-80`): the contents list takes lines 3-30, and the laws "herdr-first", "automation leads" and "Google Drive first" (`:184-218`) sit past line 100.
- Two laws contradict the build.
  "herdr-first, never background processes" (`:184-193`) versus systemd user units for the hook listener, forward and supervisor (`line/units/`, `herdr/systemd/`).
  "Google Drive first" (`:205-218`) says Drive is the source of truth for design and requires a Drive search before any design; the designs for this project are in the repo and the state root, not Drive.
  Drive searches by the Drive connector on 2026-10-14 returned 20 results for `coq-jev-herdr-plugin`, `route runner` or `small loop` (most recent 2026-09-24: "rime - REPLAN v1.0.0", "rime - F-FOUNDATIONS v1.0.0", numbered platform documents from 2026-09-16), and a second search restricted to `modifiedTime > 2026-10-01` returned 9 files, all dated 2026-10-06 and none a design of this factory.
  The law therefore adds a ritual with nowhere to land.
- The "Law: runtime data never lives in git" (`:111-123`) records its own violation: "Until roadmap items A, F and H land, bin/event.sh, make step and backlog.sh still write into the repository" (`:120`); A1 and A2 and H are `done`, F and A4 are `ready`, and the repo still tracks 179 event and 340 changelog files.
- The law "Hard rule: dated entry files" (`:82-109`) says `issues/` and `backlog/` "still write YYYY/MM/..." until WO-20261010-d354; `backlog/` is untracked in the working tree today (`git ls-files backlog` is empty, `git status` shows `?? backlog/`) because Roadmap H moved it to GitHub issues, so the paragraph is stale.

#### ROADMAP.md

- The work-item table (`ROADMAP.md:149-165`) lists A3 (WO-20261012-541a), D (WO-20261012-da1e), C (WO-20261012-e970) and I (WO-20261012-90ce) as live; all four are `cancelled` (closed 2026-10-13) and replaced by smaller tickets the roadmap does not name; K is described as "cut after the owner's card" and K2, K3, K4, K7 were cancelled and split.
  "Only the owner changes it" (`:21`) therefore freezes a stale table, and the architect's progress file (`plans/.../20261012212500-roadmap.md`) is where the truth lives, with 36 ticked and 23 unticked boxes (`grep -c '\[x\]'`, `grep -c '\[ \]'`).
- The rebuild plan landed on `origin/main` as `b7a3c5d` (#182) "stands beside" the roadmap (`20261014-factory-rebuild-plan.md:4`), which makes three plan documents (roadmap, line-ops design, rebuild plan) and one progress ledger.
- The roadmap itself says the big loop "has no design of its own yet" (`ROADMAP.md:230-231`); no design in the repo covers owner request to released change, i.e. the user-facing half of the north star.

#### COMPASS.md

- The file is the untouched scaffold template: `COMPASS.md:5` reads "One-line purpose: <what this project is, in a single sentence>.", the map rows at `:18-19` are `<path>` placeholders, and the commands at `:28-30` are `<command>`.
  It has one commit, `a5a5880` (2026-10-10T18:16Z, scaffold).
  `AGENTS.md:77` promises "COMPASS.md stays under 100 lines" and no file points an agent to it, so the router for the repo routes nowhere; AGENTS.md serves as the real router.

#### PR 35

- Open since 2026-10-12T18:28:25Z, last updated 2026-10-12T19:50:15Z, 14 files, +1,559/-0, no reviews, no comments, `mergeable` UNKNOWN; head `9b293ec` is 114 commits behind `origin/main` (`git rev-list --count $(git merge-base ...)..origin/main`; merge base `f7a891c`).
- It carries 25 `status="draft"` rules for behaviours it found diverged from design, and it records 5 divergences that the PR body calls out; ROADMAP C20 (`ROADMAP.md:67`) requires it to be revised to the locked decisions and published as v2.1 in phase 5.
- It also ships runtime data in the PR (a `CHANGELOG.md` change, six `changelog/` files and `events/2026/10/20261012T180251Z-100-ys9h7.json`), which AGENTS.md:111-123 now forbids, and it adds a second XML format (`<factory-spec>` with `<rule>` elements, `pr35.xml:2`) beside `specs/schema/spec.xsd`, checked by its own `export-check.sh` rather than the repo's spec lint, so the repo now has two spec formats and two checkers.
  Its S2-051 rule "Bus decided: NATS" contradicts C15.
- It is a snapshot of the 2026-10-12T19:46Z machine; the line changed in 114 commits since, so it describes roles and routes that no longer exist as written.

### 5.6 Where the brief's diagnosis is and is not supported by this area

The brief (section 1) quotes the owner: "we're using herdr wrong, we need a different system", and "no cog should hold up the system".

- Supported: agents hold up the system.
  The design documents themselves say so three times (ROADMAP "Why this roadmap exists" `:39-45`, SPEC-17 `s-inventory` H01 to H26, line-ops design `:22`), and the playbooks still make the architect a gate (`playbooks/architect.md:32,36`; `routes.json:15`).
- Not supported as stated: that the herdr integration is the root fault.
  The specs describe herdr correctly (labelled panes, headless scratch sessions `SPEC-04:68-71`, an event subscription that would remove the polling).
  The build ignored the design's use of herdr events and polls files instead.
  So herdr is used wrong in that the build never used its event stream, which is a build gap, not a design flaw.
- Partly supported: "we need a system, not agents".
  SPEC-16 (the Go scheduler) is exactly that design and the owner ruled it "the engine and the end state" on 2026-10-13T02:50Z (`SPEC-16:31`), but only the wave-0 skeleton (1,468 hand-written lines) exists, and the line meanwhile grew 12 `line/bin` bash scripts that SPEC-16 p-end calls interim.
  The rebuild has to choose between finishing SPEC-16 and a shelf tool; the evidence does not say SPEC-16 failed, it says it was starved: the 14 build tickets were cut then deferred (`SPEC-16:250`), and every system hour went to "Cause" tickets.
- Not supported: that there is no design.
  There is more design than build capacity: ten spec files, 109 graph nodes, 15 laws, a roadmap, a 26-row hand-fix inventory.
  The missing piece is that nothing turns the design into a dependency-ordered build that a machine executes; the architect did it by prompt (5.1, fact 3).

## 6. Waits, polls, sleeps and leases

Design-level and config-level waits seen from the design documents (L01 owns the full script walk).
Every row cites file and line; "seconds" are as configured on main `5ad1996`.

| Where | Wait | Bound | Evidence (file:line) |
| --- | --- | --- | --- |
| Route runner poll | files in the records tree | `poll_seconds` 10; `stale_seconds` 60 (belt age) | `factory/config/runner.json:3,15` |
| Flow watch poll | stall judgement | `poll_seconds` 15; `stall_seconds` 90; `busy_grace_seconds` 1800; `visible_within_seconds` 120 (poll plus stall must stay under it) | `factory/config/flow.json:3-6`; rule at `factory/bin/flow.sh:40` |
| Policy watch poll | standing-policy deadlines | `poll_seconds` 15; policy `deadline_seconds` 1800 (POL-blocked-land-it) | `factory/config/policies.json:4,14` |
| Turn watch | architect pane turns | `turn_poll_seconds` 15 | `herdr/config/herdr.json:54`, loop `herdr/bin/turnwatch.sh:27,49` |
| Record watch | records to the architect | `record_poll_seconds` 10 | `herdr/config/herdr.json:55`, loop `herdr/bin/recwatch.sh:33,54` |
| Patrol watch | compliance officer pane | `patrol_seconds` 60 | `herdr/config/herdr.json:69`, loop `herdr/bin/patrolwatch.sh:27,40` |
| Guard watch | claude session ids | `guard_watch_interval_seconds` 15 | `herdr/config/herdr.json:17`, `herdr/bin/guardwatch.sh:64` |
| Seat bring-up guard ACK | an ACK line no seat prints | `nudge_wait_seconds` 15 (cap 30; commit `3419b86` had fixed 180 s); `nudge_settle_seconds` 10 | `herdr/config/herdr.json:13-14`, `herdr/bin/seat.sh:734-784,832` |
| Session id wait | claude session file after bring-up | `session_wait_seconds` 10, 1 s sleeps | `herdr/config/herdr.json:15`, `herdr/bin/seat.sh:780-786` |
| Seat down wait | pane exit | `down_wait_seconds` 3; `down_kill_tries` 3; `down_kill_wait_seconds` 2 | `herdr/config/herdr.json:9-11`, `herdr/bin/seat.sh:370` |
| Retire poll | agent exit | `retire_poll_seconds` 10, 1 s sleeps | `herdr/config/herdr.json:12`, `herdr/bin/retire.sh:29,45` |
| Prompt wait | shell prompt | `prompt_timeout_ms` 15000; `agent_start_timeout_ms` 30000 | `herdr/config/herdr.json:7-8` |
| Belt settle | belt file after a start | `belt.settle_seconds` 20, 1 s sleeps | `herdr/config/herdr.json:39`, `herdr/bin/belt.sh:59` |
| Supervisor wait for herdr | workspace list | `supervisor.herdr_wait_seconds` 30, 1 s sleeps; patrol/step/kill timeouts 5 to 120 | `herdr/config/herdr.json:72-98`, `herdr/bin/supervisor.sh:83` |
| Monitor pane: event tail | file tail | `sleep 15` in the pane command | `herdr/config/monitors.json:42` |
| Monitor pane: queue list | queue list | `sleep 15` | `herdr/config/monitors.json:48` |
| Monitor pane: break glass sweep | `seat.sh --break-glass-sweep` | `sleep 15` | `herdr/config/monitors.json:77` |
| Monitor pane: supervisor log | log tail | `sleep 10` | `herdr/config/monitors.json:135` |
| Monitor pane: report loop age | `report/loop/loop.sh age` | `sleep 60` | `herdr/config/monitors.json:147` |
| Merge watch | PR state; prompt goes to `sched-worker-2` (`MERGE_WATCH_TO`) | `MERGE_WATCH_SECONDS` 60; 7-day backstop | `line/bin/merge-watch.sh:41,78,84,91` |
| Digest | architect digest | `DIGEST_SECONDS` 1800 | `line/bin/digest.sh:35,41` |
| Route retry | failed routes | `ROUTE_RETRY_SECONDS` 30 | `line/bin/route-retry.sh:55,88` |
| Record bus | slot-to-checkout record copy | `interval` 5, `window` 60 | `line/bin/record-bus.sh:53,107` |
| Seat queue | branch on origin; free worker slot | `SEAT_QUEUE_BRANCH_WAIT` 15; `SEAT_QUEUE_SLOT_WAIT` 60; unbounded `until` loops | `line/bin/seat-queue.sh:25,28-29` |
| Merge script backoff | gh/git retry | 3 tries, `MERGE_BACKOFF_SECONDS` 2 times attempt | `line/bin/merge.sh:80,107` |
| Verify script backoff and suite | io retry; suite budget | 3 tries, backoff 2; `VERIFY_SUITE_TIMEOUT` 1800 | `line/bin/verify-main.sh:51,85` |
| Webhook listener restart | listener supervision | `retry_seconds` 1, `restart_limit` 3, `handler_timeout_seconds` 300 | `line/config/hook.json:22-25`, `line/bin/hook-listener.sh:56,74` |
| Hook fallback | gate status | merge-watch tick, at most one minute | `$PLANS/20261013194800-ci-gate-design.md:148` |
| CI ladder | infrastructure retries | retry after 10, 30, 90 s; one clean re-run after 5 min; Jenkins timeout 90 min | `ci/README.md:154-156`, `Jenkinsfile:30` |
| Id mint lock | `bin/mint-id.sh` mkdir lock | 10 x 1 s, then die 4 | `bin/mint-id.sh:28` |
| Board lease | an item pulled | `lease_seconds` 1800 | `line/config/board.json:13` |
| Board nudge and digest | idle seat; architect digest lane | `nudge_seconds` 60; `digest_seconds` 1800 | `line/config/board.json:14-15`, `line/bin/board.sh:190` |
| Slot lease | treehouse slot | 14400 s | `herdr/config/leases.json:6` |
| Tier lease | uat server | 86400 s | `herdr/config/leases.json:12` |
| Ticket lease (herdr) | ticket held by a seat | 7200 s | `herdr/config/leases.json:18` |
| Seat lease | seat alive | 900 s | `herdr/config/leases.json:24` |
| Ticket lease (queue) | queue dequeue | `lease_ttl_seconds` 7200; `renew_grace_seconds` 300 | `queue/config/queue.json:6-7` |

Count of `sleep` occurrences, by directory, with the exact commands (run in the main checkout on 2026-10-14):

- Every line mentioning `sleep`, comments included: `grep -h sleep herdr/bin/* | wc -l` is 18, `grep -h sleep line/bin/* | wc -l` is 17, `grep -h sleep factory/bin/* | wc -l` is 3, `grep -h sleep bin/* | wc -l` is 1, `queue/bin/*` 0, `scheduler` 0.
- Executable lines only (comment lines removed with `grep -vE '^[[:space:]]*#'`): `herdr/bin` 14, `line/bin` 12, `factory/bin` 0, `bin` 1 (`bin/mint-id.sh:28`), `queue/bin` 0.
- Attempt 1 said `line/bin` 16 (undercount; the correct all-lines figure is 17, executable 12).
  The three `factory/bin` matches are comments (`factory/bin/flow.sh:162`, `policy.sh:182`, `route.sh:339`) that say the runners use `read -t` so a TERM trap fires at once, so `factory/bin` runs its waits without `sleep`.
- Executable `line/bin` sleeps: `digest.sh:41`, `hook-listener.sh:74`, `merge-watch.sh:78,91`, `merge.sh:107,255,256`, `record-bus.sh:107`, `seat-queue.sh:28,29`, `route-retry.sh:88`, `verify-main.sh:85`.
- Executable `herdr/bin` sleeps: `belt.sh:59`, `supervisor.sh:83`, `guardwatch.sh:64`, `turnwatch.sh:49`, `patrolwatch.sh:40`, `recwatch.sh:54`, `seat.sh:370,784,832`, `unfreeze.sh:94`, `retire.sh:29,45`, `seat-lib.sh:307,311`.

Design versus build: SPEC-03 and SPEC-04 say seats are woken, not polling, and the monitor subscribes to herdr events (`specs/SPEC-04-herdr-seat-lifecycle.xml:45` for the subscription, `:80` and `specs/SPEC-03-dag-and-node-contract.xml:76` for the NEVER examples "a seat that polls" and "a seat waiting in a sleep loop"); the build polls files every 10 to 15 seconds and no herdr event subscription exists (`grep -rn subscribe herdr/bin factory/bin line/bin` returns nothing).
The CI gate design (20:07Z amendment, `$PLANS/20261013194800-ci-gate-design.md:128-131`, owner: "hooks and ladder son, come the fuck on") is the first design that was built event-driven (webhook listener); the rest of the line is not.
Leases are specified with a monitor that "releases an expired one and wakes the queue" (`herdr/config/leases.json:3`), but the SPEC-17 `board.sh sweep` is the only expiry sweep in the repo and nothing calls it (see 5.2, row "Expired leases").

## 7. Decisions an LLM makes that a rule could make

Decisions the design documents say a rule should make but which are still made by an agent on main.
L13 owns the full list; these are the ones L03 can prove from design versus build.
"Status" is on main `5ad1996`.

| Decision | Where an LLM makes it (file:line) | Rule that replaces it (file:line or ticket) | Status |
| --- | --- | --- | --- |
| Verify main after a merge | two paths wake an LLM: the table wakes the architect (`factory/config/routes.json:15`; `playbooks/architect.md:36`), and the merge watch prompts the acting orchestrator `sched-worker-2` (`line/bin/merge-watch.sh:84`) | `line/bin/verify-main.sh` (exists, commit `9b3d105`); CI gate 4 on main push, WO-20261013-aff2 - CI gate 4: a green coq/gate status on main posts verified for every merge since the last ... (`ready`; line-ops design `$PLANS/20261014004500-line-ops-are-code-design.md:37`) | Code exists, both wakes still fire |
| Merge when gate and review pass | the merger seat: `factory/config/routes.json:12` seats a merger on `review.passed`, `playbooks/merger.md:25` lets it run `gh pr merge --squash` | route action `run` calling `line/bin/merge.sh` (WO-20261014-d93a - R1 - routes.json run action ...); `line/bin/merge.sh` exists | `merge.sh` built, route not switched |
| Test a PR | the tester seat: `factory/config/routes.json:8` (`pr.opened` seats a tester), `:9-11` | `coqGate()` pods and `coq/gate` (`Jenkinsfile:12-21`, commit `2247679`); tester retirement WO-20261013-3eac - CI gate 5: pr.opened routes to the reviewer only ... | Gate built; route and role not changed |
| Seat down after a result | patrol plus orchestrator: `herdr/bin/patrolwatch.sh:27-40` (60 s poll of the compliance officer) and prompt-driven downs | route `down:` key, already executed by `factory/bin/route.sh:238-246` and on rows `routes.json:9-16`; enforcement WO-20261014-7f99 - R2 - Result records down their own seat through the route down key and patrol reports su... | Mostly built; R2 not built |
| Start the next ready ticket | orchestrator by prompt: `line/bin/start-tickets.sh:1-5` takes ids as arguments and an orchestrator chooses them (line-ops design `:21`) | `start-loop.sh` (WO-20261014-3dae - R3 - start-loop.sh with its systemd user unit starts the next ready ticket ...) over `bin/wo-start.sh` and `factory/bin/claims.sh` | Not built |
| Refused seat re-route, capacity down-order | orchestrator by hand: SPEC-17 O1 `SPEC-17:86`, 429 code `SPEC-17:258`, `line/bin/seat-queue.sh:28-29` loops unbounded | SPEC-17 check C4 `SPEC-17:107` (K2, cancelled; no replacement script) | Not built |
| Clean up after a merge | orchestrator by hand: prompt text at `line/bin/merge-watch.sh:84` ("do the post-merge cleanup") | `line/bin/after-merge.sh` (WO-20261013-48f2 - Post-merge cleanup is code: line/bin/after-merge.sh ..., WO-20261013-612d - Route row: merged 200 runs line/bin/after-merge.sh ...); `merge.sh` does part (commit `17df7c9`, 2026-10-14T01:20Z) | Part built |
| Rule on a block | architect: `playbooks/architect.md:35,57` (read the evidence record, split or re-scope, 423 on third failure) | standing policies `factory/config/policies.json:1-30` (POL-blocked-land-it, 1800 s deadline) and `factory/bin/policy.sh:182` | Built for defaults; design questions still go to the architect |
| Approve a ticket | architect: `playbooks/architect.md:32` | claims plus lint gate (`factory/bin/claims.sh`; `line/bin/gate-tickets.sh`, WO-20261013-4dc2 - Cause r: a tickets-only pull request is gated by a script, not a tester seat ...) | `gate-tickets.sh` not built (`ls line/bin`); approval remains an agent step |
| Decide "idle or stuck" | orchestrator reading panes (SPEC-17 C2 `SPEC-17:105`; H16 and H22 at `:284,290`) | the flow watch already judges a gate stall by rule from `herdr agent get` agent_status (`factory/bin/flow.sh:11,32-40`, `factory/config/flow.json:4-5`) and `turnwatch.sh` | Probe and stall note exist; the repair decision is still an agent |
| Pick the seat that owns a ticket | architect forwarding (762 route failures, SPEC-17 H06 `SPEC-17:274`) | owner seat from the ticket (rule 2, `ROADMAP.md:108`); WO-20261013-9b21 - Cause aa: route.sh derives the ticket from the PR head branch ... (`done`) | Built; worker lane via board not |

## 8. What to carry forward

- The SPEC-03 node contract: schema in, schema out, three attempts, black-box seat, one record crosses the boundary, routing by table only.
  Reason: it is the common abstraction behind Argo-style steps and the field's seat contracts, and it is already implemented in `route.sh` and `event.sh`.
- `factory/config/routes.json` as the one table, with the `when`, `down`, `supersede` and `ignore` fields, and the rule "every kind exactly one row" (WO-20261013-44aa - Routes lint ...).
- The SPEC-17 board design (lanes, lease by rename, pull, done tree, digest, health line).
  `line/bin/board.sh` is a working file-based durable queue with tests; whether it stays bash or becomes a managed queue is a decision for the shelf track, but the contract (post, pull, lease, sweep, done) is the right one.
- The SPEC-17 `s-inventory` H01 to H26 (`SPEC-17:267-292`) as the acceptance list for any rebuild: each hand fix of 2026-10-12 with the system that replaces it.
- SPEC-17 `s-bringup` (`SPEC-17:161`, B1 to B10 with a checklist per node) and `s-codes` (`:246`), and the one-input-one-output node rule from the owner (2026-10-13 02:02Z).
- The status-code map and the HTTP-shaped codes (`graph/nodes/STC-http-shaped.json`), which have survived every iteration (also in rime).
- Breadcrumb comments at the fix site; they are the best record of why the code is shaped as it is.
- The CI gate design: Jenkins in the cluster, `coqGate()`, GHCR test image, webhook forward listener, the "ladder" (three infra retries, one clean rerun, then a page; `ci/README.md:154-156`).
  It is the only part of the line designed event-driven and built as designed within hours.
- The roadmap's nine "agents are never gates" rules and the guardrails (`ROADMAP.md:105-115`: no records branch, at most four tickets in flight, files declared at cut).
- `$PLANS/20261014004500-line-ops-are-code-design.md` (the rule "an agent exists only for judgement", line 24 onward) as the governing sentence of the rebuild.

## 9. What to kill

- Parallel descriptions of the same machine: PR 35 `factory-spec.xml` (114 commits behind `origin/main`), the SPEC-17 1.1.0 side draft, the line-ops-are-code design and the CI gate design where they overlap SPEC-17 and `routes.json` (section 5.4).
  Reason: they already disagree on who verifies main, whether tester and merger seats exist, and what the engine is; the rebuild needs one.
  Correction to attempt 2: `$PLANS/20261012212500-roadmap.md` is a progress ledger (its line 3 says "This file tracks progress only"), not a competing roadmap, so it is not listed here.
- The stub specs SPEC-02, SPEC-15 and the nine phantom entries SPEC-06..14 in `specs/SPEC-00-index.xml:15`, until a real spec exists.
  Reason: pointers that resolve to "Draft. Filled by its ticket" send agents to empty anchors.
- The `COMPASS.md` template, or fill it; as is it is a router that routes nowhere.
- The "Google Drive first" law (`AGENTS.md:205-218`) as written: no design of this factory is on Drive (Drive searches on 2026-10-14, section 5.5, AGENTS.md), and the law makes every design a search-first ritual with nowhere to land.
- The herdr-first "everything in a pane" law as the only supervision model (`AGENTS.md:184-196`) in favour of units supervised by the machine; the herdr dependency should be on seats only.
- Monitor panes that run `while :; do ...; sleep N; done` as the monitoring layer (`herdr/config/monitors.json:42,48,77,135,147`).
- Roles that do not match reality: `roles/orchestrator.json:29,34,45-51` ("read-only gate that routes records") and the architect playbook steps 2 and 6 (`playbooks/architect.md:32,36`).
- The "Cause <letter>" ticket cadence as a process: 35 tickets patch bash glue the owner has already ruled interim (SPEC-16 `p-end`).
- Locked graph nodes that are dead: `graph/nodes/DEC-nats-jetstream-grpc.json` (dropped, C15), `ROL-orchestrator`, `ROL-monitor`, the `REQ-event-log` "git-tracked" wording, and the cancelled-ticket residue in `work-orders/archive`.

## 10. Open questions for the owner

1. Which description of the factory is canonical for the rebuild: SPEC-17 1.0.1 as merged, the 1.1.0 side draft, PR 35 v2.0.0, or none of them and a new design from the shelf track?
   This changes whether the eight unmerged SPEC-17 1.1.0 tickets and PR 35 are landed, superseded or closed.
2. Is the Go scheduler (SPEC-16, "the engine and the end state") still the target, or does a managed workflow engine (Argo or similar from the shelf track) replace it?
   Only 3,804 lines of scaffold exist; the choice decides whether the domain tickets are cut again.
3. Do the tester and merger seats stay (locked C12, `ROADMAP.md:59`) or retire (CI gate and line-ops designs)?
   The architect's later rulings retired them without a card; the locked decision says otherwise.
4. Is "everything runs in a herdr pane" (`AGENTS.md:184`) still law for system processes, or only for agent seats?
   It decides whether systemd units for the listener, the start loop and the supervisor are legal.

## 11. Sources

Repository (main checkout, read-only, 2026-10-14; line numbers cited inline; every named target `specs/`, `factory/`, `docs/`, `playbooks/`, `roles/`, `ROADMAP.md`, `COMPASS.md`, `AGENTS.md` and PR 35 was opened):

- `AGENTS.md`, `ROADMAP.md`, `COMPASS.md`, `CLAUDE.md`, `docs/README.md`, `docs/sops/`.
- `specs/SPEC-00-index.xml`, `SPEC-01-conventions.xml`, `SPEC-02-roles-and-permissions.xml`, `SPEC-03-dag-and-node-contract.xml`, `SPEC-04-herdr-seat-lifecycle.xml`, `SPEC-05-compaction-and-checkpoint.xml`, `SPEC-15-sdlc-end-to-end.xml`, `SPEC-17-orchestrator-and-agent-health.xml`, `specs/scheduler/SPEC-16-scheduler-overview.xml`, `SPEC-16.G-config-schema.xml`.
- `factory/config/routes.json`, `flow.json`, `runner.json`, `policies.json`, `factory/bin/route.sh`, `flow.sh`, `policy.sh`.
- `herdr/config/herdr.json`, `leases.json`, `monitors.json`, `herdr/bin/*` (seat.sh, retire.sh, belt.sh, supervisor.sh, guardwatch.sh, turnwatch.sh, recwatch.sh, patrolwatch.sh, seat-lib.sh, unfreeze.sh), `herdr/systemd/`.
- `line/bin/*` (board.sh, merge-watch.sh, digest.sh, route-retry.sh, record-bus.sh, seat-queue.sh, start-tickets.sh, merge.sh, verify-main.sh, hook-listener.sh), `line/config/board.json`, `hook.json`, `line/units/`, `line/Makefile`, `queue/config/queue.json`, `bin/mint-id.sh`, `Jenkinsfile`, `ci/README.md`.
- `roles/orchestrator.json`, `playbooks/architect.md`, `playbooks/merger.md`, `playbooks/orchestrator.md`, `graph/nodes/*.json` (109 nodes; DEC-nats-jetstream-grpc, ROL-orchestrator, ROL-monitor, REQ-event-log, STC-http-shaped).
- `work-orders/**/WO-*.md` frontmatter (263 files), `work-orders/archive`.
- `scheduler/` Go sources (`find scheduler -name '*.go' | xargs cat | wc -l` = 3,804).
- PR 35: `https://github.com/jkkelley/coq-jev-herdr-plugin/pull/35`, `gh pr view 35 --json number,title,state,headRefName,createdAt,updatedAt,additions,deletions,changedFiles,files,commits,reviews,comments,body` run 2026-10-14T02:53Z (state OPEN, created 2026-10-12T18:28:25Z, updated 2026-10-12T19:50:15Z, 14 files, +1,559/-0, 0 reviews, 0 comments), and `git show origin/feat/factory-design-spec-v2-0-every-agent-workflow-ru:specs/exports/factory-spec.xml` (head `9b293ec`, merge base `f7a891c`, 114 commits behind `origin/main` `b7a3c5d`).
- `origin/main` `b7a3c5d` (2026-10-13T21:49-05:00, #182 Factory Rebuild Plan): `git show --stat origin/main`, `git show origin/main:rebuild/README.md`.
- Ticket frontmatter scan of 263 `work-orders/**/WO-*.md` files (115 ready, 97 done, 27 cancelled, 23 draft, 1 in-progress; 33 titled Cause <letter>) for the statuses quoted in sections 4 and 5.
- One `git fetch -q` was run at about 02:52Z; it updated remote-tracking refs only (no checkout, branch switch or commit in the main checkout).

Git history (all times UTC, `TZ=UTC git show -s`):

- `5ad1996` 2026-10-14T01:44Z WO-20261013-0b48 pod fix (local main).
- `ae0140e` 2026-10-14T01:59Z WO-20261014-539a cause ay fix (`origin/main`).
- `c9b6f9f` 2026-10-14T01:43Z WO-20261014-539a cut cause ay.
- `17df7c9` 2026-10-14T01:20Z cause ag, merge.sh post-merge cleanup.
- `2247679` 2026-10-14T01:18Z CI gate 2, coqGate().
- `3419b86` 2026-10-14T01:13Z belt frozen 180 s per seat bring-up.
- `3584b1e` 2026-10-14T01:07Z CI gate 6, webhook listener.
- `db1a95c` 2026-10-14T00:14Z CI gate 1, test image in GHCR.
- `e5cef84` 2026-10-13T13:59Z K1 board.
- `32fc429` 2026-10-13T13:59Z and `7e114c9` 2026-10-13T22:51Z K5 writer refuses gate record without sha.
- `c41afda` 2026-10-13T14:16Z K6 owner lane.
- `3878c97` 2026-10-13T15:29Z K8 factory board live line.
- `d3e5c6a` 2026-10-13T02:56Z K design, SPEC-17.
- `3643adf` 2026-10-13T02:56Z K1 to K8 cut, C and D cancelled.
- `80c889d` 2026-10-13T13:38Z A2 belt reads the state root.
- `6cf841b` 2026-10-13T01:26Z A1 state root.
- `af01719` 2026-10-12T21:51Z north star roadmap.
- `352821e` 2026-10-12T19:06Z and `9b293ec` 2026-10-12T19:50Z PR 35 branch.
- `9b3d105` 2026-10-13T20:21Z verify is code.
- `a5a5880` 2026-10-10T18:16Z scaffold (COMPASS).
- `fba7551` 2026-10-13T20:02Z cause m, routes ignore rows.
- `d80b49b` 2026-10-13T17:19Z case-28 role-cap test.
- Roadmap I script moves: `d086868` aq 2026-10-13T20:21Z, `8b1b6cf` digest 19:46Z, `104658b` record-bus 20:02Z, `1b58d05` merge-watch 20:21Z, `83ced7b` route-retry 20:22Z, `1ef911b` seat-queue 21:02Z, `37f57e0` flow-table 21:02Z, `f31bf7d` start-tickets 21:52Z.
- Roadmap A3 role readers: `3a0c4f5` 2026-10-13T17:42Z, `29c1b34` 17:42Z, `bab41da` 22:31Z.
- Merged but ticket still `ready`: `96fc609` 2026-10-13T23:26Z (WO-20261013-0ad7), `0435ea5` 22:56Z (WO-20261013-d182), `a6f3a25` 22:20Z (WO-20261013-e2c3).

State root (outside git):

- Also read for this attempt: `20261013-duplicate-work-audit.md` (lines 28-30, 145, 172, 196, 217), `20261013235500-duplicate-audit-rulings.md`, `20261014-factory-rebuild-plan.md`, `20261012222000-retro-architect-flood-and-halt.md:1-30`, `20261012212500-roadmap.md` lines 378, 389, 396-400, cards `20261013004357-card-c25...json`, `20261013011800-card-c26...json`, `20261013020600-card-c27...json`.

- `$PLANS/20261012212500-roadmap.md` (line 13 USERHALT), `20261012222000-retro-architect-flood-and-halt.md`, `20261013021301-spec17-1-1-0-draft-loops-maintenance-controller.{md,xml}`, `20261013194800-ci-gate-design.md` (lines 128-147), `20261014004500-line-ops-are-code-design.md` (lines 17-41, 87-89), `20261013025600-priority-list.md`, cards `20261013004357-card-c25...json`, `20261013011800-card-c26...json`, `20261013020600-card-c27...json`.

Web and Drive (Google Drive connector `search_files`, 2026-10-14; Drive has no public URL for a search, so the query strings are the record):

- Query A (2026-10-14, earlier in the investigation): `fullText contains 'herdr' or fullText contains 'software factory'` - 20 results dated 2026-09-12 to 2026-09-24, e.g. `https://docs.google.com/document/d/1qNdzEjlFtUpxw-wZ7viONpuJvrd9hFZVl5pWxHZjprY` (STANDARD_HERDR_FIRST_v1.1.0, 2026-09-19).
- Query B: `(fullText contains 'herdr' or fullText contains 'software factory') and modifiedTime > '2026-10-01T00:00:00Z'` - 9 results, all 2026-10-06, e.g. folder `https://drive.google.com/drive/folders/1MK00ifOwLoJVXDpS00zixuS0ZULA51gn` and `https://drive.google.com/file/d/1Y8yWLKev5iQcV7-iOodjM7UwZhVTvR3F/view`; none is a coq factory design.
- Query C (2026-10-14, this attempt): `fullText contains 'coq-jev-herdr-plugin' or fullText contains 'route runner' or fullText contains 'small loop'` - 20 results (first page), newest 2026-09-24 (`https://docs.google.com/document/d/1b4Cyd_KO70HtEFbW9Mw0HQB2CLmHoAB80LWilnYU-zs` "rime - REPLAN v1.0.0", `https://docs.google.com/document/d/1PxvlJDo9LFTelSPE3mKuo0QnJ4RfGSdys49CNR8WwTs` "rime - F-FOUNDATIONS v1.0.0"), oldest 2026-09-12; titles are rime documents and numbered platform documents, none dated October 2026 and none about this repository's factory.
