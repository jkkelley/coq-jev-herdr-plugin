#!/usr/bin/env bash
# 08 - components.jq: Component nodes with their runbook and decisions. Pure, so the case feeds it the fixture graph and reads the JSON.
. "$(dirname "$0")/../lib/assert.sh"
. "$REPO_ROOT/report/loop/lib/blueprint/gather.sh"
B="$FIX/blueprint"; J="$REPO_ROOT/report/loop/lib/blueprint/components.jq"
bp_nodes "$B/graph/nodes" > "$W/nodes.json"; jq -f "$J" "$W/nodes.json" > "$W/out.json"
c() { jq -r "$1" "$W/out.json"; }
eq "a Component per non-superseded Component node, sorted by id" "CMP-alpha CMP-beta CMP-delta CMP-epsilon CMP-gamma" "$(c '[.[].id] | join(" ")')"
eq "a superseded Component is left out" "0" "$(c '[.[] | select(.id == "CMP-old")] | length')"
eq "a Component's own defined_in edge to a Runbook is its runbook" "RUN-alpha" "$(c '.[] | select(.id == "CMP-alpha") | .runbook.id')"
eq "the runbook carries its title" "Alpha runbook" "$(c '.[] | select(.id == "CMP-alpha") | .runbook.title')"
eq "a Runbook's defined_in edge to the Component also counts" "RUN-gamma" "$(c '.[] | select(.id == "CMP-gamma") | .runbook.id')"
eq "no runbook edge either way is null" "null" "$(c '.[] | select(.id == "CMP-beta") | .runbook')"
eq "a decided_by edge carries the decision's status" "locked" "$(c '.[] | select(.id == "CMP-alpha") | .decisions[0].status')"
eq "a decision with no node reads missing" "missing" "$(c '.[] | select(.id == "CMP-beta") | .decisions[] | select(.id == "DEC-gone") | .status')"
eq "a Component with no decided_by edge has no decisions" "0" "$(c '.[] | select(.id == "CMP-delta") | .decisions | length')"
eq "an empty graph is an empty list" "[]" "$(echo '[]' | jq -c -f "$J")"
done_case
