#!/usr/bin/env bash
# Catches: recover.sh changing anything in --check, not stopping at the halt flag, leaving a seat whose agent exited
# unrepaired (or repairing one whose agent is alive), failing to bring the monitor seat back, running the guard other
# than once per run, or writing no closing record. Same world as case 04: bringup builds the system, then a worker seat.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/assert.sh"; . "$HERE/../lib/world.sh"
world_up recover '.bringup_gate=true | .require_guard=true' || exit 1
RC="$REPO/herdr/bin/recover.sh"; BU="$REPO/herdr/bin/bringup.sh"
T=WO-20269999-aaaa; N=worker-wo-20269999-aaaa; T2=WO-20269999-bbbb

# A guard that answers like compaction-guard: doctor is ok, recover prints one JSON line per session and logs its argv,
# so the case can count how many times and in which mode recover.sh called it.
mkdir -p "$WORLD/bin"
cat > "$WORLD/bin/compaction-guard" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${GUARD_LOG:?}"
case "${1:-}" in
  doctor) echo '{"ok":true}' ;;
  recover) [ ! -f "${GUARD_NEED:?}" ] || echo '{"session":"s-gone","name":"x","pane_alive":false,"needs_recovery":true}'
           echo '{"session":"s-live","name":"y","pane_alive":true,"needs_recovery":false}' ;;
esac
EOF
chmod +x "$WORLD/bin/compaction-guard"; export PATH="$WORLD/bin:$PATH" GUARD_LOG="$WORLD/guard.log" GUARD_NEED="$WORLD/guard-need"
: > "$GUARD_LOG"

# Two fixture tickets in the world's copy: T gets a seat, T2 is in progress and never gets one.
mkticket() { mkdir -p "$REPO/work-orders/WO-20269999-0000"; cat > "$REPO/work-orders/WO-20269999-0000/$1-fixture.md" <<EOF
---
{"id": "$1", "slug": "fixture", "title": "$2", "type": "feature", "status": "in-progress"}
---

# $1 - $2
EOF
}
mkticket "$T" "fixture ticket with a seat"; mkticket "$T2" "fixture ticket nobody holds"

