#!/usr/bin/env bash
# Catches: the belt (route.sh, gate.sh, flow.sh, policy.sh) reading records or keeping its ledger, belt, since and latch files anywhere
# but the state root (WO-20261012-0229, Roadmap A2; AC-H1 to AC-H3): in the checkout's events/ or factory/state/, or in a root of its own
# that the other scripts do not share. The world's COQ_STATE is a temp dir, so every path below is the one a host run would use.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "${REPO_ROOT:-/repo}/herdr/tests/lib/assert.sh"; . "$HERE/../lib/world.sh"
T=WO-20261012-aaaa
world_up stateroot

echo "-- AC-H1: route.sh once, with COQ_STATE set and no --state, routes a record written there and keeps its files under that root"
id=$(rec pr.opened 100 worker-wo-20261012-aaaa $T)
f=$(rec_file "$id"); base=$(basename "$f" .json)
assert_match "the record is a file in the records tree, named <timestamp>-<name>" "$f" "^$STATE/records/20[0-9]{2}/[0-9]{2}/[0-9]{14}-[a-z0-9-]+\.json$"
"$ROUTE" once --from-start --repo "$R"; assert_eq "exit 0" "$?" 0
assert_match "the tester was woken with the record's id" "$(cat "$HLOG")" "^--session stable agent prompt tester-wo-20261012-aaaa record $id playbook $R/playbooks/tester.md$"
assert_eq "the ledger entry is under <state>/ledger/routed and is named like the record file" "$(cat "$STATE/ledger/routed/$base")" "done seat"
assert_file "the belt is under <state>/run" "$STATE/run/belt"
assert_file "so is the first-start boundary" "$STATE/run/since"
assert_match "since is a file name stamp" "$(cat "$STATE/run/since")" '^[0-9]{14}$'
assert_eq "the receipt went to the state root too" "$(files_code 300 | wc -l | tr -d ' ')" 1
check "nothing was written into the checkout's factory/state" "$([ ! -e "$R/factory/state" ] && echo 1 || echo 0)"
check "nor a record into the checkout's events/ tree" "$([ -z "$(find "$R/events" -mindepth 3 -name '*.json')" ] && echo 1 || echo 0)"
assert_file "the ledger directory says what writes it and how to clean it" "$STATE/ledger/routed/README.md"
assert_file "so does the run directory" "$STATE/run/README.md"

echo "-- a second tick routes nothing again, and the README is not mistaken for an entry"
"$ROUTE" once --repo "$R"; assert_eq "exit 0" "$?" 0; assert_eq "still one herdr call" "$(hcalls)" 1

echo "-- a record still in the repository's events/ tree is not routed"
mkdir -p "$R/events/2026/10"
jq -n '{schema_version:"1.0.0", id:"20261012T000000Z-100-oldoo", at:"2026-10-12T00:00:00Z", code:100, seat:"worker-wo-20261012-bbbb", kind:"pr.opened", ticket:"WO-20261012-bbbb", evidence:[], observations:[]}' > "$R/events/2026/10/20261012000000-pr-opened-wo-20261012-bbbb.json"
"$ROUTE" once --from-start --repo "$R"; assert_eq "exit 0" "$?" 0; assert_eq "no new herdr call" "$(hcalls)" 1

echo "-- --state is the state root: a relative one is refused, an absolute one is used instead of COQ_STATE"
"$ROUTE" once --repo "$R" --state relative/dir 2>/dev/null; assert_eq "relative: exit 3" "$?" 3
other="$W/elsewhere"; "$ROUTE" once --repo "$R" --state "$other"; assert_eq "absolute: exit 0" "$?" 0
assert_file "its belt is under that root" "$other/run/belt"
"$ROUTE" status --repo "$R" --state "$other" | grep -q 'belt: running'; assert_eq "status reads the belt of the root it is given" "${PIPESTATUS[0]}" 0

echo "-- AC-H2: gate.sh finds a record by its id field under the state root, with no --events"
GATE="$R/factory/bin/gate.sh"
po=$(REC_SHA=abcdef1 REC_PR=5 rec pr.opened 100 worker-wo-20261012-cccc WO-20261012-cccc)
"$GATE" when head_current --id "$po" --repo "$R"; assert_eq "head_current on a record in the state root: exit 0" "$?" 0
"$GATE" when head_current --id 20260101T000000Z-100-nope --repo "$R" 2>/dev/null; assert_eq "an id no record has: exit 4" "$?" 4
check "the record file is not named by its id, so the lookup is by the field" "$([ ! -e "$(dirname "$(rec_file "$po")")/$po.json" ] && echo 1 || echo 0)"

echo "-- AC-H2: flow.sh finds a stalled gate record under the state root and latches it in <state>/run/flow"
flow_world; agent_state gone
g=$(rec test.passed 201 tester-wo-20261012-dddd WO-20261012-dddd); backdate "$g" 100
"$FLOW" once --from-start --repo "$R"; assert_eq "exit 0" "$?" 0
assert_match "one note, naming the record" "$(flow_notes | jq -r .note)" "test.passed 201 $g has no reviewer record"
assert_file "the latch is under <state>/run/flow" "$STATE/run/flow/$g"
assert_file "so is its boundary" "$STATE/run/flow/since"
assert_file "and its README" "$STATE/run/flow/README.md"

echo "-- policy.sh keeps its boundary and latches in <state>/run/policy"
policy_world; "$POLICY" status --from-start --repo "$R"; assert_eq "exit 0" "$?" 0
assert_file "the boundary is under <state>/run/policy" "$STATE/run/policy/since"
case_done
