#!/usr/bin/env bash
# Catches: a ticket whose files are specs, graph nodes or roles seated in a role that cannot write them (cause 2wbaq, record
# 20261013T163817Z-423-2wbaq; WO-20261013-d127). roles/worker.json denies specs/, graph/ and roles/, so the worker seated on a
# SPEC-16 per-file ticket escalated 423 on its first edit. roles/spec-author.json is that worker with the three denies lifted, on
# claude-opus-5-5, at most three seats, under the worker lane's label so the route runner's wakes and downs still reach it.
# This case seats it on a ticket whose every file is under specs/ and graph/ and pins: the seat takes the worker lane's name, is
# recorded as spec-author, runs on the role's model, its settings deny none of specs/, graph/ and roles/, and its brief names
# playbooks/spec-author.md; a worker seated on a mixed ticket in the same world still denies all three.
# The automatic pick (seat.sh seating a spec ticket's worker as spec-author from the ticket's files) is not pinned here: it is a
# follow-up, because herdr/bin/seat.sh was held by the live ticket WO-20261013-a0e2 when this case was written.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/assert.sh"; . "$HERE/../lib/world.sh"
world_up specauth || exit 1
SPEC=WO-20261013-35a1; MIXED=WO-20261013-35b2
NS="worker-${SPEC,,}"; NM="worker-${MIXED,,}"

# cut_ticket ID FILES_JSON: an in-progress ticket in the world's work-orders/ declaring those files, all seat.sh and brief.sh read
cut_ticket() {
  { echo ---
    jq -n --arg id "$1" --argjson files "$2" '{id: $id, title: ("case 35 ticket " + $id), status: "in-progress", branch: null, files: $files}'
    echo ---; echo; echo "# $1 - case 35 ticket $1"; } > "$REPO/work-orders/$1-case-35.md"
}
# denies SETTINGS DIR: 1 when the rendered settings deny Edit under the worktree's DIR/, else 0
denies() { if jq -e --arg d "$2" 'any(.permissions.deny[]; startswith("Edit(") and endswith("/" + $d + "/**)"))' "$1" >/dev/null; then echo 1; else echo 0; fi; }
# seat_up_note NAME: the note of the seat.up 100 record the world holds for that seat
seat_up_note() { local f; for f in "$EVENTS"/2*/*/*.json; do [ -f "$f" ] || continue; jq -r --arg s "$1" 'select(.kind == "seat.up" and .code == 100 and .seat == $s) | .note' "$f"; done; }
cut_ticket "$SPEC" '["specs/SPEC-16-scheduler.xml","specs/16/SPEC-16-G-config.xml","graph/nodes/DEC-spec-author.json"]'
cut_ticket "$MIXED" '["specs/16/SPEC-16-G-config.xml","herdr/bin/seat.sh"]'

echo "-- a spec ticket seated with --role spec-author: the worker lane's name, the role's model and a fence that adds specs/, graph/ and roles/"
out="$("$SEAT" --ticket "$SPEC" --role spec-author --worktree "$REPO")"; rc=$?
assert_eq "seat-up exits 0" "$rc" 0
assert_eq "the seat takes the worker lane's name, so route.sh wakes and downs reach it" "$(jq -r .name <<<"$out")" "$NS"
assert_eq "the seat is the spec-author role" "$(jq -r .role <<<"$out")" spec-author
assert_eq "seat.json names the spec-author role file" "$(jq -r '.role_file | sub(".*/roles/"; "roles/")' "$STATE/seats/$NS/seat.json")" roles/spec-author.json
ws="$(jq -r .workspace <<<"$out")"; tab="$(jq -r .tab <<<"$out")"; agent="$(jq -r .agent <<<"$out")"
assert_eq "the agent pane label shows the model and the role" "$(pane_labels "$ws" "$tab")" "MONITOR - $NS|claude-opus-5-5 - high - $SPEC spec-author|test - herdr - $NS"
argv="$(h pane process-info --pane "$agent" | jq -r '[.result.process_info.foreground_processes[].argv | join(" ")] | join("; ")')"
assert_match "claude was started with the role's model, effort, permission mode and the rendered settings" "$argv" \
  "claude --model claude-opus-5-5 --effort high --permission-mode bypassPermissions --settings $STATE/seats/$NS/settings.json"
S="$STATE/seats/$NS/settings.json"
for d in specs graph roles; do assert_eq "its settings deny no edit under $d/" "$(denies "$S" "$d")" 0; done
assert_match "its brief names the ticket and the spec-author playbook" "$(h agent read "$NS" --source recent-unwrapped --lines 200)" \
  "$SPEC - case 35 ticket $SPEC\. Playbook playbooks/spec-author\.md\."
assert_match "seat.up 100 records the role and its model" "$(seat_up_note "$NS")" "^spec-author seat up: claude-opus-5-5 high bypassPermissions$"

echo "-- a mixed ticket seated as worker keeps the worker's fence"
out="$("$SEAT" --ticket "$MIXED" --role worker --worktree "$REPO")"; rc=$?
assert_eq "seat-up exits 0" "$rc" 0
assert_eq "the seat is the worker role" "$(jq -r .role <<<"$out")" worker
assert_eq "on the worker's model" "$(jq -r .model <<<"$out")" claude-sonnet-5-5
S="$STATE/seats/$NM/settings.json"
for d in specs graph roles; do assert_eq "its settings deny edits under $d/" "$(denies "$S" "$d")" 1; done
case_done
