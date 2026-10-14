# L04 - herdr

Investigator: Sonnet seat for area L04, brief step R-01.
Written 2026-10-14T02:50Z (UTC), read-only investigation.
Main checkout read at commit 5ad1996.

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

herdr is a third-party open source (Apache-2.0, Rust, one binary) terminal workspace manager that hosts AI coding agents in panes, detects each agent's state, and exposes a CLI and a newline-JSON unix socket API (102 methods at protocol 22).
The owner has built four things around it: the 2026-09 operating manual `jkkelley/herdr`, a Windows-to-WSL sidebar bridge `jkkelley/herdr-wsl-agents`, the September stable (`jkkelley/stable`), and the October `herdr/` directory of the coq line (seat lifecycle, 36 monitor panes, supervisor, break glass).
The October line uses herdr as eight different things at once: terminal host, process launcher, service host, process supervisor, message bus, state store, screen scraper and test target.
Only the first two or three are jobs herdr was built for, and the owner's own September manual says so.
The pane-owning server is a single process, so one server crash kills every PTY it owns, which happened on 2026-10-13 at 03:32:18Z and left the line dark for 9.5 hours.

## 3. Where it lives

- Installed binary: `/home/luna/.local/bin/herdr`, version 0.9.0, file dated Sep 10 (`herdr --version`, `ls -la`). Upstream latest is v0.9.4 published 2026-10-13T15:41:22Z (GitHub API, fetched 2026-10-14).
- Server: user unit `~/.config/systemd/user/herdr-stable.service` running `herdr server --session stable`, `Restart=on-failure`, no `MemoryMax`, no `MemoryHigh`, `TasksMax=43284` (`systemctl --user show herdr-stable`).
- Session files: `~/.config/herdr/sessions/stable/{session.json,herdr-server.log,herdr-client.log,herdr.sock}`. Global config `~/.config/herdr/config.toml` holds `onboarding = false` and `[session] resume_agents_on_restore = false`.
- Line code: `herdr/bin/` in the main checkout, 19 scripts, 2871 lines (`wc -l`), plus 34 test cases and libs, 3084 lines. `herdr/config/{herdr,monitors,leases,exemptions}.json`, `herdr/layouts/`, `herdr/systemd/`, `herdr/RUNBOOK.md` (break glass), `specs/SPEC-04-herdr-seat-lifecycle.xml`.
- Callers outside `herdr/bin`: `factory/bin/route.sh` (herdr agent prompt as the wake), `line/bin/*`, `scheduler/host/bin/run.sh`, `tools/bearings`.
- Operating manual: `~/Documents/herdr` (clone of `github.com/jkkelley/herdr`, private, last push 2026-09-13, local branch `feat/alerter-reload` equals `origin/feat/alerter-reload`, PR 12 merged to main).
- `github.com/jkkelley/herdr-wsl-agents` (private, last push 2026-09-02), cloned to `investigation/clones/herdr-wsl-agents`.
- `github.com/jkkelley/stable` (private, last push 2026-09-16), cloned to `investigation/clones/stable`.
- Crash evidence: `~/.local/state/coq/coq-jev-herdr-plugin/crash/20261013T033218Z-herdr-stable/wsl-crash-1791862334-424-_home_luna_.local_bin_herdr-11.dmp`, 877 MB core.
- Upstream: `github.com/herdrdev/herdr` (43854 stars, 357 open issues, created 2026-03-27, pushed 2026-10-14; GitHub API 2026-10-14), docs `https://herdr.dev/docs/`.
- Live state at investigation time: 66 panes in 5 workspaces (`herdr --session stable pane list`), herdr process RSS 64.9 MB, 155 threads, 212 fds (`/proc/32412/status`), cgroup memory 19.1G with 4163 tasks (`systemctl --user status herdr-stable`).

## 4. What works

### 4.1 What herdr does that nothing else here can

