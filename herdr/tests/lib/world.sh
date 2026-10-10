#!/usr/bin/env bash
# herdr/tests/lib/world.sh - one throwaway world per case: a copy of the repo, a private HOME and XDG tree with a short
# path (herdr's unix socket name has a 108 byte limit), a stub claude first on PATH, a test config pointing at a scratch
# session t-<case>, and a headless herdr server for it. world_up starts it, world_down (trapped on EXIT) stops and
# deletes the session, so no case leaves one behind.
#   world_up <name> [jq filter applied to herdr.json]   e.g. world_up gate '.bringup_gate=true'
#   h <args>                                            herdr --session t-<name> <args>, markers unset
#   SEAT, REPO, STATE, EVENTS                            the paths a case asserts on
world_up() {
  local name="$1" filt="${2:-.}"
  WORLD="${COQ_CASE_WORK:-${WORK_ROOT:-/tmp}}/$name"; mkdir -p "$WORLD"
  REPO="$WORLD/repo"; cp -a "${REPO_ROOT:-/repo}/." "$REPO/"; rm -rf "$REPO/.git"
  STATE="$WORLD/state"; EVENTS="$REPO/events"
  # shellcheck disable=SC2034  # SEAT, EVENTS and STATE are the case's handles
  SEAT="$REPO/herdr/bin/seat.sh"
  # Short, unique XDG root: the socket lives under it. /tmp/hw-<pid>-<name> stays well under sun_path.
  XDG="/tmp/hw-$$-${name:0:8}"; mkdir -p "$XDG/cfg" "$XDG/state" "$XDG/run"
  export HOME="$XDG/home"; mkdir -p "$HOME"
  export XDG_CONFIG_HOME="$XDG/cfg" XDG_STATE_HOME="$XDG/state" XDG_RUNTIME_DIR="$XDG/run" SHELL="${SHELL:-/bin/bash}"
  local stubs; stubs="$(cd "$(dirname "${BASH_SOURCE[0]}")/../stubs" && pwd)"; export PATH="$stubs:$PATH"
  export COQ_HERDR_SESSION="t-$name" COQ_STATE="$STATE" DRY_RUN=0
  export COQ_HERDR_CONFIG="$WORLD/herdr.json"
  jq --arg s "t-$name" --arg st "$STATE" '.session=$s | .state_dir=$st | .require_guard=false | .bringup_gate=false | .down_wait_seconds=0 | .retire_poll_seconds=3' \
    "$REPO/herdr/config/herdr.json" | jq "$filt" > "$COQ_HERDR_CONFIG"
  unset HERDR_PANE_ID HERDR_TAB_ID HERDR_WORKSPACE_ID HERDR_SOCKET_PATH HERDR_SESSION
  (herdr --session "t-$name" server > "$WORLD/server.log" 2>&1 &)
  for _ in $(seq 1 15); do sleep 1; herdr --session "t-$name" workspace list >/dev/null 2>&1 && break; done
  herdr --session "t-$name" workspace list >/dev/null 2>&1 || { echo "world_up: herdr session t-$name did not start"; cat "$WORLD/server.log"; return 1; }
  trap 'world_down' EXIT
}
h() { herdr --session "$COQ_HERDR_SESSION" "$@"; }
world_down() {
  [ -n "${COQ_HERDR_SESSION:-}" ] || return 0
  herdr --session "$COQ_HERDR_SESSION" session stop "$COQ_HERDR_SESSION" >/dev/null 2>&1 || true
  sleep 1
  herdr --session "$COQ_HERDR_SESSION" session delete "$COQ_HERDR_SESSION" >/dev/null 2>&1 || true
  rm -rf "${XDG:-/nonexistent}"
}
# event_count KIND CODE: how many event files of that kind and code the world's repo copy holds.
event_count() { local n=0 f; for f in "$EVENTS"/2*/*/*.json; do [ -f "$f" ] || continue; jq -e --arg k "$1" --argjson c "$2" '.kind == $k and .code == $c' "$f" >/dev/null 2>&1 && n=$((n + 1)); done; echo "$n"; }
# pane_labels WS TAB: labels of a tab's panes, sorted, pipe-joined.
pane_labels() { h pane list --workspace "$1" | jq -r --arg t "$2" '[.result.panes[] | select(.tab_id == $t) | .label // ""] | sort | join("|")'; }
