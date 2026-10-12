#!/usr/bin/env bash
# Catches (WO-20261012-b800): a supervisor tick that needs a human after a herdr restart (it starts the unit, never a server of its
# own), podman's pause process left dead, the owner page and its wait loop left down or restarted with the key in a log, a stop
# that was meant undone, a tick stacked on a tick still running, a hung step holding the next tick, --check changing anything,
# the halt flag ignored, and a dead reserved pane waiting for a human.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/assert.sh"; . "$HERE/../lib/world.sh"
world_up supervisor '.bringup_gate=true | .supervisor.herdr_unit="coq-test.service" | .supervisor.herdr_wait_seconds=20 | .supervisor.bearings.script="${repo}/tools/bearings-stub/scripts/bearings.sh"' || exit 1
SUP="$REPO/herdr/bin/supervisor.sh"; MON="$REPO/herdr/bin/monitors.sh"
export SYSTEMCTL_STUB_LOG="$WORLD/systemctl.log" PODMAN_STUB_LOG="$WORLD/podman.log"
: > "$SYSTEMCTL_STUB_LOG"; : > "$PODMAN_STUB_LOG"
tick() { "$SUP" "$@" > "$WORLD/out" 2>&1; rc=$?; out="$(cat "$WORLD/out")"; }

# A bearings.sh that keeps its state in files and logs how it was called, with the url (and its key) on stdout like the real one.
B="$REPO/tools/bearings-stub"; mkdir -p "$B/scripts" "$B/config" "$B/state"
cat > "$B/config/bearings.json" <<'EOF'
{"tiers": {"stable": {"pane_label": "bearings-stable", "wait_pane_label": "bearings-stable-wait"}}}
EOF
cat > "$B/scripts/bearings.sh" <<'EOF'
#!/usr/bin/env bash
D="$(cd "$(dirname "$0")/.." && pwd)"
printf '%s | HERDR_ENV=%s HERDR_TAB_ID=%s HERDR_SESSION=%s COQ_SEAT=%s\n' "$*" "${HERDR_ENV:-}" "${HERDR_TAB_ID:-}" "${HERDR_SESSION:-}" "${COQ_SEAT:-}" >> "$D/calls.log"
case "$2" in
  status) a=false; [ ! -f "$D/state/alive" ] || a=true
          jq -n --argjson a "$a" --arg d "$D/state" '{tier:"stable",alive:$a,dir:$d,url:"http://127.0.0.1:1/?key=SECRETKEY"}' ;;
  serve) touch "$D/state/alive"; rm -f "$D/state/stopped.json"; echo "http://127.0.0.1:1/?key=SECRETKEY" ;;
  wait) echo "wait" ;;
esac
EOF
chmod +x "$B/scripts/bearings.sh"
echo '{"session":"sess-1234","model":"claude-test","working_on":"a ticket","tier":"stable"}' > "$B/state/session.json"

ws_of() { h workspace list | jq -r '.result.workspaces[] | select(.label == "coq") | .workspace_id'; }
echo "-- an architect agent whose tab holds the owner page's panes"
"$REPO/herdr/bin/bringup.sh" --worktree "$REPO" >/dev/null 2>&1; assert_eq "bringup builds the system once" "$?" 0
ws="$(ws_of)"
ATAB="$(h tab create --workspace "$ws" --label arch --cwd "$REPO")"; AP="$(jq -r '.result.root_pane.pane_id' <<<"$ATAB")"; ATID="$(jq -r '.result.tab.tab_id' <<<"$ATAB")"
sleep 2; h agent start architect --kind claude --pane "$AP" -- --model x >/dev/null; assert_eq "the architect comes up" "$?" 0