- Agent state detection from the terminal for 20+ agents, via per-agent TOML detectors (`clones/herdr-wsl-agents/windows/config/herdr/agent-detection/remote/*.toml`, 20 files, `claude.toml` 218 lines) plus hook-reported state (`pane.report_agent`). Evidence: `~/Documents/herdr/manual/concepts.md` lines 24-37.
- One owner-visible surface: every process is a labelled pane the owner can see and type into. This is the stated reason for the herdr-first law (`AGENTS.md` line 184-193).
- PTY persistence across client detach and reattach (herdr docs session-state, fetched 2026-10-14).
- Server-side event-driven waits: `agent.wait --until done|blocked` and `events.subscribe` with kinds `pane.agent_status_changed`, `pane.exited`, `pane.agent_detected`, `pane.output_matched` (herdr docs socket-api, fetched 2026-10-14).
- Agent identity and resume reference: `pane list` keeps `agent_session.value` per pane, which is what let the 2026-10-13 restart resume seats with `--resume` (memory `herdr-crash-restart-order.md`).
- A plugin system with manifest actions and event hooks (`~/Documents/herdr/plugins/agent-monitor/herdr-plugin.toml`, `~/.config/herdr/plugins.json` lists herdr-file-viewer 1.16.0).
- Multi-machine view over saved SSH machines (herdr 0.9.1 release notes, fetched 2026-10-14). Not used by the owner.

### 4.2 What the owner's code gets right around it

- Every herdr call names its session and unsets inherited pane variables: `sl_h()` at `herdr/bin/seat-lib.sh` line 78, born from bearings-v2 F-14.
- Seat bring-up is idempotent and by label, never by id: `seat.sh` lines 642-695 (workspace create, tab create, pane split), SPEC-04 s-labels.
- The September manual's discipline is sound and shipped: scripts ask the server for truth, idempotent, exit non-zero with a reason, teardown proven by absence in `pane.list` (`~/Documents/herdr/manual/determinism.md`, `agents/RULES.md`).
- `herdr/RUNBOOK.md` break glass: one command, one authorisation, noclobber record, ttl 600 s (`herdr/config/herdr.json` line 42). Small, bounded, owner-gated.
- Supervisor design is correct in shape: a systemd timer, a lock, bounded steps, never starts herdr itself (`herdr/bin/supervisor.sh` header lines 1-31, `herdr/systemd/coq-supervisor.timer.in`). It is not installed (section 5.6).
- `seat.sh --down` kills the pane's whole process tree and checks the host, not herdr's word (commit 8d4eab5, WO-20261013-50a4 - Cause g).
- The suite runs real herdr servers headless in Podman with a bind-mounted binary, one session `t-<case>` per case (`herdr/tests/Containerfile` lines 1-5, `herdr/tests/lib/world.sh` lines 1-8). It is a true integration test and found real defects.

### 4.3 Where the owner and herdr agree

- September manual finding "state: outside-in polling of derived state is unreliable" matches the 2026-10-12 owner message that `agent_status` reads idle while a seat runs tools (`plans/2026/10/20261012212500-roadmap.md` line 204; `herdr/bin/turnwatch.sh` lines 14-17).

## 5. What broke and why

### 5.1 The 2026-10-13 03:32:18Z crash: the evidence disagrees with the brief and the records

The brief and the roadmap say herdr "died at 31.8G".
The evidence says the herdr process itself was small and the 31.8G is the whole systemd cgroup.

