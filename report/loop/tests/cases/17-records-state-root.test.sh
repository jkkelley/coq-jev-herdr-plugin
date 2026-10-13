#!/usr/bin/env bash
# 17 - the board reads its records from the state root: events_dir is ${tree:records}, so a record written under COQ_STATE/records
# shows on the board and one in the repository's events/ does not (WO-20261013-3abe, AC-H1 and AC-H2).
. "$(dirname "$0")/../lib/assert.sh"
. "$(dirname "$0")/../lib/world.sh"
world_init
A=WO-20261013-1701; B=WO-20261013-1702
SA=worker-wo-20261013-1701; SB=worker-wo-20261013-1702

eq "the shipped config reads the records tree" '${tree:records}' "$(jq -r .inputs.events_dir "$REPO_ROOT/report/loop/config/board.json")"

ticket "$A" in-progress feat/a null "Records in the state root"
ticket "$B" in-progress feat/b null "Records in the repository"
panes "$SA=wD3:p5" "$SB=wD3:p6" "bearings-stable=wD3:p1N"

# AC-H1: a record under COQ_STATE/records is read. world_init made COQ_STATE and linked events/ to its records tree, so ev writes there.
ev 2026-10-11T14:00:00Z "$SA" seat.up 100 "$A" wD3:p5 "worker seat up"
t "collect with a record in the state root" collect
RESULT_JQ "a record in the state root is read" '.sources | contains("1 records")'
RESULT_JQ "and it makes its seat live on the board" '(.lines | map(select(.ticket == "WO-20261013-1701")) | .[0].st.worker.status) == "live"'
RESULT_JQ "and the sources line names the tree, not a machine path" '.sources | startswith("${tree:records} (")'
test -s "$COQ_STATE/records/2026/10/"*.json && pass "and the record is a file under COQ_STATE/records" || flunk "the record is not under COQ_STATE/records"

# A record in the repository's events/ is not read: the link goes, a real directory takes its place, and the record there is ignored.
rm "$ROOT_FIX/events"; mkdir -p "$ROOT_FIX/events/2026/10"
jq -n --arg seat "$SB" --arg ticket "$B" '{schema_version: "1.0.0", id: "20261011T140100Z-100-repo1", at: "2026-10-11T14:01:00Z", code: 100, seat: $seat, kind: "seat.up", ticket: $ticket, pane: "wD3:p6", note: "worker seat up", evidence: [], observations: []}' \
  > "$ROOT_FIX/events/2026/10/20261011T140100Z-100-repo1.json"
collect
RESULT_JQ "a record in the repository's events/ is not read" '.sources | contains("1 records")'
RESULT_JQ "so its seat is not live" '(.lines | map(select(.ticket == "WO-20261013-1702")) | .[0].st.worker.status) != "live"'
RESULT_JQ "while the state root's record still is" '(.lines | map(select(.ticket == "WO-20261013-1701")) | .[0].st.worker.status) == "live"'

# The tree follows COQ_STATE: another state root with no records reads none.
export COQ_STATE="$W/other-state"; mkdir -p "$COQ_STATE/records"
collect
RESULT_JQ "another state root with no records shows none" '.sources | contains("0 records")'
RESULT_JQ "and neither seat is live" '[.lines[].st.worker.status] | all(. != "live")'

# A state root that cannot be resolved stops the collect (exit 4) rather than reading nothing and drawing an empty floor.
export COQ_STATE="relative/state"
expect_exit 4 "a relative COQ_STATE stops collect with exit 4" collect
has "and says which value it could not resolve" "$W/collect.err" 'cannot resolve inputs.events_dir'
export COQ_STATE="$W/state"

# A relative events_dir keeps its old reading, under the root, so another repository's config need not move at once.
jq '.inputs.events_dir = "events"' "$W/board.json" > "$W/b2.json" && mv "$W/b2.json" "$W/board.json"
t "collect with a relative events_dir" collect
RESULT_JQ "a relative events_dir is read under the root" '.sources | contains("1 records")'
RESULT_JQ "and it is the repository's record, not the state root's" '(.lines | map(select(.ticket == "WO-20261013-1702")) | .[0].st.worker.status) == "live"'
done_case
