#!/usr/bin/env bash
# Catches (WO-20261011-8fb3, AC-H1, AC-H2): seat.sh --adopt starting, stopping or restarting the agent it was meant to keep (the
# whole point is that the live session and its context survive), not writing the seat record, the agent name, the pane label,
# the role's settings or the seat.up 100 record, adopting a pane with no agent or a session id herdr contradicts, adopting one
# role twice into two panes, --check not reading an adopted seat like any other, --audit flagging the adopted agent 500 because
# it was started by hand, --down killing the pane or leaving the name on it, or a second adopt duplicating the seat.up record.
# The live agent is the stub claude run by hand in a split of the architect fixture's tab, as the owner's own session is.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/assert.sh"; . "$HERE/../lib/world.sh"
world_up adopt || exit 1
N=interface; ROLE=interface-agent; SID=0b1f6c2e-4d52-4c0e-9a77-5f1d3e8a9c10
# The label the role's layout gives its agent pane, filled in the way seat.sh fills it (the layout differs between checkouts:
# seat-1x2 carries a ticket token, interface-2x2 does not), so the case follows whichever layout the role names.
WANT_LABEL="$(jq -r '.panes[] | select(.kind == "agent") | .label' "$REPO/herdr/layouts/$(jq -r .pane_layout "$REPO/roles/$ROLE.json").json" \
  | sed -e 's|${MODEL}|claude-sonnet-5-5|' -e 's|${effort}|high|' -e 's|${ticket}||' -e "s|\${seat}|$ROLE|")"

# live_pane: split the fixture tab, run the stub claude by hand in it, print the pane id once herdr reports the agent there.
live_pane() {
  local p; p="$(h pane split "$WORLD_TEST_PANE" --direction right --no-focus | jq -r '.result.pane.pane_id // empty')"
  [ -n "$p" ] || return 1
  h pane run "$p" "claude --model by-hand" >/dev/null
  for _ in $(seq 1 20); do
    h agent list | jq -e --arg p "$p" 'any((.result.agents // [])[]; .pane_id == $p and .agent == "claude")' >/dev/null && { echo "$p"; return 0; }
    sleep 1
  done
  return 1
}
fg_pid() { h pane process-info --pane "$1" | jq -r '[.result.process_info.foreground_processes[].pid] | sort | join(",")'; }

P="$(live_pane)" || { echo "  FAIL - no hand-started agent appeared in a split pane"; exit 1; }
before="$(fg_pid "$P")"
assert_eq "the hand-started agent has no herdr name" "$(h agent list | jq -r --arg p "$P" '.result.agents[] | select(.pane_id == $p) | .name // "none"')" none

echo "-- refusals build nothing"
"$SEAT" --adopt --role "$ROLE" --pane "$WORLD_TEST_PANE" --session "$SID" >/dev/null 2>"$WORLD/err"; rc=$?
assert_eq "a pane with no agent is refused, exit 3" "$rc" 3
assert_match "the refusal names the pane" "$(cat "$WORLD/err")" "no agent runs in pane $WORLD_TEST_PANE"
"$SEAT" --adopt --role "$ROLE" --pane "$P" >/dev/null 2>&1; assert_eq "no --session is a usage error, exit 2" "$?" 2
"$SEAT" --adopt --role "$ROLE" --session "$SID" >/dev/null 2>&1; assert_eq "no --pane is a usage error, exit 2" "$?" 2
"$SEAT" --adopt --role worker --pane "$P" --session "$SID" >/dev/null 2>"$WORLD/err"; rc=$?
assert_eq "a role that names its seat from a ticket needs --ticket, exit 3" "$rc" 3
assert_match "the refusal says to give --ticket" "$(cat "$WORLD/err")" "give --ticket"
"$SEAT" --adopt --role "$ROLE" --runtime codex --pane "$P" --session "$SID" >/dev/null 2>&1; assert_eq "codex has no session id to keep, exit 3" "$?" 3
# herdr keeps the first session id reported for a pane, so the contradiction lives in a pane of its own.
P3="$(live_pane)" || { echo "  FAIL - no third hand-started agent"; exit 1; }
h pane report-agent-session "$P3" --source herdr:claude --agent claude --agent-session-id 99999999-aaaa-bbbb-cccc-000000000000 >/dev/null 2>&1
"$SEAT" --adopt --role "$ROLE" --pane "$P3" --session "$SID" >/dev/null 2>"$WORLD/err"; rc=$?
assert_eq "a session id herdr contradicts is refused, exit 3" "$rc" 3
assert_match "the refusal names the session herdr sees" "$(cat "$WORLD/err")" "runs session 99999999-aaaa-bbbb-cccc-000000000000, not $SID"
assert_eq "no seat record was written" "$([ -f "$STATE/seats/$N/seat.json" ] && echo yes || echo no)" no
assert_eq "no seat.up was recorded" "$(event_count seat.up 100)" 0
h pane close "$P3" >/dev/null 2>&1
# The session herdr reports for the pane being adopted agrees with --session, which is the normal case.
h pane report-agent-session "$P" --source herdr:claude --agent claude --agent-session-id "$SID" >/dev/null 2>&1