echo "-- tick 1: the page is down, so the supervisor restarts the server and the wait loop in the architect's tab"
tick
echo "$out" | sed 's/^/    /'
assert_eq "exits 0" "$rc" 0
assert_match "herdr, podman, bringup and the belt are ok" "$(tr '\n' ' ' <<<"$out")" "^ok herdr .*ok belt "
assert_match "bearings is fixed and says what it did" "$out" "^fixed bearings \\(server and wait loop restarted, waking architect\\)"
calls="$(cat "$B/calls.log")"
assert_match "serve was joined to the page's session, model and working-on" "$calls" "serve --join --session sess-1234 --model claude-test --working-on a ticket"
assert_match "it ran with the herdr environment of the architect's tab and no seat" "$calls" "serve .*HERDR_ENV=1 HERDR_TAB_ID=$ATID HERDR_SESSION=t-supervisor COQ_SEAT=\$"
assert_match "the wait loop wakes the architect agent" "$calls" "wait --to architect"
assert_eq "the page's key is in no line of the tick or its log" "$(cat "$WORLD/out" "$STATE/supervisor/last.log" "$STATE/supervisor/bearings.err" | grep -c SECRETKEY)" 0
assert_match "a note 100 record says what was fixed" "$(jq -r 'select(.seat == "supervisor") | .note' "$EVENTS"/2*/*/*.json 2>/dev/null)" "supervisor: fixed bearings"

echo "-- a wait loop that is running makes the next tick change nothing"
WTAB="$(h pane split "$AP" --direction down --no-focus | jq -r '.result.pane.pane_id')"
h pane rename "$WTAB" bearings-stable-wait >/dev/null; h pane run "$WTAB" 'sleep 600' >/dev/null; sleep 1
tick
assert_eq "exits 0" "$rc" 0
assert_eq "nothing was fixed" "$(grep -c '^fixed ' <<<"$out")" 0
assert_match "bearings reads ok" "$out" "^ok bearings$"
assert_match "last.log holds the tick" "$("$SUP" log)" "tick \\(apply\\)"

echo "-- the wait loop shares the shell's process group, as bearings places node wait.mjs (WO-20261012-277d): still ok"
# set +m turns job control off for this shell, so the background job stays in the shell's own group, the way node wait.mjs sat in
# zsh 4175695's group on the live host (fg 4175695 = shell 4175695). Such a job ignores SIGINT, so the section kills it by pid.
h pane send-keys "$WTAB" C-c >/dev/null; sleep 1
h pane run "$WTAB" 'set +m; sleep 600 & p=$!; wait' >/dev/null; sleep 1
assert_eq "precondition: the job's group is the shell's group" "$(h pane process-info --pane "$WTAB" | jq -r '.result.process_info | .foreground_process_group_id == .shell_pid')" true
assert_match "precondition: a job that is not a shell is in the foreground" "$(h pane process-info --pane "$WTAB" | jq -r '[.result.process_info.foreground_processes[].argv[0] | split("/") | last] | join(" ")')" "sleep"
tick --check
assert_eq "--check exits 0" "$rc" 0
assert_match "bearings reads ok, the live wait loop is not called dead" "$out" "^ok bearings$"
tick
assert_eq "an apply tick fixed nothing" "$(grep -c '^fixed ' <<<"$out")" 0
h pane send-keys "$WTAB" C-c >/dev/null; sleep 1; h pane run "$WTAB" 'kill $p; set -m' >/dev/null; sleep 1
h pane run "$WTAB" 'sleep 600' >/dev/null; sleep 1

echo "-- the wait loop dies: the next tick restarts it, and only it"
n0="$(grep -c 'serve' "$B/calls.log")"
h pane send-keys "$WTAB" C-c >/dev/null; sleep 1
tick
assert_match "the wait loop is fixed" "$out" "^fixed bearings \\(wait loop restarted, waking architect\\)"
assert_eq "the server was not touched" "$(grep -c 'serve' "$B/calls.log")" "$n0"

echo "-- a stop that was meant is respected, a server that died with the herdr server is not"
rm -f "$B/state/alive"; h pane run "$WTAB" 'sleep 600' >/dev/null
echo '{"reason":"stopped","forced":false,"at":"2099-01-01T00:00:00.000Z"}' > "$B/state/stopped.json"
tick; assert_match "stopped after this herdr started: left alone" "$out" "^skipped bearings \\(stopped on purpose at 2099"
echo '{"reason":"stopped","forced":false,"at":"2000-01-01T00:00:00.000Z"}' > "$B/state/stopped.json"
tick; assert_match "stopped before this herdr started: restarted" "$out" "^fixed bearings \\(server and wait loop restarted"

