# L08 - Bearings, the owner surface

Investigator: area L08, step R-01 of the Factory Rebuild investigation.
Written 2026-10-14 UTC (investigation clock 02:3x UTC).
Read-only throughout; no bearings script, event script, line script or mutating herdr command was run.
The page key that appears in on-disk records is deliberately not reproduced here.

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

Bearings is the owner's decision page: a local Node server renders "cards" (About, Decide, 2 to 4 options, a recommended one, the owner's own words) from a `questions.json` file, takes the owner's answers and free-text messages into JSONL files, and a separate "wait" process turns each new answer or message into a line that is typed into an agent's pane.
It has had four lives in six weeks: the owner's `bearings` skill (Sep 15 2026), the `getting-my-bearings` (gmb) plugin and fleet runtime (Sep 15 to Sep 20), the `bearings-v2` design packet that turned into the `rime` bootstrap loop (Sep 21 to Oct 6), and the vendored `tools/bearings` in this repository (Oct 10 onward, 9 commits, VERSION 1.0.0).
Only the last is live: one stable server on port 44900 (pid 499443, up 13h32m at 02:3x UTC) plus one wait loop (pid 1849873).
The page's job is narrow and stable; what changed across the four lives is everything wrapped around it (who may write to it, what wakes on it, what feeds it).
The owner's own framing of its purpose, captured verbatim on 2026-09-21: "kind like what lavish is, but direct communication with the agent I choose" and "my own personal comms station" (V-10, V-19 in `~/Documents/investigations/bearings-v2-investigations/captures/V-2026-09-21-owner-vision.md`).

## 3. Where it lives

| Thing | Path | State at 2026-10-14 |
| --- | --- | --- |
| Live tool (vendored) | `~/projects/coq-jev-herdr-plugin/tools/bearings/` | 6733 lines across scripts, assets, config, tests; `assets/page.html` and `assets/theme.css` have uncommitted edits in the main checkout (`git diff --stat`: 79 insertions, 17 deletions) |
| Live page state | `~/.bearings/coq-stable/` | questions.json (1 open card C31), answers.jsonl (42), messages.jsonl (274 lines, 142 from the owner), files/ (7 screenshots) |
| Page tiers | `config/bearings.json` | stable port 44900, uat 44910-44919, dev 44920-44939 |
| Original skill | `~/.claude/skills/bearings/` | Sep 15 2026 snapshot, 547 lines of scripts, plus PLAN.md (123573 bytes), 77 manual-intervention rows, research, handoff briefs; not a git repo |
| gmb plugin and fleet runtime | `~/projects/getting-my-bearings` (main at c30f07f, 161 commits, 560 files, VERSION 0.3.0, tags v0.2.0 to v0.3.0) | last commit 2026-09-20T20:39Z; `gmb` still on PATH at `~/.local/bin/gmb` |
| gmb worktrees | about 50 under `~/projects/getting-my-bearings-*`, `~/projects/gmb-*`, `~/projects/getting-my-bearings/.wt/*`, `~/.bearings-dev/*` | triage of 2026-09-19 (docs/triage/worktrees-20260919.md): 48 worktrees, 9 landed, 39 holding something |
| bearings-core worktree | `~/projects/bearings-core-wk091` | empty directory, created Sep 20 19:44, nothing in it |
| bearings-v2 packet | `~/tools/bearings-v2` (120 commits, last 2026-10-06T08:08-05:00) | docs, streams and bash loop scripts; no application source; becomes `rime` |
| rime | `~/projects/rime` | Makefile, cmd, deploy, docs; 7 commits (not part of this area, noted because bearings-v2 became it) |
| Investigation of the bootstrap | `~/Documents/investigations/bearings-v2-investigations/` | NTSB-style report, findings F-*, owner vision capture V-01..V-62 |
| Execution rail skill | `~/.claude/skills/execution-rail/` | 50 lines of bash plus a locked HTML template; publishes to claude.ai artifacts, not to bearings |
| Board feeding the page | `report/loop/` (loop.sh 410 lines, `report/loop/out/index.html` + `data.json`), `line/bin/board.sh` | board refreshed at 02:34Z build number 1784 |
| Specs that bind the page | `specs/SPEC-17-orchestrator-and-agent-health.xml` s-owner, `tools/bearings/standards/STD-owner-comms-001.json`, `STD-owner-sitrep-001.json` | owner lane and health line defined in SPEC-17 lines 140-156 |

