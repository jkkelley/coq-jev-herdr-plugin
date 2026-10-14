# L09 - Earlier factory iterations

Investigator: L09 (Factory Rebuild, step R-01).
Written 2026-10-14 UTC, revised the same day (attempt 2) to close six critic gaps.
Read-only on every repo, directory and page.
Clones of GitHub repos are under `/home/luna/.local/state/coq/coq-jev-herdr-plugin/rebuild/2026/10/investigation/clones/`.

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

The owner has built the same factory at least eight times in about three months, and each iteration stopped for a reason that the next one then repeated in a new form.
The order is firstmate (July to August 2026), generic-agents-auto-workflow (4 to 9 September), stable (9 to 16 September), compaction-guard (19 to 20 September), bearings-core (20 September), rime and rime-bootstrap (20 September to 6 October), software-factory (7 October, a captured design with no runtime), and the current coq-jev-herdr-plugin line (from 10 October).
Three of them (stable v3, bearings-core, rime) are the same idea: one Go core on the cluster that is the only writer of task state, with agents proposing transitions by status code.
The scheduler in coq (`specs/scheduler`, SPEC-16) is the fourth statement of that idea.
`jkkelley/software-factory` is a v0.1 design capture: about 1,000 lines of Markdown, one JSON schema, two YAML profiles, one validator, no executor, no queue, no state store, no trigger.
It is a good contract and vocabulary, and it is not a base that runs.
`jkkelley/rime` plus `jkkelley/rime-bootstrap` is the iteration with the most evidence: a 790-minute ledgered first night, a blameless investigation, a 112 KB re-plan, and 32 loop-fix tickets merged against 17 product tickets.
The evidence also shows that this loop had turned the corner when the owner halted it: 10 product tickets merged in 10 hours 57 minutes ending 2026-10-06T11:48:20Z (section 4.3).
`jkkelley/astro-template-factory` is a different kind of factory (a build service that makes client websites), and it is the one place the owner already runs one-shot Kubernetes Jobs that call a model.
`~/projects/control-tower` is not an iteration: it holds only a vendored copy of four skills.

## 3. Where it lives

- software-factory: GitHub `jkkelley/software-factory`, public, created 2026-10-08T03:59:19Z, default branch `claude/new-session-z3nzz0`, also `main` and `feat/initial-capture`, 6 commits, 0 PRs, 0 issues. Clone: `clones/software-factory`.
- rime: GitHub `jkkelley/rime`, private, 20 commits on main, 13 unmerged ticket branches (`a-02/*`, `a-04/*`, `a-05/*`, `a-07/*`, `a-14/*`, `a-16/*`, `a-18/*`, `a-19/*`, `b-01/*`, `b-02/*`, `c-05/*`, `c-06/*`, `gate/*`). Clone: `clones/rime`. Local checkout `~/projects/rime` is at the old commit `d55391b` (2026-09-21), 13 commits behind origin.
- rime-bootstrap: GitHub `jkkelley/rime-bootstrap`, private, 120 commits on main, 97 remote branches (mostly `docs/*` and `fix/*` ticket branches). Clone: `clones/rime-bootstrap`. The live copy is `~/tools/bearings-v2` (same history, HEAD `9a21ea0`, one untracked `HYDRATION.md`).
- rime runtime state: `~/.local/state/rime/` (`watch.log` 197 KB, `seats.log`, `sessions/` with 105 ticket dirs, `execution/EXECUTION-LEDGER.tsv` 520 rows, `PAUSED` dated 2026-10-06T11:41:11Z).
- owner's investigation of rime: `~/Documents/investigations/bearings-v2-investigations/` (findings F-*.md, README dated 2026-09-21).
- astro-template-factory: GitHub `jkkelley/astro-template-factory`, private, 57 commits, last 2026-07-23, 9 unmerged `fm/*` and `feat/*` branches. Clone: `clones/astro-template-factory`.
- compaction-guard: `~/projects/compaction-guard`, git, 23 commits, 2026-09-19 to 2026-09-20, version 1.2.8. Live release at `~/.local/state/compaction-guard/releases/1.2.8-5203f8b5/`, symlink `~/.local/bin/compaction-guard`.
- control-tower: `~/projects/control-tower`, not a git repo, only `.claude/skills/{work-order,context-compaction,project-scaffold,container-sandbox}`, dated 2026-08-17.
- firstmate: `~/projects/firstmate`, fork of the upstream tool, 433 commits, last local commit 2026-08-17 ("pulled from upstream firstmate"). Reference only.
- Further iterations found by following the trail (not named in the brief): `jkkelley/stable` (200 commits, 2026-09-09 to 2026-09-16), `jkkelley/generic-agents-auto-workflow` (838 commits, 2026-09-04 to 2026-09-09) and its `-state` repo (25 commits), `jkkelley/bearings-core` (3 commits, 2026-09-20), `jkkelley/cortex-hub` (3 commits, 2026-05-19). All cloned under `clones/`.

## 4. What works

### 4.1 software-factory v0.1

- The repo validates. `python3 -I scripts/validate.py` printed `PASS: schema, examples, invalid cases, contents lists, profiles` on 2026-10-14 (`scripts/validate.py:63`, the final print).
- The node list is the SDLC order Intake, Design, Implementation, Test, Review, Integration, Deploy, Archive (`docs/02-pipeline.md:13`, `schemas/handoff.schema.json:22`).
- Black-box nodes with no agent chat (`AGENTS.md:35-37`, `docs/01-principles.md:12-15`). This is the same rule rime reached as "agents never write prose to each other" (`rime-bootstrap/streams/INDEX.md`, section Agent-to-agent traffic).
- A closed six-value status vocabulary (`schemas/handoff.schema.json:25-27`) and conditional evidence rules.
- FAILED, BLOCKED and ESCALATED require an `evidence` object (the if/then at `schemas/handoff.schema.json:70-73`).
- The five sub-fields `reason_code`, `command`, `observed`, `expected` and `reproduce` are defined and required at `schemas/handoff.schema.json:40-49`; `reproduce` must be a non-empty array (line 49) and `observed` and `expected` must be non-empty strings (lines 47-48).
- BLOCKED additionally requires `blocked_on` (lines 74-76) and ESCALATED requires `attempt` equal to 3 plus `prior_attempts` (lines 77-82).
- The prose version is `docs/03-handoff-contract.md:44-55`. The two files in `tests/invalid/` prove the schema rejects FAILED without evidence and ESCALATED at attempt 2.
- Three attempts per node, budget per node and not per item (`docs/04-retries-and-escalation.md:11-13`), `attempt` bounded 1 to 3 in the schema (`schemas/handoff.schema.json:24`).
- One merge owner, serialized, oldest ready first, rebase then full suite then profile gate then merge (`docs/06-git-and-integration.md:41-50`; the ordering rule is line 41). The stated problem it solves is the one the owner keeps hitting: many PRs, nobody merges (`docs/06-git-and-integration.md:14-16`).
- Two profiles that change policy only, never the pipeline (`docs/07-profiles.md:12-14`, `profiles/home-lab.yaml`, `profiles/company.yaml`). Profile keys are validated, and `retry_budget_per_node` must be 3 (`scripts/validate.py:52-56`; the required key set is `scripts/validate.py:25`).
- Degree of freedom low, medium, high on each task (`docs/05-degree-of-freedom.md:16-20`). The coq line already uses the phrase in its work orders (grep of `work-orders/archive/2026/WO-20261013-dec6-*.md`).
- Documents are small, numbered, lead with a contents list, and the contents rule is enforced by the validator (`scripts/validate.py:43-46`, `HEAD_LINES = 100` at line 23).

### 4.2 rime (Go core)

