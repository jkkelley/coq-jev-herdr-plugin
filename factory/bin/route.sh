#!/usr/bin/env bash
# route.sh - the route runner (SPEC-03 s-routes). It reads each new record in the event log, matches it against
# factory/config/routes.json top to bottom, performs the first row's action, and writes one record.routed 300.
# It applies the table and nothing else: no branch below reads a kind, a code or a note except to match a row.
# New behaviour is a routes.json row, never a line here (ticket WO-20261011-38c7, hard cap).
#
#   route.sh once   [flags]      one tick: route every new record, touch the belt file, exit
#   route.sh run    [flags]      ticks forever, every poll_seconds; run it in a labelled herdr pane, never as a background job
#   route.sh status [flags]      print the belt age; exit 0 when fresher than stale_seconds, 1 when stale or missing
# Flags: --config FILE (default factory/config/runner.json)   --repo DIR (what ${repo} means)   --routes FILE   --state DIR
#        --from-start   on the first start only, route the records already in the log (default: only records written after it)
# Actions: wake and notify_owner = herdr agent prompt <seat> "record <id> playbook <path>"; enqueue = queue.sh enqueue;
#          escalate = event.sh add --kind escalated --to <role>; ignore = the ledger entry and nothing else (no receipt, no 500).
#          A record no row matches, or an action that fails, becomes a 500 note addressed to the monitor.
# Exit: 0 ok, 1 belt stale (status only), 2 usage, 3 validation, 4 io.
#
# BREADCRUMB 2026-10-11 - WO-20261011-38c7. Three choices that look arbitrary:
#   1. Records whose seat is runner_seat are never routed. What would break: record.routed 300 matches no row, so it would
#      become a 500, whose own receipt would become another 500, without end. A kind-based skip was rejected because the
#      escalated 423 and the 500 note must stay visible to everything else; only the runner's own seat is excluded.
#      Cost: a record some other seat writes under the runner's seat name is never routed.
#   2. A record is claimed in the ledger (state/routed/<id>) before its action runs and finished after. What broke without it:
#      a cursor that advances after the action routes a record twice if the runner dies in between, and one that advances
#      before loses the route silently. Here a runner that dies mid-action leaves "claimed", and the next start writes a 500
#      to the monitor naming the record instead of repeating a wake. Rejected: a high-water cursor file, because records
#      written in the same second by two seats sort by a random suffix and a mark could skip one. Cost: one small file per
#      record under factory/state/, gitignored.
#   3. The first start routes nothing already in the log (state/since holds the boundary) unless --from-start is given.
#      What would break: starting on a log of hundreds of old records would wake every seat that ever existed.
# BREADCRUMB 2026-10-11 - WO-20261011-4db1, the ignore action. What broke: the table had no row for seat.up 100, seat.down 100,
#   note 100 or work.started 100, so each one became a 500 "no route for ..." addressed to the monitor (nine in six minutes at
#   18:32Z, and `grep "no route for" events/2026/10/*` still shows work.started 100 four times), and the monitor could not tell
#   those from a real 500 such as the pr.opened 100 that found no tester seat (muiv4). Why this fix: a row with do ignore,
#   written in routes.json like every other behaviour; route_file marks the ledger "ignored" and returns, so a record that
#   matches it leaves no trace but its ledger entry. Rejected: a skip list of kinds inside this script (it would be the first
#   line here that reads a kind outside a row match), and a receipt per ignored record (a seat that comes up writes seat.up, and
#   a receipt for it would double the log with exactly the noise this removes). Cost: an ignored record is invisible to
#   `record.routed` counts; the ledger file under state/routed/ is the only proof it was seen. work.started 100 is NOT ignored
#   here: report/loop/lib/collect.jq reads the first matching row's `to` to place a line on the board, and a row with no `to`
#   would put a ticket whose newest record is work.started at the owner station; that file is WO-20261011-616c's, so the row
#   waits for a one-line route_of change there (finding in the 4db1 retro note).
#   The seat action: a row with do seat runs `seat.sh --ticket T --role R` and then sends the same wake line a wake row sends. What
#   broke: the route runner only prompted, so pr.opened 100 for WO-20261011-23df (muiv4, 18:31Z) failed as "route failed ...
#   herdr agent prompt tester-... failed" because no tester seat existed, and the architect seated every tester, reviewer and
#   merger by hand (DEC-system-runs-the-loop). Why this fix: seat.sh already leaves a live seat as is ("agent already running"),
#   so the runner calls it for every record and never asks whether the seat is up; asking would be a second copy of that check
#   (`seat.sh --check` exits 3 both for "down since" and for "no seat named", and a herdr agent get here would be a component
#   reading another's state). Rejected: a background seat.sh (AGENTS.md: no background process; the wake would race the seat).
#   The name for the prompt comes from seat_of, the same label rule seat.sh uses. Cost: the runner is serial, so a bring-up
#   (prompt 15 s, agent start 30 s, the brief) holds every later record; belt_touch after the call keeps the belt fresh between
#   records, but one bring-up past stale_seconds (60) still reads as stopped while it runs (WO-20261011-5355 owns the belt). seat.sh
#   needs HERDR_TAB_ID to find the architect tab's "test - herdr" pane, so the runner pane must sit in that tab, or every bring-up
#   is refused and becomes a 500 naming the refusal. The prompt follows seat.sh's own brief; a prompt herdr refuses is a 500.
#   The sha on the wake line: a row that says `with pr` appends " pr N" and " sha S" from the record, so the merger gate
#   compares fields, not a note (event.sh --sha and --pr write them). What broke: playbooks/merger.md step 1 gates on "the
#   same sha" and the only copy of it was prose. A value that is not a PR number or 7 to 40 hex characters is a 500 and
#   nothing is typed into the seat: both reach a prompt as text. Rejected: dropping a bad value and sending the plain line
#   (the merger would hold with no sign why). Cost: a hand-written record with a bad sha stops its own route.
#   A record with no attempt counts as attempt 1; escalations is the number of escalated records the runner wrote for the
#   ticket before this one, which is how the table tells a first 423 from a second.
set -uo pipefail
export LC_ALL=C
HERE=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd); FACTORY=$(cd "$HERE/.." && pwd)
REPO=$(cd "$FACTORY/.." && pwd); CONFIG=$FACTORY/config/runner.json; ROUTES=""; STATE=""; FROM_START=0
die() { local c=$1; shift; printf 'route: %s\n' "$*" >&2; exit "$c"; }
log() { printf '%s route: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" >&2; }
command -v jq >/dev/null || die 4 "jq is required"
VERB=${1:-}; shift || true
while [ $# -gt 0 ]; do case $1 in
  --config) CONFIG=${2:?}; shift 2;; --repo) REPO=$(cd "${2:?}" && pwd) || die 4 "no such --repo"; shift 2;;
  --routes) ROUTES=${2:?}; shift 2;; --state) STATE=${2:?}; shift 2;; --from-start) FROM_START=1; shift;;
  *) die 2 "unknown flag $1";; esac; done
