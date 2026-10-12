# SOP-0003: Run the supervisor that keeps herdr, the panes, the belt, the owner page and the seats up

## Contents

- Purpose
- When to run this
- Steps
- Verification
- GOOD and NEVER

Diataxis mode: **how-to**.
Last reviewed: 2026-10-12.

## Purpose

Three outages on 2026-10-12 (a herdr restart, a WSL reboot, a suspend) each needed the architect by hand: restart the owner page, notice six monitor panes that bringup called ok, unstick hung commands, re-seat two seats whose claude had crashed (WO-20261012-b800 - Supervisor: at boot and every minute a process brings herdr, the belt, the watches, bearings and the seats back, judging each by its process, not its label, and re-seats a seat whose claude died). The supervisor is one script a systemd timer runs, so the line stands without an architect.

## When to run this

Setting up a host, after changing herdr/bin/supervisor.sh or herdr/config/herdr.json supervisor keys, when a pane, a seat or the owner page is down and nobody restarted it, or when the supervisor itself looks stopped.

## Steps

1. Install once, from the main checkout, by the owner or the architect (a seat renders into a scratch directory and stops): `make -C herdr supervisor-install`.
   It renders `herdr/systemd/coq-supervisor.service.in` and `.timer.in` into `~/.config/systemd/user/` with this checkout's path and the directories of `jq`, `herdr`, `treehouse`, `node`, `podman` and the rest, runs `daemon-reload` and `enable --now coq-supervisor.timer`.
   It refuses to run from a treehouse slot (exit 3), because a slot is returned when its ticket closes and the unit would point at a deleted tree.
   Lingering must be on (`loginctl show-user $USER -p Linger` says `yes`; it already is for `herdr-stable.service`), or the user manager does not start at WSL boot and neither does the timer.
2. What a tick does, every 30 seconds after the previous one ends and 20 seconds after boot: `herdr/bin/supervisor.sh`.
   The halt flag (`~/.local/state/coq/HALT`) stops it before anything else.
   Then, in order: herdr answers (when it does not, `systemctl --user start herdr-stable.service`; the supervisor never forks a server), `podman ps` answers (when it does not, `podman system migrate`), `bringup.sh` (control plane, guard doctor, the monitors grid, the monitor seat, every reserved pane judged by its process), `belt.sh --apply`, the owner page and its wait loop, then the seats.
   Every step is killed after `supervisor.step_timeout_seconds` (120), every command a step runs after its own `supervisor.timeouts.*` key, and the tick as a whole after 420 seconds, so a hung command costs one tick and never a stuck supervisor.
3. A reserved monitor pane (the slots of `herdr/config/monitors.json`, including the watches in tab 4) is healthy when its label is its owner's and herdr shows a process in the foreground that is not the shell.
   `herdr/bin/monitors.sh health` prints `ok NAME` or `FAILED NAME (why)` for each.
   A dead command is plugged in again by `monitors.sh take`; a slot labelled open under a job someone is running is left alone and reported (`left alone`), never typed into.
4. A seat is dead when its pane is gone or herdr shows no claude or codex in the pane's foreground.
   The supervisor must see it dead on two ticks at least `supervisor.reseat.grace_seconds` (20) apart, skips a seat whose record is younger than `up_seconds` (90) or whose `seat.sh --down` holds a fresh `down.lock`, and never touches an adopted seat or the monitor seat (bringup's).
   Then it reruns `seat.sh --ticket T --role R` (door 1) or `--role R --task ...` (door 2): the pane, the treehouse lease and its owned flag are kept, a fresh claude starts, gets the ticket brief and `seat.sh` records `seat.up`.
   A seat whose ticket is archived, done or cancelled is downed instead.
   After `max_per_window` (3) re-seats of one seat in `window_seconds` (1800) it stops and says so with a 500: a claude that dies every time is for a person.
5. The owner page: when `bearings.sh stable status --json` says the server is not alive, the supervisor runs `serve --join` with the session, model and working-on of `session.json`, then `wait --to architect`, in the tab that holds the page's panes (else the architect's tab).
   The page's key is never printed or logged.
   A page stopped on purpose (`stopped.json` says `stopped`, is newer than the herdr server, and no pane carries the label) is left alone.
6. Read it: `make -C herdr supervisor-status` (the timer and the last tick), `journalctl --user -u coq-supervisor -n 50`, the `supervisor` slot (4.1.3 in the watches tab), `events/bin/event.sh list --seat supervisor`.
   `make -C herdr supervisor CHECK=1` runs one tick that changes nothing and exits 1 when anything FAILED.