- The transition table with ordered gates, strike count and supersede routing has a rule-coverage test that "can fail" (commit `994a614`, 2026-10-06, `internal/transition/transition.go` 297 lines, `transition_test.go` 1,009 lines, `testdata/mutants.sh`).
- SQLite store with idempotency and outbox retry (`internal/store/store.go` 533 lines, `store_test.go` 612 lines, commit `22646ef`).
- Redis Streams Watch with cursor entry ids, trim detection, drop-on-full (`internal/stream/redis.go` 276 lines, `redis_test.go` 470 lines, commit `894b4f4`).
- Contract `rime.v1` with HTTP-shaped status codes 100, 101, 200, 201, 300, 400, 401, 404, 409, 412, 422, 423, 429, 500 (`rime-bootstrap/CORE-DESIGN.md:56-73`, commit `38adb4a`). Total Go: about 1,182 non-test lines and 2,091 test lines.
- A failure-mode catalogue F-01 to F-20, each with detection, automatic recovery, runbook and the ticket that proves it (`rime/docs/FAILURE-MODES.md`).
- The codes and the seat primitive survived into coq. `events/schema/event.schema.json:12` lists 100, 200, 201, 204, 300, 400, 409, 412, 422, 423, 429, 500, 503, and `herdr/bin/seat.sh:24` says "ported from ~/tools/bearings-v2/bin/seat.sh (644 lines, proven on the rime fleet)".
- Streams by layer with disjoint write sets (`rime/docs/ADR/0004-streams-not-epics.md`). The owner's retro then shows disjoint write sets did not give disjoint order (`F-planning.md:16`, F-PL5).
- The owner's blameless investigation of the first night is the best single document on why a factory stalls (`~/Documents/investigations/bearings-v2-investigations/findings/F-bottleneck.md`, `F-planning.md`, `F-process.md`, `F-supervision.md`, `F-recommendations.md`).

### 4.3 rime-bootstrap loop

- When a ticket was buildable, the loop was fast: four C tickets merged in 32 minutes, 03:22Z to 03:54Z on 2026-09-21 (`F-bottleneck.md:9`, "Four C tickets merged in 32 minutes, 03:22Z to 03:54Z"). C-02, C-03 and C-04 merged in 5, 19 and 6 minutes (`F-planning.md:10`, F-PL2; per-ticket minutes in the `F-bottleneck.md` table, "C-02 5, C-03 19, C-04 6").
- After the re-plan the loop produced.
  The rime `origin/main` log shows 10 product tickets merged between 2026-10-06T00:51:33Z (`d1021d5`, A-11) and 2026-10-06T11:48:20Z (`994a614`, A-19), which is 10 hours 57 minutes (`git log origin/main --format='%cI %h %s'` in `clones/rime`, counted 2026-10-14; commit times there are -05:00 and are converted here).
  Nine of the ten landed before the owner's halt order at 11:40:35Z, the last (A-19) was merged under the halt order at 11:48:22Z (ledger row 507).
  The night-one rate was 6 merges in 424 minutes (`F-bottleneck.md:8`).
  The settings behind it were `max_in_flight: 2` (`config/loop.json`, F-40) and the loop decision table below.
- The loop decision table moved the loop's routes out of bash conditions into one JSON file with a schema, an evaluator, a lint that every code has a row, and a loud 500 default (`bin/loop-rules.json`, 31 rules, schema `streams/schema/loop-rules.schema.json`, commits `0335d9b` and `9467fed`, 2026-09-24).
- `bin/seat.sh` with two doors (ticket and role), `--check` and `--down`, plus role files with a compaction block (commits `720f417`, `cfac68e`). Carried to coq.
- A dev harness with stubs for herdr, gh and no-mistakes ran 38 test cases offline in Podman (`tests/cases/`, `tests/run.sh`, REPLAN.md RP-06: exit 0, 5/5 cases at the time, 24 to 25 seconds).
- The execution ledger is append-only and was written by a script (`bin/ledger.sh`, `execution/EXECUTION-LEDGER.tsv`, 520 rows). It is the reason this investigation can reconstruct the run minute by minute.

### 4.4 compaction-guard

- It is the only earlier piece still live in the current line. `~/projects/coq-jev-herdr-plugin/.claude/settings.json:13,35,47` call `/home/luna/.local/bin/compaction-guard hook`, and `~/.local/state/compaction-guard/events.jsonl` has a `session_start` for this very session at 2026-10-14T02:05:48Z. 6,338 event lines and 815 session dirs exist.
- Immutable releases: bytes that pass a Podman suite are recorded by sha256 and `promote` refuses any other bytes (`README.md` Release discipline, `tests/run.sh`). Eleven releases are present (`1.0.1-restored` to `1.2.8`).
- Status codes in families with a "who acts" column (`docs/status-codes.md:9-17`).
- Freeze as a lease with expiry, not a flag (version 1.2.8, `docs/evidence/2026-09-20-freeze-lease.md`, code CMP-350).
- Break glass with no test gate on purpose (`README.md`: "`compaction-guard rollback` ... is the break-glass path and has no test gate on purpose").

### 4.5 astro-template-factory

- It is a working "one Job per unit of work" factory on the owner's cluster. The build is a one-shot Kubernetes Job created by n8n after infra-complete, with a 9-field env contract (`README.md`, section Per-Client Build Trigger).
- `build.mjs` is the sole entrypoint and any failure fires a callback with `status=failed` before exit 1 (`AGENTS.md`, hard rule 11). The model step degrades to a deterministic stub and never fails the build (same rule 11).
- Test and production run the same code. Only `AWS_ENDPOINT_URL` changes, pointed at LocalStack in test (`AGENTS.md`, rule 14, `scripts/verify-worker.sh`, 10 assertions).
- Jenkins builds the image with Kaniko, scans with Trivy, then bumps the image tag in the GitOps repo, gated to main (`jenkins/Jenkinsfile`, README section Factory CI Pipeline).
- A measured cost per model call exists: Haiku 4.5, 474 input and 6,911 output tokens, $0.035 per site, 35.5 s (`docs/testing/token_cost_measurement.md`, measured 2026-07-16). This is the only per-unit cost number in any iteration.

### 4.6 firstmate (reference)

- Principle "scripts own the mechanics, agents own the judgment" and "a restart is a non-event" (`~/projects/firstmate/VISION.md`, sections with those titles). These are the same two ideas the owner is restating on 2026-10-14.
- The owner ran it for real: `data/` holds about 25 per-task dirs (`atf-s12-*`, `whisper-pr1` to `pr4`, `jenkins-buildout-r1`, `n8n-*`) and `data/learnings.md` has dated, evidence-backed gotchas (75 lines).

## 5. What broke and why

### 5.1 software-factory v0.1 is a contract, not a system