## 4. What works

- The page itself is the one durable success.
  The owner has used it as the primary channel for four days: 142 owner messages and 42 recorded card answers between 2026-10-10T18:14Z and 2026-10-13T22:49Z (`~/.bearings/coq-stable/messages.jsonl`, `answers.jsonl`).
- Reply latency is good when a seat is awake.
  Of the 112 owner messages that have a direct `reply_to` answer, the median lag is 32 seconds, p90 is 151 seconds, 85 were answered under 60 seconds, 2 took over 10 minutes, the maximum is 3299 seconds (computed from messages.jsonl by pairing `reply_to` ids; 30 owner messages have no direct reply_to and may have been answered in a batched reply, which this data cannot show).
- Persistence is file-based and simple, which is why it survives restarts and compactions: append-only JSONL, idempotent message ids (`server.mjs:455-495`, a repeated id returns the stored line), `delivered.json` as the consumed-set (`wait.mjs:63`, `wait.mjs:85-87`).
- The security and isolation model is small and sound: bound to 127.0.0.1, host allow-list, 128-bit key plus HttpOnly cookie, body caps from config (`server.mjs:333-340`, `config/bearings.json:5-18`).
- Tiers (stable, uat, dev) with separate state dirs and ports keep a feature page from touching the owner's page (`tools/bearings/AGENTS.md` "Tiers"; `config/bearings.json:28-52`).
  Test evidence: 135 Playwright cases pass in Podman for WO-20261013-b221 (`work-orders/archive/2026/WO-20261013-b221-*.md`, AC-H3).
- The owner's look is locked and re-used: Figtree, night theme, blue/violet/cyan accents; the skill's page and the vendored page differ only by additions (`diff` of `~/.claude/skills/bearings/assets/page.html` against HEAD shows the skill copy is the newer file with a card pager and attachments, i.e. the vendored copy lags the skill copy).
- The SITREP panel works as a render target: a `#SITREP/v1#` reply draws a colored status card, built from records by `scripts/sitrep-build.mjs` and gated by `scripts/sitrep-check.mjs` (commits 04b8ac7 and 78ae088; RUNBOOK.md).
  It is used rarely: 1 of 132 agent replies in messages.jsonl is a SITREP payload.
- The factory board is now served behind the same key at `/board` and `/board/data.json` (`server.mjs:363-378`, commit 4860361); the owner clicked through to it from the page on 2026-10-13T22:45Z.
- Clickable links in replies and a top-bar link to the Board were requested by the owner on 2026-10-12T19:19Z ("I should be able to click the links ... fuck the terminal") and exist as uncommitted edits in the main checkout (see section 5).
- Design lineage is rich and mostly written down: the original skill (Sep 15), gmb's governance, fenced roles and break-glass runbooks (INC-20260920-01), and the bearings-v2 requirements register (`~/tools/bearings-v2/DESIGN.md`) all agree on the same product requirements: one card at a time, durable and idempotent submission, persisted before acknowledged, distinguish accepted from consumed from completed, a replay on reconnect, and "do not interrupt the agent" (V-15).

## 5. What broke and why

Findings are ordered by how much they matter to a factory driven by a system rather than by agents.