7. Stop it on purpose: `touch ~/.local/state/coq/HALT` (ticks do nothing until it is removed) or `make -C herdr supervisor-uninstall`.
8. After installing, the interim watchers from `~/.cache/coq-watch/` must go: `turn-watch.sh` sits in slot 2.3.1 and is released by `glass` on the first apply, `record-watch.sh` was in 2.3.2, which the policy watch owns since WO-20261012-9b2c, so release its pane with `herdr/bin/monitors.sh release <pane>` or it keeps prompting beside the repo's `recwatch` (two prompts per record) until bringup takes the slot back.

## Verification

A step that cannot be verified is a wish.
Record what the successful run actually printed.

Observed 2026-10-12 in `herdr/tests/cases/17-pane-health`, `18-watches`, `19-supervisor`, `20-reseat` and `21-supervisor-units` against headless scratch herdr sessions (not the live `stable` session), run as `make -C herdr test` from the worker seat's test pane:

- A reserved pane whose command was interrupted turned `FAILED events (pane <id> is a bare shell, ...)` in `monitors.sh health` within 15 seconds while `monitors.sh status` still showed its label in use; `bringup.sh --check` printed `FAILED pane-events` and judged the panes after it; `bringup.sh` printed `fixed pane-events` and the same pane ran it again.
- A slot labelled open under a running job was reported `left alone` (exit 1, one 500 record, no second record on the next run) and the pane after it was still repaired.
- `supervisor.sh` on a world with the page down printed `fixed bearings (server and wait loop restarted, waking architect)`; the stub `bearings.sh` was called with `serve --join --session <id> --model <m> --working-on <w>` under the architect tab's `HERDR_TAB_ID` and no `COQ_SEAT`; the page's key appeared in no line of the tick or its log.
- A tick with the herdr server stopped printed `fixed herdr (started coq-test.service)` (one `systemctl --user start` call); two more ticks later the exit was 0 and nothing was left to fix.
- A seat whose claude was ended with `/exit` was `skipped` on the first tick and `fixed seat-<name> (claude had been gone Ns, seat.sh started it again ...)` on the second: same pane, a claude in its foreground, one more `seat.up 100`, the brief's `Playbook playbooks/worker.md` on its screen, `ended_at` still null.
- The third death inside the window was `FAILED seat-<name> (claude died again after 2 re-seats in 1800s ...)`, exit 1, one 500 record and no agent started; a seat on a `done` ticket was downed; a seat holding a fresh `down.lock` was not judged.
- A step made to hang (`.belt.status` = `sleep 100`) was `FAILED belt (killed after 5s)` and the bearings step after it still ran; the tick took under 40 seconds.
- `supervisor-units.sh render` wrote a `Type=oneshot` service with `ExecStart=<checkout>/herdr/bin/supervisor.sh`, a PATH holding the directory of `jq`, and a timer with `OnBootSec=20s` and `OnUnitInactiveSec=30s`; from a linked worktree it exited 3 and wrote nothing.

The three live checks are the ticket's human criteria, run on the host after `make -C herdr supervisor-install`:

- AC-H1: find a reserved pane with `herdr/bin/monitors.sh status`, interrupt its command (`herdr --session stable pane send-keys <pane> C-c`); within 60 seconds `monitors.sh health` prints `ok` for it again and `events/bin/event.sh list --seat supervisor` shows `fixed pane-<name>`.
- AC-H2: end a seat's claude (`herdr --session stable agent prompt <seat> /exit`, or kill the process); within 120 seconds `seat.sh --check <seat>` exits 0, a `seat.up 100` record names it, and the pane shows the ticket brief.
- AC-H3: `wsl --shutdown` from Windows, open a new shell; within 3 minutes `herdr/bin/bringup.sh --check` prints `ok` for every node and `make -C herdr supervisor-status` shows a tick after boot.

## GOOD and NEVER

GOOD: a pane's command dies, the next tick restarts it in the same pane, and the log has one `fixed pane-<name>` line.
GOOD: `make -C herdr supervisor CHECK=1` before and after a change to the supervisor, to see what it would do with nothing changed.
GOOD: a seat that crashes three times is a 500 and a person reads its pane.
NEVER: start the herdr server from the supervisor or from a seat; `systemctl --user start herdr-stable.service` is the only start.
NEVER: put `compaction-guard recover --apply` in a tick; it resumed other projects' sessions and flooded the architect with memos on 2026-10-12.
NEVER: install the units from a treehouse slot, or edit the rendered units by hand; change the `.in` files and render again.
NEVER: print or log the owner page's url; it carries the key.
