#!/usr/bin/env bash
# world.sh - a scratch repository for the collect cases, built from the real roles, playbooks and routes table (so the cases
# cannot drift from them) plus the events, tickets, panes and belt each case writes. Source after assert.sh.
#   world_init                         $W/root with roles/, playbooks/, factory/config/routes.json, empty events/ and work-orders/
#   ev AT SEAT KIND CODE TICKET PANE NOTE     one event record, one file, as events/bin/event.sh writes it
#   ticket ID STATUS BRANCH PR [TITLE]        one ticket file with a JSON frontmatter (PR: a number or null)
#   panes LABEL=ID...                  the herdr pane list: one pane per LABEL=ID, in herdr's JSON shape; no argument: an empty list
#   belt AGE                           the route runner's belt file ($STATE/belt, state_dir of the fixture runner.json), AGE seconds old at NOW
#   live PRS BRANCHES                  the live line: PRS a JSON array of {number, headRefName, title}, BRANCHES a JSON array of names; without it collect runs --no-live
#   collect [ARGS]                     loop.sh collect against the world at NOW, with the pane list, into $W/entry.json
#   q EXPR                             jq -e EXPR against $W/entry.json, quietly
#   RESULT_JQ DESC EXPR                an assertion: the expression is true of the entry
export NOW="2026-10-11T15:00:00Z"
export ROOT_FIX="$W/root"
SEQ=0

world_init() {
  rm -rf "$ROOT_FIX"; mkdir -p "$ROOT_FIX/events" "$ROOT_FIX/work-orders" "$ROOT_FIX/factory/config" "$ROOT_FIX/herdr/config"
  cp -r "$REPO_ROOT/roles" "$REPO_ROOT/playbooks" "$ROOT_FIX/"
  cp "$REPO_ROOT/factory/config/routes.json" "$ROOT_FIX/factory/config/routes.json"
  cp "$REPO_ROOT/report/loop/config/board.json" "$W/board.json"
  echo '{"state_dir": "${repo}/factory/state"}' > "$ROOT_FIX/factory/config/runner.json"
  rm -f "$W/live.json"
  panes
}

ev() {
  local at=$1 seat=$2 kind=$3 code=$4 ticket=$5 pane=$6 note=${7:-} id d
  SEQ=$((SEQ + 1)); id="$(date -u -d "$at" +%Y%m%dT%H%M%SZ)-$code-$(printf 'x%04d' "$SEQ")"
  d="$ROOT_FIX/events/$(date -u -d "$at" +%Y/%m)"; mkdir -p "$d"
  jq -n --arg id "$id" --arg at "$at" --argjson code "$code" --arg seat "$seat" --arg kind "$kind" --arg ticket "$ticket" --arg pane "$pane" --arg note "$note" \
    '{schema_version: "1.0.0", id: $id, at: $at, code: $code, seat: $seat, kind: $kind, ticket: $ticket, pane: (if $pane == "" then null else $pane end), note: $note, evidence: [], observations: []}' > "$d/$id.json"
}

ticket() {
  local id=$1 status=$2 branch=$3 pr=$4 title=${5:-A ticket for the board}
  mkdir -p "$ROOT_FIX/work-orders/WO-20261010-aaaa"
  jq -n --arg id "$id" --arg status "$status" --arg branch "$branch" --argjson pr "$pr" --arg title "$title" \
    '{id: $id, slug: "x", title: $title, type: "feature", status: $status, parent: "WO-20261010-aaaa", branch: (if $branch == "" then null else $branch end), pr: $pr, closed: null}' > "$W/fm.json"
  { echo '---'; cat "$W/fm.json"; echo '---'; echo; echo "# $id - $title"; echo; echo 'Body text with a --- rule below.'; echo '---'; echo 'and more.'; } > "$ROOT_FIX/work-orders/WO-20261010-aaaa/$id-x.md"
}

# shellcheck disable=SC2120 # world_init calls it with no panes: an empty list
panes() {
  local a json='[]'
  for a in "$@"; do json=$(jq -c --arg l "${a%%=*}" --arg i "${a#*=}" '. + [{label: $l, pane_id: $i, workspace_id: "wX"}]' <<<"$json"); done
  jq -n --argjson p "$json" '{id: "cli:pane:list", result: {panes: $p}}' > "$W/panes.json"
}

belt() {
  mkdir -p "$ROOT_FIX/factory/state"
  : > "$ROOT_FIX/factory/state/belt"
  touch -d "@$(($(date -u -d "$NOW" +%s) - $1))" "$ROOT_FIX/factory/state/belt"
}

live() { jq -n --argjson p "$1" --argjson b "$2" '{prs: $p, branches: $b}' > "$W/live.json"; }

collect() {
  local lv=--no-live; [ ! -f "$W/live.json" ] || lv="--live $W/live.json"
  # shellcheck disable=SC2086 # $lv is one flag or a flag and a path
  LOOP_ROOT="$ROOT_FIX" LOOP_CONFIG="$W/board.json" "$LOOP" collect --now "$NOW" --panes "$W/panes.json" $lv "$@" > "$W/entry.json" 2> "$W/collect.err"
}
q() { jq -e "$1" "$W/entry.json" >/dev/null 2>&1; }
RESULT_JQ() { if q "$2"; then pass "$1"; else flunk "$1 ($2)"; jq -c "${3:-.}" "$W/entry.json" | head -c 1500 >&2; echo >&2; fi; }
