# RUNBOOK: operate the Go scheduler

## Contents

- Purpose
- The rules
- Build and test
- Bring up
- Status
- Modes: off, shadow, active
- Parity
- Rollback
- When something goes wrong
- GOOD and NEVER
- Sources

Diataxis mode: **how-to**.
Last reviewed: 2026-10-12.
Ticket: WO-20261012-df2b - Scheduler host files: the pane wrappers for the container and the executor, the inbox script, a test harness with a stub binary, and the operations runbook.
Graph node: `RUN-scheduler-operate`.
Every step names the spec section it comes from in brackets; the specs live under `specs/scheduler/`.

## Purpose

The scheduler routes the small loop and the software factory from the record log, in place of the bash belt.
It is two processes from one binary (DEC-scheduler-two-processes):
the **scheduler**, in a rootless Podman container with no network and no host tool, decides;
the **executor**, on the host in its own pane, acts, and only through the verb table in `scheduler/config/executor.json`.
They talk over one unix socket, mode 0600; nothing listens on TCP [SPEC-16.H h-proto-sockets].
This runbook brings both up, reads their state, moves the mode from off to shadow to active, and rolls back.

## The rules

1. Every build, test and lint runs in Podman through `make -C scheduler <target>`; no Go toolchain runs on the host [SPEC-16.H h-build-rule].
2. Both processes live in labelled herdr panes, never under `&`, `nohup` or a harness background job [SPEC-16 l-herdr].
3. Every value comes from `scheduler/config/scheduler.json`, `scheduler/config/executor.json` or the environment the files name; nothing is typed by hand into a podman line [SPEC-16.H h-run-wrapper, SPEC-16.G g-vars].
4. The executor comes up before the scheduler, and the scheduler before any seat [SPEC-16 l-first, SPEC-16.H h-pane-gate].
5. The mode moves off, then shadow, then active, and active only after parity exits 0 [SPEC-16.J j-parity-verdict].
6. Records are written only by the executor's record verb, through `events/bin/event.sh`; nobody writes a record file by hand [SPEC-16 l-writer].

## Build and test

| What                                     | Command                            | Where it runs              | Source                         |
| ---------------------------------------- | ---------------------------------- | -------------------------- | ------------------------------ |
| the static binary into `scheduler/dist/` | `make -C scheduler build`          | the digest-pinned Go image | SPEC-16.H h-t1                 |
| every Go test, network off               | `make -C scheduler test`           | the test image             | SPEC-16.H h-t2, SPEC-16.K k-t5 |
| vet and the format check                 | `make -C scheduler lint`           | the Go image               | SPEC-16.H h-build-targets      |
| the runtime image: one binary, no shell  | `make -C scheduler image`          | Podman                     | SPEC-16.H h-t6                 |
| the host wrappers and the inbox script   | `bash scheduler/host/tests/run.sh` | the repository lint image  | SPEC-16.H h-t7                 |
| the config files against their schemas   | `make lint`                        | the repository lint image  | SPEC-16.G g-t6                 |

A good run of the host suite ends with `tests: N passed, 0 failed`.
The executor runs the binary `make -C scheduler build` wrote, so build before every executor restart that should pick up new code.
The scheduler runs the image `make -C scheduler image` built, so rebuild the image before a scheduler restart that should pick up new code.

## Bring up

The environment both panes need, exported by the pane's shell or the supervisor's unit:

| Variable              | What it is                                        | Read by                                                        |
| --------------------- | ------------------------------------------------- | -------------------------------------------------------------- |
| `COQ_REPO`            | the repository on the host (`host_repo`)          | both                                                           |
| `COQ_HERDR_SESSION`   | the herdr session the executor addresses          | both                                                           |
| `COQ_SCHED_STATE_DIR` | the scheduler's state directory                   | the scheduler                                                  |
| `COQ_SCHED_MODE`      | `off`, `shadow` or `active`                       | the scheduler                                                  |
| `XDG_RUNTIME_DIR`     | the runtime directory holding the executor socket | both                                                           |
| `COQ_SCHED_REPO`      | the repository as the container sees it (`repo`)  | set by `run.sh` to the repository's mount point, never by hand |