echo "-- podman's pause process is gone"
touch "$HOME/podman-broken"
tick --check; assert_eq "--check exits 1" "$rc" 1
assert_match "--check names it and runs no migrate" "$out" "^FAILED podman .*podman ps fails; apply would run podman system migrate"
assert_eq "no migrate was run" "$(grep -c 'system migrate' "$PODMAN_STUB_LOG")" 0
tick; assert_match "apply migrates" "$out" "^fixed podman \\(podman system migrate\\)"; assert_eq "exit 0" "$rc" 0

echo "-- AC-H1: a reserved pane whose command died is back within one tick, and --check changes nothing"
ep="$("$MON" status | sed -nE 's/^ +2\.1\.1 .*\[([^]]+)\] +in use$/\1/p')"
h pane send-keys "$ep" C-c >/dev/null; h pane send-keys "$ep" C-c >/dev/null
for _ in $(seq 1 30); do "$MON" health 2>/dev/null | grep -q '^FAILED events ' && break; sleep 0.5; done
n500="$(event_count note 500)"
tick --check; assert_eq "--check exits 1" "$rc" 1
assert_match "--check names the pane" "$out" "FAILED pane-events"
assert_eq "--check wrote no 500 record" "$(event_count note 500)" "$n500"
assert_match "the pane is still dead" "$("$MON" health 2>&1)" "FAILED events"
tick; assert_eq "apply exits 0" "$rc" 0
assert_match "apply restarts it" "$out" "fixed pane-events"
assert_match "and says so on a record" "$(jq -r 'select(.seat == "supervisor") | .note' "$EVENTS"/2*/*/*.json | tr '\n' ' ')" "fixed .*pane-events"

echo "-- the halt flag stops everything, a running tick is not stacked on"
mkdir -p "$STATE"; touch "$STATE/HALT"; tick; assert_match "HALTED" "$out" "^HALTED"; assert_eq "one line, nothing changed" "$(wc -l < "$WORLD/out" | tr -d ' ')" 1; rm -f "$STATE/HALT"
( flock "$STATE/supervisor/lock" sleep 6 ) & sleep 1
tick; assert_match "a second tick skips" "$out" "^skipped supervisor \\(the previous tick is still running\\)"; assert_eq "and exits 0" "$rc" 0
wait

echo "-- a step that hangs is killed after the step timeout and the tick goes on"
jq '.supervisor.step_timeout_seconds = 5 | .belt.status = "sleep 100"' "$COQ_HERDR_CONFIG" > "$WORLD/c.json" && mv "$WORLD/c.json" "$COQ_HERDR_CONFIG"
start="$(date +%s)"; tick; took=$(( $(date +%s) - start ))
assert_match "the belt step is FAILED as killed" "$out" "^FAILED belt \\(killed after 5s\\)"
assert_match "bearings after it still ran" "$out" "bearings"
check "the tick took under 40 s (took ${took}s)" "$([ "$took" -lt 40 ] && echo 1 || echo 0)"
jq '.supervisor.step_timeout_seconds = 120 | .belt.status = "true"' "$COQ_HERDR_CONFIG" > "$WORLD/c.json" && mv "$WORLD/c.json" "$COQ_HERDR_CONFIG"

echo "-- AC-H3 shape: the herdr server stops; one tick starts the unit and the system is whole after the next"
herdr --session "$COQ_HERDR_SESSION" server stop >/dev/null 2>&1
for _ in $(seq 1 20); do h workspace list >/dev/null 2>&1 || break; sleep 0.5; done
h workspace list >/dev/null 2>&1; assert_eq "herdr is down" "$?" 1
tick
assert_match "herdr is fixed by starting the unit" "$out" "^fixed herdr \\(started coq-test\\.service\\)"
assert_eq "systemctl was asked to start the unit, once" "$(grep -c -- '--user start coq-test.service' "$SYSTEMCTL_STUB_LOG")" 1
tick; tick
assert_eq "within two more ticks the exit is 0" "$rc" 0
assert_eq "and nothing is left to fix" "$(grep -c '^fixed \|FAILED' <<<"$out")" 0
case_done