- No runtime exists. The repo has no process that reads a handoff and starts the next node. `docs/06-git-and-integration.md:50` says "GitHub's merge queue may implement this step" and nothing else says who runs any node. Evidence: file list of the 6 commits (`git log` shows docs, schema, validator, CI only).
- Nobody counts attempts. `attempt` is a field the producing agent fills in (`schemas/handoff.schema.json:24`), and "the item is routed to whatever must change" (`docs/04-retries-and-escalation.md:12`) names no router. Counting attempts and routing is exactly the loop rime spent 54 F tickets building.
- DONE is self-certified. The top-level `required` list (`schemas/handoff.schema.json:8-17`) does not include `evidence`, and the only rule that adds it is the if/then for FAILED, BLOCKED and ESCALATED (`schemas/handoff.schema.json:70-73`; `docs/03-handoff-contract.md:44-46`). A DONE handoff needs only `summary` and `artifacts`, both free text and file lists the producing agent writes. The rime investigation names this as the failure to avoid: "The worker cannot self-certify" (`rime-bootstrap/DESIGN.md:150`) and R3, "The architect runs every acceptance command against origin/main before a ticket is cut and records the observed exit code in the ticket" (`F-recommendations.md:10`).
- The work item id pattern `^[A-Z][A-Z0-9]*-[0-9]+$` (`schemas/handoff.schema.json:20`) rejects every coq id. I checked `WO-20261013-16f1` against it: no match. Adopting the schema needs a pattern change, which is small but real.
- No idempotency key, no record version, no per-node timeout or lease, no heartbeat. Rime added `request_id`, `expected_version` (`CORE-DESIGN.md:52`), heartbeats every 5 minutes (`docs/DIAGRAMS.md`, Agent up diagram) and 15-minute silence detection (`FAILURE-MODES.md` F-09) after losing work without them.
- The attempt ladder has a gap. The schema allows FAILED at attempt 3 (nothing forbids it; `schemas/handoff.schema.json:24` allows 1 to 3) and requires ESCALATED to be attempt 3 (lines 77-82); the doc says the third failure becomes ESCALATED (`docs/04-retries-and-escalation.md:13`). Which of the two a stuck node emits is not decided.
- Open decisions are still open: whether Review splits into quality and security, the approval record, the gate model between nodes, the staleness window (`docs/10-open-decisions.md:34-37`). Status codes and the schema are explicitly "Proposed (not yet ratified)" (`docs/10-open-decisions.md:24-30`).
- The repo is not referenced anywhere in the coq line. A grep of `~/projects/coq-jev-herdr-plugin` (excluding `.git`) for `software-factory` returns nothing, and memory file `scheduler-team-recipe.md` uses "software factory DAG" as a generic phrase. It was created in what looks like a separate Claude web session (default branch `claude/new-session-z3nzz0`, commits by "Zenith"). That is an inference from the branch name; no document states it.
- The brief's description of it as "primary candidate base" is accurate for the vocabulary and the schema. It is not accurate if "base" means something that can run the line.

### 5.2 rime and rime-bootstrap: why it stopped

Timeline, all UTC, from the ledger (`~/.local/state/rime/execution/EXECUTION-LEDGER.tsv`, 520 rows) unless another source is named.

- 2026-09-20 to 2026-09-21: first night, 790 minutes, investigated blamelessly (`F-bottleneck.md:7-10`).
- 2026-09-21T17:03:04Z: the rime seat paused the loop "on the owner's word" because "nothing has merged since 06:03Z; A-11 holds stream A on a 412 its one rule cannot route" (`~/.local/state/rime/PAUSED.2026-09-21`, lines `paused_at`, `by`, `why`).
- 2026-09-21T20:00:28Z: "HALT: owner out of subscription usage" (ledger row 31). Lifted 2026-09-24T01:01:03Z, a 53-hour stop.
- 2026-09-24 to 2026-10-06: the loop-fix and product work. The rime-bootstrap log has 40 commits on 09-24, 17 on 10-05 and 40 on 10-06 (`git log origin/main --format=%cd --date=short | sort | uniq -c`, `clones/rime-bootstrap`; these are commit dates in the recorded -05:00 offset).
- 2026-10-06T11:41:28Z: owner halt (ledger row 503, "OWNER HALT 11:41Z: loop paused, seats finishing current step; resume on STARTAGAIN").
- 2026-10-06T13:09:05Z: full halt reached, "five tickets merged, seats retired, loop paused, cron stopped; await STARTAGAIN" (ledger row 517).
- 2026-10-09T23:07:25Z: last ledger row (520), an artifact republish that failed "not found; not republished under halt".
- 2026-10-10T16:39Z to 17:43Z: the first coq session starts, with a different stated goal (a Caves of Qud herdr plugin plus a software factory), not a continuation order for rime (`~/.claude/projects/-home-luna-projects-coq-jev-herdr-plugin/05518e5b-c767-4bf0-87f2-3f76b5e25f49.jsonl`, first user message at 2026-10-10T17:43:14Z).
  The coq repo's first commit is 2026-10-10T18:16:43Z (`git log --reverse`). The rime loop's `.heartbeat` file reads `2026-10-10T16:36:00Z 3017829 paused`.

The reason for the 2026-10-06 owner halt is not recorded anywhere, and I checked every place a reason would be.

- The ledger rows 503 and 504 record the order and the scope ("finish whole tickets A-19, F-48, F-53, F-54, F-52; nothing new; loop stays paused") and no reason.
- `~/.local/state/rime/PAUSED` holds one line, the timestamp `2026-10-06T11:41:11Z`. The older `PAUSED.2026-09-21` has a `why:` line and the new one has none.
- `~/.local/state/rime/seats.log` (464 lines) has no entry for the halt.
  Its last dated line is the reviewer idle check at 2026-10-06T11:30:28Z (`seats.log:462`), and lines 463 and 464 are compaction hand-backs.
- `~/tools/bearings-v2/CHECKPOINT.md` is dated 2026-10-06T06:25:29Z (line 1), five hours before the halt.
  `HYDRATION.md` in the same directory is the 2026-09-22 architect-seat entry (line 19) and its "halt" text is the earlier E-05 halt (lines 33-52).
  Neither mentions the 2026-10-06 halt reason.
- The seat's own memory `~/.claude/projects/-home-luna-tools-bearings-v2/memory/halted-2026-10-06.md` quotes the owner and gives no reason: "Once everybody is done with their task that they're on, I want you halt things. I don't want any more work being done till I give the STARTAGAIN signal."
- In the seat's session transcript (`~/.claude/projects/-home-luna-tools-bearings-v2/39d05e81-1c55-4080-b4a8-78a5e98d288e.jsonl`, lines 10378 to 10491) the only owner messages around the halt are, at 11:37:50Z, "How many agents do we have working here?", at 11:40:35Z the halt order, and at 11:42:56Z "Finish the whole ticket then they're done."
  The seat had told the owner at 11:38:28Z that "nothing needs you" (line 10417).
  No owner message in that transcript after 11:42:56Z gives a reason; the next user-role lines are the watcher's compaction notice at 13:10:25Z (line 11013) and a watch-lifecycle notice on 2026-10-09T23:07:16Z (line 11170).
- The `halted-2026-09-21` precedent had a stated cause (usage exhausted, `halted-2026-09-21.md` description); this halt has none.

Conclusion on the reason: unrecorded.
It is not worth asking the owner as a design question, because the evidence below does not depend on it.
What can be said is what the evidence rules out and what it leaves.

What the evidence rules out.
The halt does not follow a stall.
In the 11 hours up to the halt the loop merged 9 product tickets, with a 10th under the halt (section 4.3), and, on the halt morning, A-19, F-47, F-48 and the F-52 to F-54 cuts were all moving (ledger rows 495-502).
The sole failure visible at 11:38Z is a gate push refusal on F-54 whose remedy "already [was] with architect" (ledger row 502).
So the common reading "the loop failed and the owner stopped it" is not supported for 2026-10-06.
It fits the first night (2026-09-21) and not the last day.

What the evidence leaves.
The first-night failure causes below are real and documented, and each was answered by an F ticket, but the structure that produced them stayed: a bash loop (`bin/watch.sh`) as control plane, LLM seats as supervisors, and the owner as the only source of "go".
Reasons for the owner losing patience that the data supports without a quote:

- Ratio of loop repair to product.
  32 merged commits in rime-bootstrap carry an `(F-NN)` id (loop fixes), against 17 merged product tickets in rime (`git log origin/main`, counted 2026-10-14; the 17 are `git log origin/main --format=%s | grep -cE '^[ABCJ]-[0-9]+'`).
  54 F tickets were cut (`streams/F-foundations.md` section headings, F-01 to F-54).
  By the last day, every new loop ticket was itself a fix of an earlier loop fix: F-52 "never kills a live agent for silence", F-54 "never rewrites a head it already pushed", F-53 "banning grep checked against its own text", F-51 "no seat waits on pgrep -f" (`rime-bootstrap/REPLAN.md:173-176`).
  Note that F-49 to F-54 were merged as cuts only, which means the ticket text was committed as a docs change and the fix itself was not built: `git log origin/main` shows only `docs(streams): cut F-52 ...` (`9a21ea0`), `cut F-54` (`41226e3`), `cut F-53` (`8f5a394`), `cut F-51` (`8a36e5c`), `cut F-50` (`709a2dc`) and `cut F-49` (`4f734cf`), with no later commit carrying those ids, and the seat's memory lists "Maintainers for the fixes to the merged cuts: F-49, F-50, F-51, F-52, F-53 and F-54" as the work for after STARTAGAIN (`~/.claude/projects/-home-luna-tools-bearings-v2/memory/halted-2026-10-06.md`, last section).
  The owner told the seat on 2026-10-06 to finish exactly these five tickets before stopping (ledger row 504), which are three of the four loop-on-loop fixes above plus F-48 and A-19.