echo "-- --adopt keeps the live agent and does the bookkeeping of a seat-up"
out="$("$SEAT" --adopt --role "$ROLE" --pane "$P" --session "$SID")"; rc=$?
assert_eq "adopt exits 0" "$rc" 0
assert_eq "the seat is named from the role label" "$(jq -r .name <<<"$out")" "$N"
assert_eq "no agent was started" "$(jq -r .started <<<"$out")" false
assert_eq "the agent process is the same one" "$(fg_pid "$P")" "$before"
assert_eq "herdr answers for the agent by the seat name, in the same pane" "$(h agent get "$N" | jq -r .result.agent.pane_id)" "$P"
assert_eq "the pane carries the layout's agent label" "$(h pane list | jq -r --arg p "$P" '.result.panes[] | select(.pane_id == $p) | .label')" "$WANT_LABEL"
R="$STATE/seats/$N/seat.json"; S="$STATE/seats/$N/settings.json"
assert_eq "seat.json is marked adopted" "$(jq -r .adopted "$R")" true
assert_eq "seat.json keeps the session id" "$(jq -r .claude_session "$R")" "$SID"
assert_eq "seat.json names the pane" "$(jq -r .pane "$R")" "$P"
assert_eq "seat.json carries no lease, so --down can never return a slot" "$(jq -r '.lease' "$R")" null
assert_eq "seat.json remembers the pane had no label" "$(jq -r '.prior.label' "$R")" ""
assert_eq "seat.json remembers the agent had no name" "$(jq -r '.prior.agent_name' "$R")" null
assert_eq "the role's settings were written for the next restart" "$(jq -r .permissions.defaultMode "$S")" "$(jq -r .permission_mode "$REPO/roles/$ROLE.json")"
assert_eq "no role token survives in the settings" "$(jq -r '[.permissions | (.allow + .deny)[] | select(contains("${"))] | length' "$S")" 0
assert_eq "one seat.up 100 was recorded" "$(event_count seat.up 100)" 1
ev="$(jq -r 'select(.kind == "seat.up") | .note' "$EVENTS"/2*/*/*.json)"
assert_match "the record says adopt and names the session and the pane" "$ev" "^adopt: .*$SID.*$P"
assert_match "the record is on the seat's pane" "$(jq -r 'select(.kind == "seat.up") | .pane' "$EVENTS"/2*/*/*.json)" "^$P$"

echo "-- --check reads an adopted seat like any other"
"$SEAT" --check "$N" >/dev/null; assert_eq "--check exits 0 with the agent running" "$?" 0
echo drift >> "$S"
diff="$("$SEAT" --check "$N")"; rc=$?
assert_eq "--check exits 1 on drifted settings" "$rc" 1
assert_match "--check names the drift" "$diff" "settings drifted"
h pane rename "$P" "someone renamed me" >/dev/null
diff="$("$SEAT" --check "$N")"; rc=$?
assert_eq "--check exits 1 on a changed pane label" "$rc" 1
assert_match "--check names the label" "$diff" "pane $P label is 'someone renamed me'"

echo "-- a rerun repairs and records nothing twice"
out2="$("$SEAT" --adopt --role "$ROLE" --pane "$P" --session "$SID")"; rc=$?
assert_eq "rerun exits 0" "$rc" 0
assert_eq "rerun says it is not new" "$(jq -r .new <<<"$out2")" false
assert_eq "rerun did not record seat.up again" "$(event_count seat.up 100)" 1
assert_eq "rerun kept what the first adopt read of the pane" "$(jq -r '.prior.label' "$R")" ""
assert_eq "rerun repaired the label" "$(h pane list | jq -r --arg p "$P" '.result.panes[] | select(.pane_id == $p) | .label')" "$WANT_LABEL"
"$SEAT" --check "$N" >/dev/null; assert_eq "--check exits 0 after the repair" "$?" 0
assert_eq "the agent process is still the same one" "$(fg_pid "$P")" "$before"

echo "-- one role, one live seat"
P2="$(live_pane)" || { echo "  FAIL - no second hand-started agent"; exit 1; }
"$SEAT" --adopt --role "$ROLE" --pane "$P2" --session "$SID" >/dev/null 2>"$WORLD/err"; rc=$?
assert_eq "a second pane for a live role is refused, exit 3" "$rc" 3

echo "-- --audit matches the adopted agent by its pane"
aud="$("$SEAT" --audit)"; rc=$?
assert_eq "--audit exits 1 only because the second hand-started agent is out of compliance" "$rc" 1
assert_match "the adopted agent is compliant" "$aud" "COMPLIANT $P $N pid [0-9]+ \\(adopted"
assert_match "the unadopted one is not" "$aud" "OUT OF COMPLIANCE $P2 "
assert_eq "only that one was recorded 500" "$(event_count seat.stalled 500)" 1

echo "-- --down retires the record and leaves the agent alone"
"$SEAT" --down "$N" >/dev/null; assert_eq "--down exits 0" "$?" 0
assert_eq "the pane is still there" "$(h pane list | jq -r --arg p "$P" '[.result.panes[] | select(.pane_id == $p)] | length')" 1
assert_eq "the agent process is still the same one" "$(fg_pid "$P")" "$before"
assert_eq "herdr still reports the claude agent in the pane" "$(h agent list | jq -r --arg p "$P" '[.result.agents[] | select(.pane_id == $p and .agent == "claude")] | length')" 1
assert_eq "the seat name is gone from the agent" "$(h agent list | jq -r --arg p "$P" '.result.agents[] | select(.pane_id == $p) | .name // "none"')" none
h agent get "$N" >/dev/null 2>&1 && ok=0 || ok=1; check "herdr no longer answers for the seat name" "$ok"
assert_eq "the pane label went back to what adopt read" "$(h pane list | jq -r --arg p "$P" '.result.panes[] | select(.pane_id == $p) | .label // ""')" ""
assert_eq "a seat.down 100 was recorded" "$(event_count seat.down 100)" 1
assert_match "the record carries ended_at" "$(jq -r .ended_at "$R")" '^2[0-9]{3}-'
"$SEAT" --check "$N" >/dev/null 2>&1; assert_eq "--check on a downed seat exits 3" "$?" 3
"$SEAT" --down "$N" >/dev/null; assert_eq "a second --down exits 0" "$?" 0
assert_eq "a second --down records nothing" "$(event_count seat.down 100)" 1
"$SEAT" --adopt --role "$ROLE" --pane "$P" --session "$SID" >/dev/null; rc=$?
assert_eq "the same pane can be adopted again after --down" "$rc" 0
assert_eq "and that is a new seat.up" "$(event_count seat.up 100)" 2
case_done