1. The consumer of the owner's channel is an LLM seat, typed into by `herdr agent prompt`.
   `bearings.sh wait` loops `wait.mjs` and forwards each ANSWER or MESSAGE line whole into the pane named by `--to`, else `COQ_SEAT_PANE`, else `HERDR_PANE_ID` (`scripts/bearings.sh:193-207`).
   That means every owner message lands in the architect's context as a prompt.
   The owner named the consequence on 2026-10-13T00:07Z: "having every message to you instead of some kind of board is fucking you up", and "your the gate" at 01:09Z (messages m-20261013000711852-9w0d4, m-20261013010928541-9uv7s).
   Evidence disagrees with a "herdr is the problem" reading here: the delivery mechanics work (median 32 s); the defect is that the page has exactly one reader and it is an agent, so the owner's throughput equals one agent's context and attention.
2. The owner lane and health line are built and merged but dark.
   Commit c41afda (WO-20261013-b221, PR 92, status done) added `scripts/lib/owner.mjs` and `owner-page.html`, and the server only enables them when `cfg.owner_board` exists (`server.mjs:60-62`, `server.mjs:349-352`).
   `config/bearings.json` (56 lines) has no `owner_board` key (verified by grep across tools, report, line, config, specs), and the board directory it would read, `${state}/board` per `line/config/board.json:5`, does not exist under `~/.local/state/coq/coq-jev-herdr-plugin/`.
   The ticket's own acceptance criteria were proved only against fixtures in a test container (`tests/owner.sh`).
   Result: SPEC-17 hazard H19 ("The owner had to ask where the line stood") is marked replaced in the spec (SPEC-17 line 287) but is not replaced in the running system.
   Separately the running server (started 2026-10-13T13:00Z, `server.json` mtime 13:01Z) predates c41afda (2026-10-13T09:16-05:00 = 14:16Z), so it also runs code without the lane.
3. Cards reach the owner by an agent writing a file, one batch at a time.
   The only live card, C31 "Line speed" (`~/.bearings/coq-stable/questions.json`, mtime 2026-10-14T00:32Z), was written by `make ask`; `ask` replaces all cards (`tools/bearings/AGENTS.md` "Ask, wait, reply").
   There is no producer other than an agent turn, so a decision exists only if an LLM remembered to ask it.
   Ids C22..C30 appear in answers.jsonl, so the owner has answered promptly when a card existed (last answered C30 at 2026-10-13T18:17Z); the stall points are on the agent side.
4. The stable page stops itself.
   `idle_minutes` is 240 (`config/bearings.json:11`) and the server calls `shutdown("idle 240 minutes")` when no page load, answer, message or questions change touches it (`server.mjs:604-620`, `touch()` at `server.mjs:568`).
   The wait loop then exits on `stopped.json` (`bearings.sh:206`).
   Memory records the owner rule "Bearings stable is the only always-on monitor" and SPEC-17 s-owner line 153 says a halt leaves it running; nothing restarts it after an idle stop because the supervisor ticket WO-20261012-cf8d/WO-20261013-8e0c ("The supervisor keeps only bearings stable alive while the halt flag exists ...") is still `ready`, not built.
   The owner's monitoring surface is therefore the one component allowed to die quietly.
5. The factory board lied for six hours and nothing said so.
   On 2026-10-13T22:45Z the owner asked "is this a live view?" and the answer was "No. It froze at 16:24 UTC, six hours ago. The refresh loop kept running but every pass failed quietly" (m-c20261013224555780).
   The board build was then fixed by commit 55626f5 (WO-20261013-10d8, "Board watch posts a 500 and exits after 3 failed passes, and the patrol checks the board page age").
   Four minutes later the owner caught a second wrong number: "no way we have 17 lines running now" because the board counted every ticket marked in progress, including stalled and merged ones (m-20261013224920550-jsnf3; fix commit 3878c97 exists for the earlier version and a further fix was "ordered").
   The surface the owner trusts to avoid asking the architect was wrong twice in ten minutes, and the owner, not a system check, noticed.