- systemd line: `herdr-stable.service: Main process exited, code=dumped, status=11/SEGV` at Oct 13 03:32:18, then `Consumed 1d 9h 45min 19.867s CPU time, 31.8G memory peak, 292.6M memory swap peak` (`journalctl --user -u herdr-stable`).
- The core is a SIGSEGV on the main thread, frame `#0 memcpy ()` with no further frames: the binary is stripped (`gdb -batch -c <dmp> /home/luna/.local/bin/herdr`). 180 threads in the core.
- Total size of the core's LOAD segments is 899,796,992 bytes, about 0.9 GB (`readelf -lW`). The current herdr process shows VmPeak 811,800 kB, VmHWM 159,036 kB, RSS 64,940 kB (`/proc/32412/status`).
- So the herdr process was roughly 0.9 GB virtual when it died. The 31.8G peak counts every child in the unit's cgroup: shells, claude seats (each 300-580 MB RSS, `ps`), and Podman test containers, whose output the journal shows at 03:32:00 running under the unit (`focused_merkle`, `inspiring_stonebraker`, `lucid_buck` container names in the same unit journal).
- Therefore "herdr leaked 31.8G" is not supported. What is supported: herdr 0.9.0 segfaulted in `memcpy`, with the machine at roughly 35 GB WSL memory limit (`.wslconfig` memory=36GB) under a parallel test load.
- The parallel case runner is not the cause: `bin/test-cases.sh` (WO-20261013-0bc0, commit 134af86) merged at 2026-10-13T15:59-05:00, which is 20:59Z, about 17 hours after the crash. The 03:32Z load was several seats each running whole suites in Podman at once (journal container names `focused_merkle`, `inspiring_stonebraker`, `lucid_buck`, `friendly_pascal` all active within the same minute).
- The test-speed design then cites the crash as the reason to cap JOBS (`plans/2026/10/20261013160000-test-speed-design.md` d-shape item 3). That caps test load; it does not address the herdr bug or the missing cgroup limit.
- Upstream shows the same signature class in the same version line:
  - `herdrdev/herdr#4174` (2026-09-15): 0.9.0 Linux server dies with heap corruption on a pty thread, all pane children die. Maintainer 2026-09-15: "a row full of links can corrupt memory when it scrolls ... fixed on master, not in 0.9.0".
  - `herdrdev/herdr#4762` (2026-09-29, open): server SIGSEGV in `terminal.Screen.cursorReload` during `Terminal.resize` on 0.9.1 Linux.
  - `herdrdev/herdr#3795` (open): pty master closed under a live agent pane.
  - `herdrdev/herdr#4287` (open): server fd growth, about 3.5 fds per minute after the partial fix. The owner's server holds 212 fds after 23 hours (`ls /proc/32412/fd`), not alarming.
- The installed 0.9.0 predates the memory-corruption fix and 0.9.4 notes "the server keeps running when the machine runs out of processes or threads, instead of taking every pane down with it" and session saves written before replacing the old file (v0.9.4 release notes, 2026-10-13).
- The crash site cannot be tied to #4174 or #4762 from this core: no symbols. The honest statement is "an unsymbolised memcpy SEGV in a six-week-old build with documented memory-corruption bugs".

### 5.2 Why one crash was 9.5 hours of darkness

- herdr owns the PTYs. A server stop loses every process: "Snapshot restore does not preserve running shells, servers, tests, or arbitrary processes" (herdr docs session-state, 2026-10-14). `KillMode=control-group` then SIGKILLs the rest (journal lines `Killing process 511 (zsh) with signal SIGKILL`).
- Global config sets `resume_agents_on_restore = false` (`~/.config/herdr/config.toml`, backup `config.toml.bak-20260914T0700Z`). The code justifies it: "resume_agents_on_restore stays false so nothing resumes silently" (`herdr/bin/recover.sh` line 24). So herdr's own native restore, the feature built for this exact case, is switched off, and recovery was by hand: ordered restart with `--resume <pane session id>` (memory `herdr-crash-restart-order.md`).
- The supervisor that was written to do this at boot and every 30 s is not installed: `systemctl --user list-timers` shows only `watchdog.timer` and `launchpadlib-cache-clean.timer`; `systemctl --user list-units 'coq*'` lists 0 units. `make supervisor-install` is "owner or architect, not a seat" (`herdr/Makefile` line 8). Retro of 2026-10-13: "nobody is watching" (`plans/.../20261012212500-roadmap.md` line 197).
- The dead man's switch failed because the patrol's own notes counted as records (roadmap line 227, maintenance brief cause b). The owner page, bearings, was a pane child and died with herdr (cause c).
- The only thing that did watch is `~/.cache/coq-watch/watchdog.sh` fired by `watchdog.timer` (header: "Interim outside the repo", `~/.config/systemd/user/watchdog.service`), which violates the repo's own rule that no script lives outside the repo (memory `scripts-live-in-the-project.md`).
- Same shape, earlier: September stable lost every agent on 2026-09-14T20:24:53Z (WSL VM under memory pressure) and twice on 2026-09-15 (wezterm heap corruption 0xc0000374 at 06:36Z, an unexplained WSL stop at 07:29Z) (`clones/stable/docs/runbooks/crash-recovery.md`, `docs/superpowers/handoffs/2026-09-15-overnight-crash-owner-restart.md`). The September answer was a script-only central monitor, "tattle-tale", that is "a script, never a model session" and starts first (`stable/README.md`, "The central monitor"). The October line rebuilt a supervisor and a patrol from scratch, and the patrol is an LLM seat (compliance-officer, Haiku, WO-20261013-5b33).