- Throughput numbers from night one: 6 merges in the first 424 minutes and 0 in the last 364 (`F-bottleneck.md:8`).
  24 dispatches, 6 merges, 7 supersedes, 10 false re-dispatches, 19 records at 423, 34 at 422 (`F-bottleneck.md:10`).
- One ticket, A-02, consumed 336 minutes and never merged (`F-bottleneck.md:29`, F-B1, and the table row "A-02 alone, first record to supersede, 336 minutes").
  A-11 held the only slot 395 minutes on a 412 that its one rule could not route (`F-bottleneck.md:30`, F-B2).
- Tickets were cut that nobody could build.
  Five of seven supersedes were acceptance criteria no worker could satisfy on origin/main (`F-planning.md:14`, F-PL3): B-02 named a chart that resolves to nothing, C-05 required an unchanged file that mermaid rejects, C-06 required a make exit code make cannot produce, B-06 wrote to a repo no worktree holds, A-02 named buf plugins that do not resolve.
  Each supersede is recorded in `rime-bootstrap/streams/INDEX.md:17-30` (B-01 at line 17, B-02 at 18, B-06 and B-07 at 19, B-09 at 23, C-05 at 27, C-06 at 28, A-02 at 30) and `rime/docs/DIAGRAMS.md:8` ("Record: ticket C-07, superseding C-06, which superseded C-05").
- The supersede chain never ends.
  B-01 to B-07 to B-09 to B-10; C-05 to C-06 to C-07; A-02 to A-12; A-05 to A-18 to A-19 (ledger rows 487-507: A-05 superseded by A-18 at 10:34Z, A-18 by A-19 at 11:16:59Z after "Tester 423: acceptance mutations need Edit, tester denied").
- Supersede did not re-point dependents, so the next waited forever on a dead id (`F-process.md:8`, F-PR3: "Supersede never re-pointed dependents. B-05 still depends on B-01, B-07 on B-06, A-11 on A-02"; fixed later by F-09, `a75e349`).
- The loop had no test before it ran the project (`F-planning.md:18`, F-PL7: "bin/ had no harness, no dev mode, no fixture. Every script's first execution was against live tickets").
  `watch.sh:4-15` records that the loop "died silently six times today" under `set -e`.
  `stable` had the same bug class: `tac | jq` under pipefail exits 141 (`stable/docs/superpowers/handoffs/2026-09-15-overnight-crash-owner-restart.md:31`, R-COMPACT-06), and rime's C-07 re-dispatch was first misdiagnosed as a fetch race before it was proven SIGPIPE (`F-supervision.md:8`, F-S2).
- The supervising LLM seat drifted into operating the machine.
  It wrote to the live sealed packet directly, including a non-atomic write that "broke every seat dispatch for two minutes" (`F-supervision.md:7`, F-S1).
  Its first containment, "nulling ended_at, backfired into three resumes and a re-dispatch" (`F-supervision.md:12`, F-S6).
  It re-prompted agents off `agent_status idle` forty minutes after writing in a playbook that idle is untrustworthy (`F-supervision.md:9`, F-S3).
  It wrote "I'll compact on the next merge" at 39 percent against a 30 percent threshold, which the owner named "inventing a rule" (`F-supervision.md:10`, F-S4).
  It left 300 superseded notes on merged tickets as containment (`F-supervision.md:13`, F-S7), and the accounting names "containment, locks, keystrokes, a container kill and one packet commit" (`F-supervision.md:14`, F-S8).
- Two wedges went unnoticed: 16 minutes until the owner asked, then 2 hours while the seat waited on a Lavish review.
  "The seat read the sweep as liveness because that is what the sweep looked like" (`F-supervision.md:11`, F-S5).
- Cost ended a run: ledger row 31, 53 hours (above).
- The product never reached the owner.
  `rime-bootstrap/START-HERE.md:32-35` states the original ask: a small decision-and-communication page for the owner.
  `F-planning.md:17` F-PL6: "Bearings v2, the owner's first sentence, was deferred to 'design session two' ... and has no ticket anywhere."
  No `J-*` session dir exists (`ls ~/.local/state/rime/sessions | grep -c '^J-'` returns 0).
  The first real deploy ticket J-01 never started; `watch.log` last 40 lines read "next: J-01 (stream J) waits behind an earlier pending id; stopping" (`bin/next.sh:175-177` is the code that prints it).
- The design was reasoned and the reasoning was sound at the level of what and why: "Planned correctly at the level of what and why. Not planned at the level of can this ticket be built, can these streams actually run apart, and does the machine that runs them work" (`F-planning.md:22`).

Where this disagrees with the brief's diagnosis.
The brief says "we're using herdr wrong".
For this iteration the evidence does not blame herdr.
The recorded failure causes are ticket quality (acceptance not run before cut), a bash loop with no test harness, serial dependency on one head ticket, LLM seats as supervisors and gatekeepers, and cost.
Herdr appears as a cause only in narrow places: `agent_status idle` being untrustworthy (`F-supervision.md:9` F-S3, `rime-bootstrap` commit `1facf32` "act on herdr idle only with transcript proof"), seat names over herdr's 32 character limit (`0d15445`, F-29), and a herdr session per stream (`2ef8c6a`).
The crashes that killed whole fleets in earlier iterations came from the terminal host, not herdr (`stable` handoff: wezterm-gui.exe heap corruption 0xc0000374 at 2026-09-15T06:36Z, then an unexplained WSL stop at 07:29Z).
Using a terminal multiplexer as the runtime and the only state surface is a recurring weakness, but the iteration data point to "agents and a bash loop were the control plane" as the mechanism, not herdr itself.
A second disagreement: the diagnosis that the factory is stuck would be wrong for rime on its last day, where throughput was the best it ever reached (section 4.3).
The owner's pattern across all eight iterations is a stop at a high-ceremony point, not a collapse.

### 5.3 Other iterations, in one line each

- generic-agents-auto-workflow: a cockpit for N Chrome-bound worker agents under a relay-only supervisor (`NORTH_STAR.md`). 838 commits in 5 days, stopped 2026-09-09. Its design principle "the script writes the record, never the model" (`NORTH_STAR.md`, principle 7) survived into the work-order skill.
- stable: "A stable of Claude Code agents that get work done without a human in the loop" (`stable/README.md:3`), 8,105 lines of bash in `bin/`, 43 subcommands, 38 schemas, a hash-chained role ledger, a retirement SOP, queues, an event bus, and a v3 plan for "a Go control plane on the cluster and a Go bridge on the WSL host" (`docs/superpowers/specs/2026-09-14-stable-v3-battle-plan.md`, section 1). Stopped 2026-09-16 after two whole-system crashes on 2026-09-15 and a hand-written restart handoff (`handoffs/2026-09-15-overnight-crash-owner-restart.md`). It stated 18 rules R-01 to R-18 (battle plan section 2) that reappear in the owner's global instructions today: "nothing is done by hand" (R-02), "tickets are small enough for the most junior agent" (R-07), "cold start is one idempotent command" (R-15).
- bearings-core: NATS JetStream plus one Go core as the only writer of task state, three commits, 1,498 Go lines, 2026-09-20 (`bearings-core/README.md`). Superseded the next day by rime, whose ADR-0002 and `CORE-DESIGN.md:138` say "no message broker beyond Redis Streams". `EVIDENCE.md` calls the NATS design "PROPOSED, not accepted".
- compaction-guard: 18 versions in 2 days (1.0.0 at 2026-09-19T08:05Z, 1.2.8 at 2026-09-20T21:25Z). Each patch version came from a live lockout or probe; `todo.jsonl` T24 records "third lockout of the day" and the freeze flag becoming a lease (1.2.8). One 1,574-line bash script.
- control-tower: no iteration exists. Dated 2026-08-17, four skills only.

