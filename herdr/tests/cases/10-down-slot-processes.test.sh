#!/usr/bin/env bash
# Catches: seat.sh --down running `treehouse return --force` without naming what is in the slot, or ending a process that is
# not the seat's own (WO-20261011-36d7, AC-H2): a foreign shell parked in the slot must be logged with its pid and name, must
# stop the return (exit 3, the seat stays un-ended, nothing killed, no seat.down), and must not stop a rerun once it is gone.
# A process the seat's own pane started is listed as the seat's own and does not stop the return. The pool is the stub
# treehouse, whose `status --json` lists the processes whose cwd is the slot, as the real one does.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/assert.sh"; . "$HERE/../lib/world.sh"
world_up downproc || exit 1
export TREEHOUSE_STUB_LOG="$WORLD/treehouse.log"; : > "$TREEHOUSE_STUB_LOG"
A=WO-20261010-8777; NA=worker-wo-20261010-8777
calls() { grep -c "^$1 " "$TREEHOUSE_STUB_LOG"; }
held() { treehouse status --json | jq --arg h "$1" '[.[] | select(.lease_holder == $h)] | length'; }
ORIGIN="$WORLD/origin.git"; SEED="$WORLD/seed"
git init -q --bare "$ORIGIN"; git clone -q "$ORIGIN" "$SEED" 2>/dev/null
git -C "$SEED" commit -q --allow-empty -m "seed main" && git -C "$SEED" push -q origin main || { echo "case 10: could not seed the origin"; exit 1; }
export TREEHOUSE_STUB_ORIGIN="$ORIGIN"
tfile="$(find "$REPO/work-orders" -name "$A-*.md" -not -path '*/archive/*' | head -1)"
branch="$(awk '/^---$/{c++; next} c==1' "$tfile" | jq -r .branch)"
git -C "$SEED" checkout -q -b "$branch" main && git -C "$SEED" commit -q --allow-empty -m "work on $branch" && git -C "$SEED" push -q origin "$branch"
foreign=""; trap '[ -z "$foreign" ] || kill "$foreign" 2>/dev/null; pkill -f "sleep 3017" 2>/dev/null; world_down' EXIT

out="$("$SEAT" --ticket "$A" --role worker)"; rc=$?
assert_eq "seat up" "$rc" 0
slot="$(jq -r .worktree <<<"$out")"; ws="$(jq -r .workspace <<<"$out")"; tab="$(jq -r .tab <<<"$out")"
R="$STATE/seats/$NA/seat.json"

echo "-- AC-H2: a foreign shell parked in the slot is named, and the return is refused"
(cd "$slot" && exec sleep 3016) & foreign=$!   # sleep 3016 is the foreign process the case parks in the slot, not a wait
# BREADCRUMB 2026-10-13 - WO-20261013-892f (test speed, polls part 1; design d-shape 5). What broke: a fixed `sleep 0.5` after the
#   background subshell, a `sleep 1` after the interrupt and a `sleep 1.5` after the pane command (3 s a case), each a guess at when
#   a process would be where the next line needs it. Why this fix: each is now wait_until on that condition - the subshell has
#   exec'd sleep with its cwd in the slot (the two facts the stub treehouse reads from /proc to list it), the monitor pane's
#   foreground is its shell again (`pane process-info`: foreground_processes is the shell's own pid, where it was `sleep 15`), and the
#   pane's `sleep 3017` is running. Rejected: dropping the waits (the foreign process may not be in the slot yet, and a command
#   typed into a pane still looping is never run). Cost: a wait that never ends fails in 5 to 10 s naming itself.
in_slot() { [ "$(readlink "/proc/$1/cwd" 2>/dev/null)" = "$slot" ] && [ "$(cat "/proc/$1/comm" 2>/dev/null)" = sleep ]; }
at_prompt() { h pane process-info --pane "$1" | jq -e '.result.process_info | [.foreground_processes[]?.pid] == [.shell_pid]' >/dev/null 2>&1; }
wait_until 5 in_slot "$foreign"
"$SEAT" --down "$NA" >/dev/null 2>"$WORLD/err"; rc=$?
assert_eq "--down exits 3" "$rc" 3
assert_match "the log names the foreign process by pid and name" "$(cat "$WORLD/err")" "slot $slot holds process $foreign sleep \(FOREIGN\)"
assert_match "the log says it is refusing the return" "$(cat "$WORLD/err")" "refusing treehouse return --force on $slot while a foreign process is in it"
assert_eq "no treehouse return was made" "$(calls return)" 0
kill -0 "$foreign" 2>/dev/null; assert_eq "the foreign process is still alive" "$?" 0
assert_eq "the lease is still held" "$(held "$A")" 1
assert_eq "the seat stays un-ended" "$(jq -r '.ended_at // "none"' "$R")" none
assert_eq "no seat.down was recorded" "$(event_count seat.down 100)" 0

echo "-- once the foreign process is gone a rerun returns the slot"
kill "$foreign"; wait "$foreign" 2>/dev/null; foreign=""
"$SEAT" --down "$NA" >/dev/null 2>"$WORLD/err"; rc=$?
assert_eq "the rerun exits 0" "$rc" 0
assert_eq "one treehouse return" "$(calls return)" 1
assert_eq "the lease is back" "$(held "$A")" 0
assert_eq "seat.down 100 recorded once" "$(event_count seat.down 100)" 1

echo "-- a process the seat's own pane started, which outlives the tab close, is listed as the seat's own and does not stop the return"
out="$("$SEAT" --ticket "$A" --role worker)"; rc=$?
assert_eq "seat up again" "$rc" 0
slot="$(jq -r .worktree <<<"$out")"; ws="$(jq -r .workspace <<<"$out")"; tab="$(jq -r .tab <<<"$out")"
mon="$(h pane list --workspace "$ws" | jq -r --arg t "$tab" 'first(.result.panes[] | select(.tab_id == $t and ((.label // "") | startswith("MONITOR"))) | .pane_id)')"
check "the seat has a monitor pane" "$([ -n "$mon" ] && echo 1 || echo 0)"
h pane send-keys "$mon" "$(jq -r .keys.interrupt "$COQ_HERDR_CONFIG")" >/dev/null
wait_until 10 at_prompt "$mon"
h pane run "$mon" "cd $slot && setsid nohup sleep 3017 >/dev/null 2>&1 &" >/dev/null
wait_until 10 pgrep -f 'sleep 3017' >/dev/null
own="$(pgrep -f 'sleep 3017' | head -1)"
check "a process of the seat's own pane is running in the slot" "$([ -n "$own" ] && echo 1 || echo 0)"
returns=$(calls return)
"$SEAT" --down "$NA" >/dev/null 2>"$WORLD/err"; rc=$?
assert_eq "--down exits 0" "$rc" 0
assert_match "the log names it as the seat's own, with pid and name" "$(cat "$WORLD/err")" "slot $slot holds process $own sleep \(this seat's own\)"
assert_eq "the slot went back" "$(calls return)" "$((returns + 1))"
assert_eq "seat.down 100 recorded again" "$(event_count seat.down 100)" 2
case_done
