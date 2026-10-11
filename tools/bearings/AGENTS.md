# tools/bearings - the owner's decision page

## Contents

- What this is
- Tiers
- Run it
- Ask, wait, reply
- The factory board
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
| `scripts/reply.mjs`          | appends the agent's reply to `messages.jsonl`                           |
| `scripts/lib/config.mjs`     | loads, validates and interpolates the config; resolves a tier           |
| `assets/page.html`           | the owner's page (vendored, one null-guard breadcrumb at the list handler) |
| `assets/theme.css`           | the owner's theme                                                       |
| `config/bearings.json`       | every tunable                                                           |
| `config/bearings.schema.json`| the contract for that file                                              |
| `tests/`                     | Containerfile (digest-pinned), run-tests.sh, inside.sh, probe.mjs, debug-probe.sh |
| `VERSION`                    | this tool's version, bumped on promotion                                |