6. Delivery to the agent is not acknowledged.
   `wait.mjs` writes `delivered.json` (`wait.mjs:85-87`) and exits; only afterwards does the shell loop run `herdr agent prompt` and, on failure, prints "bearings: wake not delivered" into its own pane (`bearings.sh:205-206`).
   The message is already marked consumed, so a failed prompt is never retried.
   I found no recorded instance of this loss in messages.jsonl (every owner message has a later agent reply or a batched reply), so it is a latent flaw by code reading, not an observed outage.
   It contradicts the bearings-v2 requirement "Do not equate socket delivery, terminal activity, or a submission acknowledgment with agent consumption" (`~/tools/bearings-v2/DESIGN.md`, "Communication and runtime").
7. History shows the owner surface was repeatedly deprioritised by the work that was supposed to serve it.
   The bearings-v2 investigation concludes "Bearings v2, your first sentence, was read as a workflow engine and deferred off the board" (F-PL6 in `report/REPORT-human.md`), and the owner's clarification was that Bearings is only the comms surface (V-10..V-17, `CORE-DESIGN.md` line 3-4).
   The packet then spent 790 minutes with 6 merges, 7 supersedes and 10 false re-dispatches on the loop (F-bottleneck.md), and no Bearings v2 application was ever written; `~/tools/bearings-v2` contains no application source and `REPLAN.md` section 4.6 still defers a "Bearings v2 design session" until after stream J.
   The WebSocket transport the owner accepted (`DESIGN.md`, "Communication and runtime") was never built; the live page still polls `/state` every 2 seconds (`assets/page.html:1213-1245`).
8. Scope sprawl in gmb made the surface heavy.
   gmb grew to 560 files and about 17 thousand lines of shell and JS around a 400-line page server (git ls-files, `wc`), added fenced role hooks, queues, panes, leases and a 4-hour full lockout (INC-20260920-01: "No agent had hands to clear any of it"), and its worktrees (about 50) hold unmerged work that was never decided (triage doc: the shared checkout alone held 9 commits, 277 files, +20,440 lines, on no remote at triage time).
   The owner's verdict on 2026-09-21: "Everything else GMB became is out of scope" (V-17).
9. The interface agent (the single reader the owner designated on 2026-10-10 at 18:22Z, "Only the interface agent gets this tool") has never been built.
   `work-orders/WO-20261010-329d/WO-20261011-e618-interface-agent-seat-owns-the-bearings-page-owne.md` is `draft`, updated 2026-10-14; `roles/interface-agent.json` exists as a role file (inputs `bearings.answer`, `bearings.message`, `record.factory`; `owner_channel: true`).
   Until it exists the architect is the owner's contact, which is the situation the owner has been objecting to since 2026-10-13T00:07Z.
10. Uncommitted edits sit in the main checkout on the owner-locked files, and they include non-requested reformatting.
    `git diff` of `tools/bearings/assets/page.html` shows the requested changes (Board link, solves list, clickable links) plus pure formatter churn (wrapped `if` bodies in the SITREP renderer), while `report/loop/RUNBOOK.md` states "no formatter, no hand edit that moves it off the design" for the board template, and `tools/bearings/AGENTS.md` says the page markup "is not changed here without an approved sample".
    The stable server re-reads `page.html` per request (`server.mjs:342-352`), so these edits are live on the owner's page without any PR, test or gate.
11. Credential hygiene: the page key sits in `~/.bearings/coq-stable/server.json` and was historically committed in six checkpoints before commit 4ee14cb and `rotate-key` (commit f0a6198, `bearings.sh:225-`); the owner's own messages also paste keyed URLs (m-20261013224508349-uup0t), so a keyed URL is in the page's own log.
    This is a lesser finding; it bears on any design that exports owner messages to other consumers.

Disagreement with the brief's diagnosis, stated plainly: for this area the evidence does not support "the owner surface is slow or flaky because herdr is used wrongly".
The transport works and is quick.
The weak points are (a) the only consumer of owner input is an LLM seat, (b) the producers of owner cards are LLM turns, (c) the system-side lane that was meant to replace both is merged but unwired, and (d) the displays the owner relies on have no self-check until a fix landed after the owner discovered the fault.

