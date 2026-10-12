#!/usr/bin/env bash
# Catches: unfreeze.sh --all releasing a lease that has not run out, leaving an expired one in place, skipping the
# hand-started architect pane that only exemptions.json names (the seat that froze on 2026-10-10), not waking the seat,
# not recording the release as a note 100 from seat unfreeze, or releasing the pane it runs in.
# WO-20261012-ee9c (AC-H3): unfreeze.sh releases the guard session the pane's claude is running (the stub writes its session
# file as the real one does), never a dead session bound to the same pane; the section at the end freezes one of each.
# World: two seats from seat.sh (a worker with an expired lease, a reviewer inside its lease), one hand-started stub agent
# in its own tab that only an exemption names, and hand-written guard state for all three. compaction-guard is the
# suite's stub, so the host's guard and its sessions are never touched.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/assert.sh"; . "$HERE/../lib/world.sh"
world_up unfreeze || exit 1
UF="$REPO/herdr/bin/unfreeze.sh"; GS="$HOME/.local/state/compaction-guard/sessions"
W=worker-wo-20261010-8777; R=reviewer-wo-20261010-539f

# mk_session <sid> <pane> <phase> <age seconds> <freeze seconds>: the two files compaction-guard keeps per session, with
# the fields unfreeze.sh reads (binding: driver, pane, herdr_session, freeze_seconds; phase: phase, armed_at).
mk_session() {
  mkdir -p "$GS/$1"
  jq -n --arg s "$1" --arg p "$2" --arg hs "$COQ_HERDR_SESSION" --argjson f "$5" \
    '{session:$s, driver:"herdr", pane:$p, herdr_session:$hs, freeze_seconds:$f}' > "$GS/$1/binding.json"
  jq -n --arg ph "$3" --arg at "$(date -u -d "@$(( $(date +%s) - $4 ))" +%Y-%m-%dT%H:%M:%SZ)" '{phase:$ph, armed_at:$at, armed_by:"manual"}' > "$GS/$1/phase.json"
}
# live_sid <pane>: the session id of the claude process in that pane, read the way seat-lib.sh sl_pane_session reads it.
live_sid() {
  local pid; pid="$(h pane process-info --pane "$1" | jq -r 'first(.result.process_info.foreground_processes[] | select(.argv[1] | endswith("/claude")) | .pid) // empty')"
  [ -n "$pid" ] && jq -r .sessionId "$HOME/.claude/sessions/$pid.json"
}
phase_of() { jq -r .phase "$GS/$1/phase.json"; }
# unfreeze_notes: how many note 100 records seat unfreeze has written in this world.
unfreeze_notes() { local n=0 f; for f in "$EVENTS"/2*/*/*.json; do [ -f "$f" ] || continue; jq -e '.kind == "note" and .code == 100 and .seat == "unfreeze"' "$f" >/dev/null 2>&1 && n=$((n + 1)); done; echo "$n"; }
# heard <agent>: how many screen lines carry the wake prompt; the stub echoes what it is sent (input box and "> " line), so
# the count is at least 1 for an agent that got it and exactly 0 for one that did not.
heard() { h agent read "$1" --source recent-unwrapped --lines 200 | grep -c 'guard lease released by unfreeze.sh at'; }

echo "-- a world: two seats and a hand-started agent that only an exemption names"
"$SEAT" --ticket WO-20261010-8777 --role worker --worktree "$REPO" >/dev/null; assert_eq "the worker comes up" "$?" 0
"$SEAT" --ticket WO-20261010-539f --role reviewer --worktree "$REPO" >/dev/null; assert_eq "the reviewer comes up" "$?" 0
WP="$(jq -r .pane "$STATE/seats/$W/seat.json")"; RP="$(jq -r .pane "$STATE/seats/$R/seat.json")"
ws="$(h workspace list | jq -r '.result.workspaces[] | select(.label == "coq") | .workspace_id')"
AP="$(h tab create --workspace "$ws" --label arch --cwd "$REPO" | jq -r '.result.root_pane.pane_id // empty')"
assert_match "the hand-started tab has a pane" "$AP" '^w'
sleep 2; h agent start arch --kind claude --pane "$AP" -- --model x >/dev/null; assert_eq "the hand-started agent comes up" "$?" 0
jq --arg p "$AP" '.exemptions += [{pane:$p, rule:"seat.audit", until:"2099-01-01T00:00:00Z", card_id:"suite-fixture", why:"a hand-started pane with no seat record"}]' \
  "$REPO/herdr/config/exemptions.json" > "$WORLD/ex.json" && mv "$WORLD/ex.json" "$REPO/herdr/config/exemptions.json"
SW="$(live_sid "$WP")"; SR="$(live_sid "$RP")"; SA="$(live_sid "$AP")"
assert_match "the worker pane names a live session" "$SW" '^stub-[0-9]+$'; assert_match "the reviewer pane names a live session" "$SR" '^stub-[0-9]+$'
assert_match "the hand-started pane names a live session" "$SA" '^stub-[0-9]+$'
mk_session "$SW" "$WP" compacting 600 180
mk_session "$SR" "$RP" armed 30 180
mk_session "$SA" "$AP" compacting 900 180

echo "-- AC-H2: one --all pass releases what ran out and leaves what did not"
"$UF" --all > "$WORLD/out" 2>&1; rc=$?; out="$(cat "$WORLD/out")"
echo "$out" | sed 's/^/    /'
assert_eq "exit 1: a lease inside its time is left in place" "$rc" 1
assert_match "the expired worker lease is released" "$out" "^released $WP $W \(compacting 6[0-9]{2}s, lease 180s\)$"
assert_match "the exempt hand-started pane is released too" "$out" "^released $AP $AP \(compacting 9[0-9]{2}s, lease 180s\)$"
assert_match "the fresh reviewer lease prints ok" "$out" "^ok $RP $R \(armed [0-9]+s, lease 180s not yet up\)$"
assert_eq "the worker guard session is idle" "$(phase_of "$SW")" idle
assert_eq "the exempt pane's guard session is idle" "$(phase_of "$SA")" idle
assert_eq "the fresh lease is untouched" "$(phase_of "$SR")" armed
sleep 2
check "the worker's agent heard the wake prompt" "$(( $(heard "$W") >= 1 ))"
check "the hand-started agent heard the wake prompt" "$(( $(heard arch) >= 1 ))"
assert_eq "the reviewer heard nothing" "$(heard "$R")" 0
assert_eq "one note 100 from seat unfreeze per release" "$(unfreeze_notes)" 2
assert_match "the note names the worker, its phase and its lease" "$(jq -rs 'map(select(.seat == "unfreeze") | .note) | join(" ")' "$EVENTS"/2*/*/*.json)" "released $W \(compacting [0-9]+s, lease 180s, force=0\)"

echo "-- a second pass finds nothing new to release"
"$UF" --all > "$WORLD/out" 2>&1; out="$(cat "$WORLD/out")"
assert_eq "nothing is released again" "$(grep -c '^released' <<<"$out")" 0
assert_match "the worker now reads not frozen" "$out" "^ok $WP $W \(not frozen\)$"
assert_eq "still two notes" "$(unfreeze_notes)" 2

echo "-- a pane never releases itself"
mk_session "$SW" "$WP" compacting 600 180
HERDR_PANE_ID="$WP" "$UF" --all > "$WORLD/out" 2>&1; rc=$?; out="$(cat "$WORLD/out")"
assert_eq "exit 1" "$rc" 1
assert_match "its own pane is refused" "$out" "^refused $WP \(a seat never releases itself"
assert_eq "its lease is still held" "$(phase_of "$SW")" compacting
assert_eq "no note was written for the refusal" "$(unfreeze_notes)" 2
"$UF" --all >/dev/null 2>&1
assert_eq "from outside it is released" "$(phase_of "$SW")" idle

echo "-- AC-H3: a dead session's lease is never released into a live seat's pane"
# Two dead sessions bound to the worker's pane, both past their lease, next to the live one, also frozen. Only the live one may
# be released; the dead ones get no release call and the seat gets exactly one wake prompt.
mk_session "$SW" "$WP" compacting 600 180
mk_session s-dead-one "$WP" compacting 900 180
mk_session s-dead-two "$WP" armed 900 180
before="$(heard "$W")"; notes="$(unfreeze_notes)"
"$UF" --all > "$WORLD/out" 2>&1; out="$(cat "$WORLD/out")"
echo "$out" | sed 's/^/    /'
assert_eq "exactly one release line for the worker pane" "$(grep -c "^released $WP " <<<"$out")" 1
assert_eq "the live session is released" "$(phase_of "$SW")" idle
assert_eq "the first dead session is untouched" "$(phase_of s-dead-one)" compacting
assert_eq "the second dead session is untouched" "$(phase_of s-dead-two)" armed
assert_eq "one more note 100" "$(unfreeze_notes)" "$((notes + 1))"
sleep 2
check "the seat heard the wake prompt" "$(( $(heard "$W") > before ))"
# With the live session idle, the dead ones alone must release nothing and wake nobody.
mk_session "$SW" "$WP" idle 0 180
before="$(heard "$W")"; notes="$(unfreeze_notes)"
"$UF" --all > "$WORLD/out" 2>&1; out="$(cat "$WORLD/out")"
assert_eq "no release line when only dead sessions are frozen" "$(grep -c "^released $WP " <<<"$out")" 0
assert_match "the worker pane reads not frozen" "$out" "^ok $WP $W \(not frozen\)$"
assert_eq "the dead sessions are still untouched" "$(phase_of s-dead-one)/$(phase_of s-dead-two)" "compacting/armed"
assert_eq "no note was written" "$(unfreeze_notes)" "$notes"
sleep 2
assert_eq "the seat heard nothing new" "$(heard "$W")" "$before"
"$UF" "$W" --force >/dev/null 2>&1
assert_eq "--force on the seat leaves a dead session alone too" "$(phase_of s-dead-one)" compacting

for n in "$W" "$R"; do "$SEAT" --down "$n" >/dev/null; done
case_done
