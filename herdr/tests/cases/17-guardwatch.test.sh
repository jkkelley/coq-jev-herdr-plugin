#!/usr/bin/env bash
# Catches (WO-20261012-ee9c, AC-H1, AC-H2): guardwatch.sh calling the guard for a session that is not the one running in the
# pane (the 2026-10-12 02:16Z flood: about 189 dead sessions bound to the architect pane, one GOV-100 memo each), calling it
# for a pane that has no claude process, calling it more than once per live pane per tick, not writing the resolved session to
# seat.json, or leaving a stale seat.json session in place.
# World: one worker seat from seat.sh (stub claude, which writes ~/.claude/sessions/<pid>.json as the real one does), two
# guard bindings on its pane (the live session and a dead one), and a plain shell pane that only an exemption names. The
# guard is the suite's stub; COMPACTION_GUARD_STUB_LOG records every argv it is called with.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/assert.sh"; . "$HERE/../lib/world.sh"
world_up guardwatch || exit 1
GW="$REPO/herdr/bin/guardwatch.sh"; GS="$HOME/.local/state/compaction-guard/sessions"
export COMPACTION_GUARD_STUB_LOG="$WORLD/guard.log"; : > "$COMPACTION_GUARD_STUB_LOG"
W=worker-wo-20261010-8777

mk_binding() { mkdir -p "$GS/$1"; jq -n --arg s "$1" --arg p "$2" --arg hs "$COQ_HERDR_SESSION" '{session:$s, driver:"herdr", pane:$p, herdr_session:$hs, freeze_seconds:180}' > "$GS/$1/binding.json"; }
calls() { grep -c . "$COMPACTION_GUARD_STUB_LOG" || true; }

"$SEAT" --ticket WO-20261010-8777 --role worker --worktree "$REPO" >/dev/null; assert_eq "the worker comes up" "$?" 0
WP="$(jq -r .pane "$STATE/seats/$W/seat.json")"
pid="$(h pane process-info --pane "$WP" | jq -r 'first(.result.process_info.foreground_processes[] | select(.argv[1] | endswith("/claude")) | .pid) // empty')"
assert_match "herdr names a claude process in the seat's pane" "$pid" '^[0-9]+$'
LIVE="$(jq -r .sessionId "$HOME/.claude/sessions/$pid.json")"
assert_match "the stub claude wrote its session file" "$LIVE" '^stub-[0-9]+$'
mk_binding "$LIVE" "$WP"; mk_binding s-dead-one "$WP"; mk_binding s-dead-two "$WP"

echo "-- AC-H1: three bindings on one pane, two dead - one guard call, for the live session"
"$GW" --once > "$WORLD/out" 2>&1; rc=$?; out="$(cat "$WORLD/out")"
echo "$out" | sed 's/^/    /'
assert_eq "exit 0" "$rc" 0
assert_match "the live session is watched" "$out" "^watched $WP $W $LIVE$"
assert_eq "the guard was called once" "$(calls)" 1
assert_eq "the one call is watch --once --session <live>" "$(cat "$COMPACTION_GUARD_STUB_LOG")" "watch --once --session $LIVE"
assert_eq "no dead session was named" "$(grep -c 's-dead' "$COMPACTION_GUARD_STUB_LOG")" 0

echo "-- seat.json carries the resolved session, and a stale one is replaced"
assert_eq "claude_session is the live session" "$(jq -r .claude_session "$STATE/seats/$W/seat.json")" "$LIVE"
jq '.claude_session = "stale-session"' "$STATE/seats/$W/seat.json" > "$WORLD/seat.tmp" && mv "$WORLD/seat.tmp" "$STATE/seats/$W/seat.json"
: > "$COMPACTION_GUARD_STUB_LOG"
"$GW" --once >/dev/null 2>&1
assert_eq "the stale session was rewritten" "$(jq -r .claude_session "$STATE/seats/$W/seat.json")" "$LIVE"

echo "-- AC-H2: a pane with no claude process is skipped with one line and no guard call"
SP="$(h pane split "$WORLD_TEST_PANE" --direction right --no-focus | jq -r '.result.pane.pane_id // empty')"
assert_match "a plain shell pane exists" "$SP" '^w'
jq --arg p "$SP" '.exemptions += [{pane:$p, rule:"seat.audit", until:"2099-01-01T00:00:00Z", card_id:"suite-fixture", why:"a shell pane with no agent"}]' \
  "$REPO/herdr/config/exemptions.json" > "$WORLD/ex.json" && mv "$WORLD/ex.json" "$REPO/herdr/config/exemptions.json"
: > "$COMPACTION_GUARD_STUB_LOG"
"$GW" --once > "$WORLD/out" 2>&1; out="$(cat "$WORLD/out")"
echo "$out" | sed 's/^/    /'
assert_eq "exactly one skipped line for the shell pane" "$(grep -c "^skipped $SP " <<<"$out")" 1
assert_match "the line says there is no claude process" "$out" "^skipped $SP $SP \(no claude process in the pane\)$"
assert_eq "the guard was still called once, for the worker only" "$(calls)" 1

echo "-- a seat whose claude is gone is skipped, not watched"
rm -f "$HOME/.claude/sessions/$pid.json"
: > "$COMPACTION_GUARD_STUB_LOG"
"$GW" --once > "$WORLD/out" 2>&1; out="$(cat "$WORLD/out")"
assert_match "claude without a session file is skipped" "$out" "^skipped $WP $W \(claude has no session file yet\)$"
assert_eq "no guard call at all" "$(calls)" 0

"$SEAT" --down "$W" >/dev/null
case_done
