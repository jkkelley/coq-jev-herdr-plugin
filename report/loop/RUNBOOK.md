# Runbook - the factory board on a repository

## Contents

- Rules that bind
- What this is
- What you get
- Needs
- 1. Put the tool in the repository
- 2. Edit `config/board.json`
- 3. Look before you serve
- 4. Keep it current
- 5. Serve it
- 6. Prove it
- Changing the page
- When it goes wrong
- Graph

## Rules that bind

- The page is drawn from records, tickets, roles, routes, the herdr pane list and the belt state file; no value on it is typed in.
- The watcher runs in a labelled pane, never detached.
- The template is owner-locked: no formatter, no hand edit that moves it off the design.
- The config is the only thing a second repository changes.

GOOD: `report/loop/loop.sh watch` in a labelled monitors pane, `out_dir` gitignored, `board_dir` in the bearings config pointing at the same path.
GOOD: a new record shows on the open `/board` within 30 seconds, with every folded line still folded.
NEVER: `loop.sh watch &`, `nohup` or `setsid`; a background watcher is invisible and reads as nothing happening.
NEVER: a hand-written station state, seat count or bar in `data.json`; fix the record or the ticket that it comes from.
NEVER: running the prettier hook over `assets/template.html` or `design/`; the page stops matching the design byte for byte.

## What this is

This sets up the factory board (WO-20261011-616c) so the open page shows the lines on the factory floor, drawn from the records.
A reader who has never seen this repository can do it on another one by editing one config file.
Nothing on the page is typed in: every value comes from event records, ticket files, role files, the routes table, the herdr pane list and the route runner's state file.

## What you get

One page, `index.html`, and the data behind it, `data.json`, written into a directory (`out_dir`).
A server hands both to the owner: `GET /board` and `GET /board/data.json`.
The open page asks `data.json` every `poll_seconds` and redraws in place, keeping every folded line and every sideways scroll.
A watcher rewrites the two files every `watch_seconds`, and only when the floor changed.
A record therefore shows within `poll_seconds + watch_seconds`, which the config keeps at 30 seconds or less.

## Needs

- bash, jq, awk, sed and python3 with `jsonschema` (the lint image of this repository has all of them).
- Event records, one JSON file each, under `YYYY/MM/<utc>-<code>-<suffix>.json`, with `at`, `code`, `seat`, `kind`, `ticket`, `pane`, `note`.
- Ticket files named `WO-*.md` whose frontmatter between the first two `---` lines is JSON with `id`, `title`, `status`, `branch`, `pr`.
- Role files `roles/<role>.json`, a routes table (`routes.json`), and a playbooks directory.
- A herdr session whose workspace holds the seats' panes; without herdr the page says "HERDR PANES UNAVAILABLE" and trusts the seat records alone.
- A server that can hand a directory to the owner at `/board` (bearings does, see "Serve it").

## 1. Put the tool in the repository

Copy `report/loop/` into the other repository, or leave it where it is and point it at the other tree with `LOOP_ROOT=<repo>` and `LOOP_CONFIG=<config>`.
Either way the tool reads nothing outside the config's paths.

## 2. Edit `config/board.json`

Every key is described in `config/board.schema.json`, and `loop.sh` refuses a config that breaks it.
These are the ones to change:

| Key                                    | What to set                                                                                                                                |
| -------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| `out_dir`                              | Where `index.html` and `data.json` are written, relative to the repository root. Gitignore it.                                             |
| `poll_seconds`, `watch_seconds`        | Between 5 and 30 each, and their sum at most 30.                                                                                           |
| `actor`                                | Who the page says built it.                                                                                                                |
| `inputs.*`                             | Where the records, tickets, roles, routes, playbooks, herdr config and the belt state file are, relative to the repository root.           |
| `inputs.belt_max_age_seconds`          | How old the route runner's state file may be before the belt reads as stopped.                                                             |
| `inputs.owner_pane_label`              | The label of the pane that serves the owner's page; while it is in the pane list the owner station reads live.                             |
| `line_statuses`                        | A ticket in one of these statuses is a line on the floor.                                                                                  |
| `stations`                             | The stations in order: an `id`, the `role` file it belongs to (null for a station with no seat), what it `does` and the record it `emits`. |
| `kickbacks`                            | The lanes drawn behind the line. Each names the row of the routes table it draws, and a lane naming no row is refused.                     |
| `board`, `board_title`, `legend_notes` | The tickets the build board tracks, its heading and the legend notes. The bar of each ticket follows its status.                           |

