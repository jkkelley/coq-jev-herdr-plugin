#!/usr/bin/env bash
# bearings.sh - the one entry point for a bearings tier. Every verb resolves the
# tier through config/bearings.json (via lib/config.mjs) and never carries a
# default of its own. Inside herdr (HERDR_ENV=1) the server and the wait each get
# a labelled pane in the current tab (Rule 18: nothing backgrounded, every
# watcher visible). Outside herdr it refuses, unless --no-herdr is given, which
# the Podman test harness uses because no herdr runs there.
#
#   bearings.sh <tier> serve    [--ticket ID] [--config P] [--session S] [--model M] [--working-on TEXT] [--no-herdr]
#   bearings.sh <tier> stop     [--ticket ID] [--config P]
#   bearings.sh <tier> wait     [--ticket ID] [--config P] [--no-herdr]
#   bearings.sh <tier> reply    [--ticket ID] [--config P] --to <message-id> "text"
#   bearings.sh <tier> status   [--ticket ID] [--config P] [--json]
#   bearings.sh <tier> url      [--ticket ID] [--config P]
#   bearings.sh <tier> ask      [--ticket ID] [--config P] <questions.json>
#   bearings.sh <tier> migrate  [--ticket ID] [--config P] <from-page-dir> [--force]
#
# Exit codes: 0 ok, 2 usage, 3 validation or refused, 4 io, 6 not found.
set -euo pipefail

readonly EX_OK=0 EX_USAGE=2 EX_VALIDATION=3 EX_IO=4 EX_NOTFOUND=6
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TOOL=$(cd "$HERE/.." && pwd)

die() { local code=$1; shift; printf 'bearings: %s\n' "$*" >&2; exit "$code"; }
note() { printf 'bearings: %s\n' "$*" >&2; }
need() { command -v "$1" >/dev/null 2>&1 || die "$EX_IO" "$1 is required and not on PATH"; }

[ $# -ge 2 ] || { sed -n '2,20p' "$0" >&2; exit "$EX_USAGE"; }
TIER=$1; VERB=$2; shift 2
TICKET=""; CONFIG="${BEARINGS_CONFIG:-$TOOL/config/bearings.json}"; NO_HERDR=0; JSON=0; FORCE=0
SESSION=""; MODEL=""; CWD=""; WORKING_ON=""; TO=""
POS=()
while [ $# -gt 0 ]; do
  case $1 in
    --ticket) TICKET=${2:-}; shift 2 ;;
    --config) CONFIG=${2:-}; shift 2 ;;
    --session) SESSION=${2:-}; shift 2 ;;
    --model) MODEL=${2:-}; shift 2 ;;
    --cwd) CWD=${2:-}; shift 2 ;;
    --working-on) WORKING_ON=${2:-}; shift 2 ;;
    --to) TO=${2:-}; shift 2 ;;
    --no-herdr) NO_HERDR=1; shift ;;
    --json) JSON=1; shift ;;
    --force) FORCE=1; shift ;;
    --help|-h) sed -n '2,20p' "$0" >&2; exit "$EX_OK" ;;
    --*) die "$EX_USAGE" "unknown flag $1" ;;
    *) POS+=("$1"); shift ;;
  esac
done
need node; need jq
[ -f "$CONFIG" ] || die "$EX_IO" "config not found: $CONFIG"

