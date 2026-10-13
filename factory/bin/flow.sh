#!/usr/bin/env bash
# flow.sh - the flow watch (WO-20261011-6842, DEC-system-runs-the-loop, DEC-automate-recover-retry). It turns a stalled line into
# a 500 note addressed to the monitor, so a line that sits still no longer looks the same as a quiet one. It reads the event
# log and the belt and decides nothing else: no branch below reads a kind, a code or a note except through factory/config/flow.json.
#
#   flow.sh once   [flags]   one tick: write a 500 for every stall not already noted, exit
#   flow.sh run    [flags]   ticks forever, every poll_seconds; run it in a labelled herdr pane (herdr/config/monitors.json slot flow), never as a background job
#   flow.sh status [flags]   print every stall now present, write nothing; exit 1 when there is one
# Flags: --config FILE (default factory/config/flow.json)   --repo DIR (what ${repo} means)   --state DIR (the state root, as COQ_STATE)   --from-start
#        --from-start   on the first start only, judge the gate records already in the log (default: only records written after it)
# A gate record whose consumer seat is mid-turn (herdr agent_status working) is not a stall, until busy_grace_seconds (flow.json) has passed.
# Three stalls, each one 500 note (seat flow-watch, kind note, to monitor):
#   gate record   a gates row of the config (kind and code) older than stall_seconds with no record of one of its consumer kinds on the same ticket after it
#   belt          route.sh status says the belt file is stale or missing; one note per stall, the latch clears when the belt is fresh again
#   runner pane   no herdr pane labelled like runner_pane_label_regex, or its foreground is the shell; same latch
# Exit: 0 ok, 1 a stall is present (status only), 2 usage, 3 validation, 4 io.
#
# BREADCRUMB 2026-10-11 - WO-20261011-6842. What broke: 2026-10-11 18:01Z to 18:23Z the line sat still with every gate record
#   posted and no seat woken (the runner was not running), and nothing said so: the monitor seat has no wake source, bringup
#   and recover check health and not flow. Why this shape, three choices that look arbitrary:
#   1. Every note is latched in factory/state/flow/ before it is written (a gate record by its id, the belt and the pane by a
#      latch file that is removed when the condition clears). What would break without it: the watcher ticks every poll and
#      the same stall would write a 500 per tick, and each 500 wakes the monitor. Rejected: asking the event log whether the
#      note exists, because notes are 240 characters of prose and the watcher reads no prose. Cost: a gate record noted once is
#      never noted again, even if it is still stuck; the monitor owns it from then on.
#   2. The first start judges only records written after it (state/flow/since), like route.sh. What would break: starting on a
#      log of hundreds of old tickets would 500 for every gate record that ever lacked a consumer.
#   3. The belt age is not computed here: route.sh status owns it and its stale_seconds, so there is one definition of stale.
#      Rejected: a second threshold in flow.json that could drift from runner.json. Cost: flow.sh needs route.sh and its config.
#   BREADCRUMB 2026-10-12 - WO-20261012-3bb0. What broke: the gate rule fired three false alarms on 2026-10-12 (records ch471, 0ui6q and
#   06gu1) 90 s after a gate record while the consumer seat was in the middle of its turn - a tester running a 4 minute suite has
#   posted nothing for longer than stall_seconds and is working exactly as designed, and each false 500 woke the monitor. Why this
#   fix: the stall is judged by the seat's own state, `herdr agent get <seat>` agent_status, which is what "working" means; a
#   working seat is skipped this tick WITHOUT claiming the latch, so the same record is judged again on the next tick and noted the
#   moment the seat goes idle with still no record. Rejected: a longer stall_seconds (it breaks visible_within_seconds, and hides
#   the idle stall it exists for), and reading the pane for a spinner (herdr already did that and calls it agent_status). Cost:
#   busy_grace_seconds is a timer after all, the backstop for a turn that hangs in "working"; a seat whose status herdr cannot
#   report (no such agent, herdr down) is judged as idle, so the old behaviour is the fallback. The seat name comes from
#   roles/<role>.json the way route.sh's seat_of builds it, so a role label change moves both.
#   poll_seconds plus stall_seconds must not pass visible_within_seconds (120): the board must show a stall within two minutes
#   of it starting, so a config that breaks that is refused at start with exit 3.
# BREADCRUMB 2026-10-13 - WO-20261012-0229 (Roadmap A2). What broke: events_dir was ${repo}/events and state_dir ${repo}/factory/state/flow
#   in factory/config/flow.json, so this watcher read its own checkout's log and kept its latches there while records are written to the state root
#   (WO-20261012-7e13); with nothing to read it would never note a stall. Why this fix: both values name a tree through the resolver
#   (events_dir ${tree:records}, state_dir ${tree:run}/flow, see factory/bin/paths.sh) and --state DIR is the state root, as in
#   route.sh, which it passes on to route.sh status through COQ_STATE so there is still one belt. Rejected: reading the repository
#   events/ as well (route.sh does not route it, so a stall there would be noted for a record the belt never saw). Cost: a latch from
#   before this change (factory/state/flow) is not seen, so a stall noted under the old path is noted once more.
set -uo pipefail
export LC_ALL=C
HERE=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd); FACTORY=$(cd "$HERE/.." && pwd)
REPO=$(cd "$FACTORY/.." && pwd); CONFIG=$FACTORY/config/flow.json; STATE_ROOT=""; FROM_START=0
die() { local c=$1; shift; printf 'flow: %s\n' "$*" >&2; exit "$c"; }
log() { printf '%s flow: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" >&2; }
command -v jq >/dev/null || die 4 "jq is required"
VERB=${1:-}; shift || true
while [ $# -gt 0 ]; do case $1 in
  --config) CONFIG=${2:?}; shift 2;; --repo) REPO=$(cd "${2:?}" && pwd) || die 4 "no such --repo"; shift 2;;
  --state) STATE_ROOT=${2:?}; shift 2;; --from-start) FROM_START=1; shift;;
  *) die 2 "unknown flag $1";; esac; done
