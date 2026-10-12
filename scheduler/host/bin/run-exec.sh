#!/usr/bin/env bash
# run-exec.sh - the executor in the foreground of its herdr pane (SPEC-16.H h-pane, h-executor). The command of the
# executor's monitors slot; bring-up and the supervisor restart it by running it again, with no verb of their own.
#
#   run-exec.sh          exec the static binary's exec subcommand on scheduler/config/executor.json
#
# The executor is the host half by design (DEC-scheduler-two-processes): it runs the binary make -C scheduler build put in
# dist/, never a Go toolchain, and inherits the pane's PATH with herdr, jq and the host scripts (h-exec-path). The binary
# owns the file: it resolves the variables, refuses a missing or unknown key, and listens on the socket with mode 0600.
# The wrapper only checks that the binary and the file are there, makes the socket's directory private, and execs, so the
# pane's stop reaches the binary itself and the exit code the pane shows is the executor's.
# Exit codes: 0 ok, 2 usage, 3 validation (an unset variable or a missing key), 4 io (no binary, no config), else the binary's.
set -euo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd); SCHED=$(cd "$HERE/../.." && pwd)
# shellcheck source-path=SCRIPTDIR source=../lib/config.sh
. "$SCHED/host/lib/config.sh"
CFG_WHO=run-exec

[ $# -eq 0 ] || cfg_die 2 "usage: run-exec.sh (no arguments; everything comes from $SCHED/config/executor.json)"
BIN=$SCHED/dist/scheduler CFG=$SCHED/config/executor.json
[ -x "$BIN" ] || cfg_die 4 "no binary at $BIN; run make -C scheduler build"
[ -f "$CFG" ] || cfg_die 4 "no config at $CFG"
command -v jq >/dev/null || cfg_die 4 "jq is not on PATH"

# The socket's directory is created here, private to the owner, because run.sh mounts that directory into the container
# and podman refuses a mount of a path that does not exist; the executor creates the socket itself.
sock=$(cfg_raw "$CFG" socket); sock=$(cfg_resolve "$CFG" "$sock"); sockdir=$(dirname "$sock")
mkdir -p "$sockdir" && chmod 0700 "$sockdir" || cfg_die 4 "cannot create $sockdir"

exec "$BIN" exec --config "$CFG"
