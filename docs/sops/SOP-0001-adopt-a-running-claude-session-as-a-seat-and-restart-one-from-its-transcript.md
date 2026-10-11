# SOP-0001: Adopt a running claude session as a seat, and restart one from its transcript

## Contents

- Purpose
- When to run this
- Steps
- Verification
- GOOD and NEVER

Diataxis mode: **how-to**.
Last reviewed: 2026-10-11.

## Purpose

The owner can order a live session to become a role's seat with everything the day put in its context (DEC-architect-becomes-interface-agent), and a seat can be restarted from a transcript. seat.sh --adopt does the bookkeeping of a seat-up and starts nothing; seat.sh --resume starts claude with --resume. Ticket: WO-20261011-8fb3 - seat.sh adopt: a running claude session becomes a seat in place, keeping its context, under the role's label, settings and record. An adopted agent was started by hand, so its environment has no COQ_SEAT, COQ_ROLE or COQ_EVENTS_ROOT: it posts records with an explicit --seat, and --audit matches it to its seat by pane and cannot compare its flags.

## When to run this

The owner orders a live claude session into a role's seat without losing its context, or a seat has to be re-started from a session transcript in a fresh pane.

## Steps

1. Read the session id of the pane being adopted: `herdr agent get <pane> | jq -r .result.agent.agent_session.value`. Inside that session the pane id is `$HERDR_PANE_ID`.
2. Adopt it from any shell in the same herdr session: `herdr/bin/seat.sh --adopt --role <role> --pane <pane> --session <session id>` (add `--ticket <WO>` for a role whose label carries a ticket token). seat.sh names the herdr agent for the role, labels the pane with the layout's agent label, writes `seat.json` (marked adopted, with the session id and what the pane was called before) and the role's `settings.json` under the state directory, and records `seat.up` 100 with a note that starts `adopt:`. It types nothing into the pane, so the session keeps its context, model and permission mode.
3. Expect a refusal (exit 3) for a pane with no claude agent, a session id herdr contradicts, a name another agent already holds, or a second pane for a role that already has its seat. A rerun with the same pane repairs the name, label and settings and records nothing twice.
4. The layout's other panes and `pre_start` lines are not built. Anything the role's layout would have put in the seat's tab, such as the bearings panes for the interface agent, stays where it already is; point its wait loop at the adopted pane yourself.
5. The owner changes the session's model and permission mode in the pane when they want the role's values. The rendered `settings.json` binds the seat at its next start.
6. To restart the seat from the same conversation, end the session and run `herdr/bin/seat.sh --role <role> --task "<text>" --resume <session id> --worktree <the checkout the session ran in>` (door 2), or `herdr/bin/seat.sh --ticket <WO> --role <role> --resume <session id>` (door 1). claude starts with `--resume <session id>` under the role's model, effort, permission mode and settings, and its first prompt is one line saying the session was resumed, not the full brief. Claude Code looks a session up under the directory it is started in, so pass the original checkout as `--worktree`; a door 1 seat that leases a fresh slot may be told there is no such conversation. `--resume` is refused (exit 3) for a runtime other than claude.
7. To take an adopted seat back: `herdr/bin/seat.sh --down <seat name>`. It gives the agent its old name and the pane its old label back, retires the record and records `seat.down` 100. It never runs `/exit`, closes a tab or returns a slot, so the session keeps running.

## Verification

A step that cannot be verified is a wish.
Record what the successful run actually printed.

Observed in `herdr/tests/cases/13-adopt.test.sh` and `14-resume.test.sh` against a headless herdr with a stub claude:

- `herdr/bin/seat.sh --check <seat name>` prints nothing and exits 0 with the agent running; it exits 1 and names the difference when the settings drifted or the pane label changed.
- `herdr/bin/seat.sh --audit` prints `COMPLIANT <pane> <seat name> pid <n> (adopted: mode and settings apply at the next restart)` for the adopted agent.
- `herdr/bin/seat.sh --down <seat name>` exits 0, the pane's process id is the one it was before the adopt, and `events/bin/event.sh list --code 100` shows one `seat.up` and one `seat.down` for the seat.
- A restart with `--resume` shows `--resume <session id>` after `--settings <path>` in the pane's process argv.

## GOOD and NEVER

GOOD: the owner orders the architect session into the interface seat, and `seat.sh --adopt` names that same pane, so the conversation and its context carry on unchanged.
GOOD: `--session` is read from `herdr agent get <pane>`, so the id the seat record keeps is the one herdr sees.
GOOD: a seat that has to be restarted gets `--resume <session id>` and `--worktree` set to the checkout the session ran in.
NEVER: `seat.sh --adopt` to start an agent, because it starts nothing; a pane with no claude in it is refused, exit 3.
NEVER: `retire.sh`, a tab close or `treehouse return` on an adopted seat, because that ends the session the adoption exists to keep; `--down` is the way out.
NEVER: trusting `--audit` to check the flags of an adopted agent, because it was started by hand and only the next start applies the role's settings.