# Resolve the tier once through the same loader the node scripts use, so bash
# and node can never disagree about a name or a port.
RESOLVED=$(node --input-type=module -e '
  import { loadConfig, resolveTier } from "'"$HERE"'/lib/config.mjs";
  const { cfg } = loadConfig(process.argv[1]);
  const T = resolveTier(cfg, process.argv[2], process.argv[3] || undefined);
  console.log(JSON.stringify({ ...T, split: cfg.pane_split }));
' "$CONFIG" "$TIER" "$TICKET")
PAGE=$(jq -r .page <<<"$RESOLVED"); DIR=$(jq -r .stateDir <<<"$RESOLVED")
PANE_LABEL=$(jq -r .paneLabel <<<"$RESOLVED"); WAIT_LABEL=$(jq -r .waitPaneLabel <<<"$RESOLVED")
SPLIT_DIR=$(jq -r .split.direction <<<"$RESOLVED"); SPLIT_RATIO=$(jq -r .split.ratio <<<"$RESOLVED")
TICKET_ARGS=(); [ -n "$TICKET" ] && TICKET_ARGS=(--ticket "$TICKET")
COMMON=(--tier "$TIER" "${TICKET_ARGS[@]}" --config "$CONFIG")

server_json() { [ -f "$DIR/server.json" ] && cat "$DIR/server.json" || echo '{}'; }
server_pid() { jq -r '.pid // empty' <<<"$(server_json)"; }
server_alive() { local p; p=$(server_pid); [ -n "$p" ] && kill -0 "$p" 2>/dev/null && [ ! -f "$DIR/stopped.json" ]; }
in_herdr() { [ "${HERDR_ENV:-}" = 1 ] && [ -n "${HERDR_PANE_ID:-}" ]; }

# Find a pane by label in the current tab, or split one off the current pane.
pane_by_label() {
  # Breadcrumb 2026-10-10 UTC (WO-20261010-ba08): this used `herdr pane list --tab "$HERDR_TAB_ID"`.
  # herdr 0.9.0 `pane list` only takes --workspace, so it exited 2 (usage); 2>/dev/null hid the
  # message, pipefail carried the 2 into the command substitution and errexit killed the script
  # inside `stop`, after the server was stopped and before any pane was closed. Every stop left
  # its two labelled panes behind and `make stop` reported Error 2. Filtering tab_id in jq is
  # the fix because it needs no flag the CLI may not have; the alternative, --workspace plus a
  # tab filter, still breaks on a CLI without --workspace. Cost: one unfiltered list per lookup.
  herdr pane list 2>/dev/null | jq -r --arg l "$1" --arg t "${HERDR_TAB_ID:-}" \
    '.result.panes[]? | select(.label == $l and ($t == "" or .tab_id == $t)) | .pane_id' | head -1 || true
}
pane_for() {
  local label=$1 p
  p=$(pane_by_label "$label")
  if [ -z "$p" ]; then
    p=$(herdr pane split "$HERDR_PANE_ID" --direction "$SPLIT_DIR" --ratio "$SPLIT_RATIO" --cwd "$TOOL" --no-focus | jq -r '.result.pane.pane_id')
    [ -n "$p" ] || die "$EX_IO" "herdr pane split returned no pane id"
    herdr pane rename "$p" "$label" >/dev/null
  fi
  printf '%s\n' "$p"
}
wait_for_server() {
  local _; for _ in $(seq 1 60); do server_alive && [ -n "$(jq -r '.url // empty' <<<"$(server_json)")" ] && return 0; sleep 0.25; done
  return 1
}

case $VERB in
  serve)
    server_alive && die "$EX_VALIDATION" "$PAGE is already running: $(jq -r .url <<<"$(server_json)")"
    ARGS=("${COMMON[@]}"); [ -n "$SESSION" ] && ARGS+=(--session "$SESSION"); [ -n "$MODEL" ] && ARGS+=(--model "$MODEL")
    [ -n "$CWD" ] && ARGS+=(--cwd "$CWD"); [ -n "$WORKING_ON" ] && ARGS+=(--working-on "$WORKING_ON")
    rm -f "$DIR/stopped.json"
    if in_herdr && [ "$NO_HERDR" = 0 ]; then
      need herdr
      P=$(pane_for "$PANE_LABEL")
      herdr pane run "$P" "node $HERE/server.mjs $(printf '%q ' "${ARGS[@]}")" >/dev/null
      wait_for_server || die "$EX_IO" "server did not come up in pane $P; read it with: herdr pane read $P"
      note "server in pane $P ($PANE_LABEL)"
    elif [ "$NO_HERDR" = 1 ]; then
      mkdir -p "$DIR"
      nohup node "$HERE/server.mjs" "${ARGS[@]}" >"$DIR/server.log" 2>&1 &
      wait_for_server || die "$EX_IO" "server did not come up; see $DIR/server.log"
    else
      die "$EX_VALIDATION" "not inside herdr (HERDR_ENV unset): every bearings process needs a labelled pane; run this from a herdr pane or pass --no-herdr in a test harness"
    fi
    jq -r .url <<<"$(server_json)"
    ;;
  stop)
    node "$HERE/server.mjs" "${COMMON[@]}" --stop
    if in_herdr && [ "$NO_HERDR" = 0 ] && command -v herdr >/dev/null 2>&1; then
      for l in "$WAIT_LABEL" "$PANE_LABEL"; do
        p=$(pane_by_label "$l"); [ -n "$p" ] && herdr pane close "$p" >/dev/null 2>&1 && note "closed pane $p ($l)"
      done
    fi
    ;;
  wait)
    LOOP="while [ ! -f $(printf '%q' "$DIR/stopped.json") ]; do node $(printf '%q' "$HERE/wait.mjs") $(printf '%q ' "${COMMON[@]}"); sleep 1; done"
    if in_herdr && [ "$NO_HERDR" = 0 ]; then
      need herdr
      P=$(pane_for "$WAIT_LABEL")
      herdr pane run "$P" "$LOOP" >/dev/null
      note "wait loop in pane $P ($WAIT_LABEL)"; printf '%s\n' "$P"
    elif [ "$NO_HERDR" = 1 ]; then
      exec node "$HERE/wait.mjs" "${COMMON[@]}"
    else
      die "$EX_VALIDATION" "not inside herdr (HERDR_ENV unset); pass --no-herdr to run one wait in the foreground"
    fi
    ;;
  reply)
    [ -n "$TO" ] || die "$EX_USAGE" "reply needs --to <message-id>"
    if [ ${#POS[@]} -gt 0 ]; then node "$HERE/reply.mjs" "${COMMON[@]}" --to "$TO" "${POS[0]}"; else node "$HERE/reply.mjs" "${COMMON[@]}" --to "$TO"; fi
    ;;
  status)
    ALIVE=false; server_alive && ALIVE=true
    OUT=$(jq -n --arg tier "$TIER" --arg ticket "$TICKET" --arg page "$PAGE" --arg dir "$DIR" --argjson alive "$ALIVE" --argjson s "$(server_json)" \
      '{tier:$tier, ticket:(if $ticket=="" then null else $ticket end), page:$page, dir:$dir, alive:$alive, url:($s.url // null), port:($s.port // null), pid:($s.pid // null)}')
    if [ "$JSON" = 1 ]; then printf '%s\n' "$OUT"; else jq -r 'to_entries[] | "\(.key)\t\(.value // "-")"' <<<"$OUT"; fi
    ;;
  url)
    server_alive || die "$EX_NOTFOUND" "$PAGE is not running"
    jq -r .url <<<"$(server_json)"
    ;;
  ask)
    [ ${#POS[@]} -eq 1 ] || die "$EX_USAGE" "ask takes exactly one questions.json path"
    jq -e '.items | type == "array"' "${POS[0]}" >/dev/null 2>&1 || die "$EX_VALIDATION" "${POS[0]} is not a questions file with an items array"
    mkdir -p "$DIR"; cp "${POS[0]}" "$DIR/questions.json.tmp" && mv "$DIR/questions.json.tmp" "$DIR/questions.json"
    note "asked $(jq '.items | length' "$DIR/questions.json") card(s) on $PAGE"
    ;;
  migrate)
    [ ${#POS[@]} -eq 1 ] || die "$EX_USAGE" "migrate takes exactly one source page directory"
    SRC=${POS[0]}; [ -d "$SRC" ] || die "$EX_NOTFOUND" "no such directory $SRC"
    server_alive && die "$EX_VALIDATION" "$PAGE is running; stop it before migrating into it"
    if [ -s "$DIR/answers.jsonl" ] && [ "$FORCE" = 0 ]; then die "$EX_VALIDATION" "$DIR already has answers; pass --force to overwrite"; fi
    mkdir -p "$DIR"
    for f in questions.json answers.jsonl messages.jsonl delivered.json; do [ -f "$SRC/$f" ] && cp "$SRC/$f" "$DIR/$f"; done
    for f in answers.jsonl messages.jsonl; do
      [ -f "$SRC/$f" ] && ! cmp -s "$SRC/$f" "$DIR/$f" && die "$EX_IO" "$f differs after copy"
    done
    note "migrated $SRC -> $DIR ($(wc -l <"$DIR/answers.jsonl" 2>/dev/null || echo 0) answers)"
    ;;
  *) die "$EX_USAGE" "unknown verb $VERB" ;;
esac