## 6. Waits, polls, sleeps and leases

| Where | What it waits on | Bound |
| --- | --- | --- |
| `wait.mjs:72` (`setTimeout(tick, 1000)`) | owner answer or message to appear in JSONL; also holds off `settle_ms` (3000) after the last write so typing bursts are batched | 1 s poll, 3 s settle, no upper bound (runs until `stopped.json`) |
| `bearings.sh:206` (`sleep 1`) | pause between wait.mjs runs in the pane loop | 1 s, loop ends only on `stopped.json` |
| `bearings.sh:206` (`herdr agent prompt`) | herdr queueing a prompt into a busy agent; lands at end of its turn | none visible; no ack back to bearings (finding 6) |
| `assets/page.html:1213-1245` | page polls `/state` every 2 s, and a 1 s clock tick (`page.html:256`) | 2 s, forever while a tab is open |
| `scripts/lib/owner-page.html:40-49` | owner-lane and health poll of `/state`, `poll_seconds` 2 (`lib/owner-board.json:4`) | 2 s; dark because `owner_board` is not configured |
| `server.mjs:604-620` | idle timer for the whole server | `idle_minutes` 240, checked every 60 s; then the stable page exits and the wait loop ends |
| `server.mjs` stop path (`stop_tries` 3, `stop_try_ms` 5000) | clean close of connections | 3 tries of 5 s, then forced exit (`config/bearings.json:13-14`) |
| `bearings.sh:137,239,241` (`sleep 0.25` in 60/40/20-iteration loops) | server up, server down, stopped.json written | 15 s, 10 s, 5 s |
| `bearings.sh:213-214` | C-c of an existing loop, then `wait-output` for a prompt | `--timeout 10000` |
| `report/loop/loop.sh:391` | board rebuild sleep, `watch_seconds` from `report/loop/config/board.json`; `poll_seconds + watch_seconds <= 30` is enforced at `loop.sh:61-68` | 30 s ceiling for a new record to show |
| board lease (`line/config/board.json`) | lease_seconds 1800, nudge_seconds 60, digest_seconds 1800, retention 30 days | owner lane items are never leased to a seat; they are drained by the page (SPEC-17 s-owner) |
| Original skill wait loop (`~/.claude/skills/bearings/RESTART.md` 3b) | page flap guard | at most 5 restarts, a page that dies within 1 minute counts as flapping (not in the vendored tool) |
| Owner reply lag (measured) | an awake architect reading its prompt queue | median 32 s, p90 151 s, max 3299 s |

There is no lease on a card or an answer in the live tool: an answer is consumed once by whichever wait loop reads it (AGENTS.md NEVER: "A second wait loop for one tier; one wait per page, or events are delivered twice").

## 7. Decisions an LLM makes that a rule could make

- Whether to ask the owner at all: today an agent decides to run `make ask` (`tools/bearings/AGENTS.md`).
  Rule: an item posted to the owner lane of the board (kind `request`, codes 300/423/503 per SPEC-17) renders as a card by itself; the page pulls it (`owner.mjs`, already built, needs `owner_board` configured and `board.sh` posting).
- What a card says: the architect writes About/Decide/options each time.
  Rule: build cards from a record template keyed by status code (the SITREP builder already does this for briefings: `sitrep-build.mjs` fills `config/sitrep.template.json` from tickets, events and PRs).
- Which message goes to which agent: all messages go to the one seat in `COQ_SEAT_PANE`.
  Rule: a router by prefix or tag on the message (or an explicit "to" field on the page) posting a `request.forwarded` 300 record to the right lane, with a seat woken only through the board nudge (`nudge_seconds` 60), as SPEC-17 already designs.
- What counts as a SITREP: the agent chooses when to send one.
  Rule: send a SITREP on a schedule or on a state change in the health file; the content is already script-built.
