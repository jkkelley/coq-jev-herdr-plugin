#!/usr/bin/env bash
# scheduler/host/tests/lib/world.sh - one throwaway world per case (SPEC-16.H h-t7). A world is a copy of scheduler/host
# under $W/repo/scheduler, so the wrappers find everything relative to themselves exactly as they do in the real tree, plus:
#   a stub scheduler binary at $W/repo/scheduler/dist/scheduler: one argv word per line into $W/bin.argv, its environment
#     into $W/bin.env, then exit with the number in $W/bin.exit (0 when absent)
#   a stub podman first on PATH: `image exists REF` answers from $W/podman.images (one ref per line, the fixture's image
#     is there from the start); any other call writes one argv word per line into $W/podman.argv and exits 0
#   the two config files rendered from SPEC-16.G g-keys and g-executor with only the variable forms of g-vars, because the
#     config ticket's files land in the same wave (ticket assumption 3); the wrappers read nothing else from them
# Nothing real runs: no podman, no Go binary, no herdr. The environment the files name is set to paths inside $W.
#   world_up NAME        sets W, R (the repo copy), SCHED (its scheduler dir), and exports the ENV names the files use
#   argv_of FILE         the logged argv as one line, words joined by a space
world_up() {
  W="${COQ_CASE_WORK:-${WORK_ROOT:-/tmp}}/$1"; R="$W/repo"; SCHED="$R/scheduler"
  rm -rf "$W"; mkdir -p "$SCHED/dist" "$SCHED/config" "$W/bin" "$W/home" "$W/run" "$W/state" "$R/events"
  cp -r "${REPO_ROOT:-/repo}/scheduler/host" "$SCHED/"
  cat > "$SCHED/dist/scheduler" <<STUB
#!/usr/bin/env bash
printf '%s\n' "\$0" "\$@" > "$W/bin.argv"; env | sort > "$W/bin.env"
exit "\$(cat "$W/bin.exit" 2>/dev/null || echo 0)"
STUB
  cat > "$W/bin/podman" <<STUB
#!/usr/bin/env bash
if [ "\$1 \${2:-}" = "image exists" ]; then grep -qxF -- "\$3" "$W/podman.images"; exit; fi
printf '%s\n' "\$@" > "$W/podman.argv"
STUB
  chmod +x "$SCHED/dist/scheduler" "$W/bin/podman"
  export PATH="$W/bin:$PATH" HOME="$W/home"
  export XDG_RUNTIME_DIR="$W/run" COQ_REPO="$R" COQ_SCHED_STATE_DIR="$W/state" COQ_SCHED_MODE=shadow COQ_HERDR_SESSION=scratch
  unset COQ_SCHED_REPO
  render_scheduler_json > "$SCHED/config/scheduler.json"
  render_executor_json > "$SCHED/config/executor.json"
  jq -r '."runtime.image"' "$SCHED/config/scheduler.json" > "$W/podman.images"
  mkdir -p "$W/home/.local/state/coq" "$W/home/.treehouse/pool-a/slot/events" "$W/home/.treehouse/pool-b/slot/events"
}

# A real unix socket file where the executor would listen, so run.sh's socket check sees what it sees in a live pane.
executor_socket_up() {
  mkdir -p "$XDG_RUNTIME_DIR/coq-scheduler"
  python3 -c 'import socket, sys; socket.socket(socket.AF_UNIX).bind(sys.argv[1])' "$XDG_RUNTIME_DIR/coq-scheduler/executor.sock"
}

# The keys of SPEC-16.G g-keys a wrapper reads, in the forms g-vars allows; the rest of the file is the loader's business.
render_scheduler_json() {
  jq -n '{
    schema_version: "1.0.0",
    mode: "${ENV:COQ_SCHED_MODE}",
    seat: "scheduler",
    herdr_session: "${ENV:COQ_HERDR_SESSION}",
    repo: "${ENV:COQ_SCHED_REPO}",
    host_repo: "${ENV:COQ_REPO}",
    state_dir: "${ENV:COQ_SCHED_STATE_DIR}",
    routes_file: "${repo}/factory/config/routes.json",
    halt_flag: "${HOME}/.local/state/coq/HALT",
    drain_seconds: 30,
    "intake.roots": ["${repo}/events", "${HOME}/.treehouse/pool-*/slot/events"],
    "executor.socket": "${ENV:XDG_RUNTIME_DIR}/coq-scheduler/executor.sock",
    "control.socket": "${state_dir}/scheduler.sock",
    "belt.file": "${state_dir}/belt",
    "shadow.dir": "${state_dir}/shadow",
    "runtime.image": "localhost/coq-scheduler@sha256:0000000000000000000000000000000000000000000000000000000000000001",
    "runtime.memory": "256m",
    "runtime.container_name": "coq-scheduler"
  }'
}

render_executor_json() {
  jq -n '{
    schema_version: "1.0.0",
    socket: "${ENV:XDG_RUNTIME_DIR}/coq-scheduler/executor.sock",
    host_repo: "${ENV:COQ_REPO}",
    state_dir: "${HOME}/.local/state/coq",
    herdr_session: "${ENV:COQ_HERDR_SESSION}",
    seat: "scheduler",
    tail_lines: 20,
    unset_env: ["HERDR_PANE_ID"],
    verbs: {}
  }'
}

argv_of() { paste -sd' ' "$1" 2>/dev/null; }
