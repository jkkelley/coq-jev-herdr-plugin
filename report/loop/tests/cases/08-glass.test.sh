#!/usr/bin/env bash
# 08 - the board shows every break glass as a line (WO-20261011-4562, AC-H3): one row per request id, folded from the records that
# name it, moving asked -> granted -> in effect -> done -> restored without a hand edit, a refused one kept, and none of it moving
# a ticket's line or counting as a seat coming up.
. "$(dirname "$0")/../lib/assert.sh"
. "$(dirname "$0")/../lib/world.sh"
world_init
T=WO-20261011-0001; S=worker-wo-20261011-0001; ACT='gh pr merge 17 --squash'

# bg AT SEAT CODE ACTION [ANSWER] [TICKET]: one break.glass record, as events/bin/event.sh writes it; prints its id.
bg() {
  local at=$1 seat=$2 code=$3 action=$4 answer=${5:-} ticket=${6:-} id d
  SEQ=$((SEQ + 1)); id="$(date -u -d "$at" +%Y%m%dT%H%M%SZ)-$code-$(printf 'g%04d' "$SEQ")"
  d="$ROOT_FIX/events/$(date -u -d "$at" +%Y/%m)"; mkdir -p "$d"
  jq -n --arg id "$id" --arg at "$at" --argjson code "$code" --arg seat "$seat" --arg action "$action" --arg answer "$answer" --arg ticket "$ticket" \
    '{schema_version: "1.0.0", id: $id, at: $at, code: $code, seat: $seat, kind: "break.glass", ticket: (if $ticket == "" then null else $ticket end), pane: null, note: "", evidence: [], observations: [], action: $action}
     + (if $answer == "" then {} else {answer: $answer} end)' > "$d/$id.json"
  echo "$id"
}

ticket "$T" in-progress feat/make-the-thing null "Make the thing"
ev 2026-10-11T14:00:00Z "$S" seat.up 100 "$T" wD3:p5 "worker seat up"
ev 2026-10-11T14:01:00Z "$S" note 100 "$T" wD3:p5 "work.started: worker seat begins"
panes "$S=wD3:p5" "bearings-stable=wD3:p1N"
collect
RESULT_JQ "with no break glass the entry carries an empty glass list" '.glass == []'

R1=$(bg 2026-10-11T14:10:00Z "$S" 300 "$ACT" "" "$T")
collect
RESULT_JQ "a request is one row, asked, with the seat and the exact command" '(.glass | length) == 1 and .glass[0].state == "asked" and .glass[0].seat == "worker-wo-20261011-0001" and .glass[0].action == "gh pr merge 17 --squash"'
RESULT_JQ "the row carries the request id and its short form" '.glass[0].request == "'"$R1"'" and .glass[0].id == "g0003"'
RESULT_JQ "a request does not move the ticket line" '.lines[0].here == "worker" and (.lines[0].st.worker.status == "live")'

bg 2026-10-11T14:11:00Z "$S" 200 "$ACT" "$R1" "$T" >/dev/null; collect
RESULT_JQ "a 200 moves the same row to granted, not a second row" '(.glass | length) == 1 and .glass[0].state == "granted"'
bg 2026-10-11T14:12:00Z "$S" 100 "$ACT" "$R1" "$T" >/dev/null; collect
RESULT_JQ "a 100 is in effect" '.glass[0].state == "in effect" and .glass[0].at == "2026-10-11T14:12:00Z"'
bg 2026-10-11T14:13:00Z "$S" 201 "$ACT" "$R1" "$T" >/dev/null; collect
RESULT_JQ "a 201 is done" '.glass[0].state == "done"'
bg 2026-10-11T14:14:00Z "$S" 204 "$ACT" "$R1" "$T" >/dev/null; collect
RESULT_JQ "a 204 is restored" '(.glass | length) == 1 and .glass[0].state == "restored"'
RESULT_JQ "none of it moved the ticket line or its worker station" '.lines[0].here == "worker" and .lines[0].st.worker.status == "live" and ([.lines[0].st.worker.parts[][1]] | all(contains("break.glass") | not))'

R2=$(bg 2026-10-11T14:20:00Z "$S" 300 "gh pr merge 18")
bg 2026-10-11T14:21:00Z "$S" 423 "gh pr merge 18" "$R2" >/dev/null; collect
RESULT_JQ "a second request is a second row, refused, after the first" '(.glass | length) == 2 and .glass[0].state == "restored" and .glass[1].state == "refused" and .glass[1].action == "gh pr merge 18"'

# A 423 written for a seat that is already down must not read as that seat coming back up.
ev 2026-10-11T14:30:00Z "$S" seat.down 100 "$T" wD3:p5 "seat retired"
R3=$(bg 2026-10-11T14:40:00Z "$S" 300 "$ACT"); bg 2026-10-11T14:41:00Z "$S" 423 "$ACT" "$R3" >/dev/null
panes "$S=wD3:p5" "bearings-stable=wD3:p1N"; collect
RESULT_JQ "a refusal after seat.down does not bring the seat back" '.lines[0].st.worker.status == "building" and (.glass | length) == 3'

# The page: render keeps the rows in data.json and the page's script draws them.
t "render writes the page" "$LOOP" render --in "$W/entry.json" --out "$W/out"
RESULT_JQ_FILE() { jq -e "$2" "$1" >/dev/null 2>&1 && pass "$3" || flunk "$3"; }
RESULT_JQ_FILE "$W/out/data.json" '.glass | length == 3' "data.json carries the three rows"
has "the page embeds the rows" "$W/out/index.html" 'gh pr merge 18'
has "the page script has the break glass table" "$W/out/index.html" 'break glass</th>'
done_case
