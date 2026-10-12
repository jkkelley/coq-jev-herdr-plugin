#!/usr/bin/env bash
# 09 - decisions.jq: the locked Decision nodes, and only those.
. "$(dirname "$0")/../lib/assert.sh"
. "$REPO_ROOT/report/loop/lib/blueprint/gather.sh"
B="$FIX/blueprint"; J="$REPO_ROOT/report/loop/lib/blueprint/decisions.jq"
bp_nodes "$B/graph/nodes" > "$W/nodes.json"; jq -c -f "$J" "$W/nodes.json" > "$W/out.json"
eq "every locked Decision, sorted by id, as id and title" '[{"id":"DEC-one","title":"One is locked"},{"id":"DEC-three","title":"Three is locked and unrelated"}]' "$(cat "$W/out.json")"
eq "a proposed Decision is not listed" "0" "$(jq '[.[] | select(.id == "DEC-two")] | length' "$W/out.json")"
eq "a superseded Decision is not listed" "0" "$(jq '[.[] | select(.id == "DEC-old")] | length' "$W/out.json")"
eq "a locked node of another type is not listed" "0" "$(jq '[.[] | select(.id == "REQ-x")] | length' "$W/out.json")"
eq "an empty graph is an empty list" "[]" "$(echo '[]' | jq -c -f "$J")"
done_case
