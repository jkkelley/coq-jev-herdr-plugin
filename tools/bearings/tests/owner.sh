#!/usr/bin/env bash
# shellcheck disable=SC2034  # CASE is read by check() in inside.sh, which sources this file
# Owner lane and health line cases (WO-20261013-b221, SPEC-17 s-owner, T12), sourced by inside.sh after the SITREP cases so
# ok/bad/check, $B and /work are in scope. Fixtures are written here: the board is a directory of one JSON file per item, the
# health line is one JSON file beside the lanes, answers are records whose `answer` field names an item id.
BD=/work/oboard; RD=/work/orecords/2026/10
mkdir -p "$BD/owner" "$RD"
# owner_board enables the lane; caps, thresholds and the poll interval are the defaults of lib/owner-board.json (validated at start).
jq --arg d "$BD" --arg r /work/orecords '.owner_board = {dir:$d,records_dir:$r,owner_lane:"owner",health_file:"health.json",answer_scan_seconds:0,owner_item_max_bytes:65536,health_max_bytes:262144,health_stale_seconds:180}' /work/config.json > /work/config-owner.json
item() { # item ID TICKET KIND CODE POSTED -> one owner-lane item with a card
  jq -n --arg id "$1" --arg t "$2" --arg k "$3" --argjson c "$4" --arg p "$5" '{id:$id,kind:$k,code:$c,ticket:$t,priority:"p0",posted_at:$p,
    card:{about:"a ticket is blocked",decide:"Split the ticket or re-scope it?",options:[{label:"Split",then:"two small tickets"},{label:"Re-scope",then:"drop the second half"}],rec:0}}' > "$BD/owner/$1.json"
}
item 20261013T040000Z-423-aaaaa WO-x blocked 423 2026-10-13T04:00:00Z
item 20261013T041000Z-423-bbbbb WO-x blocked 423 2026-10-13T04:10:00Z
item 20261013T042000Z-423-ccccc WO-y blocked 423 2026-10-13T04:20:00Z
echo '{"id":"torn"' > "$BD/owner/torn.json"
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
jq -n --arg at "$NOW" '{state:"running",at:$at,lanes:{tester:{open:2,leased:1,oldest_age_seconds:120},owner:{open:2,leased:0}},seats:[{seat:"worker-1",role:"worker",check:"ok"},{seat:"merger",role:"merger",check:"stuck",detail:"busy 12 min"}],stalls:[{title:"a pull request waits on a gate",age_seconds:900}],counters:{architect_nudges_per_hour:1}}' > "$BD/health.json"
OC=(--ticket o1 --config /work/config-owner.json --no-herdr)
OURL=$($B dev serve "${OC[@]}")
OBASE=${OURL%%/\?key=*}; OKEY=${OURL##*key=}
st() { node -e 'fetch(process.argv[1]).then(r=>r.text()).then(t=>process.stdout.write(t))' "$OBASE/state?key=$OKEY"; }
st > /work/o-state.json
CASE="a second 423 on one ticket renders as exactly one card (AC-H1): two tickets, two cards"; check test "$(jq '.questions.items | length' /work/o-state.json)" = 2
CASE="the card keeps the id of the oldest item and says it was raised twice"; check bash -c 'jq -e ".questions.items[] | select(.id==\"20261013T040000Z-423-aaaaa\") | .about | test(\"raised 2 times\")" /work/o-state.json >/dev/null'
CASE="the card carries the decision, its options and the recommendation"; check bash -c 'jq -e ".questions.items[0] | (.decide|length>0) and (.options|length==2) and .rec==0" /work/o-state.json >/dev/null'
CASE="an item that cannot be a card is reported, not dropped silently"; check bash -c 'jq -e ".owner_problems | length==1 and .[0].file==\"torn.json\"" /work/o-state.json >/dev/null'
CASE="health line: state, lanes, seats, stalls and counters come through"; check bash -c 'jq -e ".health | .available and .state==\"running\" and (.lanes|length==2) and (.seats|length==2) and (.stalls|length==1) and (.counters|length==1) and .stale==false" /work/o-state.json >/dev/null'
CASE="the page's age thresholds come from lib/owner-board.json, not from the page"; check bash -c 'jq -e ".health.dur_minutes_from_seconds==90 and .health.dur_hours_from_seconds==5400" /work/o-state.json >/dev/null'
node /skill/tests/owner-probe.mjs "$OURL" /work/owner.png > /work/owner-probe.json
CASE="the page draws the health line from the file (AC-H2)"; check bash -c 'jq -e ".health_hidden==false and (.health_head|test(\"running\")) and (.health_text|test(\"Lane tester\")) and (.health_text|test(\"busy 12 min\")) and (.health_text|test(\"waits on a gate\"))" /work/owner-probe.json >/dev/null'
CASE="the page draws the owner card and no page errors"; check bash -c 'jq -e "(.card|test(\"Split the ticket\")) and (.errors|length==0) and (.object_object|not)" /work/owner-probe.json >/dev/null'
# An answer record naming any member id clears the card (AC-H1).
jq -n '{schema_version:"1.0.0",id:"20261013T043000Z-200-zzzzz",at:"2026-10-13T04:30:00Z",code:200,seat:"x",kind:"break.glass",answer:"20261013T041000Z-423-bbbbb"}' > "$RD/20261013043000-answer.json"
st > /work/o-state2.json
CASE="an answer record clears the card, the other ticket's card stays"; check bash -c 'jq -e "(.questions.items|length==1) and .questions.items[0].about!=null and (.questions.items[0].item_ids==[\"20261013T042000Z-423-ccccc\"])" /work/o-state2.json >/dev/null'
# The line halted: the health line still renders, and says so.
jq '.state="halted" | .reason="owner halt"' "$BD/health.json" > "$BD/h.t" && mv "$BD/h.t" "$BD/health.json"
node /skill/tests/owner-probe.mjs "$OURL" /work/owner-halt.png > /work/owner-halt.json
CASE="a halted line still renders its health line"; check bash -c 'jq -e "(.health_hidden==false) and (.health_head|test(\"halted\")) and (.health_text|test(\"owner halt\"))" /work/owner-halt.json >/dev/null'
# Missing and malformed health files are said out loud.
rm "$BD/health.json"
st > /work/o-state3.json
CASE="no health file -> unavailable with a reason, not an empty strip"; check bash -c 'jq -e ".health.available==false and (.health.reason|test(\"no health file\"))" /work/o-state3.json >/dev/null'
echo '{"state":"sideways"}' > "$BD/health.json"
CASE="a health file with an unknown state -> unavailable naming the states"; check bash -c 'st=$(node -e "fetch(process.argv[1]).then(r=>r.json()).then(j=>console.log(JSON.stringify(j.health)))" "$0/state?key=$1"); jq -e ".available==false and (.reason|test(\"running, draining or halted\"))" <<<"$st" >/dev/null' "$OBASE" "$OKEY"
# The owner answers a lane card through the page endpoint and wait delivers it.
node -e 'fetch(process.argv[1],{method:"POST",body:JSON.stringify({id:process.argv[2],pick:1,words:"owner words"})}).then(r=>console.log(r.status))' "$OBASE/answer?key=$OKEY" 20261013T042000Z-423-ccccc > /work/o-ans.txt
CASE="a lane card can be answered through /answer"; check test "$(cat /work/o-ans.txt)" = 200
CASE="wait.mjs delivers the lane card's ANSWER line"; check bash -c 'timeout 15 $0 dev wait --ticket o1 "$@" | grep -q "^ANSWER 20261013T042000Z-423-ccccc - Split the ticket or re-scope it? -> Re-scope | words: owner words"' "$B" --config /work/config-owner.json --no-herdr
$B dev stop "${OC[@]}" >/dev/null; sleep 2
# A config without owner_board draws neither.
OURL2=$($B dev serve --ticket o2 "${C[@]}")
CASE="no owner_board in the config -> no health line, no lane cards"; check bash -c 'r=$(node -e "fetch(process.argv[1]).then(r=>r.json()).then(j=>console.log(JSON.stringify([j.health,j.owner_problems])))" "$(echo "$0" | sed "s#/?key=#/state?key=#")"); test "$r" = "[null,[]]"' "$OURL2"
$B dev stop --ticket o2 "${C[@]}" >/dev/null; sleep 2
jq '.owner_board.health_file="../x"' /work/config-owner.json > /work/config-obad.json
set +e; out=$(node /skill/scripts/server.mjs --tier dev --ticket o3 --config /work/config-obad.json 2>&1); rc=$?; set -e
CASE="a bad owner_board key fails at start (exit 3) naming it"; check test "$rc" = 3 -a "${out#*owner_board.health_file}" != "$out"
jq '.owner_board.caps.decide=0' /work/config-owner.json > /work/config-ocap.json
set +e; out=$(node /skill/scripts/server.mjs --tier dev --ticket o4 --config /work/config-ocap.json 2>&1); rc=$?; set -e
CASE="a non-positive owner_board.caps key fails at start (exit 3) naming it"; check test "$rc" = 3 -a "${out#*owner_board.caps.decide}" != "$out"
