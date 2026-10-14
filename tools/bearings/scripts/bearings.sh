#!/usr/bin/env bash
# bearings.sh - the one entry point for a bearings tier. Every verb resolves the
# tier through config/bearings.json (via lib/config.mjs) and never carries a
# default of its own. Inside herdr (HERDR_ENV=1) the server and the wait each get
# a labelled pane in the current tab (Rule 18: nothing backgrounded, every
# watcher visible). That pane is an OPEN tool-grid slot (label starts with
# open_label_prefix) relabelled for the job, never a split of the calling seat's
# pane; stop relabels it OPEN again and closes nothing. Outside herdr it refuses,
# unless --no-herdr is given, which the Podman test harness uses where no herdr runs.
#
#   bearings.sh <tier> serve    [--ticket ID] [--config P] [--session S] [--join] [--model M] [--working-on TEXT] [--no-herdr]
#   bearings.sh <tier> stop     [--ticket ID] [--config P]
#   bearings.sh <tier> rotate-key [--ticket ID] [--config P] [--to PANE] [--no-herdr]   new key, same page, same panes; prints the new url
#   bearings.sh <tier> wait     [--ticket ID] [--config P] [--to PANE] [--no-herdr]   each wake is prompted into PANE (default COQ_SEAT_PANE, else the calling pane)
#   bearings.sh <tier> reply    [--ticket ID] [--config P] --to <message-id> "text"
#   bearings.sh <tier> sitrep   [--ticket ID] [--config P] --payload FILE [--to <message-id>]   check, then send as a reply; refuses on a violation
#   bearings.sh <tier> front-door      [--ticket ID] [--config P] [--no-herdr]   TCP forwarder tailnet-IP:port -> 127.0.0.1:port in a labelled pane, no root (scripts/front-door.mjs)
#   bearings.sh <tier> front-door-stop  [--ticket ID] [--config P]   explicit only; stop never touches it
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

[ $# -ge 2 ] || { sed -n '2,25p' "$0" >&2; exit "$EX_USAGE"; }
TIER=$1; VERB=$2; shift 2
TICKET=""; CONFIG="${BEARINGS_CONFIG:-$TOOL/config/bearings.json}"; NO_HERDR=0; JSON=0; FORCE=0
SESSION=""; MODEL=""; CWD=""; WORKING_ON=""; TO=""; JOIN=0; PAYLOAD=""
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
    --payload) PAYLOAD=${2:-}; shift 2 ;;
    --no-herdr) NO_HERDR=1; shift ;;
    --json) JSON=1; shift ;;
    --force) FORCE=1; shift ;;
    --join) JOIN=1; shift ;;
    --help|-h) sed -n '2,25p' "$0" >&2; exit "$EX_OK" ;;
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
  console.log(JSON.stringify({ ...T, split: cfg.pane_split, openPrefix: cfg.open_label_prefix }));
