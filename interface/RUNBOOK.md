# RUNBOOK: hand the owner channel to the interface agent

## Contents

- Purpose
- What you need
- Hand over
- Verify
- What the architect does from now on
- Repair and take back
- Setting this up on another repository
- Limits
- GOOD and NEVER

Diataxis mode: **how-to**.
Last reviewed: 2026-10-12.
Ticket: WO-20261011-e618 - Interface agent seat owns the bearings page: owner requests become records and the done line comes from it.

## Purpose

Until this runbook is done, the owner talks to the architect seat in chat and the architect runs the bearings page.
After it, one read-only seat, the interface agent, owns the bearings page and is the only seat that talks to the owner.
An owner message on the page becomes a `request.forwarded` 300 record to the orchestrator within a minute.
A `verified` 201 record, or a `blocked` 423 that has already been escalated once, becomes one line on the page.
On the owner's request the seat renders a SITREP or copies the board, and says where the file is.
Every one of those is a script verb (`interface/bin/interface.sh`), so the seat does not compose records or pages by judgement.

## What you need

- A herdr session with the monitor seat up (seat.sh refuses any other seat while the monitor is down).
- `compaction-guard` on PATH (seat.sh refuses a Claude seat without it), `jq`, `node`, `podman` for the tests.
- `tools/bearings` configured with a `stable` tier whose `pane_label` is `bearings-stable` and `wait_pane_label` is `bearings-stable-wait` (`tools/bearings/config/bearings.json`).
  Those two labels are the two bearings panes in `herdr/layouts/interface-2x2.json`; if your config names them differently, change the layout labels to match.
- `roles/interface-agent.json` with `pane_layout` `interface-2x2` and `interface/bin/interface.sh forward|line|snapshot *` in `allow.commands`; then `roles/bin/render-playbook.sh roles playbooks` so the playbook agrees.
  The role file belongs to the architect.
- The route rows that address the seat are in `factory/config/routes.json`: `verified` 201 goes to `interface-agent`, and so does a `blocked` 423 that has already been escalated once (the first one goes to the architect).
  The route runner (WO-20261011-38c7 - Route runner: factory/bin/route.sh applies routes.json to every new record and nothing else) applies them; until it is running, the architect wakes the seat by hand with a herdr prompt that carries the record id (SOP-0004 shows the prompt shape).

## Hand over

1. Run the suite: `make -C interface test` and `make -C herdr test`, both from the labelled test pane. Both must end green before the page moves.
2. Stop the page where it runs now. From the tab that holds `bearings-stable`: `tools/bearings/scripts/bearings.sh stable stop`.
   The seat that owned it receives one `STOPPED` wake line; that is expected, not an incident, and `interface.sh forward` ignores it.
   Both bearings panes go back to `OPEN - any tool` slots; nothing is closed. The page's state directory is untouched, so the owner's messages survive.
3. Bring the seat up: `make -C interface up`.
   That runs `herdr/bin/seat.sh --role interface-agent --task "<interface/brief.txt>"`.
   seat.sh builds a tab named `interface` with four panes: the agent, `MONITOR - interface`, `bearings-stable` and `bearings-stable-wait`.
   Before the agent starts, the layout's `pre_start` lines run in the agent pane: serve the stable page with `--join` when it is not alive, then start the wait loop aimed at the agent pane.
   If a line does not finish within `prompt_timeout_ms`, seat.sh exits 4 and names the line; read the pane it names, fix the cause, run `make -C interface up` again.
4. Tell the owner once, in chat, that the page is now answered by the interface agent and that the URL has not changed (`tools/bearings/scripts/bearings.sh stable url`; never paste it into a record, a checkpoint or this file, it is a credential).
5. Stop talking to the owner (next section).

## Verify

Each check is one command and one expected result.

| Check                                   | Command                                                                                                                                  | Expected                                                                                                                           |
| --------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| Seat is up, read only, panes in its tab | `make -C interface check`                                                                                                                | no output, exit 0; `jq -r .permission_mode roles/interface-agent.json` prints `dontAsk`                                            |
| Bearings panes are in the seat's tab    | `herdr pane list` and look for `bearings-stable` and `bearings-stable-wait` in the tab labelled `interface`                              | both present                                                                                                                       |
| An owner message becomes a record       | the owner posts `ping` on the page; then `events/bin/event.sh list --code 300`                                                           | a `request.forwarded` 300, `seat` `interface`, `to` `orchestrator`, note `m-...: ping`, within 60 seconds, and no architect action |
| A verified record becomes a page line   | `events/bin/event.sh add --code 201 --seat tester-<x> --kind verified --ticket <WO> --note "..."`, then wake the seat with the record id | one reply under the owner's last message: `<WO> - <full title> - verified 201: ... (<record id>)`                                  |
| A snapshot is published                 | ask the seat for a SITREP                                                                                                                | a reply `snapshot: <path>` with the Windows path under WSL, and the file exists                                                    |

