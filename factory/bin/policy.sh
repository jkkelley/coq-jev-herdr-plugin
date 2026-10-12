#!/usr/bin/env bash
# policy.sh - the policy watch (WO-20261012-9b2c, under epic WO-20261012-187e). An escalation that nobody answers by its deadline gets
# the default its policy row names, so the line takes the default instead of waiting. It reads the event log and the table in
# factory/config/policies.json and decides nothing else: no branch below reads a kind, a code or a note except through a row.
#
#   policy.sh once   [flags]   one tick: apply the default of every escalation past its deadline, exit
#   policy.sh run    [flags]   ticks forever, every poll_seconds; run it in a labelled herdr pane (herdr/config/monitors.json slot policy), never as a background job
#   policy.sh status [flags]   print every escalation a policy covers that still waits, write nothing; exit 1 when one is past its deadline
# Flags: --config FILE (default factory/config/policies.json)   --repo DIR (what ${repo} means)   --state DIR   --from-start
#        --from-start   on the first start only, judge the escalations already in the log (default: only records written after it)
# One default, in this order: (1) a policy.applied 200 record (seat policy-watch, to the role woken, --policy the row id, --answer the
# escalation's id, the default text in the note), (2) herdr agent prompt <seat> "record <id> playbook <path>", the line route.sh sends.
# An escalation is covered when a row's match (kind, code, optional attempt) holds for it; it is open until a record of one of the row's
# answered_by kinds lands on the same ticket after it. A kind with no row is never touched here: it waits for its answer (AC-H2).
# Exit: 0 ok, 1 an escalation is past its deadline (status only), 2 usage, 3 validation, 4 io.
#
# BREADCRUMB 2026-10-12 - WO-20261012-9b2c. What broke: the PR 22 criteria split (WO-20261011-4562) was escalated to the owner with
#   no deadline and no default, and waited hours for an answer the owner's locked decisions already implied (land the PR, no dead
#   code); routes.json has no notion of time, so a record sent to the architect or the owner stays sent until a person acts, and a
#   dead architect stops the ticket (epic WO-20261012-187e). Why this shape, four choices that look arbitrary:
#   1. The deadline and the default are rows in policies.json, not branches here. New behaviour is a row and make lint, as in
#      routes.json (WO-20261011-38c7). The route runner is untouched: it has no clock, and a clock added to it would make its
#      receipt for a record depend on when it ran.
#   2. A default is a RECORD first (policy.applied 200 naming the row) and a wake second. What would break with the wake alone: the
#      board, the flow watch and the next seat read the log, and a default taken in a prompt leaves no trace of why the ticket moved.
#      A failed wake is a 500 note to the monitor and the record stands, so a dead seat that the supervisor re-seats finds its answer
#      in the log. Rejected: routing the record through a routes.json wake row (a row's `to` is one fixed role, and the seat to wake
#      is the one that asked).
#   3. limit_per_ticket counts policy.applied records already in the log for that ticket and row, not a counter in state/. What would
#      break without it: a seat that is blocked for a reason the default cannot cure posts blocked again, each one a new escalation
#      with a new deadline, and the default would be sent every deadline for ever. Past the limit the repeat waits for the owner, which
#      is what routes.json already does with a second blocked 423. Cost: the count lives in the log, so a log that is pruned resets it.
#   4. break.glass is refused at start (exit 3), on top of the schema. Owner order (WO-20261011-4562): the owner authorises each break
#      glass by hand, once. A table edited to cover it would let the line grant itself the one thing it must never grant itself.
#   The first start judges only records written after it (state/since), like route.sh and flow.sh: a log of old escalations would
#   otherwise wake every seat that ever blocked. Cost of the whole: a default can land up to poll_seconds after its deadline, and the
#   answered_by list is a judgement per row, so a row whose list is too short applies a default over an answer it did not recognise.
set -uo pipefail
export LC_ALL=C
HERE=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd); FACTORY=$(cd "$HERE/.." && pwd)
REPO=$(cd "$FACTORY/.." && pwd); CONFIG=$FACTORY/config/policies.json; STATE=""; FROM_START=0
die() { local c=$1; shift; printf 'policy: %s\n' "$*" >&2; exit "$c"; }
log() { printf '%s policy: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" >&2; }
command -v jq >/dev/null || die 4 "jq is required"
VERB=${1:-}; shift || true
while [ $# -gt 0 ]; do case $1 in
  --config) CONFIG=${2:?}; shift 2;; --repo) REPO=$(cd "${2:?}" && pwd) || die 4 "no such --repo"; shift 2;;
  --state) STATE=${2:?}; shift 2;; --from-start) FROM_START=1; shift;;
  *) die 2 "unknown flag $1";; esac; done
