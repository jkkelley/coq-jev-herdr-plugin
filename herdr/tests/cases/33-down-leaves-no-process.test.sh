#!/usr/bin/env bash
# Catches (WO-20261013-50a4, cause g, AC-H1): seat.sh --down or retire.sh declaring a seat down while one of its claude processes
# still runs, as a background session outside the pane's process tree, and so holds the treehouse slot (the PR 87 tester and
# tester-wo-20261013-f298 on 2026-10-13). A claude whose cwd is the seat's leased slot, and a claude whose COQ_SEAT is the seat's
# name from anywhere, must be gone after --down and the slot free; a claude of another seat or of nobody must be left alone; a
# survivor must be a 500 naming its pid and must stop --down (exit 4, seat un-ended, no seat.down) so a rerun retries.
# The planted sessions are the suite's stub claude, started with setsid so they are in no pane's tree, as the live ones were.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/assert.sh"; . "$HERE/../lib/world.sh"
world_up downnone '.down_kill_wait_seconds=1' || exit 1
A=WO-20261010-8777; NA=worker-wo-20261010-8777
held() { treehouse status --json | jq --arg h "$1" '[.[] | select(.lease_holder == $h)] | length'; }
ORIGIN="$WORLD/origin.git"; SEED="$WORLD/seed"
git init -q --bare "$ORIGIN"; git clone -q "$ORIGIN" "$SEED" 2>/dev/null
git -C "$SEED" commit -q --allow-empty -m "seed main" && git -C "$SEED" push -q origin main || { echo "case 33: could not seed the origin"; exit 1; }
export TREEHOUSE_STUB_ORIGIN="$ORIGIN"
tfile="$(find "$REPO/work-orders" -name "$A-*.md" -not -path '*/archive/*' | head -1)"
branch="$(awk '/^---$/{c++; next} c==1' "$tfile" | jq -r .branch)"
git -C "$SEED" checkout -q -b "$branch" main && git -C "$SEED" commit -q --allow-empty -m "work on $branch" && git -C "$SEED" push -q origin "$branch"
# A fifo held open for writing keeps a planted claude's stdin from ever reaching EOF without a child process of its own.
mkfifo "$WORLD/stdin"; exec 7<>"$WORLD/stdin"
trap 'pkill -f "stubs/claude" 2>/dev/null; world_down' EXIT
# plant TAG DIR [VAR=value...]: a stub claude in its own session (setsid), cwd DIR, found again by its session id TAG.
plant() { local tag="$1" dir="$2"; shift 2; (cd "$dir" && env CLAUDE_STUB_SESSION="$tag" ${1+"$@"} setsid bash -c 'exec claude' < "$WORLD/stdin" > /dev/null 2>&1 &); }
pid_of() { local f; for _ in $(seq 1 25); do f="$(grep -l "\"sessionId\":\"$1\"" "$HOME"/.claude/sessions/*.json 2>/dev/null | head -1)"; [ -z "$f" ] || { basename "$f" .json; return 0; }; sleep 0.2; done; }
alive() { kill -0 "$1" 2>/dev/null && [ "$(ps -o stat= -p "$1" 2>/dev/null | cut -c1)" != Z ]; }

echo "-- the seat comes up in a leased slot"
out="$("$SEAT" --ticket "$A" --role worker)"; rc=$?
assert_eq "seat up" "$rc" 0
slot="$(jq -r .worktree <<<"$out")"; R="$STATE/seats/$NA/seat.json"
mkdir -p "$WORLD/elsewhere"
plant bg-slot "$slot"; plant bg-env "$WORLD/elsewhere" COQ_SEAT="$NA"; plant bystander "$WORLD/elsewhere"
P_SLOT="$(pid_of bg-slot)"; P_ENV="$(pid_of bg-env)"; P_BY="$(pid_of bystander)"
check "all three planted sessions run" "$([ -n "$P_SLOT" ] && [ -n "$P_ENV" ] && [ -n "$P_BY" ] && alive "$P_SLOT" && alive "$P_ENV" && alive "$P_BY" && echo 1 || echo 0)"
assert_match "the stub in the slot has the slot as its cwd" "$(readlink "/proc/$P_SLOT/cwd")" "^$slot\$"

echo "-- AC-H1: a survivor ends --down with exit 4, the seat un-ended and no seat.down (retire.sh stood in by exit 3)"
cp "$REPO/herdr/bin/retire.sh" "$REPO/herdr/bin/retire-real.sh"; printf '#!/usr/bin/env bash\nexit 3\n' > "$REPO/herdr/bin/retire.sh"
"$SEAT" --down "$NA" >/dev/null 2>"$WORLD/err"; rc=$?
assert_eq "--down exits 4" "$rc" 4
assert_match "it says a process survived" "$(cat "$WORLD/err")" "a process of the seat survived retire.sh"
assert_eq "the seat stays un-ended" "$(jq -r '.ended_at // "none"' "$R")" none
assert_eq "no seat.down was recorded" "$(event_count seat.down 100)" 0
assert_eq "the lease is still held" "$(held "$A")" 1
mv "$REPO/herdr/bin/retire-real.sh" "$REPO/herdr/bin/retire.sh"

echo "-- AC-H1: the real --down ends the session in the slot and the one that carries COQ_SEAT, and spares the bystander"
"$SEAT" --down "$NA" >/dev/null 2>"$WORLD/err"; rc=$?
assert_eq "--down exits 0" "$rc" 0
assert_match "the log names what it ended" "$(cat "$WORLD/err")" "seat $NA: ending process\(es\) .*$P_SLOT"
check "the session whose cwd was the slot is gone" "$(alive "$P_SLOT" && echo 0 || echo 1)"
check "the session that carried COQ_SEAT is gone" "$(alive "$P_ENV" && echo 0 || echo 1)"
check "a claude of nobody, elsewhere, is still running" "$(alive "$P_BY" && echo 1 || echo 0)"
assert_eq "the slot is free" "$(held "$A")" 0
assert_eq "seat.down 100 recorded once" "$(event_count seat.down 100)" 1
assert_eq "the seat is ended" "$([ "$(jq -r '.ended_at // "none"' "$R")" != none ] && echo yes)" yes

echo "-- retire.sh on its own: an agent herdr no longer answers for, a claude still in the slot"
out="$("$SEAT" --ticket "$A" --role worker)"; rc=$?
assert_eq "seat up again" "$rc" 0
slot="$(jq -r .worktree <<<"$out")"; pane="$(jq -r .pane "$R")"
plant bg-slot2 "$slot"; P2="$(pid_of bg-slot2)"
"$REPO/herdr/bin/retire.sh" "$NA" --pane "$pane" --slot "$slot" 2>"$WORLD/err"; rc=$?
assert_eq "retire.sh exits 0" "$rc" 0
check "the session in the slot is gone" "$(alive "$P2" && echo 0 || echo 1)"
check "the bystander is still running" "$(alive "$P_BY" && echo 1 || echo 0)"
plant bg-slot3 "$slot"; P3="$(pid_of bg-slot3)"
"$REPO/herdr/bin/retire.sh" "$NA" --pane "$pane" 2>"$WORLD/err"; rc=$?
assert_eq "without --slot a claude only in the cwd is not swept" "$(alive "$P3" && echo kept || echo gone)" kept
kill "$P3" 2>/dev/null
"$SEAT" --down "$NA" >/dev/null 2>&1

echo "-- AC-H1: a pid that survives three rounds is a 500 note naming it, and the function returns 1"
out="$("$SEAT" --ticket "$A" --role worker)"; slot="$(jq -r .worktree <<<"$out")"
plant stuck "$slot"; P4="$(pid_of stuck)"
( . "$REPO/herdr/bin/seat-lib.sh"; kill() { return 0; }; sl_end_seat_procs "$NA" "" "$slot" "" ) 2>"$WORLD/err"; rc=$?
assert_eq "sl_end_seat_procs returns 1" "$rc" 1
assert_match "the log counted three rounds" "$(cat "$WORLD/err")" "round 3 of 3"
note="$(jq -r 'select(.kind == "note" and .code == 500) | .note' "$EVENTS"/2*/*/*.json | grep survived | head -1)"
assert_match "a 500 note names the pid and the process" "$note" "$P4\(.*claude"
kill "$P4" 2>/dev/null
"$SEAT" --down "$NA" >/dev/null 2>&1
case_done
