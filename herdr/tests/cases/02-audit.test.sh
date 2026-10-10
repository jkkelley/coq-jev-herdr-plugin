#!/usr/bin/env bash
# Catches: seat.sh --audit missing a hand-started agent (AC-H2), judging a seat.sh-started seat non-compliant, or not
# recording seat.stalled 500. Two halves: the container's real /proc after a real seat and a hand-started stub in a
# second pane, then a /proc fixture (SEAT_PROC) for the flag comparisons no live run can vary cheaply.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/assert.sh"; . "$HERE/../lib/world.sh"
world_up audit || exit 1
T=WO-20261010-8777; N=worker-wo-20261010-8777

echo "-- live: one seat through seat.sh, one agent started by hand"
out="$("$SEAT" --ticket "$T" --role worker --worktree "$REPO")"; ws="$(jq -r .workspace <<<"$out")"
hand="$(h tab create --workspace "$ws" --cwd /tmp --label by-hand --no-focus | jq -r .result.root_pane.pane_id)"
h pane wait-output "$hand" --regex '[$%>❯] *$' --timeout 10000 >/dev/null
h agent start by-hand --kind claude --pane "$hand" -- --permission-mode bypassPermissions >/dev/null
sleep 1
rep="$("$SEAT" --audit)"; rc=$?
echo "$rep" | sed 's/^/    /'
assert_eq "--audit exits 1 with a hand-started agent present" "$rc" 1
assert_match "the seat.sh seat is COMPLIANT" "$rep" "^COMPLIANT [^ ]+ $N pid"
assert_match "the hand-started agent is OUT OF COMPLIANCE" "$rep" "^OUT OF COMPLIANCE [^ ]+ claude pid [0-9]+: hand-started"
assert_eq "one seat.stalled 500 was recorded" "$(event_count seat.stalled 500)" 1
h agent prompt by-hand "/exit" >/dev/null 2>&1; sleep 1
"$SEAT" --down "$N" >/dev/null

echo "-- fixture: flags that drift from the role"
P="$WORLD/proc"; mkdir -p "$P"
R="$STATE/seats/$N/seat.json"; S="$(jq -r .settings "$R")"
jq '.ended_at=null' "$R" > "$R.tmp" && mv "$R.tmp" "$R"
mkproc() { # mkproc PID "argv\0..." "ENV\0..."
  mkdir -p "$P/$1"; printf '%b' "$2" > "$P/$1/cmdline"; printf '%b' "$3" > "$P/$1/environ"
}
mkproc 10 "claude\0--model\0claude-sonnet-5-5\0--effort\0high\0--permission-mode\0bypassPermissions\0--settings\0$S\0" "COQ_SEAT=$N\0HERDR_PANE_ID=w9:p1\0"
mkproc 11 "claude\0--model\0claude-sonnet-5-5\0--permission-mode\0dontAsk\0--settings\0$S\0" "COQ_SEAT=$N\0HERDR_PANE_ID=w9:p2\0"
mkproc 12 "claude\0--model\0claude-sonnet-5-5\0--permission-mode\0bypassPermissions\0" "COQ_SEAT=$N\0HERDR_PANE_ID=w9:p3\0"
mkproc 13 "claude\0bg-helper\0" "COQ_SEAT=$N\0"
mkproc 14 "bash\0/x/stubs/claude\0--model\0claude-sonnet-5-5\0--permission-mode\0bypassPermissions\0--settings\0$S\0" "COQ_SEAT=$N\0HERDR_PANE_ID=w9:p4\0"
mkproc 15 "zsh\0" ""
rep="$(SEAT_PROC="$P" "$SEAT" --audit)"; rc=$?
echo "$rep" | sed 's/^/    /'
assert_match "matching flags are COMPLIANT" "$rep" "^COMPLIANT w9:p1 $N pid 10"
assert_match "a permission mode other than the role's is named" "$rep" "^OUT OF COMPLIANCE w9:p2 $N pid 11: permission mode dontAsk, role says bypassPermissions"
assert_match "a missing --settings is named" "$rep" "^OUT OF COMPLIANCE w9:p3 $N pid 12: settings , seat.sh rendered"
assert_match "an interpreter-launched claude is read as claude" "$rep" "^COMPLIANT w9:p4 $N pid 14"
assert_match "claude bg-* helpers and shells are skipped" "$rep" "^audited: 4 agent processes"
assert_eq "exit 1 while any is out of compliance" "$rc" 1
assert_eq "one seat.stalled 500 per non-compliant process" "$(event_count seat.stalled 500)" 3

echo "-- fixture: an exemption with a card id lifts the audit for a pane"
jq --arg p w9:p2 '.exemptions += [{pane:$p, rule:"seat.audit", until:"2999-01-01T00:00:00Z", card_id:"test-card", why:"case 02"}]' \
  "$REPO/herdr/config/exemptions.json" > "$REPO/herdr/config/exemptions.json.tmp" && mv "$REPO/herdr/config/exemptions.json.tmp" "$REPO/herdr/config/exemptions.json"
rep="$(SEAT_PROC="$P" "$SEAT" --audit)"
assert_match "the exempt pane is reported EXEMPT, not failed" "$rep" "^EXEMPT w9:p2 $N pid 11"
case_done