case $VERB in once|run|status) ;; *) sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2;; esac

[ -f "$CONFIG" ] || die 4 "config $CONFIG missing"
cfg() { local v; v=$(jq -r --arg k "$1" '.[$k] // empty' "$CONFIG") || die 3 "config $CONFIG is not JSON"; [ -n "$v" ] || die 3 "config key $1 missing"; printf '%s' "${v//\$\{repo\}/$REPO}"; }
POLL=$(cfg poll_seconds); SEAT=$(cfg watcher_seat); EVENTS=$(cfg events_dir); EVENT_BIN=$(cfg event_bin); RUNNER_CFG=$(cfg runner_config)
[ -n "$STATE" ] || STATE=$(cfg state_dir)
POLICIES=$(jq -c '.policies' "$CONFIG") || die 3 "config $CONFIG is not JSON"
rcfg() { local v; v=$(jq -r --arg k "$1" '.[$k] // empty' "$RUNNER_CFG" 2>/dev/null); [ -n "$v" ] || die 3 "runner config $RUNNER_CFG has no $1"; printf '%s' "${v//\$\{repo\}/$REPO}"; }
[ -f "$RUNNER_CFG" ] || die 4 "runner config $RUNNER_CFG missing"
ROLES=$(rcfg roles_dir); PLAYBOOKS=$(rcfg playbooks_dir); SESSION=${COQ_HERDR_SESSION:-$(rcfg herdr_session)}
SINCE=$STATE/since