The script suite proves the same contracts without a live page: `make -C interface test` (five cases) and, for the seat and its panes, `herdr/tests/cases/12-interface-seat-bearings-panes.test.sh`.

## What the architect does from now on

The architect stops addressing the owner in chat.
To tell the owner something, the architect writes a record and wakes the interface agent with its id (the route table does this itself only for a 423 that was escalated once, so the architect's own record is woken by hand):

```sh
events/bin/event.sh add --code 423 --seat architect --kind blocked --to interface-agent --ticket <WO-ID> --note "what the owner must decide, 240 characters or fewer"
```

The seat turns it into one line naming the ticket and its full title.
A decision with options becomes a card (2 to 4 options and a recommendation) through `tools/bearings/scripts/bearings.sh stable ask`, which the seat is allowed to run.
The owner's replies reach the architect only as `request.forwarded` records addressed to the orchestrator.

## Repair and take back

- The wait loop died or the seat's tab is wrong: `make -C interface down`, then `make -C interface up`. pre_start runs only when the agent is started, so a live seat is repaired by a down and an up.
- The page is not answering: `tools/bearings/scripts/bearings.sh stable status --json` (do not paste its output; it carries the URL with the key).
- Take the channel back: `make -C interface down`, `tools/bearings/scripts/bearings.sh stable stop`, then serve the page from the architect tab with `serve --join` as before.
- A record posted twice for one message cannot happen: `forward` finds the record whose note starts with the message id and prints it; `line` finds the reply carrying the record id and says it is already there.

## Setting this up on another repository

Copy these paths; none of them names this repository.

- `interface/` (the verb script, its tests, `brief.txt`, `Makefile`, this file).
- `herdr/bin/seat.sh`, `herdr/bin/seat-lib.sh`, `herdr/layouts/interface-2x2.json`, `herdr/layouts/layout.schema.json` (it knows `pre_start`).
- `roles/interface-agent.json`, `roles/bin/render-playbook.sh`, `roles/bin/brief.sh`, `playbooks/interface-agent.md`.
- `events/bin/event.sh` and `events/schema/event.schema.json` (they carry the factory kinds, `--to`, and `COQ_EVENTS_ROOT`).
- `tools/bearings/` with its `stable` tier configured.
- `report/sitrep/` for SITREP snapshots; `report/loop/` for the board (optional: `snapshot board` exits 6 until a board has rendered).
- `factory/config/routes.json` rows for `interface-agent`, if the repository runs the route runner.

Then follow "Hand over" from step 1.
A repository with its own bearings tier name, project name or port changes `tools/bearings/config/bearings.json` and the two layout labels, nothing else.

## Limits

- A page line is a bearings reply threaded under an owner message, because bearings has no unsolicited line API and bearings code changes are outside this ticket.
  With no owner message on the page yet, `interface.sh line` exits 6 rather than invent one; the owner posts one message first.
- A snapshot is announced as a file path (and its Windows form), not a clickable http link, because a bearings reply carries text only.
  Serving the file from the page is a bearings change and belongs after the north star.
- The seat's `must` lines in `roles/interface-agent.json` still describe it writing the request record itself; it runs `interface.sh forward` instead, as `interface/brief.txt` tells it.
  Aligning that wording is the architect's edit.

## GOOD and NEVER

GOOD: the architect tells the owner something by writing a record with `--to interface-agent` and waking the seat with its id, so the seat turns it into one page line naming the ticket and its full title.
GOOD: a down seat or a dead wait loop is repaired with `make -C interface down` then `make -C interface up`, because `pre_start` runs only when the agent is started.
GOOD: `make -C interface check` exits 0, and `bearings-stable` and `bearings-stable-wait` show in the tab labelled `interface`, before the channel is called handed over.
GOOD: the suites `make -C interface test` and `make -C herdr test` run from the labelled test pane and end green before the page moves.
NEVER: paste the output of `bearings.sh stable status --json`, because it carries the page URL with the key.
NEVER: let the architect answer the owner in chat once the seat is up, because the owner's replies reach the architect only as `request.forwarded` records.
NEVER: compose a record or a page line by judgement in the seat, because `interface.sh forward|line|snapshot` finds the existing record or reply first and a hand-written one posts twice.
NEVER: edit `roles/interface-agent.json` from this runbook's seat, because the role file belongs to the architect.
