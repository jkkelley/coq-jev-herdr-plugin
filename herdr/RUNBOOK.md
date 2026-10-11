# RUNBOOK: break glass

## Contents

- Purpose
- The rules
- The records
- The flow, end to end
- Ask for one
- Verify
- When something goes wrong
- What it never does
- GOOD and NEVER
- Limits

Diataxis mode: **how-to**.
Last reviewed: 2026-10-11.
Ticket: WO-20261011-4562 - Break glass: one owner-authorised action at a time flips one seat to bypass permissions and back, recorded, never a session or a day.
Decision: `DEC-break-glass-one-time` (locked 2026-10-11 18:42Z).

## Purpose

A seat sometimes needs the one command its role denies: a merge, a force push, a slot destroy.
Until now the only way through was the architect running it by hand, outside every record.
Break glass is the owner's lever for exactly that: the owner says yes to one named command for one named seat, the seat runs it, and the role comes back.
It is a script path, `herdr/bin/seat.sh --break-glass`, never a hand edit of a settings file.

## The rules

1. Only the owner authorises, on the bearings page.
   The owner's answer is a line in the page's `answers.jsonl` whose id is the request's record id, whose choice is `Grant`, and whose card text names the seat and the exact command.
   `seat.sh` reads that line itself.
   A `break.glass` 200 record is a notice, never the authority.
2. One action per authorisation, never a session or a day.
   The answer is used once: `<state_dir>/break-glass/<request id>.json` is created with noclobber and is never deleted, so a second use of the same answer is refused 423.
3. The action is one plain command.
   No newline, `;`, `&`, `|`, backtick, `$(` or `*`.
   A multi-step fix is a script, and the script's path is the action.
4. For that one command the seat runs with bypass permissions, and a second command is still denied (below).
5. The role settings come back when the command's follow-up record lands or after `break_glass.ttl_seconds` in `herdr/config/herdr.json` (600, at most 3599), whichever is first.
6. A seat that keeps bypass after that is a `seat.stalled` 500 from `seat.sh --audit`.
7. Every one is a record, and the board shows each as a row.

## The records

All are kind `break.glass`.
The record's `seat` is the seat the glass is broken for, whoever wrote it.
`action` is the one command.
`answer` is the id of the 300 request, which is also the id of the owner's card.

| Code | Meaning                                  | Written by                                                          |
| ---- | ---------------------------------------- | ------------------------------------------------------------------- |
| 300  | request                                  | the seat or the architect: `events/bin/event.sh add --kind break.glass --code 300 --seat <seat> --action "<command>"` |
| 200  | granted by the owner                     | `interface/bin/interface.sh forward` on the owner's answer           |
| 423  | refused                                  | the interface agent on a Refuse, or `seat.sh` on any refusal, with the reason in the note |
| 100  | in effect                                | `seat.sh --break-glass`                                              |
| 201  | the one command finished                 | `herdr/bin/break-glass-guard.sh post`, the hook                      |
| 204  | role settings restored and verified      | `seat.sh --break-glass-restore`                                      |

## The flow, end to end

1. The 300 request is written.
   `factory/config/routes.json` sends it to the interface agent as a decision (`notify_owner`, line `decision`).
2. The interface agent runs `interface/bin/interface.sh line --record <id>`, which puts a Grant or Refuse card on the bearings page.
   Refuse is preselected, so Grant is never the default.
3. The owner answers on the page.
   The interface agent runs `interface.sh forward` on the answer wake: `Grant` becomes a 200, anything else a 423.
4. The route runner sees the 200 and runs `herdr/bin/seat.sh --break-glass <seat> --record <200 id>` (route `do: break-glass`).
   `seat.sh` takes the seat and the command from the 300 request, not from the 200, and refuses 423 unless every check below holds.
5. `seat.sh` rewrites the seat's `settings.json`: bypassPermissions, the deny rules that cover the command removed, the command allowed, and a PreToolUse and PostToolUse hook on Bash.
   It keeps the role's own copy at `<state_dir>/seats/<seat>/settings.pre-break-glass.json`, writes 100, and prompts the seat with the record id and the command.
6. The hook lets exactly that command through once.
   Any other command that holds the head of a lifted rule (for `gh pr merge *` the head is `gh pr merge`) is blocked with exit 2, and so is the same command a second time.
7. When the command finishes the hook writes 201 and asks `seat.sh --break-glass-restore` to put the role back, which writes 204.
   If that did not happen, the watcher pane `glass` (slot 2.3.1 in `herdr/config/monitors.json`) runs `seat.sh --break-glass-sweep` every 15 seconds and restores any break glass whose 201 landed or whose ttl passed.

