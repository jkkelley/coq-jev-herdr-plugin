# AGENTS.md

## Contents

- What this repository is
- Golden rule: checkpoint every step, compact early
- Hard rule: the first 100 lines route
- Hard rule: dated entry files, one file per entry
- Law: the bus is NATS JetStream, the control plane is gRPC, status codes drive it
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

TODO: FILL THIS IN

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
<tree>/YYYY/MM/YYYYMMDD-<descriptive-name>.<ext>
```

`YYYY`, `MM` and `YYYYMMDD` are the UTC date the entry was written.
`<descriptive-name>` says what the entry is, in under 50 characters, lowercase, words joined by `-`.
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

## Law: the bus is NATS JetStream, the control plane is gRPC, status codes drive it

Owner decision, 2026-10-10 UTC: the producer-consumer model runs on NATS JetStream, gRPC carries only the synchronous control plane, and routing is by status code (SPEC-01 s-codes, SPEC-03 routes.json).
Every component is a black box behind a subject: it consumes messages, emits a record with a code, and never reaches into another component.
Adding behaviour is a routes row and a consumer.
The file queue in `queue/` is the offline fallback only, until WO-20261010-539f lands the bus (graph node DEC-nats-jetstream-grpc).

GOOD: a seat waits as a durable pull consumer and is woken by the publish, with no polling loop.
NEVER: a second broker, gRPC streaming for events, or a component that reads another component's state directory to decide what to do.

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