case $VERB in once|run|status) ;; *) sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2;; esac

[ -f "$CONFIG" ] || die 4 "config $CONFIG missing"
# shellcheck source=paths.sh
. "$HERE/paths.sh" || die 4 "cannot load paths.sh or the state-root resolver beside it"
[ -z "$STATE_ROOT" ] || fx_set_root "$STATE_ROOT" || exit $?
cfg() { local v; v=$(jq -r --arg k "$1" '.[$k] // empty' "$CONFIG") || die 3 "config $CONFIG is not JSON"; [ -n "$v" ] || die 3 "config key $1 missing"; fx_expand "$v"; }
POLL=$(cfg poll_seconds); STALL=$(cfg stall_seconds); GRACE=$(cfg busy_grace_seconds); VISIBLE=$(cfg visible_within_seconds); SEAT=$(cfg watcher_seat)
EVENTS=$(cfg events_dir); EVENT_BIN=$(cfg event_bin); RUNNER_BIN=$(cfg runner_script); RUNNER_CFG=$(cfg runner_config)
PANE_RE=$(cfg runner_pane_label_regex); STATE=$(cfg state_dir)
# cfg runs in a subshell, so a state root it could not resolve (it says why on stderr) arrives here as an empty path
[ -n "$EVENTS" ] && [ -n "$STATE" ] || die 4 "the state root did not resolve; set COQ_STATE or pass --state DIR"
GATES=$(jq -c '.gates' "$CONFIG") || die 3 "config $CONFIG is not JSON"
[ "$((POLL + STALL))" -le "$VISIBLE" ] || die 3 "poll_seconds $POLL + stall_seconds $STALL is more than visible_within_seconds $VISIBLE"
SESSION=${COQ_HERDR_SESSION:-$(jq -r '.herdr_session // empty' "$RUNNER_CFG" 2>/dev/null)}
ROLES_DIR=$(jq -r '.roles_dir // empty' "$RUNNER_CFG" 2>/dev/null); ROLES_DIR=$(fx_expand "$ROLES_DIR")
SINCE=$STATE/since