### 5.3 herdr is used as a message bus, and typed text is not a delivery

- `factory/bin/route.sh` wakes a seat with `herdr agent prompt <seat> "record <id> playbook <path>"` (header line 12; implementation `herdr_prompt()` line 205). In `herdr/bin` and `factory/bin` the CLI shows 24 `agent prompt` call sites (grep count).
- The herdr server log shows 88 `agent.prompt` calls in 71 minutes, 18 `agent.send_keys`, 10 `agent.start` (`~/.config/herdr/sessions/stable/herdr-server.log`, 01:30:17Z to 02:41:13Z).
- herdr's own docs say `agent.prompt` "proves delivery, not that a turn started", and a stalled or timed-out prompt "does not prove it was lost: read before resending" (`~/Documents/herdr/manual/concepts.md`, Prompting).
- Concrete losses on file: open issue 78 - "A merge wake sent to the one busy merger is lost: the belt downs the merger after its gate record for the PR it was working, and the queued PR is never merged"; open issue 76 - "route.sh never retries a failed route"; the architect flood of 2026-10-12 where each record became a typed prompt (`plans/2026/10/20261012222000-retro-architect-flood-and-halt.md`: 2,689 runtime files, the compaction resume notice six minutes late "behind the queue").
- The September manual rejected this: "Restart from failure means replay the file", the record is a file, panes only view it (`manual/determinism.md` rules table). The October line kept the file (records) and then also pushed a typed copy through a terminal.

### 5.4 herdr is used as a screen scraper and a polled database, not an event source