now() { date -u +%Y-%m-%dT%H:%M:%SZ; }
stamp() { date -u +%Y%m%dT%H%M%SZ; }
herdr_prompt() { env -u HERDR_PANE_ID -u HERDR_TAB_ID -u HERDR_WORKSPACE_ID -u HERDR_SOCKET_PATH herdr --session "$SESSION" agent prompt "$1" "$2" >/dev/null 2>&1; }
# trouble TICKET TEXT: a 500 note to the monitor. Returns 1 when the record could not be written.
trouble() {
  local args=(--code 500 --kind note --to monitor --note "$(printf '%s' "$2" | cut -c1-240)")
  [ "$1" = - ] || args+=(--ticket "$1")
  "$EVENT_BIN" add --seat "$SEAT" "${args[@]}" >/dev/null 2>&1
}
claim() { ( set -C; printf 'handled %s\n' "$(now)" > "$1" ) 2>/dev/null; }
# seat_of ROLE TICKET / role_of_seat SEAT TICKET: roles/<role>.json label with ${ticket} lowercased, as route.sh and seat.sh name a seat.
seat_of() {
  local label; label=$(jq -r '.label // empty' "$ROLES/$1.json" 2>/dev/null) || return 1
  label=${label//\$\{ticket\}/${2,,}}; case $label in ''|*'${'*) return 1;; esac; printf '%s' "${label,,}"
}
role_of_seat() {
  local f label
  for f in "$ROLES"/*.json; do
    label=$(jq -r '.label // empty' "$f" 2>/dev/null) || continue
    label=${label//\$\{ticket\}/${2,,}}; case $label in ''|*'${'*) continue;; esac
    if [ "${label,,}" = "$1" ]; then basename "$f" .json; return 0; fi
  done
  return 1
}

# open_escalations: id, ticket, seat, policy id, seconds until its deadline (negative when past), defaults already applied to the
# ticket by that row, and the row's limit, for each escalation a row covers that nobody answered and the limit still allows.
open_escalations() {
  local boundary; boundary=$(cat "$SINCE")
  find "$EVENTS" -path '*/20*/*.json' -name '*.json' -print0 2>/dev/null | xargs -0 -r cat 2>/dev/null | jq -rs \
    --argjson pols "$POLICIES" --argjson now "$(date +%s)" --arg since "$boundary" '
    . as $all | $all[] | select(.ticket != null and .id >= $since and .kind != "policy.applied") | . as $r
    | ($pols[] | select(.match.kind == $r.kind and .match.code == $r.code and (.match.attempt == null or ($r.attempt // 1) == .match.attempt))) as $p
    | select([$all[] | select(.ticket == $r.ticket and .id > $r.id and ([.kind] | inside($p.answered_by)))] | length == 0)
    | select([$all[] | select(.kind == "policy.applied" and .answer == $r.id)] | length == 0)
    | ([$all[] | select(.kind == "policy.applied" and .ticket == $r.ticket and .policy == $p.id)] | length) as $have
    | select($have < $p.limit_per_ticket)
    | [$r.id, $r.ticket, $r.seat, $p.id, (($r.at | fromdateiso8601) + $p.deadline_seconds - $now), $have, $p.limit_per_ticket] | @tsv' 2>/dev/null
}

# apply ID TICKET SEAT POLICY: the default of one escalation. The latch is taken before anything is written, so a tick that dies
# half way never repeats a wake; a record that could not be written drops the latch so the next tick tries again.
apply() {
  local id=$1 ticket=$2 seat=$3 pol=$4 row to role target answer rec prompt why=""
  row=$(jq -c --arg p "$pol" 'first(.[] | select(.id == $p))' <<<"$POLICIES")
  claim "$STATE/$id" || return 0
  to=$(jq -r .default.to <<<"$row"); answer=$(jq -r .default.answer <<<"$row")
  if [ "$to" = source ]; then role=$(role_of_seat "$seat" "$ticket"); target=$seat; else role=$to; target=$(seat_of "$to" "$ticket"); fi
  local args=(--code 200 --kind policy.applied --ticket "$ticket" --policy "$pol" --answer "$id" --note "default $pol: $answer")
  [ -z "$role" ] || args+=(--to "$role")
  rec=$("$EVENT_BIN" add --seat "$SEAT" "${args[@]}" 2>/dev/null) || { rm -f "$STATE/$id"; log "could not write the policy.applied record for $id"; return 1; }
  if [ -z "$role" ] || [ -z "$target" ]; then why="no seat or role for $to on ticket $ticket"
  else
    prompt="record $rec playbook $PLAYBOOKS/$role.md"
    herdr_prompt "$target" "$prompt" || why="herdr agent prompt $target failed"
  fi
  [ -z "$why" ] || trouble "$ticket" "policy $pol on record $id: $why; the record $rec stands" || log "could not write the 500 for $id"
  log "applied $pol to $id on $ticket: record $rec${why:+, $why}"
}

FOUND=0
tick() {
  local id ticket seat pol left have limit
  declare -A done_now=()
  while IFS=$'\t' read -r id ticket seat pol left have limit; do
    [ -n "$id" ] || continue
    if [ "$VERB" = status ]; then
      if [ "$left" -le 0 ]; then printf 'overdue %s %s %s: %s past its deadline, not applied\n' "$pol" "$ticket" "$id" "$((-left))s"; FOUND=1
      else printf 'waiting %s %s %s: default in %ss\n' "$pol" "$ticket" "$id" "$left"; fi
      continue
    fi
    [ "$left" -le 0 ] || continue
    # the log count was taken before this tick, so two escalations of one ticket and row in the same tick are counted here
    [ "$((have + ${done_now["$ticket $pol"]:-0}))" -lt "$limit" ] || continue
    apply "$id" "$ticket" "$seat" "$pol" && done_now["$ticket $pol"]=$((${done_now["$ticket $pol"]:-0} + 1))
  done < <(open_escalations)
}
start() {
  mkdir -p "$STATE" || die 4 "cannot create $STATE"; [ -x "$EVENT_BIN" ] || die 4 "event.sh not executable: $EVENT_BIN"
  [ -d "$ROLES" ] || die 4 "roles directory $ROLES missing"
  jq -e 'map(select(.match.kind == "break.glass")) | length == 0' <<<"$POLICIES" >/dev/null || die 3 "a policy matches break.glass; the owner authorises every break glass by hand"
  jq -e '(map(.id) | length) == (map(.id) | unique | length)' <<<"$POLICIES" >/dev/null || die 3 "policy ids are not unique"
  if [ ! -f "$SINCE" ]; then if [ "$FROM_START" = 1 ]; then echo 00000000T000000Z > "$SINCE"; else stamp > "$SINCE"; fi; fi
}
case $VERB in
  status) start; tick; [ "$FOUND" = 0 ] || exit 1 ;;
  once) start; tick ;;
  run) start; trap 'log "stopping"; exit 0' TERM INT; log "running: events $EVENTS, $(jq length <<<"$POLICIES") policies, every ${POLL}s"
    # `read -t` rather than `sleep`, as route.sh and flow.sh: the trap runs at once when TERM arrives during the wait.
    while true; do tick; read -r -t "$POLL" <> <(:) || true; done ;;
esac