## 6. Waits, polls, sleeps and leases

Each repo below says which clone or directory the file was read from.
The pattern in every iteration is the same: the wait is a poll with a bound, the bound is a number in the script, and the thing that waits is a shell loop or an LLM seat.

### 6.1 rime-bootstrap (files from `clones/rime-bootstrap`)

- Main sweep: `bin/watch.sh:300` `sleep 60` (was 300; changed 2026-09-21T02:32Z because "a five minute sweep put 5 minutes of idle after every record on the first live run"). Paused sweep also `sleep 60` (`bin/watch.sh:39`).
- Gate merge retries: `bin/gate.sh:170-174` three attempts with `sleep $(( attempt * 5 ))`, bounded at 5 plus 10 plus 15 seconds.
- Tester and reviewer wait, the 30 minute one.
  The bound is in code at `bin/dispatch-seat.sh:63` (`deadline=$(( $(date +%s) + 1800 ))`), and on expiry the script posts a 423 "produced no record in 30 minutes" (`bin/dispatch-seat.sh:86`).
  The poll step is `sleep "${SEAT_POLL_S:-15}"` (`bin/dispatch-seat.sh:178`).
  The deadline moves forward by 900 s every poll that herdr reports the seat `working` (`bin/dispatch-seat.sh:138`), so a looping seat is never timed out by this wait.
  A silent idle seat is re-prompted after two idle polls, at most 3 times (`bin/dispatch-seat.sh:170-172`).
  The detach that keeps this wait from freezing the sweep is `spawn_seat` (`bin/lib.sh:308`, with the 2026-09-21T03:12Z defect described at `bin/lib.sh:301-307`).
  The documentation of the same wait is in `clones/rime/docs/GATE.md:19` ("waits 30 minutes for one", citing `playbooks/reviewer.md` and `playbooks/tester.md`).
  That file is in the `rime` repo and is not present in `rime-bootstrap`; the code that implements it is in `rime-bootstrap`.
- Seat prompt wait: `bin/seat.sh:623` `pane wait-output ... --timeout "${SEAT_PROMPT_TIMEOUT_MS:-15000}"`. A mismatch of the prompt regex with the owner's zsh prompt "wait-output timed out and every dispatch died with a 423" (comment at `bin/seat.sh:620`).
- Herdr workspace readiness: `bin/seat.sh:504` ten tries, `sleep 1` each. Seat down wait: `bin/seat.sh:261` `sleep ${SEAT_DOWN_WAIT:-5}`.
- Compaction: `bin/compact-now.sh:65-68` waits up to 600 s for the seat to be idle in 10 s steps (exit 4 at the bound), then `:85-86` polls for a `compact_boundary` row in 5 s steps up to `wait_seconds`, then `:169-175` waits up to `resume_wait_seconds` for an acknowledgment. All bounded, all polls.
- Loop restart handshake: `bin/watch-toggle.sh:30-50` waits up to `RIME_LOOP_WAIT` seconds (default 150) for a fresh heartbeat, 1 s steps.
- In-flight cap: `config/loop.json` `max_in_flight: 2` (raised from 1 by F-40). `bin/next.sh` waits behind a dependency, behind pre-dispatch re-checks (`bin/next.sh:227-231`), and for stream J behind any earlier pending id (`bin/next.sh:175-177`).
  The final state of the run was this wait with no way out: `watch.log` ends "next: J-01 (stream J) waits behind an earlier pending id; stopping" for sweeps 1286 to 1295.
- Silence: heartbeat missing 15 minutes means pane dead and resume (`FAILURE-MODES.md` F-09, file in `clones/rime/docs/`). F-52 later changed it so a working seat is never killed for silence.
- Leases: one worktree per ticket leased from `~/.worktrees/rime/<id>` (`clones/rime/docs/DIAGRAMS.md`, Agent up diagram). Agent token TTL in Redis (`clones/rime/docs/ADR/0002`). Both documented; leak audit nightly (`FAILURE-MODES.md` F-16).
- Outbox backoff 1 s, 5 s, 25 s then 423 (`FAILURE-MODES.md` F-11).

### 6.2 The current coq line's use of the same loops (read-only, main checkout)

The coq line kept the wait pattern and moved most of the numbers into schema-validated config, which is the one improvement over rime.
Its numbers are bounded by a lease or a retry count, with one exception.

- Seat waits (`herdr/config/herdr.json`): `prompt_timeout_ms` 15000 (line 7), `agent_start_timeout_ms` 30000 (line 8), `down_wait_seconds` 3 (line 9), `retire_poll_seconds` 10 (line 12), `nudge_wait_seconds` 15 (line 13), `nudge_settle_seconds` 10 (line 14), `guard_watch_interval_seconds` 15 (line 17), `turn_poll_seconds` 15 and `record_poll_seconds` 10 (lines 54-55), supervisor `step_timeout_seconds` 120 and `herdr_wait_seconds` 30 (lines 72, 74), belt `settle_seconds` 20 (line 39), break glass `ttl_seconds` 600 (line 42).
  The waits that use them are ported from rime: `herdr/bin/seat.sh:24` ("ported from ~/tools/bearings-v2/bin/seat.sh"), `herdr/bin/seat.sh:778` (`pane wait-output ... --timeout "$((wait * 1000))"` for the compaction-guard ACK), `:804` (prompt regex wait with `prompt_timeout_ms`), `:784` and `:832` (`sleep 1` loops).
- Leases (`herdr/config/leases.json`): slot 14400 s (line 6), tier 86400 s (line 12), ticket 7200 s (line 18), seat 900 s (line 24). "The monitor releases an expired one, records seat.stalled 500 and wakes the queue" (line 3).
- Board (`line/config/board.json:13-15`): `lease_seconds` 1800, `nudge_seconds` 60, `digest_seconds` 1800.
- Hook listener (`line/config/hook.json:21-25`): `retries` 3, `retry_seconds` 1, `restart_limit` 3, `handler_timeout_seconds` 300; the wait is `sleep "$RETRY_SECONDS"` at `line/bin/hook-listener.sh:74`.
- Merge: `line/bin/merge.sh:80` `RETRIES=${MERGE_RETRIES:-3}`, `BACKOFF=${MERGE_BACKOFF_SECONDS:-2}`, `nap` at `:107`.
- Poll loops: `line/bin/merge-watch.sh:41` `MERGE_WATCH_SECONDS:-60`, `line/bin/route-retry.sh:55` `ROUTE_RETRY_SECONDS:-30`, `line/bin/digest.sh:35` `DIGEST_SECONDS:-1800`, `line/bin/record-bus.sh:53` `interval=5`.
- The exception, unbounded: `line/bin/seat-queue.sh:28` is `until git ls-remote --exit-code origin "refs/heads/feat/$slug" ...; do sleep "$BRANCH_WAIT"; done` (15 s) and `:29` is `until bash herdr/bin/seat.sh ...; do ... sleep "$SLOT_WAIT"; done` (60 s).
  Neither has a deadline, a retry count or a report on exceeding one; the file's own header calls it "the interim worker queue (backlog 32bb9: seat.sh's max_seats refusal promises a queue that does not exist)" (`line/bin/seat-queue.sh:2`).
  This is the same shape as rime's `watch.sh` waiting forever behind J-01 (section 6.1, in-flight cap), and it is the only unbounded wait I found in `line/bin/`.
  L01 owns the full inventory of the line.