The page carries no project name and no absolute path, whatever the config says, and the entry is validated against `schema/loop.schema.json` before anything is written.

## 3. Look before you serve

```sh
report/loop/loop.sh collect --out /tmp/entry.json   # derive the entry from the records and validate it
report/loop/loop.sh render --in /tmp/entry.json --out /tmp/board
```

Open `/tmp/board/index.html` as a file.
It draws what it was built with and shows "page offline", because there is no server to ask.
The same entry can also be checked alone: `loop.sh validate <file>`.

## 4. Keep it current

```sh
report/loop/loop.sh watch
```

This collects every `watch_seconds` and rewrites `out_dir` only when the entry changed apart from its time and build number.
Unchanged, it touches no file, so a file that moved means the floor moved.
It prints one line per build or failure and nothing otherwise.
A pass that cannot read its inputs says so and keeps the last good page; fix the input and the next pass recovers.
The build number is kept in `out_dir/.watch.json`.

Run it in a labelled pane, never detached.
In this repository that is the monitors grid: `herdr/bin/monitors.sh take board board -- report/loop/loop.sh watch`, which `herdr/bin/bringup.sh` does for slot 2.2.1.
Elsewhere any terminal you leave open will do; do not use `&`, `nohup` or `setsid`.

## 5. Serve it

Bearings serves it: set `board_dir` in `tools/bearings/config/bearings.json` to the same path as `out_dir`, and restart the tier.
`make -C report/loop lint` fails when the two differ.
The owner opens the bearings link and then `/board`; the key and cookie of the bearings page cover both routes.
A board that was never built answers 503 `board not built`.

Any other server works if it serves `index.html` at a path `P` and `data.json` at `P/data.json`, because the page asks `<its own path>/data.json`.

## 6. Prove it

```sh
make -C report/loop test           # 7 cases, Podman, no network: schema, render, parity, derive, by-hand, board, watch
make -C report/loop test-browser   # a real browser against the real bearings server: pixel parity with the design, redraw in place
make -C report/loop lint
```

Then do the three checks by eye:

1. Collect with no hand value: the entry validates, and a ticket whose `pr.opened` record exists shows its work at the tester.
2. A PR in a ticket's frontmatter with no `pr.opened` record shows "opened by hand" on the worker station.
3. Open `/board`, post a record (`events/bin/event.sh add ...`), and watch the page change within 30 seconds without reloading.

## Changing the page

The page is `assets/template.html`; its markup and style are the owner-locked design (`design/loop-design-iteration-5.html`).
Do not let a formatter touch it: the repository's `.prettierignore` opts the template and `design/` out of the global prettier hook, and a re-indented template no longer matches the design byte for byte.
`make -C report/loop test-browser` fails on a pixel difference.
After any template change run `loop.sh render` (or restart the watcher after deleting `out_dir/index.html`) so the served page is rebuilt.

## When it goes wrong

| You see                                                      | It means                                  | Do                                                          |
| ------------------------------------------------------------ | ----------------------------------------- | ----------------------------------------------------------- |
| `GET /board` answers 503 `board not built`                   | the watcher never wrote `out_dir`         | start `loop.sh watch`                                       |
| `GET /board` answers 404                                     | the bearings config has no `board_dir`    | set it, restart the tier                                    |
| the page says "page offline"                                 | the page's last ask of `data.json` failed | check the server and the key link                           |
| the page's time is old but "page live"                       | nothing on the floor changed since        | nothing; the time is the last change, not the last look     |
| "HERDR PANES UNAVAILABLE"                                    | herdr did not answer                      | start herdr; seats are trusted from their records meanwhile |
| `loop: ...: poll_seconds + watch_seconds must be 30 or less` | the config breaks the 30 second promise   | lower one of them                                           |
| the watcher prints `pass N failed`                           | a ticket or record could not be read      | read the line under it, fix the file                        |

## Graph

The tool is the node `CMP-factory-board` and this runbook is `RUN-factory-board`, joined by a `defined_in` edge.
`make lint` fails when a new Component node has no `defined_in` edge to a Runbook node; see `graph/config/component-runbook-grandfathered.json` for the older Components that have not got one yet.