now() { date -u +%Y-%m-%dT%H:%M:%SZ; }
stamp() { date -u +%Y%m%dT%H%M%SZ; }  # a record id's time part: flow compares .id, not file names
herdr_q() { env -u HERDR_PANE_ID -u HERDR_TAB_ID -u HERDR_WORKSPACE_ID -u HERDR_SOCKET_PATH herdr --session "$SESSION" "$@" 2>/dev/null; }
# note TICKET TEXT: one 500 note to the monitor. Returns 1 when the record could not be written.
note() {
  local args=(--code 500 --kind note --to monitor --note "$(printf '%s' "$2" | cut -c1-240)")
  [ "$1" = - ] || args+=(--ticket "$1")
  "$EVENT_BIN" add --seat "$SEAT" "${args[@]}" >/dev/null 2>&1
}
# seat_of ROLE TICKET: the seat name that role has for the ticket (roles/<role>.json label, ${ticket} lowercased), empty when unresolvable.
seat_of() {
  local label; label=$(jq -r '.label // empty' "$ROLES_DIR/$1.json" 2>/dev/null) || return 1
  label=${label//\$\{ticket\}/${2,,}}; case $label in ''|*'${'*) return 1;; esac; printf '%s' "${label,,}"
}
# seat_working ROLE TICKET AT: 0 when that role's seat for the ticket is mid-turn and the record is younger than busy_grace_seconds.
seat_working() {
  local seat st; [ "$(( $(date +%s) - $3 ))" -lt "$GRACE" ] || return 1
  seat=$(seat_of "$1" "$2") || return 1
  st=$(herdr_q agent get "$seat" | jq -r '.result.agent.agent_status // empty' 2>/dev/null) || return 1
  [ "$st" = working ]
}
# claim PATH: create the latch, false when it already exists.
claim() { ( set -C; printf 'noted %s\n' "$(now)" > "$1" ) 2>/dev/null; }

# stalled_gates: id, ticket, kind, code, consumer role and epoch seconds of each gate record past stall_seconds with no consumer record after it.
stalled_gates() {
  local boundary; boundary=$(cat "$SINCE")
  find "$EVENTS" -path '*/20*/*.json' -name '*.json' -print0 2>/dev/null | xargs -0 -r cat 2>/dev/null | jq -rs \
    --argjson gates "$GATES" --argjson now "$(date +%s)" --argjson stall "$STALL" --arg since "$boundary" '
    . as $all | $all[] | select(.ticket != null and .id >= $since) | . as $r
    | ($gates[] | select(.kind == $r.kind and .code == $r.code)) as $g
    | select(($r.at | fromdateiso8601) <= $now - $stall)
    | select([$all[] | select(.ticket == $r.ticket and .id > $r.id and ([.kind] | inside($g.consumers)))] | length == 0)
    | [$r.id, $r.ticket, $r.kind, ($r.code | tostring), $g.role, ($r.at | fromdateiso8601 | tostring)] | @tsv' 2>/dev/null
}
# check_gates: one note per stalled gate record not already latched.
check_gates() {
  local id ticket kind code role at
  while IFS=$'\t' read -r id ticket kind code role at; do
    [ -n "$id" ] || continue
    # a consumer seat that is mid-turn is working, not stalled: skip without claiming, so the next tick judges it again.
    ! seat_working "$role" "$ticket" "$at" || continue
    if [ "$VERB" = status ]; then printf 'stall gate %s %s %s %s: no %s record after %ss\n' "$id" "$ticket" "$kind" "$code" "$role" "$STALL"; FOUND=1; continue; fi
    claim "$STATE/$id" || continue
    note "$ticket" "stall: $kind $code $id has no $role record after ${STALL}s" || { rm -f "$STATE/$id"; log "could not write the 500 for $id"; }
  done < <(stalled_gates)
}
# latched NAME CONDITION_RC TEXT: write TEXT once while the condition (rc 0 = stalled) holds; drop the latch when it clears.
latched() {
  local name=$1 rc=$2 text=$3 latch=$STATE/$1
  if [ "$rc" != 0 ]; then rm -f "$latch"; return; fi
  if [ "$VERB" = status ]; then printf 'stall %s: %s\n' "$name" "$text"; FOUND=1; return; fi
  claim "$latch" || return
  note - "$text" || { rm -f "$latch"; log "could not write the 500 for $name"; }
}
check_belt() {
  local out rc; out=$("$RUNNER_BIN" status --repo "$REPO" --config "$RUNNER_CFG" 2>&1); rc=$?
  case $rc in 0) latched belt-stale 1 "" ;; 1) latched belt-stale 0 "stall: belt ${out#belt: }" ;; *) log "route.sh status exited $rc: $out" ;; esac
}
# runner_running: 0 when a pane labelled like the runner has a job in the foreground (its process group is not the shell's).
runner_running() {
  local pane
  pane=$(herdr_q pane list | jq -r --arg re "$PANE_RE" 'first((.result.panes // [])[] | select((.label // "") | test($re)) | .pane_id) // empty') || return 1
  [ -n "$pane" ] || return 1
  herdr_q pane process-info --pane "$pane" | jq -e '.result.process_info | .foreground_process_group_id != null and .shell_pid != null and .foreground_process_group_id != .shell_pid' >/dev/null
}
check_pane() {
  if runner_running; then latched runner-gone 1 ""; else latched runner-gone 0 "stall: the route runner pane is not running (no pane labelled like $PANE_RE with a job in it)"; fi
}
tick() { FOUND=0; check_gates; check_belt; check_pane; }
start() {
  mkdir -p "$STATE" || die 4 "cannot create $STATE"; [ -x "$EVENT_BIN" ] || die 4 "event.sh not executable: $EVENT_BIN"
  fx_readme "$STATE" "# run/flow - the flow watch's latches
Written by factory/bin/flow.sh: one file per gate record it has noted, belt-stale and runner-gone while those stalls stand, and since (the first-start boundary, a record id time stamp).
Read by flow.sh itself, so a stall is noted once.
Clean: safe to delete; a deleted latch lets the same stall be noted once more, a deleted since makes the next start set a new boundary."
  [ -x "$RUNNER_BIN" ] || die 4 "route.sh not executable: $RUNNER_BIN"
  if [ ! -f "$SINCE" ]; then if [ "$FROM_START" = 1 ]; then echo 00000000T000000Z > "$SINCE"; else stamp > "$SINCE"; fi; fi
}
case $VERB in
  status) start; tick; [ "$FOUND" = 0 ] && echo "flow: ok" || exit 1 ;;
  once) start; tick ;;
  run) start; trap 'log "stopping"; exit 0' TERM INT; log "running: events $EVENTS, stall after ${STALL}s, every ${POLL}s"
    # `read -t` rather than `sleep`, as route.sh: the trap runs at once when TERM arrives during the wait.
    while true; do tick; read -r -t "$POLL" <> <(:) || true; done ;;
esac