`seat.sh` refuses 423, changing nothing, when: the record is not a break.glass 200 or 300; a 200 carries no `answer`; the request is for another seat or another command; the action is not one plain command; the page has no answer for the id, or it is not `Grant`, or its card text does not name this seat and this command; the seat is down; or the answer was already used.

## Ask for one

```sh
events/bin/event.sh add --kind break.glass --code 300 --seat <seat> --ticket <WO-id> \
  --action "gh pr merge 17 --squash" --note "why the role cannot do this"
```

Then stop and wait; the owner's answer arrives as the 200.
Do not run the command, do not edit `settings.json`, do not send prose to another agent.

## Verify

| Check                                  | Command                                                              | Expected                                                                                          |
| -------------------------------------- | -------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| The suite, from the labelled test pane | `make -C herdr test` and `make -C factory test` and `make -C report/loop test` | all green; `herdr` case 13, `factory` case 08 and `report/loop` case 08 are this feature |
| A break glass is active                | `herdr/bin/seat.sh --check <seat>`                                   | exit 1, one line `break glass <id> active until <UTC>: settings differ from the role by design`  |
| It is over and verified                | `herdr/bin/seat.sh --check <seat>`                                   | no output, exit 0                                                                                 |
| Nothing kept bypass                    | `herdr/bin/seat.sh --audit`                                          | no `break glass ... kept bypass` line; an active one reads `COMPLIANT ... (break glass <id> until <UTC>)` |
| The board shows it                     | the `Floor` section of the factory board                             | a `break glass` table with a row per request and its state                                        |
| It is on the log                       | `events/bin/event.sh list --json \| jq 'select(.kind == "break.glass")'` | the 300, 200, 100, 201 and 204 of the request, or the 423 and its reason                       |

The live proof (AC-H1) is done once on a real seat, with the owner's answer: the command runs, the same command a second time and another command in its territory are refused by the hook, and `--check` is clean afterwards.
The suite proves the file, the hook and the records; it does not run a real Claude Code.
If a running Claude Code does not re-read `--settings` on change, the symptom is a seat that still reports the role's deny for the command: say so in a `blocked` record and stop, do not work around it.

## When something goes wrong

| Symptom                                      | Cause                                                                 | Do                                                                                       |
| -------------------------------------------- | --------------------------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| A 423 with `no owner answer`                 | the owner has not answered, or the card was never put on the page     | run `interface.sh line --record <300 id>`; ask the owner; write a new 300 only if the old one is closed |
| A 423 with `already used`                    | that answer has been spent                                            | a second action needs a new 300 and a new answer                                          |
| `break glass ... past its ttl` in `--check`  | the sweep watcher is not running, or restore failed                   | `herdr/bin/seat.sh --break-glass-restore <seat> --why manual`, then bring the `glass` pane back with `herdr/bin/bringup.sh` |
| A 500 `did not verify after the restore`    | the role file changed during the break glass                          | `seat.sh --down <seat>` and bring it up again                                             |
| The hook blocks a harmless command           | the command contains the head of a lifted rule, even in a string      | run it after the restore, or ask for it in the request                                    |

## What it never does

- It never grants without an owner answer on the page, whatever the records say.
- It never lasts: no session, no day, no standing elevation.
- It never covers a second command or a non-Bash action.
- It never edits a role file, `specs/`, `graph/` or any file but the seat's own `settings.json`.

## GOOD and NEVER

GOOD: the architect writes a 300 for `gh pr merge 17 --squash`, the owner grants on the page, the merge runs, `--check` is clean a minute later.
GOOD: a second merge needed? A second 300, a second answer.
NEVER: a 200 record written by hand to get a command through; `seat.sh` reads the page and refuses it.
NEVER: widening the action with a `*` or a `;`; split it into a script and name the script.
NEVER: leaving a seat in bypass "until the work is done"; the ttl is the longest it lasts.

## Limits

- A running Claude Code is assumed to re-read `--settings` and its hooks on change; see Verify.
- The ttl is checked by the sweep every 15 seconds, so a restore can be that late.
- Only the newest 24 requests show on the board, and an expired but unrestored break glass reads `in effect` there; `seat.sh --audit` is what calls it out.
- The interface agent's card and verdict need `interface/bin/interface.sh` from the interface agent ticket (WO-20261011-e618 - Interface agent seat owns the bearings page: owner requests become records and the done line comes from it).