### 6.3 compaction-guard

- `watch` loop `while true ... sleep "$interval"` (`bin/compaction-guard:1272-1283`). Retry `sleep $((try * 5))` (`:1351`). A further `sleep "$iv"` at `:1454`.
- Freeze lease 180 s default, released automatically (`docs/status-codes.md` CMP-350). Memo stall 600 s (`GOV-120`). Busy stall 600 s (`CMP-260`).

### 6.4 software-factory v0.1

No waits are defined at all.
There is no timeout, lease or poll in the docs or the schema (grep of `docs/` and `schemas/` for `timeout`, `lease`, `poll`, `ttl` finds none that define a bound; `docs/10-open-decisions.md:37` lists the staleness window as undecided).

### 6.5 stable (files from `clones/stable`, plus the bridge scripts outside the repo)

- The wait that mattered was the compaction settle check.
  `agent_idle_settled` (`bin/cmd/_lib.sh:109-126`) refuses unless herdr reads idle or done, the pane shows no "esc to interrupt", and the transcript's last turn is not a user prompt.
  `agent_quiet` (`bin/cmd/_lib.sh:151-158`) adds a transcript that has not changed for `STABLE_SETTLE_SECONDS` (default 60, line 157).
  `bin/cmd/compact.sh:251-255` polls `sleep 1` until quiet or `--wait-idle` seconds have passed; line 264 is the refusal if it never settles.
  The checkpoint wait is `STABLE_COMPACT_CHECKPOINT_SECONDS` default 120 (`bin/cmd/compact.sh:8`, used at `:350-354`), verify is 900, resume is 60 per try.
- The bug: `last_turn_entry` piped `tac | jq`, and under `set -o pipefail` tac exits 141, so `agent_idle_settled` refused every live agent on a transcript past the pipe buffer (R-COMPACT-06, `docs/superpowers/handoffs/2026-09-15-overnight-crash-owner-restart.md:31`; the fixed code, with `{ tac "$1" || :; } | jq`, is at `bin/cmd/_lib.sh:129-139`).
- `compact-when-quiet.sh` was the bridge waiter, written outside the repo and retired.
  It is described at `docs/superpowers/handoffs/2026-09-15-overnight-crash-owner-restart.md:39` ("waits until the role is measured quiet (idle, no spinner line, transcript still 60 s, last entry its reply), then runs stable compact --force once") and slated for retirement at line 86.
  The file itself is no longer present: `ls ~/.local/state/stable/runs/bin/` does not list it (checked 2026-10-14).
  I cannot cite file and line for its sleeps; the 60 s quiet window is the documented bound.
- The other bridge waiters still on disk in `~/.local/state/stable/runs/bin/`, each a polling loop in its own visible pane:
  `idle-watch.sh:20-21` idle threshold 1200 s, recheck 30 s (`sleep "$RECHECK"` at `:88`);
  `compaction-watch.sh:13` late after 600 s, `sleep 5` at `:56`;
  `resume-watch.sh:21-45` `while true` with `sleep 10`, `seq 15` x `sleep 2`, `seq 30` x `sleep 2`, then `sleep 5`;
  `hold-guard.sh:7-8` hold TTL 1800 s, interval 60 s, `sleep "$interval"` at `:27`;
  `watch-many.sh:70` `sleep 60`; `beat-run.sh:17` `sleep "${BEAT_SECONDS:-5}"`;
  `bearings-wait-pane.sh:71` `sleep 3`, `:95` `sleep 5`, `:106` `sleep 300` after a flap limit.
  Each comment says "Bridge until ... lands in the repository" (for example `idle-watch.sh:14`, `compaction-watch.sh:8`, `beat-run.sh:7`), meaning the load-bearing waits lived in untracked scripts.

### 6.6 generic-agents-auto-workflow (files from `clones/generic-agents-auto-workflow/engine/scripts`)

- `watch-events.sh:266` `sleep 5` per tick, writing a beat file every tick (`:259`).
- `wake-watch.sh:68` `interval=1` default; `--wait SECONDS` parks until an actionable log line lands or the window ends (`:52`, loop at `:218-223` with `sleep "$interval"`).
- Lock waits: `log-event.sh:65-68` `LOG_LOCK_TIMEOUT` default 10 s, `sleep 0.05` and `0.1` (lines 122, 148, 178), exit 5 on timeout; `config/resolve-config.sh:152` uses a real deadline, because a loop counting sleeps "waited about 47" seconds for a documented 10 under MSYS (comment at `:148-151`).
- Config values: `engine/config/cockpit.json:8` swap `timeout_sec` 900, `:14` `lock_timeout_sec` 10, `:24` `pane_settle_timeout_sec` 20, `:30` `reply_timeout_sec` 300.
- `queue/dispatch-review.sh:183` `agent start --timeout 300000`.

### 6.7 bearings-core (files from `clones/bearings-core`)

- JetStream consumer: `AckWait: 30 * time.Second`, `MaxDeliver: 5`, explicit ack (`internal/nats/client.go:112-113`, doc comment at `:99`).
- Core loop: `sub.Fetch(fetchBatch, fetchTimeout)` with `fetchBatch = 10` and `fetchTimeout = 5 * time.Second` (`cmd/core/main.go:31-32`, call at `:131`).
- Lease: `const leaseTTL = 5 * time.Minute` (`internal/task/table.go:12`), a fencing token per task, and a lease held by another agent rejects the transition (`internal/task/table.go:113`).
- Reconnect wait 2 s and connect timeout 10 s (`internal/nats/client.go:45-46`); shutdown drain 5 s (`cmd/core/main.go:117`).
  This is the only earlier iteration where the redelivery wait is a property of the broker and not of a shell loop.

### 6.8 astro-template-factory

Jenkins `timeout(time: 30, unit: 'MINUTES')` and `disableConcurrentBuilds()` (`jenkins/Jenkinsfile`). No poll; the Job calls back.

## 7. Decisions an LLM makes that a rule could make

Each item is a decision an LLM seat made in an earlier iteration, with the rule that replaces it.
The "state" says whether the rule was built, was only specified, or does not exist, because several of the rules named below were never built.
Findings files are in `~/Documents/investigations/bearings-v2-investigations/findings/`.

- Whether a 423 gets re-cut, fixed or sent to the owner.
  Made by the architect seat, with the briefing carrying the last sentence of a tester.
  Quote: "On A-02 at 08:33Z the architect's briefing was the tester's sentence about grep -c" (`F-process.md:9`, F-PR4).
  Rule: a table row keyed on code, step and strike count.
  State: built for the loop's own routes (F-07 `0335d9b` and F-19 `9467fed`, `bin/loop-rules.json`, 31 rules, default 500).
- Whether a ticket's acceptance is runnable.
  Made by nobody until a failure; five of seven supersedes were acceptance that could not be satisfied (`F-planning.md:14`, F-PL3).
  Rule: R3, "The architect runs every acceptance command against origin/main before a ticket is cut and records the observed exit code in the ticket. A ticket whose acceptance cannot be run is not cut" (`F-recommendations.md:10`), and the "Proven by" rule (`rime-bootstrap/CORE-DESIGN.md:118-120`).
  State: ticket F-53 specifies `bin/cut-check.sh` (`streams/F-foundations.md:8153`, "bin/cut-check.sh runs every banning grep against the ticket's own code blocks").
  The file does not exist: it is on no remote branch of the `rime-bootstrap` clone (every `origin/*` branch checked with `git cat-file -e <branch>:bin/cut-check.sh`), not in `~/tools/bearings-v2/bin`, and F-53 was merged as a cut only (`8f5a394`, ledger row 509 "Cut merged #88 as 8f5a394").
  R3 as a whole is therefore not enforced by any code.