- When to restart the page or the wait loop after a stop: today an agent notices `STOPPED` or the owner reports it.
  Rule: the supervisor ticket WO-20261013-8e0c (still `ready`) plus a heartbeat check of the page (HTTP `/health` is already served, `server.mjs:379`).
- When to tell the owner a display is stale: found by the owner on 2026-10-13T22:45Z.
  Rule: the board page already has `at`/`number` fields (`data.json`); a staleness line computed on the page from `at` and `poll_seconds` needs no LLM.
- Whether a reply obeys the prose standard: the agent counts words by hand (STD-owner-comms-001 `check.how`).
  Rule: route every owner-facing reply through `sitrep-check.mjs`/a bubble linter in `reply.mjs` (the SITREP path is already enforced, the bubble path is not).

## 8. What to carry forward

- The page and its theme: it is the one artifact the owner has consistently accepted, and the requirements register is stable.
  Keep `assets/page.html` and `assets/theme.css` as the single front end, with the card/answer/message data model unchanged.
- JSONL plus idempotent ids plus a consumed-set: simple, auditable, survives compaction (`server.mjs:455-495`, `wait.mjs`).
- The owner-lane design in SPEC-17 s-owner and its already-written reader `scripts/lib/owner.mjs` (309 lines, caps, dedupe per ticket/kind/code, answer records mark done, bad items shown as problems).
  It is exactly the "system, not agent" path the owner asked for; it needs wiring, not rewriting.
- The health line as a pulled file read: a stale or missing file draws "not reporting" with the reason (b221 AC-H2), never an empty strip.
- The SITREP builder and checker (script-built, standard-checked): the model for every owner-facing summary.
- Tiers (dev/uat/stable) and the `make upgrade` promotion flow, plus the build-stamp self-reload (`server.mjs` comment at lines 18-27).
- The bearings-v2 requirement set as an acceptance list: durable-then-acknowledge, accepted vs consumed vs completed, bounded queues, replay on reconnect, no mid-turn interruption (`~/tools/bearings-v2/DESIGN.md`).
- F-decision-table from the bootstrap investigation: route every state through one JSON table with a loud default (R14), which fits the page's `request`/`bearings.*` input vocabulary.
- The gmb break-glass and incident write-up (INC-20260920-01) as the template for "owner-only, one time" recovery, already echoed in SPEC-17.

## 9. What to kill

- The idea that an agent reads the owner's page: replace with the owner lane plus a router (finding 1); the interface agent seat then reads only escalations, not the raw stream.
- `getting-my-bearings` as a runtime: 560 files, about 50 worktrees, fenced roles and 14 playbooks around a page server; the owner already declared the rest of it out of scope (V-17).
  Archive the repository and its worktrees after the triage's "Hold" items are decided; do not mine it for the fleet runtime.
  The only reusable pieces are the incident write-ups and the bearings module.
- The empty `~/projects/bearings-core-wk091` directory and the stale pages under `~/.bearings/` (`bearings-test`, `stable-442cf4`, `coq-uat-WO-20261010-ba08`, the Sep test dirs, `--help`): they are pure clutter.
- The "bearings v2 as Go/gRPC workflow engine" interpretation: the owner corrected it; the live part of that work is the status-code routing idea, not a second page.
- Idle shutdown on stable (`idle_minutes` 240): contradicts the always-on monitoring rule; keep it only on uat and dev.
- Hand-fed cards through `make ask` as the only producer.
- Hand edits to the owner-locked page in the main checkout outside a ticket (finding 10).
- Publishing owner-facing pages as claude.ai artifacts (execution-rail) as a parallel surface: the owner said lavish and artifact-link style pages are refused for status (STD-owner-comms-001 `bad[1]`), and the Rail depends on a manual republish step; fold its plan/ledger/step model into the board instead.

## 10. Open questions for the owner

1. Is the single owner surface the bearings page (cards, messages, board link) with every other page served from it, or do you still want a separate artifact surface for plans such as the execution rail?
   This changes whether the rebuild has one front end or two.
