#!/usr/bin/env bash
# Catches: seat.sh building the wrong tab, panes or labels (AC-H1), starting the agent with flags other than the role's,
# rendering settings that miss the role's deny list, duplicating on a rerun instead of repairing, or --check and --down
# misreporting. Runs against a real headless herdr, so the JSON shapes are herdr's own.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/assert.sh"; . "$HERE/../lib/world.sh"
world_up seat || exit 1
T=WO-20261010-8777; N=worker-wo-20261010-8777

echo "-- a ticket seat needs the labelled test pane in the tab it was started from"
env -u HERDR_TAB_ID "$SEAT" --ticket "$T" --role worker --worktree "$REPO" >/dev/null 2>"$WORLD/err"; rc=$?
assert_eq "refused with exit 3 when the caller is in no tab" "$rc" 3
assert_match "the refusal names the missing test pane" "$(cat "$WORLD/err")" "no pane labelled 'test - herdr'"
assert_eq "nothing was built" "$(h workspace list | jq '[.result.workspaces[] | select(.label == "coq")] | length')" 0

echo "-- door 1: --ticket $T --role worker"
out="$("$SEAT" --ticket "$T" --role worker --worktree "$REPO")"; rc=$?
assert_eq "door 1 exits 0" "$rc" 0
assert_eq "the seat is named from the role label, lowercased" "$(jq -r .name <<<"$out")" "$N"
ws="$(jq -r .workspace <<<"$out")"; tab="$(jq -r .tab <<<"$out")"; agent="$(jq -r .agent <<<"$out")"
assert_eq "the workspace carries the configured label" "$(h workspace list | jq -r --arg w "$ws" '.result.workspaces[] | select(.workspace_id == $w) | .label')" coq
assert_match "the brief names the test pane the worker may use" "$(h agent read "$N" --source recent-unwrapped --lines 200)" "Your test pane is $WORLD_TEST_PANE; run commands only there, through herdr/bin/testpane.sh"
assert_eq "COQ_TEST_PANE rode the environment line into the agent pane" "$(h pane read "$agent" --source recent-unwrapped --lines 200 | grep -cF "COQ_TEST_PANE=$WORLD_TEST_PANE")" 1
assert_eq "the tab carries the seat name" "$(h tab list --workspace "$ws" | jq -r --arg t "$tab" '.result.tabs[] | select(.tab_id == $t) | .label')" "$N"
assert_eq "seat-1x2 builds 2 panes with SPEC-04 labels" "$(pane_labels "$ws" "$tab")" "MONITOR - $N|claude-sonnet-5-5 - high - $T worker"
assert_eq "herdr answers for the agent, idle" "$(h agent get "$N" | jq -r .result.agent.agent_status)" idle
argv="$(h pane process-info --pane "$agent" | jq -r '[.result.process_info.foreground_processes[].argv | join(" ")] | join("; ")')"
assert_match "the agent was started with the role's model, effort, permission mode and the rendered settings" "$argv" \
  "claude --model claude-sonnet-5-5 --effort high --permission-mode bypassPermissions --settings $STATE/seats/$N/settings.json"
S="$STATE/seats/$N/settings.json"
assert_eq "settings default mode is the role's" "$(jq -r .permissions.defaultMode "$S")" bypassPermissions
miss=0; while IFS= read -r c; do
  if [[ "$c" == *'*'* ]]; then r="Bash($c)"; else r="Bash($c:*)"; fi
  jq -e --arg r "$r" '.permissions.deny | index($r) != null' "$S" >/dev/null || { miss=1; echo "    deny lacks $r"; }
done < <(jq -r '.deny.commands[]' "$REPO/roles/worker.json")
check "the rendered deny list holds every deny command of the role" "$((1 - miss))"
assert_eq "bare Edit and Write are not allowed" "$(jq -r '.permissions.allow | any(. == "Edit" or . == "Write")' "$S")" false
assert_eq "a seat.up 100 event was recorded" "$(event_count seat.up 100)" 1
R="$STATE/seats/$N/seat.json"
assert_eq "the seat record names the agent pane" "$(jq -r .pane "$R")" "$agent"
assert_eq "the seat record has no ended_at" "$(jq -r '.ended_at // "null"' "$R")" null
sleep 1
assert_match "the brief was the first prompt and names the ticket and playbook" "$(h agent read "$N" --source recent-unwrapped --lines 200)" "$T - herdr seat scripts.*Playbook playbooks/worker.md"

echo "-- --check on a healthy seat"
"$SEAT" --check "$N" >/dev/null; assert_eq "--check exits 0" "$?" 0

echo "-- rerun is a repair, not a duplicate"
out2="$("$SEAT" --ticket "$T" --role worker --worktree "$REPO")"; rc=$?
assert_eq "rerun exits 0" "$rc" 0
assert_eq "rerun did not start a second agent" "$(jq -r .started <<<"$out2")" false
assert_eq "still one tab for the seat" "$(h tab list --workspace "$ws" | jq -r --arg l "$N" '[.result.tabs[] | select(.label == $l)] | length')" 1
assert_eq "still 2 panes" "$(h pane list --workspace "$ws" | jq -r --arg t "$tab" '[.result.panes[] | select(.tab_id == $t)] | length')" 2
mon="$(h pane list --workspace "$ws" | jq -r --arg t "$tab" --arg l "MONITOR - $N" '.result.panes[] | select(.tab_id == $t and .label == $l) | .pane_id')"
h pane close "$mon" >/dev/null 2>&1
diff="$("$SEAT" --check "$N")"; rc=$?
assert_eq "--check exits 1 with the monitor pane gone" "$rc" 1
assert_match "--check names the missing pane" "$diff" "pane missing: MONITOR - $N"
"$SEAT" --ticket "$T" --role worker --worktree "$REPO" >/dev/null
assert_eq "the rerun split the missing pane back" "$(pane_labels "$ws" "$tab")" "MONITOR - $N|claude-sonnet-5-5 - high - $T worker"
"$SEAT" --check "$N" >/dev/null; assert_eq "--check exits 0 after the repair" "$?" 0

echo "-- --down"
"$SEAT" --down "$N" >/dev/null; assert_eq "--down exits 0" "$?" 0
h agent get "$N" >/dev/null 2>&1 && ok=0 || ok=1; check "herdr no longer answers for the agent" "$ok"
# The seat's tab was the workspace's last, so herdr closed the workspace with it; either answer means the tab is gone.
assert_eq "the tab is closed" "$({ h tab list --workspace "$ws" 2>/dev/null || echo '{}'; } | jq -r --arg l "$N" '[(.result.tabs // [])[] | select(.label == $l)] | length')" 0
assert_eq "a seat.down 100 event was recorded" "$(event_count seat.down 100)" 1
assert_match "the record carries ended_at" "$(jq -r .ended_at "$R")" '^2[0-9]{3}-'
"$SEAT" --check "$N" >/dev/null 2>&1; assert_eq "--check on a downed seat exits 3" "$?" 3
"$SEAT" --down "$N" >/dev/null; assert_eq "a second --down exits 0" "$?" 0
assert_eq "a second --down records nothing" "$(event_count seat.down 100)" 1
case_done