case $VERB in once|run|status) ;; *) sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2;; esac

[ -f "$CONFIG" ] || die 4 "config $CONFIG missing"
cfg() { local v; v=$(jq -r --arg k "$1" '.[$k] // empty' "$CONFIG") || die 3 "config $CONFIG is not JSON"; [ -n "$v" ] || die 3 "config key $1 missing"; printf '%s' "${v//\$\{repo\}/$REPO}"; }
POLL=$(cfg poll_seconds); SEAT=$(cfg runner_seat); SESSION=${COQ_HERDR_SESSION:-$(cfg herdr_session)}
EVENTS=$(cfg events_dir); EVENT_BIN=$(cfg event_bin); QUEUE_BIN=$(cfg queue_bin)
SEAT_BIN=$(cfg seat_bin); ROLES=$(cfg roles_dir); PLAYBOOKS=$(cfg playbooks_dir); STALE=$(cfg stale_seconds)
[ -n "$ROUTES" ] || ROUTES=$(cfg routes_file); [ -n "$STATE" ] || STATE=$(cfg state_dir)
LEDGER=$STATE/routed; BELT=$STATE/belt; SINCE=$STATE/since

now() { date -u +%Y-%m-%dT%H:%M:%SZ; }
stamp() { date -u +%Y%m%dT%H%M%SZ; }
belt_touch() { printf '%s pid %s\n' "$(now)" "$$" > "$BELT"; }
belt_age() { local m; m=$(stat -c %Y "$BELT" 2>/dev/null) || return 1; echo $(( $(date +%s) - m )); }

