#!/usr/bin/env bash
# Catches: a claude seat that acks the compaction-guard memo and goes idle never receiving the continue prompt (AC-H1, the stall of
# WO-20261010-8fa8, -a429, -2d04 and WO-20261011-4c5e), a seat that keeps working past the ack being prompted anyway (AC-H2), a seat
# prompted more than once (a repair rerun, a second look), seat.json missing nudged_at or --check calling it a difference (AC-H3),
# and a seat whose guard sends no memo failing instead of moving on. The stub claude (tests/stubs/claude) plays the memo's ack from
# a mode file; the settle window is 4 s here so the working case stays short. WO-20261011-dc0d.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/assert.sh"; . "$HERE/../lib/world.sh"
world_up nudge '.nudge_wait_seconds = 8 | .nudge_settle_seconds = 4' || exit 1
A=WO-20261010-8777; NA=worker-wo-20261010-8777
B=WO-20261010-c274; NB=worker-wo-20261010-c274
C=WO-20261010-8fa8; NC=worker-wo-20261010-8fa8
D=WO-20261010-539f; ND=worker-wo-20261010-539f
MODE="$HOME/claude-stub.mode"
nudges() { h agent read "$1" --source recent-unwrapped --lines 300 | grep -c '^> .*[Cc]ontinue your brief'; }
up() { "$SEAT" --ticket "$1" --role worker --worktree "$REPO" 2>"$WORLD/err-$1"; }

echo "-- AC-H1: a seat that acks the memo and goes idle gets one continue prompt"
echo ack > "$MODE"
up "$A" >/dev/null; rc=$?
assert_eq "seat.sh exits 0" "$rc" 0
assert_match "the log says the seat was nudged once" "$(cat "$WORLD/err-$A")" "seat $NA: idle after the guard ack, nudged once"
sleep 1
assert_eq "the seat received exactly one continue prompt" "$(nudges "$NA")" 1
assert_match "the prompt names the ticket and its title" "$(h agent read "$NA" --source recent-unwrapped --lines 300)" "> $A - .+\. Continue your brief from the step you reached\. Playbook playbooks/worker\.md\."
assert_match "seat.json nudged_at is a UTC timestamp" "$(jq -r .nudged_at "$STATE/seats/$NA/seat.json")" '^2[0-9]{3}-[0-9]{2}-[0-9]{2}T[0-9:]{8}Z$'
"$SEAT" --check "$NA" >/dev/null; assert_eq "--check reports nothing for a nudged seat" "$?" 0

echo "-- a repair rerun of that live seat nudges nothing more and keeps nudged_at"
was="$(jq -r .nudged_at "$STATE/seats/$NA/seat.json")"
up "$A" >/dev/null; assert_eq "the rerun exits 0" "$?" 0
sleep 1
assert_eq "still one continue prompt" "$(nudges "$NA")" 1
assert_eq "nudged_at is the one first recorded" "$(jq -r .nudged_at "$STATE/seats/$NA/seat.json")" "$was"
"$SEAT" --down "$NA" >/dev/null; assert_eq "--down exits 0" "$?" 0

echo "-- AC-H2: a seat that keeps working after the ack gets no prompt"
echo "ack-work 12" > "$MODE"
up "$B" >/dev/null; assert_eq "seat.sh exits 0" "$?" 0
assert_match "the log says the seat was still working" "$(cat "$WORLD/err-$B")" "seat $NB: still working after the guard ack, no nudge"
assert_eq "herdr reads the seat as working, so the case proves working and not just not-idle" \
  "$(h pane list | jq -r --arg p "$(jq -r .pane "$STATE/seats/$NB/seat.json")" '.result.panes[] | select(.pane_id == $p) | .agent_status')" working
sleep 1
assert_eq "no continue prompt was sent" "$(nudges "$NB")" 0
assert_eq "seat.json nudged_at is null" "$(jq -c .nudged_at "$STATE/seats/$NB/seat.json")" null
"$SEAT" --check "$NB" >/dev/null; assert_eq "--check reports nothing for a seat that was not nudged" "$?" 0
sleep 12
assert_eq "and none after it finished either: the seat is nudged once at most, at bring-up" "$(nudges "$NB")" 0
"$SEAT" --down "$NB" >/dev/null; assert_eq "--down exits 0" "$?" 0

echo "-- a seat whose guard sends no memo: moves on after nudge_wait_seconds, not an error"
: > "$MODE"
up "$C" >/dev/null; assert_eq "seat.sh exits 0" "$?" 0
assert_match "the log says no ack arrived" "$(cat "$WORLD/err-$C")" "seat $NC: no guard ack within 8s, no nudge"
assert_eq "no continue prompt was sent" "$(nudges "$NC")" 0
assert_eq "seat.json nudged_at is null" "$(jq -c .nudged_at "$STATE/seats/$NC/seat.json")" null
"$SEAT" --down "$NC" >/dev/null; assert_eq "--down exits 0" "$?" 0

echo "-- the wording comes from roles/bin/nudge.sh when it exists"
printf '#!/usr/bin/env bash\necho "NUDGE-FROM-ROLES $4 role $2"\n' > "$REPO/roles/bin/nudge.sh"; chmod +x "$REPO/roles/bin/nudge.sh"
echo ack > "$MODE"
up "$D" >/dev/null; assert_eq "seat.sh exits 0" "$?" 0
sleep 1
assert_match "the seat was prompted with that wording" "$(h agent read "$ND" --source recent-unwrapped --lines 300)" "> NUDGE-FROM-ROLES $D role worker"
"$SEAT" --down "$ND" >/dev/null; assert_eq "--down exits 0" "$?" 0

echo "-- DRY_RUN prints the nudge and waits for nothing"
dry="$(DRY_RUN=1 "$SEAT" --ticket "$A" --role worker --worktree "$REPO" 2>&1 >/dev/null)"; rc=$?
assert_eq "dry run exits 0" "$rc" 0
assert_match "the dry run says it would nudge" "$dry" "DRY: nudge $NA once after the line"
case_done
