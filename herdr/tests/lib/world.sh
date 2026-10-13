#!/usr/bin/env bash
# herdr/tests/lib/world.sh - one throwaway world per case: a copy of the repo, a private HOME and XDG tree with a short
# path (herdr's unix socket name has a 108 byte limit), a stub claude first on PATH, a test config pointing at a scratch
# session t-<case>, and a headless herdr server for it. world_up starts it, world_down (trapped on EXIT) stops and
# deletes the session, so no case leaves one behind.
#   world_up <name> [jq filter applied to herdr.json]   e.g. world_up gate '.bringup_gate=true'
#   h <args>                                            herdr --session t-<name> <args>, markers unset
#   wait_until SECONDS CMD...                           poll CMD every 0.2 s until it succeeds; fails naming CMD after SECONDS
#   SEAT, REPO, STATE, EVENTS                            the paths a case asserts on
#   notest_layout / role_layout ROLE LAYOUT              a world whose role names a layout with no test slot (AC-H4)
world_up() {
  local name="$1" filt="${2:-.}"
  WORLD="${COQ_CASE_WORK:-${WORK_ROOT:-/tmp}}/$name"; mkdir -p "$WORLD"
  REPO="$WORLD/repo"; cp -a "${REPO_ROOT:-/repo}/." "$REPO/"; rm -rf "$REPO/.git"
  # BREADCRUMB 2026-10-12 - WO-20261012-7e13, case 17-resume-checkpoint still failed after PR 80 (WO-20261012-9f5d). What broke: every
  #   treehouse slot has .claude/skills as a symlink to the host's installed skills (skill-sync), `cp -a` copies the link, and
  #   inside the container its target does not exist, so the case's `mkdir -p .claude/skills` died with "File exists" and its
  #   `cp` of the checkpoint.sh fixture found no directory (17-resume-checkpoint.test.sh line ~15, the output of run 2026-10-12
  #   23:5x UTC). Why this fix: the world is a throwaway copy that must not depend on the host's home, so a dangling or any
  #   .claude/skills link is dropped and the case makes the real directory it needs. Rejected: following the link with cp -aL (it
  #   would copy the owner's whole skill set into every world) and editing the case (tests/cases is not this ticket's).
  #   Cost: no case can use the host's installed skills from a world; none does.
  [ ! -L "$REPO/.claude/skills" ] || rm "$REPO/.claude/skills"
  # BREADCRUMB 2026-10-12 - WO-20261012-7e13 (Roadmap A1), same ruling. What broke: event.sh add now prints the new file's path (AC-H1),
  #   and case 13-break-glass takes that output as the record id (`id=$("$EV" add ...)`, then `seat.sh --record $id` and
  #   `--answer $id`), so seven refusals became "--record needs a record id" (seat.sh line 59). Why this fix: the real event.sh runs
  #   as event-real.sh and the world's event.sh is a shim that runs it and prints the record's id field, the old stdout of add; the
  #   record itself is written by the real writer, under COQ_STATE. Rejected: editing the case (tests/cases is not this ticket's) and
  #   changing add to print the id (AC-H1 asks for the path). Cost: this world never exercises add's stdout; events/tests case 02 does.
  mv "$REPO/events/bin/event.sh" "$REPO/events/bin/event-real.sh"
  cat > "$REPO/events/bin/event.sh" <<'SHIM'
#!/usr/bin/env bash
# world shim for events/bin/event.sh (herdr/tests/lib/world.sh): the real writer, then the record's id on stdout instead of its path.
real=$(dirname "$0")/event-real.sh
[ "${1:-}" = add ] || exec "$real" "$@"
args=(); json=0; for a in "$@"; do if [ "$a" = --json ]; then json=1; else args+=("$a"); fi; done
p=$("$real" "${args[@]}") || exit $?
if [ "$json" = 1 ]; then cat "$p"; else jq -r .id "$p"; fi
SHIM
  chmod +x "$REPO/events/bin/event.sh"
  # BREADCRUMB 2026-10-12 - WO-20261012-7e13 (Roadmap A1), architect ruling on blocked record 20261012T231224Z-423-8cv0o. What broke:
  #   event.sh add writes under the state root, and this world exports COQ_STATE="$STATE" (below) while EVENTS pointed at
  #   $REPO/events, so event_count and every case that globs "$EVENTS"/2*/*/*.json counted 0 records (14 of 25 cases failed). Why this
  #   fix: the world already gives the test its own temp COQ_STATE, so EVENTS is that state root's records tree, which has the same
  #   YYYY/MM/*.json shape; the cases are unchanged and read the records the real event.sh wrote. Rejected: pointing COQ_STATE back at
  #   the copy's events/ (the records would be written outside the layout under test). Cost: scripts that read $REPO/events directly
  #   (recwatch, the belt) see nothing the seats record in this world until roadmap items A2 and A3 move them onto the state root.
  STATE="$WORLD/state"; EVENTS="$STATE/records"
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
  # BREADCRUMB 2026-10-12 - WO-20261012-9b2c. What would break: the policy watch (2.3.2, factory/bin/policy.sh run) is a third slot
  #   whose live command writes records (policy.applied, and a 500 note when a wake fails), and the cases that count or compare
  #   events would see ones they did not make. Why this fix: it joins the runner and the flow watch in the filter above, keeping
  #   its name, label and place. Rejected: leaving it live and loosening counts. Cost: no herdr case runs policy.sh through a pane;
  #   factory case 12 proves the script and case 04 proves the slot is drawn, labelled and in use.
  jq '(.tabs[].reserved[] | select(.name == "runner" or .name == "flow" or .name == "policy") | .command) = "while :; do sleep 30; done"' \
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
  # BREADCRUMB 2026-10-11 - WO-20261011-dc0d. What broke: the first full run after seat.sh learned to nudge sat in case 03 for
  #   8 minutes, because every claude seat now waits nudge_wait_seconds (180 in herdr.json) for the guard's ack line and the
  #   stub claude never sends one unless a case writes its mode file, so each seat of every case paid 3 minutes. Why this fix:
  #   the world's config shortens both nudge keys to 1 s, which is a seat with no memo moving on at once; case 11 raises them
  #   in its own filter, the only case that plays the memo. Rejected: a stub that always acks (it would send the nudge prompt
  #   into every case's agent read) and skipping the nudge when require_guard is false (the production path would go untested).
  #   Cost: a case that wants the ack must write the mode file and set the keys itself, as 11 does. Record: WO-20261011-dc0d.
  jq --arg s "t-$name" --arg st "$STATE" '.session=$s | .state_dir=$st | .require_guard=false | .bringup_gate=false | .down_wait_seconds=0 | .retire_poll_seconds=3 | .nudge_wait_seconds=1 | .nudge_settle_seconds=1 | .belt.status="true"' \
    "$REPO/herdr/config/herdr.json" | jq "$filt" > "$COQ_HERDR_CONFIG"
  unset HERDR_PANE_ID HERDR_TAB_ID HERDR_WORKSPACE_ID HERDR_SOCKET_PATH HERDR_SESSION
  (herdr --session "t-$name" server > "$WORLD/server.log" 2>&1 &)
  # BREADCRUMB 2026-10-13 - WO-20261013-892f (test speed, polls part 1; design d-shape 5). What broke: the server wait slept 1 s before
  #   its first look, so every world paid at least a second before its first look whether or not the server was already answering,
  #   and the cap was a count of sleeps, not a time. Why this fix: wait_until looks at once and every 0.2 s up to 15 s,
  #   the same cap, so a world that is up in 0.3 s is used in 0.3 s. Rejected: a longer fixed sleep "to be safe" (the cost of every
  #   world, forever) and an unbounded wait (a server that never starts would hang the suite). Cost: none; the failure message is the
  #   same, plus wait_until's line naming what it waited for.
  wait_until 15 herdr_answers || { echo "world_up: herdr session t-$name did not start"; cat "$WORLD/server.log"; return 1; }
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
# BREADCRUMB 2026-10-11 - WO-20261011-f896. What broke (would break): seat-1x2 now carries its own test pane, so cases 01 and 08,
#   which prove the architect-tab fallback and its refusal (a ticket seat with no 'test - herdr' pane to name is refused before
#   any lease), could no longer reach that path with the real worker role. Why this fix: the world copies the repo, so it
#   can point its copy of a role at seat-nt, seat-1x2 minus its test slot, which is exactly the shape of a layout that has
#   none (player-1x3, interface-2x2). Rejected: an env switch in seat.sh (the production path would go untested). Cost: a
#   case that calls role_layout must put the role back (role_layout ROLE seat-1x2) before it asserts on the real shape.
#   notest_layout            writes herdr/layouts/seat-nt.json in the world
#   role_layout ROLE LAYOUT  points the world's copy of roles/ROLE.json at LAYOUT
notest_layout() { jq '.id = "seat-nt" | .panes |= map(select(.kind != "test"))' "$REPO/herdr/layouts/seat-1x2.json" > "$REPO/herdr/layouts/seat-nt.json"; }
role_layout() { jq --arg l "$2" '.pane_layout = $l' "$REPO/roles/$1.json" > "$REPO/roles/$1.json.tmp" && mv "$REPO/roles/$1.json.tmp" "$REPO/roles/$1.json"; }
h() { herdr --session "$COQ_HERDR_SESSION" "$@"; }
# wait_until SECONDS CMD...: run CMD (a command or a function, with its arguments) now and every 0.2 s until it succeeds, for at most SECONDS;
# returns 0 at the first success, else 1 after printing "wait_until: timed out after Ns waiting for: CMD..." to stderr, so a case that
# waited for a condition names it when it fails. This replaces a fixed sleep with the condition the sleep stood for (WO-20261013-892f).
# The 0.2 s between looks is the poll interval itself, not a wait for anything.
wait_until() {
  local limit="$1" end; shift
  end=$(( $(date +%s%N) / 1000000 + limit * 1000 ))
  while :; do
    "$@" && return 0
    [ $(( $(date +%s%N) / 1000000 )) -lt "$end" ] || break
    sleep 0.2
  done
  echo "wait_until: timed out after ${limit}s waiting for: $*" >&2
  return 1
}
herdr_answers() { h workspace list >/dev/null 2>&1; }
herdr_gone() { ! herdr_answers; }
world_down() {
  [ -n "${COQ_HERDR_SESSION:-}" ] || return 0
  herdr --session "$COQ_HERDR_SESSION" session stop "$COQ_HERDR_SESSION" >/dev/null 2>&1 || true
  # BREADCRUMB 2026-10-13 - WO-20261013-892f. What broke: a fixed second between `session stop` and `session delete`, paid by every case on
  #   its way out whether the server had stopped in 50 ms or not. Why this fix: wait until the server stops answering (at most 5 s), then
  #   delete; a server that is still up after that gets the delete anyway, as before, and run.sh's teardown check counts the session
  #   directory if it survives. Cost: none.
  wait_until 5 herdr_gone || true
  herdr --session "$COQ_HERDR_SESSION" session delete "$COQ_HERDR_SESSION" >/dev/null 2>&1 || true
  rm -rf "${XDG:-/nonexistent}"
}
# event_count KIND CODE: how many event files of that kind and code the world's repo copy holds.
event_count() { local n=0 f; for f in "$EVENTS"/2*/*/*.json; do [ -f "$f" ] || continue; jq -e --arg k "$1" --argjson c "$2" '.kind == $k and .code == $c' "$f" >/dev/null 2>&1 && n=$((n + 1)); done; echo "$n"; }
# pane_labels WS TAB: labels of a tab's panes, sorted, pipe-joined.
pane_labels() { h pane list --workspace "$1" | jq -r --arg t "$2" '[.result.panes[] | select(.tab_id == $t) | .label // ""] | sort | join("|")'; }
# world_real_belt: put the repo's own runner and flow commands back in the world's monitors.json (before bringup runs).
world_real_belt() { cp "${REPO_ROOT:-/repo}/herdr/config/monitors.json" "$REPO/herdr/config/monitors.json"; }