gone() { # gone <agent name>: end the stub the way the real one ends, then wait until herdr stops answering for it.
  h agent prompt "$1" "/exit" >/dev/null 2>&1
  for _ in $(seq 1 20); do h agent get "$1" >/dev/null 2>&1 || return 0; sleep 1; done
  return 1
}
run() { "$RC" "$1" > "$WORLD/out" 2>&1; rc=$?; out="$(cat "$WORLD/out")"; }
seats_up() { local n=0 f; for f in "$STATE"/seats/*/seat.json; do [ -f "$f" ] && [ -z "$(jq -r '.ended_at // empty' "$f")" ] && n=$((n + 1)); done; echo "$n"; }

# The world is a copy of the repo, so it already holds the repo's own events; every count below is a delta from here.
notes0="$(event_count note 100)"; downs0="$(event_count seat.down 100)"
echo "-- bringup, then a worker seat behind the monitor seat"
"$BU" --worktree "$REPO" >/dev/null 2>&1; assert_eq "bringup exits 0" "$?" 0
"$SEAT" --ticket "$T" --role worker --worktree "$REPO" >/dev/null; assert_eq "the worker comes up" "$?" 0

echo "-- AC-H1: --check on a healthy world prints ok per object and exits 0"
run --check
echo "$out" | sed 's/^/    /'
assert_eq "--check exits 0" "$rc" 0
assert_match "herdr, monitors, the monitor seat, the belt and the worker are ok, in that order" "$(tr '\n' ' ' <<<"$out")" "^ok herdr ok monitors ok monitor ok belt ok $N "
assert_match "the guard ran and was ok" "$out" "^ok compaction-guard$"
assert_match "the ticket nobody holds is warned, with its title" "$out" "^WARN $T2 - fixture ticket nobody holds \(no live seat"
assert_eq "the ticket with a seat is not warned" "$(grep -c "^WARN $T " <<<"$out")" 0
assert_eq "--check called the guard once, without --apply" "$(grep -c '^recover$' "$GUARD_LOG")" 1
# Twelve since WO-20261012-da52 (eleven since WO-20261012-9b2c, ten since WO-20261011-4562): monitors, the monitor seat and ten reserved panes (lease and guard joined events and queue in
# WO-20261010-8fa8, the factory board watch in WO-20261011-616c, the route runner and the flow watch in WO-20261011-6842, the
# break glass restore watch in WO-20261011-4562, the policy watch in WO-20261012-9b2c, the record bus in WO-20261012-da52).
assert_eq "--check wrote no note 100 beyond bringup's twelve" "$(( $(event_count note 100) - notes0 ))" 12

echo "-- AC-H3: the halt flag stops both modes and changes nothing"
touch "$STATE/HALT"; before="$(find "$EVENTS" -name '*.json' | wc -l)"; : > "$GUARD_LOG"
for m in --check --apply; do
  run "$m"
  assert_eq "$m exits 0 on the halt flag" "$rc" 0
  assert_match "$m prints HALTED" "$out" "^HALTED"
  assert_eq "$m printed nothing else" "$(wc -l <<<"$out" | tr -d ' ')" 1
done
assert_eq "no event was written" "$(find "$EVENTS" -name '*.json' | wc -l)" "$before"
assert_eq "the guard was not called" "$(wc -c < "$GUARD_LOG" | tr -d ' ')" 0
assert_file "the flag is still there, never lifted here" "$STATE/HALT"
rm -f "$STATE/HALT"

echo "-- AC-H1: a seat whose agent exited is FAILED (agent gone) and --check changes nothing"
gone "$N" && exited=1 || exited=0; check "the worker's agent exited and herdr no longer answers for $N" "$exited"
before="$(find "$EVENTS" -name '*.json' | wc -l)"
run --check
echo "$out" | sed 's/^/    /'
assert_eq "--check exits 1" "$rc" 1
assert_match "it names the seat and the reason" "$out" "^FAILED $N \(agent gone\)$"
assert_eq "the healthy objects still print ok" "$(grep -c '^ok ' <<<"$out")" 5
assert_eq "no event was written" "$(find "$EVENTS" -name '*.json' | wc -l)" "$before"
assert_eq "the seat record has no ended_at" "$(jq -r '.ended_at // "null"' "$STATE/seats/$N/seat.json")" null
assert_eq "no seat.down was recorded" "$(( $(event_count seat.down 100) - downs0 ))" 0

echo "-- AC-H2: --apply downs the gone seat, records it, and a second --check exits 0"
: > "$GUARD_LOG"; touch "$GUARD_NEED"; notes="$(event_count note 100)"
run --apply
echo "$out" | sed 's/^/    /'
assert_eq "--apply exits 0" "$rc" 0
assert_match "it prints fixed <name>" "$out" "^fixed $N \(agent gone, seat downed\)$"
assert_eq "a seat.down 100 was recorded" "$(( $(event_count seat.down 100) - downs0 ))" 1
assert_match "the record carries ended_at" "$(jq -r .ended_at "$STATE/seats/$N/seat.json")" '^2[0-9]{3}-'
assert_eq "exactly one closing note 100 was recorded" "$(( $(event_count note 100) - notes ))" 1
assert_match "the closing note says what was repaired" "$(jq -rs '[.[] | select(.seat == "recover")] | last | .note' "$EVENTS"/2*/*/*.json)" "2 repaired"
assert_match "the guard was applied, once, in --apply mode" "$(cat "$GUARD_LOG")" "^recover --apply$"
assert_eq "the guard was called exactly once" "$(wc -l < "$GUARD_LOG" | tr -d ' ')" 1
assert_match "the guard line reports the session it re-armed" "$out" "^fixed compaction-guard \(recover --apply ran over 1 session"
rm -f "$GUARD_NEED"
run --check; assert_eq "the second --check exits 0" "$rc" 0
assert_eq "the downed seat is history and is not listed" "$(grep -c "$N" <<<"$out")" 0

echo "-- the monitor seat: --check reports it, --apply brings it back through bringup.sh"
gone monitor
run --check
assert_eq "--check exits 1 with the monitor seat's agent gone" "$rc" 1
assert_match "it names the monitor seat" "$out" "^FAILED monitor \(agent gone\)$"
run --apply
echo "$out" | sed 's/^/    /'
assert_eq "--apply exits 0" "$rc" 0
assert_match "it prints fixed monitor" "$out" "^fixed monitor \(bringup.sh"
assert_eq "the monitor seat is idle again" "$(h agent get monitor | jq -r .result.agent.agent_status)" idle
run --check; assert_eq "--check exits 0 afterwards" "$rc" 0

echo "-- a difference that is not 'agent not running' is reported and never repaired"
"$SEAT" --ticket "$T" --role worker --worktree "$REPO" >/dev/null; assert_eq "the worker is back" "$?" 0
pane="$(h pane list | jq -r --arg l "MONITOR - $N" '.result.panes[] | select(.label == $l) | .pane_id')"
h pane close "$pane" >/dev/null 2>&1
run --apply
echo "$out" | sed 's/^/    /'
assert_eq "--apply exits 1" "$rc" 1
assert_match "the missing pane is reported FAILED" "$out" "^FAILED $N \(pane missing: MONITOR - $N\)$"
h agent get "$N" >/dev/null 2>&1 && alive=1 || alive=0; check "the live agent was not touched" "$alive"
assert_eq "the seat was not downed again" "$(( $(event_count seat.down 100) - downs0 ))" 1
assert_eq "the closing record is a 500" "$(jq -rs '[.[] | select(.seat == "recover")] | last | .code' "$EVENTS"/2*/*/*.json)" 500
"$SEAT" --down "$N" >/dev/null; "$SEAT" --down monitor >/dev/null
assert_eq "every seat is down at the end" "$(seats_up)" 0
case_done
