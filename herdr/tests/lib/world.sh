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
  # BREADCRUMB 2026-10-10 - WO-20261010-c274, cases 01-04 all failed on the first run of case 05. What broke: (1) every
  #   case seats WO-20261010-8777, which closed and moved to work-orders/archive/ (seat.sh line ~215 refuses a ticket it
  #   cannot find outside archive/: "no ticket ... (archived or never cut)"); (2) event_count read the copy's events/, which
  #   holds the live repo's real history (10 note 100 where case 04 wants 4, an extra seat.stalled 500 in case 02). Why this
  #   fix: the world is a scratch copy, so it gets the archived tickets back at the root and an empty event log, and every
  #   absolute count in a case means "this world made it". Rejected: pointing the cases at a ticket that is still open
  #   (the test would break again the day that one closes), and baselining each count in each case (five places to
  #   forget). Cost: a case cannot assert anything about the repo's real events or about archive/ staying archived.
  # BREADCRUMB 2026-10-11 - WO-20261011-6842. What would break: bringup now plugs the route runner (2.2.2) and the flow watch
  #   (2.2.3) into the world, and a live runner writes a 500 note for every record it has no route for (seat.up, seat.down, the
  #   closing notes), so the cases that assert "no event was written" or count records would see events they did not make.
  #   Why this fix: both slots keep their name, label and place but run a sleep loop here; case 13 puts the real commands back
  #   with world_real_belt. Rejected: leaving them live and loosening every count, which hides the next real change.
  #   Cost: cases 01-12 do not exercise route.sh or flow.sh through a pane; the factory suite and case 13 do. The same goes
#   for recover.sh's belt node: .belt.status is `true` in the world's config, so the node reads ok; case 13 sets the real one.
  jq '(.tabs[].reserved[] | select(.name == "runner" or .name == "flow") | .command) = "while :; do sleep 30; done"' \
    "$REPO/herdr/config/monitors.json" > "$REPO/herdr/config/monitors.json.new" && mv "$REPO/herdr/config/monitors.json.new" "$REPO/herdr/config/monitors.json"
  find "$REPO/work-orders/archive" -name 'WO-*.md' -exec cp -n {} "$REPO/work-orders/" \; 2>/dev/null
  rm -rf "$REPO"/events/20*
  # shellcheck disable=SC2034  # SEAT, EVENTS and STATE are the case's handles
  SEAT="$REPO/herdr/bin/seat.sh"
  # Short, unique XDG root: the socket lives under it. /tmp/hw-<pid>-<name> stays well under sun_path.
  XDG="/tmp/hw-$$-${name:0:8}"; mkdir -p "$XDG/cfg" "$XDG/state" "$XDG/run"
  export HOME="$XDG/home"; mkdir -p "$HOME"
  export XDG_CONFIG_HOME="$XDG/cfg" XDG_STATE_HOME="$XDG/state" XDG_RUNTIME_DIR="$XDG/run" SHELL="${SHELL:-/bin/bash}"
  local stubs; stubs="$(cd "$(dirname "${BASH_SOURCE[0]}")/../stubs" && pwd)"; export PATH="$stubs:$PATH"
  export COQ_HERDR_SESSION="t-$name" COQ_STATE="$STATE" DRY_RUN=0
  export COQ_HERDR_CONFIG="$WORLD/herdr.json"
  jq --arg s "t-$name" --arg st "$STATE" '.session=$s | .state_dir=$st | .require_guard=false | .bringup_gate=false | .down_wait_seconds=0 | .retire_poll_seconds=3 | .belt.status="true"' \
    "$REPO/herdr/config/herdr.json" | jq "$filt" > "$COQ_HERDR_CONFIG"
  unset HERDR_PANE_ID HERDR_TAB_ID HERDR_WORKSPACE_ID HERDR_SOCKET_PATH HERDR_SESSION
  (herdr --session "t-$name" server > "$WORLD/server.log" 2>&1 &)
  for _ in $(seq 1 15); do sleep 1; herdr --session "t-$name" workspace list >/dev/null 2>&1 && break; done
  herdr --session "t-$name" workspace list >/dev/null 2>&1 || { echo "world_up: herdr session t-$name did not start"; cat "$WORLD/server.log"; return 1; }
  # BREADCRUMB 2026-10-10 - WO-20261010-8fa8. What broke (would break): seat.sh now refuses a ticket seat unless the tab it
  #   was started from holds a pane labelled "test - herdr", so every case that seats a worker or reviewer was refused with
  #   exit 3. Why this fix: the world gets what the live system has, an architect tab with a labelled test pane, in a
  #   workspace of its own (architect-fixture, never the configured coq one), and the case shell is "inside" it through
  #   HERDR_TAB_ID and HERDR_WORKSPACE_ID, exactly as a pane in herdr would be. WORLD_TEST_PANE is its id. Rejected: an env
  #   override that skips the check, which would leave the production path untested. Cost: `workspace list` now holds this
  #   fixture, so a case counts or picks workspaces by label (03, 04 and 06 did not).
  local aw; aw="$(herdr --session "t-$name" workspace create --label architect-fixture --cwd "$REPO" --no-focus)"
  HERDR_WORKSPACE_ID="$(jq -r '.result.workspace.workspace_id // empty' <<<"$aw")"; HERDR_TAB_ID="$(jq -r '.result.tab.tab_id // empty' <<<"$aw")"
  WORLD_TEST_PANE="$(jq -r '.result.root_pane.pane_id // empty' <<<"$aw")"
  [ -n "$WORLD_TEST_PANE" ] && herdr --session "t-$name" pane rename "$WORLD_TEST_PANE" "test - herdr fixture" >/dev/null \
    || { echo "world_up: no architect fixture pane in t-$name"; return 1; }
  export HERDR_WORKSPACE_ID HERDR_TAB_ID WORLD_TEST_PANE
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
# world_real_belt: put the repo's own runner and flow commands back in the world's monitors.json (before bringup runs).
world_real_belt() { cp "${REPO_ROOT:-/repo}/herdr/config/monitors.json" "$REPO/herdr/config/monitors.json"; }