# match_route RECORD_JSON ESCALATIONS: the first routes row whose match holds, as JSON, empty when none.
match_route() {
  jq -c --argjson r "$1" --argjson esc "$2" '
    def ok: ($r.attempt // 1) as $a
      | (.kind == null or .kind == $r.kind) and (.code == null or .code == $r.code) and (.code_gte == null or $r.code >= .code_gte)
        and (.attempt == null or $a == .attempt) and (.attempt_lt == null or $a < .attempt_lt)
        and (.escalations == null or $esc == .escalations) and (.escalations_lt == null or $esc < .escalations_lt);
    first(.routes[] | select(.match | ok)) // empty' "$ROUTES"
}
# escalations_before TICKET ID: escalated records the runner wrote for TICKET with an id before ID.
escalations_before() {
  grep -rl 'escalated' "$EVENTS" --include='*.json' 2>/dev/null | xargs -r jq -r --arg s "$SEAT" --arg t "$1" --arg id "$2" \
    'select(.seat == $s and .kind == "escalated" and .ticket == $t and .id < $id) | .id' 2>/dev/null | wc -l | tr -d ' '
}
# seat_of ROLE TICKET: the seat name seat.sh gives that role (roles/<role>.json label, ${ticket} lowercased), empty when unresolvable.
seat_of() {
  local label; label=$(jq -r '.label // empty' "$ROLES/$1.json" 2>/dev/null) || return 1
  label=${label//\$\{ticket\}/${2,,}}; case $label in ''|*'${'*) return 1;; esac; printf '%s' "${label,,}"
}
emit() { "$EVENT_BIN" add --seat "$SEAT" "$@" >/dev/null; }
# trouble ID TICKET TEXT: a 500 note addressed to the monitor; the monitor wakes on new events.
trouble() {
  local args=(--code 500 --kind note --to monitor --note "$(printf '%s' "$3" | cut -c1-240)")
  [ "$2" = - ] || args+=(--ticket "$2"); emit "${args[@]}" || log "could not write the 500 for $1"
}
# wake_extras ROW ID REC: for a row that says `with pr`, " pr N" and " sha S" from the record, whichever it carries; prints a reason
# and returns 1 when one is malformed. Both reach a seat's prompt as typed text, so neither is passed on unless it is a PR number or hex.
wake_extras() {
  local pr sha out=""; [ "$(jq -r '.with // empty' <<<"$1")" = pr ] || return 0
  pr=$(jq -r '.pr // empty' <<<"$3"); sha=$(jq -r '.sha // empty' <<<"$3")
  [ -z "$pr" ] || [[ $pr =~ ^[1-9][0-9]*$ ]] || { echo "record $2 has a malformed pr"; return 1; }
  [ -z "$sha" ] || [[ $sha =~ ^[0-9a-f]{7,40}$ ]] || { echo "record $2 has a malformed sha"; return 1; }
  [ -z "$pr" ] || out+=" pr $pr"; [ -z "$sha" ] || out+=" sha $sha"; printf '%s' "$out"
}
herdr_prompt() { env -u HERDR_PANE_ID -u HERDR_TAB_ID -u HERDR_WORKSPACE_ID -u HERDR_SOCKET_PATH herdr --session "$SESSION" agent prompt "$1" "$2" >/dev/null 2>&1; }

# perform ROW ID TICKET RECORD_JSON: the row's action; prints a reason and returns 1 when it fails.
perform() {
  local row=$1 id=$2 ticket=$3 rec=$4 act to seat text more rc prio qargs=()
  act=$(jq -r .do <<<"$row"); to=$(jq -r .to <<<"$row")
  case $act in
    wake|notify_owner|seat)
      seat=$(seat_of "$to" "$ticket") || { echo "no seat name for role $to on ticket $ticket"; return 1; }
      if [ "$act" = notify_owner ]; then text="record $id line $(jq -r .line <<<"$row") playbook $PLAYBOOKS/$to.md"
      else more=$(wake_extras "$row" "$id" "$rec") || { echo "$more"; return 1; }; text="record $id$more playbook $PLAYBOOKS/$to.md"; fi
      if [ "$act" = seat ]; then
        [ "$ticket" != - ] || { echo "seat needs a ticket"; return 1; }
        # seat.sh leaves a live seat as is, so it is called for every record and the table never asks whether the seat is up.
        # Its stdout is one JSON line nobody here reads; its stderr is the reason a refusal gives, last line only.
        more=$("$SEAT_BIN" --ticket "$ticket" --role "$to" 2>&1 >/dev/null); rc=$?; belt_touch
        [ "$rc" = 0 ] || { echo "seat.sh --ticket $ticket --role $to failed (exit $rc): $(tail -n 1 <<<"$more" | cut -c1-120)"; return 1; }
      fi
      herdr_prompt "$seat" "$text" || { echo "herdr agent prompt $seat failed"; return 1; } ;;
    enqueue)
      [ "$ticket" != - ] || { echo "enqueue needs a ticket"; return 1; }
      prio=$(jq -r '.priority // empty' <<<"$rec"); [[ $prio =~ ^p[0-3]$ ]] && qargs=(--priority "$prio")
      "$QUEUE_BIN" enqueue --ticket "$ticket" --from "$id" "${qargs[@]}" >/dev/null 2>&1 || { echo "queue.sh enqueue $ticket failed"; return 1; } ;;
    escalate)
      local args=(--code "$(jq -r .code <<<"$row")" --kind escalated --to "$to" --note "escalated record $id"); [ "$ticket" = - ] || args+=(--ticket "$ticket")
      emit "${args[@]}" || { echo "event.sh escalated record failed"; return 1; } ;;
    *) echo "unknown action $act"; return 1;;
  esac
}