The names are the `${ENV:...}` references in the two config files; the files are the authority, and this table follows them [SPEC-16.G g-vars, SPEC-16.H h-run-env].
`run.sh` passes every name `scheduler.json` references into the container with the pane's value, plus `HOME`, and refuses with exit 3 when one is unset.
The container's own settings are plain strings in `scheduler.json`, with no variable: `runtime.image` (the image by digest), `runtime.memory` and `runtime.container_name` [SPEC-16.G g-keys].
After `make -C scheduler image`, repin `runtime.image` to the new digest, or `run.sh` refuses with exit 4 because the pinned image is not in local storage.

1. **Executor first.**
   Its monitors grid slot runs `scheduler/host/bin/run-exec.sh`, which is `make -C scheduler run-exec` [SPEC-16.H h-pane-two, h-pane-cmd].
   The wrapper checks the binary and `executor.json` are there, creates the socket's directory with mode 0700, and execs `scheduler/dist/scheduler exec`; the pane's exit code is the executor's [SPEC-16.H h-executor].
   It is up when its pane shows the listening line and Health answers [SPEC-16.F f-executor].
2. **Scheduler second.**
   Its slot runs `scheduler/host/bin/run.sh`, which is `make -C scheduler run` [SPEC-16.H h-pane-cmd].
   The wrapper refuses to start while the executor socket is missing, then runs the container in the foreground: rootless, network none, user namespace keep-id, an init process, the memory limit, the image by digest, removed on exit, and a fixed name so a second start is refused by Podman [SPEC-16.H h-run-flags].
   Every host path the scheduler reads is mounted at the same path it has on the host, so the configuration resolves the same on both sides: the repository and every intake root read-only, the state directory read-write, the executor socket's directory, the halt flag's directory read-only, and nothing else from the home directory [SPEC-16.H h-run-mounts].
   A path with a `:` or `,` in it cannot be a podman mount, and `run.sh` refuses it with exit 3.
   Intake root patterns are expanded when the wrapper starts; restart the scheduler pane after the treehouse pool grows, or a new slot's log is not read [SPEC-16.A a-roots].
3. **Bring-up gates.**
   `herdr/bin/bringup.sh` refuses the scheduler slot while the executor's Health fails, and seats while the scheduler's Health fails [SPEC-16.F f-sup-exec, SPEC-16.H h-pane-gate].
   The supervisor restarts either slot by running its command again; no new verb exists for it [SPEC-16.F f-supervisor].