' "$CONFIG" "$TIER" "$TICKET")
PAGE=$(jq -r .page <<<"$RESOLVED"); DIR=$(jq -r .stateDir <<<"$RESOLVED")
PANE_LABEL=$(jq -r .paneLabel <<<"$RESOLVED"); WAIT_LABEL=$(jq -r .waitPaneLabel <<<"$RESOLVED")
SPLIT_DIR=$(jq -r .split.direction <<<"$RESOLVED"); SPLIT_RATIO=$(jq -r .split.ratio <<<"$RESOLVED")
FD_LABEL=$(jq -r '.frontDoorPaneLabel // empty' <<<"$RESOLVED")
OPEN_PREFIX=$(jq -r .openPrefix <<<"$RESOLVED")
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
# pane_for <label>: sets P to the pane that carries <label> in this tab and P_WAS to the label an OPEN slot had before
# it was taken (empty when the pane already carried <label>, or was split). Sets globals instead of printing because
# a command substitution would lose P_WAS.
#
# BREADCRUMB 2026-10-11 UTC - WO-20261010-2d04. What broke: this function split $HERDR_PANE_ID, the pane of whichever
#   seat ran the verb, whenever no pane carried the label. Restarting the stable tier from the architect seat at
#   22:25 UTC on 2026-10-10 closed the two grid panes (the old stop) and then carved two new ones out of the architect
#   column (line `herdr pane split "$HERDR_PANE_ID"`), so the owner's 3x3 arc broke: one agent on the left, two tool
#   slots gone. Why this fix: the tool grid already holds panes labelled "<open_label_prefix> ..." for exactly these
#   jobs, so a missing pane is claimed from them (relabelled) and nothing is ever split inside a seat layout. The
#   split stays only for a caller with no seat (COQ_SEAT unset), where there is no layout to break. A seat with no
#   OPEN slot left dies naming the tab: a clear stop beats a silently re-carved column. Rejected: a config key naming a
#   pane id (changes with every herdr restart), and splitting the last pane of the tab (still lands in a seat's space).
#   Cost: a full grid refuses a third tool until the owner frees a slot, which is the point of a fixed grid.
#   Record: work-orders/WO-20261010-329d/WO-20261010-2d04-*.md, Notes, decision of 2026-10-11 UTC.
pane_for() {
  local label=$1 open
  P_WAS=""
  P=$(pane_by_label "$label")
  if [ -z "$P" ]; then
    open=$(herdr pane list 2>/dev/null | jq -r --arg pre "$OPEN_PREFIX" --arg t "${HERDR_TAB_ID:-}" --arg self "${HERDR_PANE_ID:-}" \
      '[.result.panes[]? | select((.label // "") | startswith($pre)) | select(.pane_id != $self and ($t == "" or .tab_id == $t))] | first // empty | [.pane_id, .label] | @tsv' || true)
    if [ -n "$open" ]; then
      P=${open%%$'\t'*}; P_WAS=${open#*$'\t'}
      herdr pane rename "$P" "$label" >/dev/null || die "$EX_IO" "herdr pane rename $P failed"
    elif [ -z "${COQ_SEAT:-}" ]; then
      P=$(herdr pane split "$HERDR_PANE_ID" --direction "$SPLIT_DIR" --ratio "$SPLIT_RATIO" --cwd "$TOOL" --no-focus | jq -r '.result.pane.pane_id')
      [ -n "$P" ] || die "$EX_IO" "herdr pane split returned no pane id"
      herdr pane rename "$P" "$label" >/dev/null
    else
      die "$EX_VALIDATION" "tab ${HERDR_TAB_ID:-?} has no pane labelled '$OPEN_PREFIX...' for $label, and seat ${COQ_SEAT} must not be split; free a tool slot (relabel a pane '$OPEN_PREFIX') and run it again"
    fi
  fi
}
# slots_save <kept> <kind> <was>: server.json keeps open_slots {server, wait} = the label each slot had before it was
# taken. server.mjs rewrites server.json whole at every start and drops extra keys, so serve and rotate-key hand the
# slots they read before the start back in as <kept>. A no-op while server.json does not exist yet.
slots_save() {
  local kept=$1 kind=$2 was=$3
  [ -f "$DIR/server.json" ] || return 0
  jq --argjson k "$kept" --arg kind "$kind" --arg was "$was" \
    '.open_slots = ($k + (if $was == "" then {} else {($kind): $was} end))' "$DIR/server.json" >"$DIR/server.json.tmp" && mv "$DIR/server.json.tmp" "$DIR/server.json"
}
slots_kept() { jq -c '.open_slots // {}' <<<"$(server_json)"; }
wait_for_server() {
  local _; for _ in $(seq 1 60); do server_alive && [ -n "$(jq -r '.url // empty' <<<"$(server_json)")" ] && return 0; sleep 0.25; done
  return 1
}

case $VERB in
  serve)
    server_alive && die "$EX_VALIDATION" "$PAGE is already running: $(jq -r .url <<<"$(server_json)")"
    ARGS=("${COMMON[@]}"); [ -n "$SESSION" ] && ARGS+=(--session "$SESSION"); [ -n "$MODEL" ] && ARGS+=(--model "$MODEL")
    [ -n "$CWD" ] && ARGS+=(--cwd "$CWD"); [ -n "$WORKING_ON" ] && ARGS+=(--working-on "$WORKING_ON")
    # BREADCRUMB 2026-10-10 22:3x UTC. What broke: server.mjs:105 refuses to start when session.json names another
    #   session unless it is given --join, and this script had no way to pass it, so a successor seat on the same page
    #   (the architect after a compaction or a new session) got "server did not come up in pane" and the owner page
    #   stayed down (this seat, 22:25Z). Why this fix: forward the flag; the refusal in server.mjs is the right guard
    #   and stays. Rejected: deleting session.json before serve (hand-edits a state file and loses the started time).
    [ "$JOIN" = 1 ] && ARGS+=(--join)
    rm -f "$DIR/stopped.json"
    if in_herdr && [ "$NO_HERDR" = 0 ]; then
      need herdr
      KEPT=$(slots_kept)
      pane_for "$PANE_LABEL"
      herdr pane run "$P" "node $HERE/server.mjs $(printf '%q ' "${ARGS[@]}")" >/dev/null
      wait_for_server || die "$EX_IO" "server did not come up in pane $P; read it with: herdr pane read $P"
      slots_save "$KEPT" server "$P_WAS"
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
    # BREADCRUMB 2026-10-11 UTC - WO-20261010-2d04. What broke: this closed the wait and server panes (herdr pane close),
    #   so every restart removed two tool-grid cells and the next serve had to carve new ones out of the caller's column
    #   (see pane_for). Why this fix: the grid is fixed and nothing closes a pane (monitors.sh says the same); a stopped
    #   tier hands each pane back as an OPEN slot with the label it had when it was taken, kept in server.json open_slots,
    #   else the bare open_label_prefix. The wait loop ends by itself on stopped.json and the server process is gone, so
    #   the pane is an idle shell again. Cost: the pane keeps its scrollback; a clear is the next job's first command.
    SLOTS=$(slots_kept)
    node "$HERE/server.mjs" "${COMMON[@]}" --stop
    if in_herdr && [ "$NO_HERDR" = 0 ] && command -v herdr >/dev/null 2>&1; then
      for k in wait server; do
        if [ "$k" = wait ]; then l=$WAIT_LABEL; else l=$PANE_LABEL; fi
        p=$(pane_by_label "$l")
        if [ -n "$p" ]; then
          was=$(jq -r --arg k "$k" '.[$k] // empty' <<<"$SLOTS")
          herdr pane rename "$p" "${was:-$OPEN_PREFIX}" >/dev/null 2>&1 && note "pane $p ($l) is an open slot again: ${was:-$OPEN_PREFIX}"
        fi
      done
      if [ -f "$DIR/server.json" ]; then
        jq 'del(.open_slots)' "$DIR/server.json" >"$DIR/server.json.tmp" && mv "$DIR/server.json.tmp" "$DIR/server.json"
      fi
    fi
    ;;
  wait)
    # Breadcrumb 2026-10-10 20:3x UTC (owner, chat: "when you come back from compaction, you need to turn the
    # bearings back on, wtf, i dropped a message there"). What broke: the loop below printed every ANSWER and
    # MESSAGE line into the wait pane (wD3:pD) and marked it delivered; the seat that asked was never woken,
    # so a message dropped while the seat was busy or just compacted sat in a pane nobody reads. Why this fix:
    # every wake is forwarded whole, as one `herdr agent prompt <pane>`, into the seat's pane (herdr queues a
    # prompt to a busy agent and lands it at the end of its turn, the same path bin/step.sh uses for /compact),
    # and it still prints into the wait pane so it stays visible. Rejected: a background wait inside the seat's
    # own shell, which dies with every compaction and hides a process under an agent (owner rule). Cost: the
    # wait needs a target pane; without one it prints only and says so.
    WAKE_PANE=${TO:-${COQ_SEAT_PANE:-${HERDR_PANE_ID:-}}}
    [ -n "$WAKE_PANE" ] || note "wait: no --to pane and no COQ_SEAT_PANE or HERDR_PANE_ID; wakes print only"
    FWD=""; [ -z "$WAKE_PANE" ] || FWD="[ -z \"\$out\" ] || herdr agent prompt $(printf '%q' "$WAKE_PANE") \"\$out\" >/dev/null 2>&1 || printf 'bearings: wake not delivered to %s\\n' $(printf '%q' "$WAKE_PANE");"
    LOOP="while [ ! -f $(printf '%q' "$DIR/stopped.json") ]; do out=\$(node $(printf '%q' "$HERE/wait.mjs") $(printf '%q ' "${COMMON[@]}")); printf '%s\\n' \"\$out\"; $FWD sleep 1; done"
    if in_herdr && [ "$NO_HERDR" = 0 ]; then
      need herdr
      pane_for "$WAIT_LABEL"
      slots_save "$(slots_kept)" wait "$P_WAS"
      # A loop already running in that pane is stopped first, so the new one is never typed into it.
      if herdr pane process-info --pane "$P" 2>/dev/null | jq -e '.result.process_info | .foreground_process_group_id != null and .shell_pid != null and .foreground_process_group_id != .shell_pid' >/dev/null 2>&1; then
        herdr pane send-keys "$P" C-c >/dev/null 2>&1 || true; sleep 1; herdr pane send-keys "$P" C-c >/dev/null 2>&1 || true
        herdr pane wait-output "$P" --regex '[$%>❯] *$' --timeout 10000 >/dev/null 2>&1 || die "$EX_IO" "pane $P did not come back to a prompt; read it with: herdr pane read $P"
      fi
      herdr pane run "$P" "$LOOP" >/dev/null
      note "wait loop in pane $P ($WAIT_LABEL), waking ${WAKE_PANE:-nobody}"; printf '%s\n' "$P"
    elif [ "$NO_HERDR" = 1 ]; then
      exec node "$HERE/wait.mjs" "${COMMON[@]}"
    else
      die "$EX_VALIDATION" "not inside herdr (HERDR_ENV unset); pass --no-herdr to run one wait in the foreground"
    fi
    ;;
  front-door)
    # BREADCRUMB 2026-10-14 UTC (PR 186 follow-up). What broke: the server listens on 127.0.0.1 only and `tailscale serve`
    #   needs root, so the owner's phone on the tailnet could not open the stable page. Why this fix: scripts/front-door.mjs
    #   (its header has the full reasoning) is started the way the server and wait are: in a labelled OPEN-slot pane via
    #   pane_for, never backgrounded under a seat. Rejected: folding it into `serve`, which would restart the live stable
    #   server (owner: stable never stops) and bind a second listener inside the page process. Cost: a third pane per tier
    #   that uses it, and `stop` deliberately leaves it running; front-door-stop is the explicit way down.
    [ -n "$FD_LABEL" ] || die "$EX_VALIDATION" "tier $TIER has no front_door_pane_label in $CONFIG; it has no front door"
    FD_PID=$(jq -r '.pid // empty' "$DIR/front-door.json" 2>/dev/null || true)
    if [ -n "$FD_PID" ] && kill -0 "$FD_PID" 2>/dev/null; then
      die "$EX_VALIDATION" "front door already running for $PAGE: pid $FD_PID $(jq -r '"\(.bind):\(.port)"' "$DIR/front-door.json")"
    fi
    FD_CMD="node $HERE/front-door.mjs $(printf '%q ' "${COMMON[@]}")"
    if in_herdr && [ "$NO_HERDR" = 0 ]; then
      need herdr
      pane_for "$FD_LABEL"
      herdr pane run "$P" "$FD_CMD" >/dev/null
      note "front door starting in pane $P ($FD_LABEL)"
    elif [ "$NO_HERDR" = 1 ]; then
      mkdir -p "$DIR"
      # shellcheck disable=SC2086
      nohup $FD_CMD >"$DIR/front-door.log" 2>&1 &
    else
      die "$EX_VALIDATION" "not inside herdr (HERDR_ENV unset): every bearings process needs a labelled pane; run this from a herdr pane or pass --no-herdr in a test harness"
    fi
    # front-door.mjs retries the bind 3 times 2 s apart, so allow it 10 s before calling it failed.
    for _ in $(seq 1 40); do
      FD_PID=$(jq -r '.pid // empty' "$DIR/front-door.json" 2>/dev/null || true)
      [ -n "$FD_PID" ] && kill -0 "$FD_PID" 2>/dev/null && { jq -r '"front door up: \(.bind):\(.port) pid \(.pid)"' "$DIR/front-door.json"; exit "$EX_OK"; }
      sleep 0.25
    done
    if [ -n "${P:-}" ]; then die "$EX_IO" "front door did not come up in pane $P; read it with: herdr pane read $P"; fi
    die "$EX_IO" "front door did not come up; see $DIR/front-door.log"
    ;;
  front-door-stop)
    FD_PID=$(jq -r '.pid // empty' "$DIR/front-door.json" 2>/dev/null || true)
    [ -n "$FD_PID" ] && kill -0 "$FD_PID" 2>/dev/null || die "$EX_NOTFOUND" "no running front door for $PAGE"
    kill -TERM "$FD_PID"
    for _ in $(seq 1 40); do kill -0 "$FD_PID" 2>/dev/null || break; sleep 0.25; done
    kill -0 "$FD_PID" 2>/dev/null && die "$EX_IO" "front door pid $FD_PID did not stop"
    note "front door pid $FD_PID stopped"
    # Hand the pane back as an OPEN slot, the way stop does for the server and wait panes; nothing is closed.
    if [ -n "$FD_LABEL" ] && in_herdr && [ "$NO_HERDR" = 0 ] && command -v herdr >/dev/null 2>&1; then
      p=$(pane_by_label "$FD_LABEL")
      [ -z "$p" ] || { herdr pane rename "$p" "$OPEN_PREFIX" >/dev/null 2>&1 && note "pane $p ($FD_LABEL) is an open slot again: $OPEN_PREFIX"; }
    fi
    ;;
  rotate-key)
    # BREADCRUMB 2026-10-11 UTC, owner: "Do it now". What broke: the keyed page URL sat in six committed checkpoints
    #   of the public repo (CONTEXT_STATE.md, 2026-10-10 20:01 to 21:45 UTC); the in-tree redaction left it in git
    #   history. Why this fix: server.mjs reuses server.json's key on every start (the KEY line), so a new key means
    #   dropping it from server.json between a stop and a start. Doing that here keeps the file owned by the tool,
    #   keeps the labelled panes (stop closes them, this does not), and keeps the session binding (--join with the
    #   session.json values). Rejected: rewriting history on a public main (breaks every clone and the worker's
    #   branch base, and a dead key needs no scrubbing). Cost: the owner opens the new link once; the old cookie no
    #   longer matches.
    server_alive || die "$EX_VALIDATION" "$PAGE is not running; nothing to rotate"
    SESS=$(jq -r '.session // empty' "$DIR/session.json" 2>/dev/null || true)
    SMODEL=$(jq -r '.model // empty' "$DIR/session.json" 2>/dev/null || true)
    SWORK=$(jq -r '.working_on // empty' "$DIR/session.json" 2>/dev/null || true)
    KEPT=$(slots_kept)
    node "$HERE/server.mjs" "${COMMON[@]}" --stop >/dev/null
    for _ in $(seq 1 40); do server_alive || break; sleep 0.25; done
    server_alive && die "$EX_IO" "$PAGE did not stop"
    for _ in $(seq 1 20); do [ -f "$DIR/stopped.json" ] && break; sleep 0.25; done
    jq 'del(.key, .url, .pid)' "$DIR/server.json" >"$DIR/server.json.tmp" && mv "$DIR/server.json.tmp" "$DIR/server.json"
    rm -f "$DIR/stopped.json"
    ARGS=("${COMMON[@]}" --join)
    [ -n "$SESS" ] && ARGS+=(--session "$SESS"); [ -n "$SMODEL" ] && ARGS+=(--model "$SMODEL"); [ -n "$SWORK" ] && ARGS+=(--working-on "$SWORK")
    if in_herdr && [ "$NO_HERDR" = 0 ]; then
      need herdr
      pane_for "$PANE_LABEL"
      herdr pane run "$P" "node $HERE/server.mjs $(printf '%q ' "${ARGS[@]}")" >/dev/null
      wait_for_server || die "$EX_IO" "server did not come back in pane $P; read it with: herdr pane read $P"
      slots_save "$KEPT" server "$P_WAS"
      note "server back in pane $P ($PANE_LABEL) with a new key"
      # The wait loop ended on stopped.json; the wait verb restarts it in its own labelled pane.
      "$0" "$TIER" wait "${TICKET_ARGS[@]}" --config "$CONFIG" ${TO:+--to "$TO"} >/dev/null
    elif [ "$NO_HERDR" = 1 ]; then
      nohup node "$HERE/server.mjs" "${ARGS[@]}" >"$DIR/server.log" 2>&1 &
      wait_for_server || die "$EX_IO" "server did not come back; see $DIR/server.log"
    else
      die "$EX_VALIDATION" "not inside herdr (HERDR_ENV unset): every bearings process needs a labelled pane; run this from a herdr pane or pass --no-herdr in a test harness"
    fi
    jq -r .url <<<"$(server_json)"
    ;;
  reply)
    [ -n "$TO" ] || die "$EX_USAGE" "reply needs --to <message-id>"
    if [ ${#POS[@]} -gt 0 ]; then node "$HERE/reply.mjs" "${COMMON[@]}" --to "$TO" "${POS[0]}"; else node "$HERE/reply.mjs" "${COMMON[@]}" --to "$TO"; fi
    ;;
  sitrep)
    # WO-20261012-668a. The owner's status briefing: a #SITREP/v1# payload (scripts/sitrep-build.mjs makes one from the records)
    # is measured against STD-owner-sitrep-001 by sitrep-check.mjs and sent as a reply only when it passes. What this prevents:
    # a dense briefing reaching the owner because the writer judged that it "reads fine"; the standard says it is counted, so
    # a violation exits 3 here and nothing is written to messages.jsonl. The checker prints the normalised message text on
    # stdout (--emit), so the file may be bare JSON or already tagged, and what is sent is always tag plus minified JSON.
    # --to defaults to the newest message the owner typed on this page, because a briefing is almost always the answer to one;
    # a page with none needs --to spelled out (exit 6 from reply.mjs says so).
    [ -n "$PAYLOAD" ] || die "$EX_USAGE" "sitrep needs --payload FILE (a #SITREP/v1# message or its bare JSON)"
    [ -f "$PAYLOAD" ] || die "$EX_NOTFOUND" "no such payload file $PAYLOAD"
    if ! MSG=$(node "$HERE/sitrep-check.mjs" "$PAYLOAD" --config "$CONFIG" --emit); then
      die "$EX_VALIDATION" "SITREP refused: $PAYLOAD breaks the standard (violations above); nothing was sent"
    fi
    TO_ID=$TO
    [ -n "$TO_ID" ] || TO_ID=$(jq -rs '[.[] | select(.from == "you")] | last | .id // empty' "$DIR/messages.jsonl" 2>/dev/null || true)
    [ -n "$TO_ID" ] || die "$EX_NOTFOUND" "no owner message on $PAGE to reply to; pass --to <message-id>"
    printf '%s' "$MSG" | node "$HERE/reply.mjs" "${COMMON[@]}" --to "$TO_ID"
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
