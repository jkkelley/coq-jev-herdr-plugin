#!/usr/bin/env bash
# Catches: unfreeze.sh --all releasing a lease that has not run out, leaving an expired one in place, skipping the
# hand-started architect pane that only exemptions.json names (the seat that froze on 2026-10-10), not waking the seat,
# not recording the release as a note 100 from seat unfreeze, or releasing the pane it runs in.
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
ws="$(h workspace list | jq -r '.result.workspaces[0].workspace_id')"
AP="$(h tab create --workspace "$ws" --label arch --cwd "$REPO" | jq -r '.result.root_pane.pane_id // empty')"
assert_match "the hand-started tab has a pane" "$AP" '^w'
sleep 2; h agent start arch --kind claude --pane "$AP" -- --model x >/dev/null; assert_eq "the hand-started agent comes up" "$?" 0
jq --arg p "$AP" '.exemptions += [{pane:$p, rule:"seat.audit", until:"2099-01-01T00:00:00Z", card_id:"suite-fixture", why:"a hand-started pane with no seat record"}]' \
  "$REPO/herdr/config/exemptions.json" > "$WORLD/ex.json" && mv "$WORLD/ex.json" "$REPO/herdr/config/exemptions.json"
mk_session s-worker "$WP" compacting 600 180
mk_session s-review "$RP" armed 30 180
mk_session s-arch "$AP" compacting 900 180

echo "-- AC-H2: one --all pass releases what ran out and leaves what did not"
"$UF" --all > "$WORLD/out" 2>&1; rc=$?; out="$(cat "$WORLD/out")"
echo "$out" | sed 's/^/    /'
assert_eq "exit 1: a lease inside its time is left in place" "$rc" 1
assert_match "the expired worker lease is released" "$out" "^released $WP $W \(compacting 6[0-9]{2}s, lease 180s\)$"
assert_match "the exempt hand-started pane is released too" "$out" "^released $AP $AP \(compacting 9[0-9]{2}s, lease 180s\)$"
assert_match "the fresh reviewer lease prints ok" "$out" "^ok $RP $R \(armed [0-9]+s, lease 180s not yet up\)$"
assert_eq "the worker guard session is idle" "$(phase_of s-worker)" idle
assert_eq "the exempt pane's guard session is idle" "$(phase_of s-arch)" idle
assert_eq "the fresh lease is untouched" "$(phase_of s-review)" armed
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
mk_session s-worker "$WP" compacting 600 180
HERDR_PANE_ID="$WP" "$UF" --all > "$WORLD/out" 2>&1; rc=$?; out="$(cat "$WORLD/out")"
assert_eq "exit 1" "$rc" 1
assert_match "its own pane is refused" "$out" "^refused $WP \(a seat never releases itself"
assert_eq "its lease is still held" "$(phase_of s-worker)" compacting
assert_eq "no note was written for the refusal" "$(unfreeze_notes)" 2
"$UF" --all >/dev/null 2>&1
assert_eq "from outside it is released" "$(phase_of s-worker)" idle

for n in "$W" "$R"; do "$SEAT" --down "$n" >/dev/null; done
case_done