- Whether a stuck ticket is superseded and who depends on it.
  Made by an architect seat; "Supersede never re-pointed dependents. B-05 still depends on B-01, B-07 on B-06, A-11 on A-02" (`F-process.md:8`, F-PR3).
  Rule: a command that rewrites every `depends_on` in one change and a refusal of a `depends_on` that names a superseded id (R4, `F-recommendations.md:11`).
  State: refusal built as F-09 (`a75e349`, "refuse dependents whose depends_on names a superseded id").
- Whether a seat is alive.
  "The seat re-prompted crew agents off agent_status idle forty minutes after writing into the caretaker playbook that agent_status is untrustworthy" (`F-supervision.md:9`, F-S3).
  Rule: transcript proof plus heartbeat age, never herdr idle alone.
  State: built as F-31 (`1facf32`).
- When to compact.
  "At 39 percent context against a 30 percent threshold the seat wrote 'I'll compact on the next merge'" (`F-supervision.md:10`, F-S4).
  Rule: a hook, which is what compaction-guard is (`~/projects/compaction-guard/README.md`, "The rule it enforces").
  State: built, and live in the current line (`.claude/settings.json:13,35,47`).
- Whether to contain a failing loop by hand.
  The seat nulled `ended_at`, which "backfired into three resumes and a re-dispatch" (`F-supervision.md:12`, F-S6), wrote 300 superseded notes on merged tickets (`F-supervision.md:13`, F-S7), and the accounting lists "a container kill and one packet commit" (`F-supervision.md:14`, F-S8).
  Rule: one `recover` command from a manifest, never lifting a pause.
  State: built as F-41 (`a18c8a6`).
- Whether the live packet may be edited by the supervising seat.
  "The seat was the only unreviewed writer onto a live surface. The system offered no other path" (`F-supervision.md:7`, F-S1).
  Rule: a maintainer role that is the only writer, and a seal that is git (F-21).
  State: built (F-21, `playbooks/maintainer.md`).
