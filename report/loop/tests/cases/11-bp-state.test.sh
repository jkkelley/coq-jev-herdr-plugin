#!/usr/bin/env bash
# 11 - state.jq: done, in flight or coming up per Component, and the missing-runbook flag. The rule is in RUNBOOK.md.
. "$(dirname "$0")/../lib/assert.sh"
. "$REPO_ROOT/report/loop/lib/blueprint/gather.sh"
B="$FIX/blueprint"; L="$REPO_ROOT/report/loop/lib/blueprint"
bp_nodes "$B/graph/nodes" | jq -f "$L/components.jq" > "$W/components.json"
bp_tickets "$B/work-orders" | jq -f "$L/tickets.jq" > "$W/tickets.json"
jq -n --slurpfile c "$W/components.json" --slurpfile t "$W/tickets.json" '{components: $c[0], tickets: $t[0]}' | jq -f "$L/state.jq" > "$W/out.json"
s() { jq -r --arg id "$1" '.[] | select(.id == $id) | .state' "$W/out.json"; }
eq "locked, no ticket naming it: done" "done" "$(s CMP-alpha)"
eq "a ticket naming it is in progress: in flight" "in-flight" "$(s CMP-beta)"
eq "proposed, a done ticket names it: done" "done" "$(s CMP-gamma)"
eq "draft, its only ticket cancelled: coming up" "coming-up" "$(s CMP-delta)"
eq "locked and a ticket in review names it: in flight, work wins" "in-flight" "$(s CMP-epsilon)"
eq "a cancelled ticket is not listed against the Component" "0" "$(jq '.[] | select(.id == "CMP-delta") | .tickets | length' "$W/out.json")"
eq "tickets listed against a Component are id, title and status" '[{"id":"WO-20260101-0002","title":"Gamma lands","status":"done"},{"id":"WO-20260101-0003","title":"A later ticket","status":"draft"}]' "$(jq -c '.[] | select(.id == "CMP-gamma") | .tickets | sort_by(.id)' "$W/out.json")"
eq "no runbook is flagged" "true" "$(jq -r '.[] | select(.id == "CMP-beta") | .missing_runbook' "$W/out.json")"
eq "a runbook clears the flag" "false" "$(jq -r '.[] | select(.id == "CMP-alpha") | .missing_runbook' "$W/out.json")"
eq "a proposed Component whose only ticket is a draft is coming up" "coming-up" "$(jq -n --slurpfile c "$W/components.json" '{components: [$c[0][] | select(.id == "CMP-gamma")], tickets: [{id:"WO-20260101-0003",title:"x",status:"draft",cmps:["CMP-gamma"]}]}' | jq -f "$L/state.jq" | jq -r '.[0].state')"
done_case