4. **Stop.**
   A stop from the pane (Ctrl-C, or the supervisor's restart) reaches the binary, which drains: no new job, running jobs get `drain_seconds`, state is written, exit 0 [SPEC-16.F f-drain, SPEC-16.H h-run-signal].
   Never `podman kill` the container; a killed scheduler leaves running jobs for discovery at the next start instead of finishing them.

Until WO-20261012-fa36 - Scheduler cut-over (see Modes below) wires the two grid slots, put each process in a monitors slot through the monitors script, executor first: `herdr/bin/monitors.sh take <slot> <label> -- make -C scheduler run-exec`, then the same with `run` [SPEC-16.H h-pane-two].
`take` refuses a slot another job holds, so a second scheduler never starts beside the first.

## Status

- `make -C scheduler status STATE_DIR=<the scheduler state directory>` asks the control socket and prints mode, start gate and reason, belt age, last tick, boundary, table versions, executor health, counters and lists [SPEC-16.I i-status-what].
- It exits 1 when the belt is stopped or the start gate failed, 0 otherwise; scripts branch on the code [SPEC-16.H h-cli-exit].
- The belt flag of the status subcommand prints only the bash runner's belt words, so the supervisor's belt check reads the scheduler unchanged after cut-over [SPEC-16.I i-status-belt].
- Every line about a record carries its id: search the id in the scheduler pane and the executor pane and the two together are the record's whole story [SPEC-16.I i-trace-rule].
- A quiet pane is normal: the scheduler logs one line per change and nothing per empty tick [SPEC-16.I i-log-when].

## Modes: off, shadow, active

The mode is `COQ_SCHED_MODE` in the scheduler pane's environment; `scheduler.json` reads it through a variable, and the scheduler only reads it at start, so a change is a restart of the scheduler pane [SPEC-16.J j-mode-values, SPEC-16.G g-reload-not].

| Mode     | What it does                                                                   | What it may run                                                              | Source                              |
| -------- | ------------------------------------------------------------------------------ | ---------------------------------------------------------------------------- | ----------------------------------- |
| `off`    | answers Health and Status, nothing else                                        | nothing                                                                      | SPEC-16.J j-mode-values             |
| `shadow` | decides every record and writes one decision file per record into `shadow.dir` | only observation verbs: agent_list, pane_read, pane_process_info, seat_quiet | SPEC-16.J j-mode-gate, j-mode-verbs |
| `active` | decides and acts                                                               | every verb in the table                                                      | SPEC-16.J j-mode-values             |

**Into shadow.**

1. Point `COQ_SCHED_STATE_DIR` at a state directory of the scheduler's own, never the bash belt's: shadow has its own boundary, ledger, jobs and belt and runs beside the belt on the same log [SPEC-16.J j-shadow-state].
2. Set `COQ_SCHED_MODE=shadow` and restart the scheduler pane.
3. Status says shadow with the gate passed; decision files appear in `shadow.dir` as records arrive [SPEC-16.J j-shadow-decision].

**Into active**, by the cut-over script of WO-20261012-fa36 - Scheduler cut-over: shadow mode and its decision files, the parity report and subcommand, going active with the belt panes released and the ledger adopted, rollback, the grid slots and the belt status command, per SPEC-16.J, in this order and never by hand [SPEC-16.J j-active-steps]:

1. Parity exits 0 (below).
2. The three belt panes and the two architect watches are released through `herdr/bin/monitors.sh release` [SPEC-16.J j-retire-what].
3. `COQ_SCHED_STATE_DIR` points at the bash belt's state directory, so the ledger, the boundary and the belt file continue and nothing is routed twice [SPEC-16.J j-active-adopt].
4. `COQ_SCHED_MODE=active`; the scheduler pane restarts.
5. Status says active with the gate passed.
6. The belt status command in `herdr/config/herdr.json` becomes the scheduler's status with the belt flag [SPEC-16.J j-active-config].

The scheduler refuses to go active while a verb it can emit is missing from the executor's Health, and says which [SPEC-16.F f-exec-verbs].

## Parity

- The parity subcommand compares each shadow decision with the bash belt's ledger word for that record and, when the belt finished it, the receipt the belt wrote: verdict, action, addressee and down [SPEC-16.J j-parity-oracle].
- It exits 0 only when at least `shadow.parity_min_records` records were compared and no mismatch was found; otherwise 1, listing each mismatch with both sides [SPEC-16.J j-parity-verdict].
- Improvements are counted apart and are not mismatches: where the belt wrote a 500 and the scheduler holds a retry [SPEC-16.J j-parity-known].
- Going active is refused while parity exits 1. Read every mismatch; a mismatch is a scheduler bug or a routes-table question for the architect, never something to wait out.

## Rollback

In this order [SPEC-16.J j-rollback-steps]:

1. `COQ_SCHED_MODE=off` and restart the scheduler pane.
2. Restore the runner slot's command and the belt status command in `herdr/config/herdr.json` (the cut-over script's rollback does both).
3. Run `herdr/bin/bringup.sh`: the belt panes come back on the shared ledger and route from the first record the scheduler had not finished.
4. Jobs the scheduler had in flight stay in its store; a record it claimed but did not finish is reported once as interrupted by the belt [SPEC-16.J j-rollback-jobs].
   Nothing is lost: every claim is a file.

## When something goes wrong