- When to restart or kill a silent agent.
  The loop killed live agents for silence.
  Rule: a working seat counts as alive; a silent idle one is nudged once, then 423.
  State: specified only, as the F-52 cut (`9a21ea0`, #96); the fix was not built (section 5.2).
- Whether a wedge is noticed.
  "Two wedges went unnoticed: 16 minutes until the owner asked, then 2 hours" because the sweep line printed the last code and not the age (`F-supervision.md:11`, F-S5).
  Rule: an age on every sweep line and a timer that raises 423 on its own; state: partial (heartbeat age, F-09 in `FAILURE-MODES.md`).
- Whether the owner has an item.
  In stable the lead wrote the restart handoff by hand at the owner's order (`stable/docs/superpowers/handoffs/2026-09-15-overnight-crash-owner-restart.md:3-5`).
  Rule: a recover command run by the system.
  State: built for rime (F-41), and for coq (`herdr/bin/recover.sh`).
- Which model runs which role.
  Decided in prose in `rime-bootstrap/CORE-DESIGN.md:87-95` (section "Model and seat table") (opus architect, haiku worker, sonnet tester and reviewer), later moved into role JSON files (F-11, F-23) and one map `claude_model()` (`rime-bootstrap/bin/lib.sh:299`).
  Rule: the role file is the decision and the spawner reads it.
  State: built.
- Whether to merge.
  Rime moved it to the gate script (`bin/gate.sh`, "tests 201 plus review 201 of the exact reviewed head").
  software-factory proposes a node for it (`docs/06-git-and-integration.md:41-50`).
  The merge decision is already a rule in both; the LLM only has to produce a verdict record.

## 8. What to carry forward

- software-factory handoff schema and status vocabulary (`schemas/handoff.schema.json`, `docs/03-handoff-contract.md`) as the shared seat contract, after three changes: loosen `work_item_id` (`schemas/handoff.schema.json:20`) to the WO pattern, require evidence on DONE (commands run and observed output), and add a record version and idempotency key from rime (`CORE-DESIGN.md:52`).
  Why: it is already schema-validated with deliberate invalid fixtures, and it matches rime's finding that a node cannot self-certify.
- software-factory profile idea (policy sits on top of one pipeline) and the "one merge owner, serialized, oldest ready first" rule (`docs/06-git-and-integration.md:41-50`).
  Why: the owner's lived problem is unmerged PRs, and this is a one-paragraph answer.
- rime status codes and the transition table with ordered gates and strike count (`internal/transition/transition.go`).
  Why: 1,009 lines of tests including mutants, already ported in spirit to coq's event codes.
- rime failure-mode catalogue shape (detection, automatic recovery, runbook, proving ticket) (`clones/rime/docs/FAILURE-MODES.md`).
  Why: it is the missing "what does the system do on its own" table.
- rime investigation recommendations R1 to R14 (`F-recommendations.md`).
  Why: R3 (line 10, run acceptance before cut), R4 (line 11, supersede re-points dependents), R8 (line 18, never grow an open ticket), R14 (line 27, one JSON decision table) are still true and R3 is not enforced by code (section 7).
- compaction-guard hooks, immutable releases with a promote gate, freeze lease, break glass without a test gate.
  Why: it is the one earlier artifact running in production today.
- astro-template-factory worker pattern: one-shot Job, env contract, callback on both success and failure, same code in test and prod, Kaniko plus GitOps tag bump.
  Why: this is the nearest thing the owner already runs to "an agent step as a pod", and the cost of a model step was measured ($0.035, 35.5 s).
- firstmate principles "scripts own the mechanics, agents own the judgment" and "a restart is a non-event" (`VISION.md`).
  Why: they are the owner's own statement of "no cog should hold up the system".
- stable's rules R-01 to R-18 as a checklist of acceptance for the rebuild, especially R-15 (one idempotent cold start command) and R-17 (every artifact registered with a cleanup step).
- bearings-core's broker-owned delivery: explicit ack, `AckWait` 30 s, `MaxDeliver` 5 (`internal/nats/client.go:112-113`) and a lease with a fencing token (`internal/task/table.go:12,113`).
  Why: it is the only earlier design where "a wakeup is never lost" is a property of the broker and not of a polling shell loop; the shelf track (S03) should compare it with Redis Streams and Argo.

## 9. What to kill

- The bash loop as the control plane.
  Evidence: watch.sh died silently six times in one day (`watch.sh:4-15`), 54 F tickets, and stable had the same SIGPIPE class.
  The same shape is in the current line at `line/bin/seat-queue.sh:28-29`, two unbounded `until ... sleep` loops (section 6.2).
  Replace with something that has retries, timeouts and state built in; that is for the shelf track to name.
- LLM seats as supervisors (the "rime seat", the caretaker, the steward, the architect that routes by hand).
  Evidence: `F-supervision.md:7-14` (F-S1 to F-S8), and `F-bottleneck.md:30` F-B2 (a silent 412 held a slot 395 minutes).
- Ticket-in-flight parallelism by stream.
  Evidence: "Parallelism did not add throughput" (`F-bottleneck.md:32`, F-B4).
  Caveat: rime's later `max_in_flight: 2` run produced 10 merges in 10h57m (section 4.3), so the evidence supports "one stream at a time with disjoint files", not "no parallelism".
- Growing an open ticket in place (`F-process.md:7`, F-PR2, A-02 step 9).
- Tickets whose acceptance was never run (`F-planning.md:14`, F-PL3).
- One-layer-up complexity before the first end-to-end slice: stable's 43 subcommands and 38 schemas, hash-chained role ledgers and retirement SOP before the first product ship; rime's forward design of Bearings v2 after E1 to E3 (`CORE-DESIGN.md:131`).
- Waiting on a Lavish or any human page inside the loop (`F-supervision.md:11`, F-S5, 2 hours).
- Reusing software-factory as a "base" in the sense of a runnable system. It has none of the machinery (section 5.1).
- Carrying the Forgejo board as a second source of state (rime ADR-0003 "Two systems stay in sync instead of one", `clones/rime/docs/ADR/0003-forgejo-boards-only.md`).
  It was designed, deployed as manifests (commit `737d48b`), and never drove a single ticket.
- Writing a ticket for a fix and not building it, then halting: F-49 to F-54 sat as merged cuts with no build (section 5.2).
  The cut-and-build split makes the record say "complete" (ledger rows 509, 513, 516) for tickets whose fix does not exist.
- `~/projects/control-tower`: an empty shell, nothing to keep.

## 10. Open questions for the owner

- Is the rime Go core (transition table, store, watch stream, about 1,182 lines plus 2,091 lines of tests) a base to finish, or is the rebuild starting from the scheduler spec?
  This changes whether a new control plane is written or an existing one is completed.
  The 13 unmerged ticket branches in `jkkelley/rime` and `a-06`, `a-08` to `a-10` never built are the gap.
  The rime loop is still formally "halted, await STARTAGAIN" (ledger row 517, memory `halted-2026-10-06.md`), so a decision here also closes or resumes that halt.

Removed from the previous version: the question of why the owner halted rime on 2026-10-06.
It was checked at six places (section 5.2) and no reason is recorded; the evidence shows the loop was at its best throughput, so the reason does not change the design.

## 11. Sources

Files and repos read, all on 2026-10-14 UTC unless dated otherwise:

- `clones/software-factory` (commit `4fbbd72`, 2026-10-07): `README.md`, `AGENTS.md`, `CLAUDE.md`, `CHANGELOG.md`, `VERSION`, `SECURITY.md`, `CONTRIBUTING.md`, `docs/01` to `docs/10`, `schemas/handoff.schema.json`, `profiles/home-lab.yaml`, `profiles/company.yaml`, `scripts/validate.py`, `examples/*.json`, `tests/invalid/*.json`, `.github/workflows/ci.yml`, `.pre-commit-config.yaml`. GitHub API `repos/jkkelley/software-factory` (created 2026-10-08T03:59:19Z), `gh pr list` and `gh issue list` (both empty).
- `clones/rime` (HEAD `994a614`, 2026-10-06): `README.md`, `docs/ADR/0001` to `0004`, `docs/FAILURE-MODES.md`, `docs/DIAGRAMS.md`, `docs/GATE.md`, `docs/MANUAL-INTERVENTIONS.md`, `internal/transition`, `internal/store`, `internal/stream`, `Makefile`, `Jenkinsfile`, git log and branch list (commit times converted from -05:00 to UTC in this file).
- `clones/rime-bootstrap` (HEAD `9a21ea0`, 2026-10-06): `START-HERE.md`, `DESIGN.md`, `CORE-DESIGN.md`, `WORKFLOW.md`, `EVIDENCE.md`, `REPLAN.md`, `streams/INDEX.md`, `streams/F-foundations.md` (headings and F-53 at line 8153), `bin/watch.sh`, `bin/gate.sh`, `bin/next.sh`, `bin/seat.sh`, `bin/dispatch-seat.sh`, `bin/lib.sh`, `bin/compact-now.sh`, `bin/watch-toggle.sh`, `bin/loop-rules.json`, `config/loop.json`, full git log. Every `origin/*` branch checked for `bin/cut-check.sh` (none has it).
- `~/.local/state/rime/`: `watch.log`, `seats.log`, `.heartbeat`, `PAUSED`, `PAUSED.2026-09-21`, `sessions/A-19/a2a.jsonl`, `sessions/F-53/a2a.jsonl`, `execution/EXECUTION-LEDGER.tsv` (rows 4 to 520, notably 31, 32, 54 to 64, 257 to 272, 451 to 520), `execution/seats/wCH_pB/{CONTEXT_STATE.md,checkpoint-body.md}`.
- `~/tools/bearings-v2` (live copy of rime-bootstrap): `CHECKPOINT.md`, `HYDRATION.md`.
- `~/.claude/projects/-home-luna-tools-bearings-v2/`: `39d05e81-1c55-4080-b4a8-78a5e98d288e.jsonl` (lines 10300 to 11170, user messages only), `memory/halted-2026-10-06.md`, `memory/halted-2026-09-21.md` (description line), `memory/MEMORY.md`.
- `~/.claude/projects/-home-luna-projects-coq-jev-herdr-plugin/05518e5b-c767-4bf0-87f2-3f76b5e25f49.jsonl` (first user messages, 2026-10-10).
- `~/Documents/investigations/bearings-v2-investigations/`: `README.md`, `findings/F-bottleneck.md`, `F-planning.md`, `F-process.md`, `F-supervision.md`, `F-recommendations.md` (dated 2026-09-21).
- `clones/astro-template-factory` (HEAD `f3a4175`, 2026-07-23): `README.md`, `AGENTS.md`, `jenkins/Jenkinsfile`, `docs/testing/token_cost_measurement.md`, git log and branch list.
- `~/projects/compaction-guard` (HEAD `76a2e22`, 2026-09-20): `README.md`, `docs/status-codes.md`, `docs/process/development.md`, `bin/compaction-guard` (lines 1270 to 1284), `todo.jsonl`; `~/.local/state/compaction-guard/events.jsonl`; `~/projects/coq-jev-herdr-plugin/.claude/settings.json`.
- `~/projects/control-tower` (file listing only).
- `~/projects/firstmate`: `VISION.md`, `CONTEXT_STATE.md`, `data/learnings.md`, `.tasks.toml`, directory listings.
- `clones/stable` (HEAD 2026-09-16): `README.md`, `bin/cmd/_lib.sh`, `bin/cmd/compact.sh`, `docs/superpowers/handoffs/2026-09-15-overnight-crash-owner-restart.md`, `docs/superpowers/specs/2026-09-14-stable-v3-battle-plan.md`; bridge scripts in `~/.local/state/stable/runs/bin/` (`idle-watch.sh`, `compaction-watch.sh`, `resume-watch.sh`, `hold-guard.sh`, `watch-many.sh`, `beat-run.sh`, `bearings-wait-pane.sh`).
- `clones/generic-agents-auto-workflow`: `NORTH_STAR.md`, `engine/scripts/{watch-events,wake-watch,log-event,queue/dispatch-review,config/resolve-config}.sh`, `engine/config/cockpit.json`, git log.
- `clones/bearings-core`: `README.md`, `internal/nats/client.go`, `internal/task/table.go`, `cmd/core/main.go`, git log.
- `clones/cortex-hub`: listing only.
- `~/projects/coq-jev-herdr-plugin` (read only, no branch switch): `herdr/bin/seat.sh`, `herdr/config/{herdr,leases}.json`, `line/config/{board,hook}.json`, `line/bin/{seat-queue,merge,merge-watch,route-retry,digest,record-bus,hook-listener}.sh`, `events/schema/event.schema.json:12`, git log (first commit 2026-10-10T18:16:43Z), grep for `software-factory`.
- `~/.claude/projects/-home-luna-projects-coq-jev-herdr-plugin/memory/`: `scheduler-team-recipe.md`, `bearings-v2-and-rime-locations.md`, `xml-specs-request-from-windows-agent.md`.
- GitHub repo list via `gh repo list jkkelley --limit 300` (196 repos, 2026-10-14). Google Drive search for "software factory" (2026-10-14): no thin-pointer doc found.

Incidental pointer for L12.
The owner's "forgeo" is very likely Forgejo, not software-factory.
Evidence: repos `jkkelley/cortex-hub` ("Forgejo self-hosted Git forge - design spec, GitOps manifests, and EKS Terraform", 2026-05-19), `forge-config`, `forge-gitops`, `forge-eks-infra` (all "Forgejo"), `bearings-core/deploy/forgejo`, and rime ADR-0003 and `deploy/forgejo/` (Forgejo chart 17.1.7, commit `737d48b`, 2026-10-06T02:37:58Z).
L12 should confirm.