- The line does not use `events.subscribe`, `events.wait`, `agent.wait` or `pane.report_agent` anywhere in `herdr/bin`, `line/bin` or `factory/bin` (grep of those trees returned zero hits). It uses `pane read`, `pane list`, `pane process-info`, `agent get`, `pane wait-output`.
- SPEC-04 s-monitors line 45 says "The monitor seat subscribes to herdr events (pane.agent_status_changed, pane.exited, workspace.closed)". Built instead: `herdr/bin/turnwatch.sh` polls `pane read --lines 12` for each seat every `turn_poll_seconds` = 15 and greps the Claude Code footer: busy if `… \([0-9]+[ms]|Running…`, finished if ` for [0-9]+[hms].*done HH:MMZ` (lines 33-38). Its own breadcrumb: "a change of that footer silences it".
- Server load from this: in 71 minutes herdr logged 2968 `pane.read`, 1586 `pane.process_info`, 97 `agent.get`, and 4671 requests with `outcome="error"` (about 66 per minute), 98 percent of them `pane.read` and `pane.process_info` (`herdr-server.log`). herdr does not log the error code. A probe of a missing pane returns `pane_not_found` and produces an identical log line, so the likely cause is pollers addressing panes that no longer exist. This is an inference, not proven.
- The September manual states the replacement outright: "`events.subscribe` over the socket: one JSON line per state change, no polling" (`report/findings.tsv` row "events"), and "Gate on the marker ... never on agent_status" for completion (row "completion", `pane.wait_for_output` on the agent's own DONE line).
- Disagreement with the owner's wording: the brief and owner say "we're using herdr wrong". Evidence supports it for message passing, state and supervision. Evidence does not support blaming herdr for the crash alone (5.1).

### 5.5 Seat bring-up types a shell line and a prompt into a terminal

- `seat.sh` lines 795-813: `pane wait-output` for a shell prompt regex (15 s), `pane run` a long `cd ... && export COQ_SEAT=... PATH=...` line, `ensure_trust` edits `~/.claude.json`, `agent start --kind claude --pane ... -- --model --effort --permission-mode --settings`, then `agent prompt` with the brief, then a nudge. The environment of a seat rides one typed line.
- The brief is the whole contract (`roles/bin/brief.sh`), delivered as terminal input. If the TUI is busy or a dialog is up it is lost; the code logs "brief could not be sent; the monitor will re-prompt" (line 844).
- Guard ACK nudge: seat.sh waited up to 180 s for a line `● ACK compaction-guard ` that no seat printed, freezing the serial belt for 3 minutes per bring-up; fixed to 15 s with a schema cap of 30 (commit 3419b86, WO-20261013-7af7, `seat.sh` lines 747-768, issue 67).
- 24 of the last 246 commits (about 10 percent) since 2026-10-10 are titled "Cause ..." / "Pod fix" / "Main is red" fixes, 94 of 246 mention herdr, seat or pane, 47 commits touch `herdr/` in four days (git log since 2026-10-10 at 5ad1996). Each recent herdr-area fix carries a long breadcrumb about a timing or state race (for example commit 5ad1996: "herdr case 11-guard-ack-nudge passes in arm64 pods (herdr seen idle twice in 4s)").

### 5.6 herdr is used as the service host and supervisor

- `herdr/config/monitors.json` defines 4 tabs of 3x3 panes, 36 monitoring panes plus 3 seat panes per seat (test 03:20:16Z in the unit journal: "still 36 monitoring panes plus 3 seat panes"). Panes run: `route.sh run` (the belt), `flow.sh run`, `policy.sh run`, `loop.sh watch`, three blueprint HTTP servers, `turnwatch.sh`, `recwatch.sh`, `patrolwatch.sh`, `guardwatch.sh --watch`, `unfreeze.sh --watch`, and `while :; do ...; sleep 15; done` tails (`monitors.json`).
- `route.sh` says "run it in a labelled herdr pane, never as a background job" (line 8). The law behind it: "every long-running thing lives in a labeled herdr pane ... Never shell &, nohup, disown, setsid" (`AGENTS.md` lines 184-193, binding `AGENT_CONTRACT_HERDR_FIRST_v1.1.0`).
- Consequence: the belt, the routing state machine, and the owner page all die with herdr, because a pane is a child of the herdr process. Memory `bearings-stable-is-the-only-always-on-monitor.md` says the owner page is the one thing that must never stop, while the herdr-first law puts it in a pane.
- The unit cgroup is also the build farm: Podman test containers and `jenkins-mcp` containers appear in the same unit journal (03:31:01Z `podman ... container kill ... jenkins-mcp`), so tests, pods, agents and the multiplexer share one cgroup with no `MemoryMax`, 4163 tasks live (`systemctl --user status herdr-stable`).
- Compare September: the stable put only agents and a script-only monitor in herdr and the services on Kubernetes ("every service on Kubernetes", `stable/README.md` line 3).

### 5.7 Version pin held for a feature that no longer exists

- Memory `herdr-pane-graphics-live.md` (2026-10-10): pin herdr 0.9.0 because `pane.graphics.*` exists there and coq-term is built on it.
- herdr 0.9.2 (2026-09-29) removed it deliberately: "The Herdr-specific pane graphics API is gone ... Apps show images by writing standard Kitty graphics to their terminal, which Herdr renders natively" (v0.9.2 release notes). So the pin that keeps the owner on a build with documented memory-corruption bugs was for an API upstream replaced two weeks before the pin was recorded. The memory file itself says "v0.9.3 docs say removed".

### 5.8 Smaller faults

- `treehouse return --force` killed the parked test pane twice (memory `treehouse-return-kills-parked-shells.md`); seat.sh now checks slot processes (WO-20261011-36d7).
- Duplicate seats: two testers for PR 162 at 2026-10-13T23:36Z (`plans/2026/10/20261013-duplicate-work-audit.md` F1) because a pane list is the only truth and no lock sits in front of `seat.sh`.
- herdr test suite is slow: 27 cases, 74 fixed sleeps in 22 case files, the full serial suite 20-25 min (`20261013160000-test-speed-design.md` d-inventory, roadmap lines 304 and 338).
- Upstream open issue 4972: "Live handoff under a systemd user service kills all panes (or leaves the new server unsupervised)". Relevant when the owner updates herdr under `herdr-stable.service`: the safe path is a planned stop and restore, not `--handoff`.

## 6. Waits, polls, sleeps and leases

Every herdr-related block, with its bound. Config values from `herdr/config/herdr.json`.

| Where | Waits on | Bound |
| --- | --- | --- |
| `seat.sh` 804 `pane wait-output` | shell prompt in new pane | `prompt_timeout_ms` 15000, then dies exit 4 |
| `seat.sh` 813 `agent start` | claude process recognised | `agent_start_timeout_ms` 30000 |
| `seat.sh` 778 `pane wait-output` ACK | `● ACK compaction-guard ` line | `nudge_wait_seconds` 15 (was 180, cap 30) |
| `seat.sh` 779-786 settle loop | two idle reads of `agent_status` | `nudge_settle_seconds` 10, 1 s sleeps |
| `seat.sh` 828-834 | claude session file | `session_wait_seconds` 10, 1 s sleeps |
| `seat.sh` 370 | down grace | `down_wait_seconds` 3, `down_kill_tries` 3 x 2 s |
| `retire.sh` | agent exit | `retire_poll_seconds` 10 |
| `turnwatch.sh` 49 | forever loop | `turn_poll_seconds` 15, pane read per seat |
| `recwatch.sh` | forever loop | `record_poll_seconds` 10 |
| `patrolwatch.sh` | forever loop, wakes the Haiku patrol | `patrol_seconds` 60 |
| `guardwatch.sh --watch`, `unfreeze.sh --watch 30` | forever loops | 15 s and 30 s |
| `monitors.json` loops | `while :; clear; ...; sleep 15` (events, queue), 15 s (glass sweep), 60 s (board age), 10 s (supervisor log) | none, panes run forever |
| `supervisor.sh` | systemd timer `OnBootSec=20s`, `OnUnitInactiveSec=30s`, `flock -n`, step timeout 120 s | bounded, but timer not installed |
| `belt` (`route.sh run`) | poll loop, `belt.settle_seconds` 20, stale 60 | runs inside a pane; serial, so a blocking `seat.sh` stalls routing |
| break glass | owner answer, `ttl_seconds` 600, sweep every 15 s | bounded |
| `compaction-guard` lease | seat lease on compaction | see L01 |
| treehouse slot lease | `seat.sh` takes a slot per ticket | released at `--down`, see `herdr/tests/cases/08-treehouse-lease.test.sh` |
| herdr tests | `wait_until SECONDS CMD` 0.2 s polls (`world.sh`), 74 fixed sleeps before polls parts 1-4 | per case budgets in `config/tests.json` |

Every item above waits on a polled screen or process state or a clock, never on an event the system pushes. herdr offers pushed events for most of them (section 4.1).

## 7. Decisions an LLM makes that a rule could make

- "Is this seat idle, busy or finished?" Currently an LLM-adjacent screen read: `agent_status` (unreliable) or footer grep (`turnwatch.sh`). Rule: seat writes `work.started` and a terminal record, and hooks call `pane.report_agent` (`SessionStart idle`, `UserPromptSubmit working`, `Stop idle`, `Notification blocked`), exactly as `clones/herdr-wsl-agents/README.md` "The hooks map" already does. Then `agent.wait --until done` is event-driven.
- "Wake the seat that owns this record." The architect and orchestrator seats ruled on this by hand during the flood; the route table `factory/config/routes.json` now covers it. Remaining LLM step: re-prompting when `agent prompt` fails (`seat.sh` line 844 "the monitor will re-prompt"). Rule: a pull queue the seat reads on its own `Stop` hook, with an ack record; no typed prompt.
- "Is a dead pane a problem?" The compliance-officer Haiku seat patrols every agent screen and process each minute (WO-20261013-5b33). Rule: the supervisor compares `pane list` against the seat records, a pure set difference, and the 3-sightings card rule (maintenance brief cause e) is a counter.
- "Which seat does the work after a crash?" Done by the architect/orchestrator by hand on 2026-10-13. Rule: one `seat.sh --resume` per seat record whose `ended_at` is empty and whose pane has no agent, driven by the supervisor in dependency order (bearings, belt, watchers, orchestrator, workers), with the `agent_session.value` from `pane list`.
- "Does the test pane exist?" Seat refuses without a pane labelled `test - herdr` (memory `treehouse-return-kills-parked-shells.md`). Rule: seat.sh creates it (it does since commit 778e9df, WO-20261012-3cb1, `testpane.sh`).
- "Nudge or not nudge after the guard ACK?" The bound is a timer already (15 s). Rule exists; the rule is the problem (the ACK is never printed). Replace the whole branch with a Stop-hook driven continue.

## 8. What to carry forward

- The September manual's rules, as principles: ask the server, do not remember; the record is a file; wait for a state or an event, not a sleep; prove teardown by absence; a timeout is information, not a retry trigger (`~/Documents/herdr/manual/determinism.md`, `agents/RULES.md`). They are the field's reconciliation-loop idea and the owner wrote them first.
- `pane.report_agent` plus hook mapping from `herdr-wsl-agents/src/herdr-agent-state.sh` (87 lines): the correct way for a seat to state its own lifecycle.
- `events.subscribe` as the one monitor feed: `~/Documents/herdr/scripts/watch.sh` and `alerter.sh` (rules file reloaded on mtime) and the `agent-monitor` plugin manifest are working, tested code (`~/Documents/herdr/tests/alerter.sh`).
- The stable's central monitor: a script-only watcher that starts first, owns the inventory of what is watched, opens one case per problem per hour, and writes a recovery record of every target running, missing or off spec (`clones/stable/README.md`, `docs/runbooks/central-monitor.md`, commit 8f65899).
- The stable's failure-mode catalogue, 13 rows, each with detection, automated recovery, runbook and a chaos experiment (`clones/stable/docs/superpowers/specs/2026-09-14-failure-modes-catalogue.md`). FM-02 "Herdr socket or server gone" and FM-01 "Pane dies under an agent" are exactly 2026-10-13.
- Resume by session id from `pane list` (`herdr agent start <name> --kind claude --pane <pane> -- --resume <id>`) as the one recovery primitive.
- The break glass design (`herdr/RUNBOOK.md`) and the bounded supervisor design (`herdr/bin/supervisor.sh` header).
- The integration-test idea: a real herdr per case in Podman, bind-mounted binary. Keep it for the thin herdr adapter only.
- herdr itself for what it does: the owner's window onto agents, state display, PTY host, event source. Upgrade to 0.9.4 (see section 9 and 10).

## 9. What to kill

- Keeping `herdr 0.9.0` pinned. The pin reason (pane.graphics API) was removed upstream in 0.9.2, and 0.9.0 predates fixes for memory corruption on pty threads (#4174). Replace by a planned stop, upgrade, restore. Do not use `--handoff` under the unit (#4972).
- Typed prompts as the wake or message transport (`route.sh` `herdr_prompt`, `turnwatch.sh` prompting the architect, `recwatch.sh`). Records are the message; a pull or a hook-driven continue replaces the type-in.
- Screen scraping for state (`turnwatch.sh` footer regexes, `sl_pane_busy`, `patrolwatch` screen reads). Replace with `pane.report_agent` hooks and `events.subscribe`.
- The herdr-first law as written ("every watcher, poll, tail and server lives in a pane", `AGENTS.md` 184-193). Keep "every agent is a labelled pane the owner can see". Kill "every service": route runner, flow, policy, board, blueprint servers, bearings stable belong under systemd user units or on the cluster, with a pane that only tails the log for the owner.
- The 36-pane monitoring grid as a supervision mechanism (`herdr/config/monitors.json`, `monitors.sh` 275 lines, bringup judging panes by process). Keep one read-only dashboard pane at most.
- A supervisor that is an unregistered script (`supervisor.sh` is correct but uninstalled) and a watchdog in `~/.cache`. Replace by installed units owned by the repo (`line/units/` already has three hook units).
- `herdr/bin/seat.sh` as an 848-line shell program that types environment into a terminal. The seat contract (input, output, evidence, limits) belongs in a job spec run by a worker, with herdr only attached for the owner to watch.
- The parallel real-herdr test suite as a gate for every PR: 3084 lines of cases, 20-25 min serial, memory-heavy parallel, and the cause of the JOBS cap. Keep a small smoke slice.
- `resume_agents_on_restore = false` as a standing choice without a recovery owner: either turn it on (0.9.2 staggers restored agents 100 ms apart) or install the supervisor that resumes by session id. Having neither is what produced 9.5 hours.

## 10. Open questions for the owner

- Is herdr an owner-facing terminal window (agents plus panes you watch) or part of the control plane? The evidence says it is reliable as the first and fragile as the second.
- May the herdr server be restarted onto 0.9.4 in a planned window, accepting one full re-seat, now that the pane-graphics pin is moot?
- Should bearings stable and the belt move out of panes to systemd or the cluster, so a herdr crash cannot take the owner page and the router with it?

## 11. Sources

Local files and commands, all read 2026-10-14 UTC:
- `/home/luna/projects/coq-jev-herdr-plugin/herdr/{Makefile,RUNBOOK.md,bin/*.sh,config/herdr.json,config/monitors.json,systemd/coq-supervisor.timer.in,tests/Containerfile,tests/lib/world.sh}` at commit 5ad1996.
- `/home/luna/projects/coq-jev-herdr-plugin/{AGENTS.md,factory/bin/route.sh,specs/SPEC-04-herdr-seat-lifecycle.xml}`.
- Git log since 2026-10-10: commits 3419b86, 25b7c5c, 8d4eab5, 5ad1996, 134af86, 137260e, 778e9df.
- GitHub issues of `jkkelley/coq-jev-herdr-plugin`: 67, 76, 77, 78 (`gh issue list`, 2026-10-14).
- `/home/luna/.local/state/coq/coq-jev-herdr-plugin/plans/2026/10/`: `20261012212500-roadmap.md` (lines 197, 204, 227, 304), `20261012222000-retro-architect-flood-and-halt.md`, `20261013-duplicate-work-audit.md`, `20261013131747-maintenance-brief-crash-causes.md`, `20261013160000-test-speed-design.md`.
- `/home/luna/.local/state/coq/coq-jev-herdr-plugin/crash/README.md` and the 877 MB dump, opened with `gdb -batch` and `readelf -lW`.
- `journalctl --user -u herdr-stable` for 2026-10-13 03:30Z to 03:36Z; `systemctl --user status|show herdr-stable`; `systemctl --user list-timers`; `/proc/32412/status`; `~/.config/systemd/user/{herdr-stable.service,watchdog.service,watchdog.timer}`; `~/.wslconfig`.
- `~/.config/herdr/{config.toml,config.toml.bak-20260914T0700Z,plugins.json}` and `sessions/stable/herdr-server.log` (4991 lines, 01:30:17Z to 02:41:13Z).
- `~/Documents/herdr`: `README.md`, `PLAN.md`, `DEVIATIONS.md`, `agents/RULES.md`, `manual/{concepts,determinism,monitoring}.md`, `report/findings.tsv`, `plugins/agent-monitor/herdr-plugin.toml`, git history (cd5488f, 2026-09-12; 20 commits 2026-09-11 to 2026-09-12).
- Clones: `investigation/clones/herdr-wsl-agents` (commits 9110a70, 4003c86, 2026-09-02), `investigation/clones/stable` (200 commits, HEAD 4d60e5c 2026-09-16; `README.md`, `docs/runbooks/crash-recovery.md`, `docs/superpowers/handoffs/2026-09-15-overnight-crash-owner-restart.md`, `docs/superpowers/specs/2026-09-14-failure-modes-catalogue.md`).
- Memory files under `~/.claude/projects/-home-luna-projects-coq-jev-herdr-plugin/memory/`: `herdr-crash-restart-order.md`, `herdr-pane-graphics-live.md`, `treehouse-return-kills-parked-shells.md`.

Web and API, fetched 2026-10-14:
- `https://herdr.dev/docs/` (features index).
- `https://herdr.dev/docs/socket-api/` (method groups, event kinds, `agent.wait`, `pane.report_agent`).
- `https://herdr.dev/docs/session-state/` (restore, resume, snapshots, live handoff).
- `https://github.com/herdrdev/herdr` and `gh api repos/herdrdev/herdr` (stars, license, release list v0.9.0 2026-09-07 to v0.9.4 2026-10-13).
- Release notes v0.9.1 (2026-09-16), v0.9.2 (2026-09-29), v0.9.4 (2026-10-13) via `gh api repos/herdrdev/herdr/releases/tags/<tag>`.
- Issues `herdrdev/herdr#4174` (created 2026-09-15, closed same day), `#4762` (2026-09-29, open), `#4972` (2026-10-05, open), `#4287` (2026-09-17, open), `#3795` (2026-09-08, open), found with `gh search issues`.