| Symptom                                          | Why                                                                | Do this                                                                            | Source                     |
| ------------------------------------------------ | ------------------------------------------------------------------ | ---------------------------------------------------------------------------------- | -------------------------- |
| `run.sh` exits 4: no executor socket             | the executor is not up                                             | bring the executor pane up first                                                   | SPEC-16.H h-pane-gate      |
| a wrapper exits 3 naming `ENV:<NAME> is unset`   | the pane's environment lacks a name the config uses                | export it in the pane's shell or the unit, then restart                            | SPEC-16.G g-vars           |
| a wrapper exits 3 naming a key                   | a config file lacks a key                                          | fix the file and run `make lint`                                                   | SPEC-16.G g-nodefault-rule |
| `run.sh` exits 3: an intake root matches nothing | a root pattern resolves to no directory                            | fix the pattern or create the root                                                 | SPEC-16.G g-val-cross      |
| `run.sh` exits 4: image not in local storage     | `runtime.image` names a digest that was never built here           | `make -C scheduler image`, then repin `runtime.image`                              | SPEC-16.H h-image          |
| `run.sh` exits 3: image must be by digest        | `runtime.image` names a tag                                        | pin it by digest                                                                   | SPEC-16.H h-run-flags      |
| `run-exec.sh` exits 4: no binary                 | nothing built                                                      | `make -C scheduler build`                                                          | SPEC-16.H h-t1             |
| podman refuses: the name is in use               | a scheduler container already runs                                 | find its pane; never start a second                                                | SPEC-16.H h-run-flags      |
| status exits 1, the start gate failed            | a start step failed; the scheduler stays up and retries every tick | read the reason in status, fix that, wait one tick                                 | SPEC-16.F f-rec-gate       |
| one 500 note, executor down                      | the executor pane died or restarted                                | the supervisor restarts it; held jobs run when Health answers, no attempt is spent | SPEC-16.F f-exec-rule      |
| one 500 note naming a table                      | a changed routes, policies or flow table failed its checks         | the old table stays loaded; fix the file and save                                  | SPEC-16.G g-reload-fail    |
| status says halted                               | the halt flag exists                                               | remove the flag when the reason is cleared; the scheduler resumes where it was     | SPEC-16.F f-halt-rule      |
| a wake did not reach a seat                      | the seat's quiet window was open                                   | the wake is a file in the seat's inbox; the guard drains it after the resume       | SPEC-16.D d-quiet-check    |

## GOOD and NEVER

GOOD: the executor pane restarts; for forty seconds Health fails, one 500 note is written, no job attempt is spent; the executor answers and the held jobs run [SPEC-16.F f-examples].
GOOD: parity over 300 records shows 297 agreeing, 3 improvements and no mismatch, and the operator runs the cut-over script [SPEC-16.J j-examples].
GOOD: one record id searched in both panes shows listed, plan row, seat-up run, prompt run, confirmed, receipt written [SPEC-16.I i-examples].
NEVER: going active with the route runner pane still running; two routers on one ledger race on every claim [SPEC-16.J j-examples].
NEVER: shadow mode writing into the bash belt's state directory to keep the supervisor quiet [SPEC-16.J j-examples].
NEVER: a shell in the runtime image so an operator can look inside; looking is the status subcommand [SPEC-16.H h-examples].
NEVER: a podman line typed by hand with a flag the wrapper does not set; the wrapper is the only place that knows the host [SPEC-16.H h-run-env].
NEVER: `go test` on the host because the image build was slow [SPEC-16.K k-examples].

## Sources

- `specs/scheduler/SPEC-16-scheduler-overview.xml` s-laws.
- `specs/scheduler/SPEC-16.F-health-supervision.xml` f-executor, f-halt, f-drain, f-recovery, f-supervisor.
- `specs/scheduler/SPEC-16.G-config-schema.xml` g-vars, g-nodefault, g-reload.
- `specs/scheduler/SPEC-16.H-podman-runtime-executor.xml` h-run, h-pane, h-executor, h-verbs, h-build.
- `specs/scheduler/SPEC-16.I-observability.xml` i-status, i-trace, i-log.
- `specs/scheduler/SPEC-16.J-cut-over.xml` j-mode, j-shadow, j-parity, j-active, j-rollback.