# route_file FILE: claim, match, perform, receipt. At most once per record id.
route_file() {
  local f=$1 line id rseat ticket kind code rec row esc why to act
  rec=$(jq -c . "$f" 2>/dev/null) || { id=$(basename "$f" .json); ( set -C; echo unreadable > "$LEDGER/$id" ) 2>/dev/null && trouble "$id" - "unreadable record $id"; return; }
  line=$(jq -r '[.id, .seat, (.ticket // "-"), .kind, (.code | tostring)] | @tsv' <<<"$rec") || return
  IFS=$'\t' read -r id rseat ticket kind code <<<"$line"
  ( set -C; printf 'claimed %s\n' "$(now)" > "$LEDGER/$id" ) 2>/dev/null || return
  if [ "$rseat" = "$SEAT" ]; then echo own > "$LEDGER/$id"; return; fi
  esc=$(escalations_before "$ticket" "$id"); row=$(match_route "$rec" "${esc:-0}")
  if [ -z "$row" ]; then trouble "$id" "$ticket" "no route for $kind $code, record $id"; echo unrouted > "$LEDGER/$id"; return; fi
  # ignore: the table says this record is housekeeping. Its ledger entry is all it leaves; no receipt, so a seat coming up or
  #   going down does not write a second record for every first one (see the breadcrumb at the top, item 4).
  if [ "$(jq -r .do <<<"$row")" = ignore ]; then echo ignored > "$LEDGER/$id"; return; fi
  if why=$(perform "$row" "$id" "$ticket" "$rec"); then
    to=$(jq -r .to <<<"$row"); act=$(jq -r .do <<<"$row")
    local r=(--code 300 --kind record.routed --to "$to" --note "routed $kind $code ($id): $act $to" --evidence "${f#"$REPO"/}"); [ "$ticket" = - ] || r+=(--ticket "$ticket")
    emit "${r[@]}" || log "could not write the receipt for $id"; echo "done $act" > "$LEDGER/$id"
  else trouble "$id" "$ticket" "route failed for $kind $code, record $id: $why"; echo failed > "$LEDGER/$id"; fi
}

# recover_interrupted: a ledger entry still "claimed" at start was cut off mid-action; say so, never repeat it.
recover_interrupted() {
  local e id
  for e in "$LEDGER"/*; do [ -f "$e" ] || continue; grep -q '^claimed' "$e" || continue
    id=$(basename "$e"); trouble "$id" - "routing of record $id was interrupted; not repeated"; echo interrupted > "$e"; done
}
tick() {
  local f base boundary
  belt_touch; boundary=$(cat "$SINCE")
  while IFS= read -r f; do base=$(basename "$f" .json)
    [[ $base < $boundary ]] && continue; [ -e "$LEDGER/$base" ] && continue
    route_file "$f"
  done < <(find "$EVENTS" -path '*/20*/*.json' -name '*.json' 2>/dev/null | awk -F/ '{print $NF"\t"$0}' | sort | cut -f2-)
}
start() {
  mkdir -p "$LEDGER" || die 4 "cannot create $LEDGER"; [ -x "$EVENT_BIN" ] || die 4 "event.sh not executable: $EVENT_BIN"
  jq -e '.routes | type == "array"' "$ROUTES" >/dev/null 2>&1 || die 3 "routes file $ROUTES is not a routes table"
  if [ ! -f "$SINCE" ]; then if [ "$FROM_START" = 1 ]; then echo 00000000T000000Z > "$SINCE"; else stamp > "$SINCE"; fi; fi
  recover_interrupted
}

case $VERB in
  status) age=$(belt_age) || { echo "belt: stopped (no belt file at $BELT)"; exit 1; }
    if [ "$age" -le "$STALE" ]; then echo "belt: running (touched ${age}s ago)"; else echo "belt: stopped (last touched ${age}s ago, stale after ${STALE}s)"; exit 1; fi ;;
  once) start; tick ;;
  run) start; trap 'log "stopping"; exit 0' TERM INT; log "running: events $EVENTS, routes $ROUTES, every ${POLL}s"
    # `read -t` rather than `sleep`: bash defers a trap until the foreground command ends, so a TERM sent during a sleep waited
    #   out the whole poll interval before the runner stopped. read is interrupted by the signal and the trap runs at once.
    while true; do tick; read -r -t "$POLL" <> <(:) || true; done ;;
esac