2. When you type a message on the page, should it be addressed to one named seat (interface agent, architect, orchestrator), to a router by rule, or only ever to the interface agent that raises escalations to the others?
   This decides the router design and removes the architect from the raw stream.
3. Is a transport upgrade to WebSocket (your accepted baseline in the bearings-v2 requirements) still wanted, given the polling page replies in a median of 32 seconds, or is polling at 2 seconds acceptable for the rebuild?

## 11. Sources

Files read (all local, all read only, dates are file or commit dates):

- `/home/luna/projects/coq-jev-herdr-plugin/tools/bearings/AGENTS.md`, `RUNBOOK.md`, `Makefile`, `VERSION`
- `.../tools/bearings/scripts/server.mjs` (lines 18-27, 60-62, 333-378, 455-495, 568-620), `wait.mjs` (lines 21, 63, 72, 85-87), `bearings.sh` (lines 137, 193-241), `reply.mjs`, `lib/owner.mjs`, `lib/owner-page.html`, `lib/owner-board.json`, `lib/config.mjs`
- `.../tools/bearings/config/bearings.json`, `config/bearings.schema.json`, `standards/STD-owner-comms-001.json`, `STD-owner-sitrep-001.json`, `assets/page.html` (and `git diff` of the uncommitted changes), `assets/theme.css`, `tests/owner.sh`
- `git log` of `tools/bearings` (9 commits: c0ea099, a22ad1c, 4ee14cb, f0a6198, 639704f, 4860361, 04b8ac7, 78ae088, c41afda)
- `/home/luna/projects/coq-jev-herdr-plugin/specs/SPEC-17-orchestrator-and-agent-health.xml` (lines 10, 44, 79, 140-156, 252, 287, 312, 335-352)
- `.../work-orders/archive/2026/WO-20261013-b221-roadmap-k6-the-owner-lane-on-the-page-bearings-r.md`
- `.../work-orders/WO-20261010-329d/WO-20261011-e618-interface-agent-seat-owns-the-bearings-page-owne.md`
- `.../work-orders/WO-20261012-cf8d/WO-20261013-8e0c-the-supervisor-keeps-only-bearings-stable-alive-.md`
- `.../roles/interface-agent.json`, `line/config/board.json`, `report/loop/RUNBOOK.md`, `report/loop/loop.sh`, `report/loop/out/data.json`
- `/home/luna/.bearings/coq-stable/` (server.json, session.json, questions.json, answers.jsonl, messages.jsonl, delivered.json, files.jsonl) and `~/.bearings/` directory listing
- `/home/luna/.claude/skills/bearings/` (SKILL.md, RESTART.md, docs/bearings-flow.md, scripts, assets, manual-interventions.jsonl, incidents.jsonl)
- `/home/luna/.claude/skills/execution-rail/` (SKILL.md, bin, runbooks)
- `/home/luna/projects/getting-my-bearings/` (README.md, AGENTS.md, git log, `git worktree list`, docs/incidents/INC-20260920-01-lockout.md, docs/design/bearings-core-v2.md, docs/observability-decision-20260919.md, docs/triage/worktrees-20260919.md)
- `/home/luna/projects/bearings-core-wk091` (empty), `/home/luna/projects/rime` (listing only)
- `/home/luna/tools/bearings-v2/` (START-HERE.md, CHECKPOINT.md, DESIGN.md, CORE-DESIGN.md, REPLAN.md sections 4.5 to 4.7, git log)
- `/home/luna/Documents/investigations/bearings-v2-investigations/` (README.md, report/REPORT-human.md, findings/F-bottleneck.md, findings/F-decision-table.md, captures/V-2026-09-21-owner-vision.md)
- `/home/luna/.local/state/coq/coq-jev-herdr-plugin/rebuild/2026/10/briefs/20261014-brief-B-investigation.md`
- Process table (`ps`) at 2026-10-14 02:3x UTC for pids 499443 and 1849873.
- No web sources were used for this local area.
