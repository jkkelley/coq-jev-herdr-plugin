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
#          escalate = event.sh add --kind escalated --to <role>; break-glass = seat.sh --break-glass <record's seat> --record <id>;
#          seat = seat.sh --ticket T --role R, then the wake; ignore = the ledger entry and nothing else (no receipt, no 500);
#          none = the receipt only. A record no row matches, or an action that fails, becomes a 500 note addressed to the monitor.
# Row fields besides match/do/to: with (ticket|pr|record|verify|merge-main), down (a role), when (a gate.sh predicate: head_current,
#          heads_match; a row whose predicate holds is receipted "held" and does nothing else), supersede (true: the wake line names the
#          older head gate.sh says this record replaces).
# Exit: 0 ok, 1 belt stale (status only), 2 usage, 3 validation, 4 io.
#
# BREADCRUMB 2026-10-12 - WO-20261012-3bb0, the when guard, supersede and with merge-main. What broke: three gate rules lived in the
#   architect's head (a test on a head that differs from the reviewed one only by record files counts; a head that moves re-wakes
#   the tester and drops the old run; a PR that conflicts with main goes back to its worker to merge main), so the line stopped when
#   the architect did (epic WO-20261012-187e, 13:16Z to 13:53Z on 2026-10-12). Why this shape: the rules are rows plus ONE call into
#   factory/bin/gate.sh, which owns the git and event-log reasoning (its header has the breadcrumb for the rules themselves). This
#   file still reads no kind, code or note outside matching a row: `when` and `supersede` are fields of the row, and the three
#   outcomes of gate.sh are generic (0 proceed, 1 held, other = a failure that becomes a 500). A held record writes its receipt
#   and nothing else, not even the row's `down`: a stale test.passed must not take down the tester seat, which is named per ticket and
#   is by then running the newer head. Rejected: a hold as a 500 (a stale result is expected, not trouble), a hold that still wakes
#   the merger with a "hold" word in the line (an LLM seat would have to compute what this refuses to), and gate code in this script
#   (the 38c7 cap). Cost: gate.sh is spawned for each record whose row names it, a jq pass over the event log each time, and a held
#   review.passed has no consumer record, so flow.sh notes it as a stall after stall_seconds, which is the right alarm.
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
#   4. Two actions that are not a queue or a wake, break-glass and none (WO-20261011-4562, DEC-break-glass-one-time). What broke
#      without them: the ticket asks for a route row "do:break-glass", and the lifecycle records of one break glass (100 in effect,
#      201 action done, 204 restored) matched no row, so each became a "no route" 500 to the monitor, the same noise seat.up 100
#      already makes. Why this fix: break-glass runs seat.sh with the 200 record's id and nothing else; seat.sh reads the owner's
#      answer itself and writes its own 423 when it refuses, so exit 3 is a handled refusal here, not a runner failure (a second
#      500 for the same refusal would bury it). none is the generic "seen, nothing to do" row, with no branch on any kind.
#      Rejected: a break-glass branch that reads the record's action or answer (the verdict must stay in seat.sh, where the page
#      is) and routing the three lifecycle records to the monitor (three agent wakes per grant for no decision). Cost: the
#      runner blocks for the length of one seat.sh call, a few file writes and one herdr prompt.
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
#   The down field: a row with `down: <role>` runs `seat.sh --down <that role's seat for the ticket>` after its own action. What
#   broke: a tester, reviewer or merger seat stayed up after its gate record until the architect took it down by hand, holding
#   max_seats and its treehouse slot (AGENTS.md: nothing is run by hand). Why a field and not a row of its own: a record matches
#   one row, first match wins, and the same test.passed that wakes the reviewer must also release the tester, so a second row
#   never gets its turn. The down runs after the action, and runs even when the action failed: the gate record is on disk either
#   way, the seat is finished, and a failed action is never retried (a 500 names it). Rejected: down first (a refused bring-up
#   would leave neither seat), down only on success (a failed prompt would strand a finished seat), and the next seat's seat.sh
#   doing it (it would have to know what the previous seat was). Costs: the merger is ONE shared seat named merger (roles/merger.json
#   label has no ${ticket}), so merged 200 for one ticket takes down a merger another ticket's review.passed just woke when two are in
#   flight; the label belongs to roles/, which a worker may not edit. A gate record hand-posted for a ticket whose seat never existed
#   makes seat.sh refuse ("no seat named") and that becomes a 500; the runner does not read seat records to tell the cases apart.
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
SEAT_BIN=$(cfg seat_bin); ROLES=$(cfg roles_dir); PLAYBOOKS=$(cfg playbooks_dir); STALE=$(cfg stale_seconds); GATE_BIN=$HERE/gate.sh
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
# wake_extras ROW ID REC: for a row that says `with pr` or `with merge-main`, " pr N" and " sha S" from the record, whichever it carries,
# then " merge main" for merge-main, then " supersedes ID" for a row with `supersede` when gate.sh names an older head; prints a reason
# and returns 1 when one is malformed or gate.sh fails. All of it reaches a seat's prompt as typed text, so none is passed on unless it
# is a PR number, hex, or a record id.
wake_extras() {
  local with pr sha sup out=""; with=$(jq -r '.with // empty' <<<"$1"); case $with in pr|merge-main) ;; *) return 0;; esac
  pr=$(jq -r '.pr // empty' <<<"$3"); sha=$(jq -r '.sha // empty' <<<"$3")
  [ -z "$pr" ] || [[ $pr =~ ^[1-9][0-9]*$ ]] || { echo "record $2 has a malformed pr"; return 1; }
  [ -z "$sha" ] || [[ $sha =~ ^[0-9a-f]{7,40}$ ]] || { echo "record $2 has a malformed sha"; return 1; }
  [ -z "$pr" ] || out+=" pr $pr"; [ -z "$sha" ] || out+=" sha $sha"; [ "$with" != merge-main ] || out+=" merge main"
  if [ "$(jq -r '.supersede // empty' <<<"$1")" = true ]; then
    sup=$("$GATE_BIN" supersedes --id "$2" --repo "$REPO" --events "$EVENTS" 2>&1) || { echo "gate.sh supersedes failed: $(tail -n 1 <<<"$sup" | cut -c1-120)"; return 1; }
    [ -z "$sup" ] || [[ $sup =~ ^[0-9]{8}T[0-9]{6}Z-[0-9]{3}-[a-z0-9]+$ ]] || { echo "gate.sh supersedes gave a malformed id"; return 1; }
    [ -z "$sup" ] || out+=" supersedes $sup"
  fi
  printf '%s' "$out"
}
herdr_prompt() { env -u HERDR_PANE_ID -u HERDR_TAB_ID -u HERDR_WORKSPACE_ID -u HERDR_SOCKET_PATH herdr --session "$SESSION" agent prompt "$1" "$2" >/dev/null 2>&1; }

# act_primary ROW ID TICKET RECORD_JSON: the row's own action; prints a reason and returns 1 when it fails.
act_primary() {
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
    break-glass)
      "$SEAT_BIN" --break-glass "$(jq -r .seat <<<"$rec")" --record "$id" >/dev/null 2>&1; rc=$?
      case $rc in 0|3) ;; *) echo "seat.sh --break-glass exited $rc"; return 1;; esac ;;
    none) ;;
    *) echo "unknown action $act"; return 1;;
  esac
}
# act_down ROLE TICKET: take the seat that role holds for the ticket down. seat.sh --down is idempotent (a second one prints "already
# down" and exits 0), so a second gate record for the same ticket costs nothing.
act_down() {
  local seat out rc
  [ "$2" != - ] || { echo "down needs a ticket"; return 1; }
  seat=$(seat_of "$1" "$2") || { echo "no seat name for role $1 on ticket $2"; return 1; }
  out=$("$SEAT_BIN" --down "$seat" 2>&1 >/dev/null); rc=$?; belt_touch
  [ "$rc" = 0 ] || { echo "seat.sh --down $seat failed (exit $rc): $(tail -n 1 <<<"$out" | cut -c1-120)"; return 1; }
}
# perform ROW ID TICKET RECORD_JSON: the row's action, then its down when it has one, the down even when the action failed (the
# gate record is on disk either way, so the seat is finished); prints every reason, joined, and returns 1 when either failed.
perform() {
  local row=$1 id=$2 ticket=$3 rec=$4 down why="" more
  more=$(act_primary "$row" "$id" "$ticket" "$rec") || why=$more
  down=$(jq -r '.down // empty' <<<"$row")
  if [ -n "$down" ]; then more=$(act_down "$down" "$ticket") || why=${why:+$why; }$more; fi
  [ -z "$why" ] || { echo "$why"; return 1; }
}

# route_file FILE: claim, match, perform, receipt. At most once per record id.
route_file() {
  local f=$1 line id rseat ticket kind code rec row esc why to act down when grc r
  rec=$(jq -c . "$f" 2>/dev/null) || { id=$(basename "$f" .json); ( set -C; echo unreadable > "$LEDGER/$id" ) 2>/dev/null && trouble "$id" - "unreadable record $id"; return; }
  line=$(jq -r '[.id, .seat, (.ticket // "-"), .kind, (.code | tostring)] | @tsv' <<<"$rec") || return
  IFS=$'\t' read -r id rseat ticket kind code <<<"$line"
  ( set -C; printf 'claimed %s\n' "$(now)" > "$LEDGER/$id" ) 2>/dev/null || return
  if [ "$rseat" = "$SEAT" ]; then echo own > "$LEDGER/$id"; return; fi
  esc=$(escalations_before "$ticket" "$id"); row=$(match_route "$rec" "${esc:-0}")
  if [ -z "$row" ]; then trouble "$id" "$ticket" "no route for $kind $code, record $id"; echo unrouted > "$LEDGER/$id"; return; fi
  # ignore: the table says this record is housekeeping. Its ledger entry is all it leaves; no receipt, so a seat coming up or
  #   going down does not write a second record for every first one (see the ignore breadcrumb at the top).
  if [ "$(jq -r .do <<<"$row")" = ignore ]; then echo ignored > "$LEDGER/$id"; return; fi
  # when: a gate.sh predicate. 0 proceeds; 1 holds this record (a receipt that says why, no action, no down, no 500); anything else is a failure.
  when=$(jq -r '.when // empty' <<<"$row")
  if [ -n "$when" ]; then
    why=$("$GATE_BIN" when "$when" --id "$id" --repo "$REPO" --events "$EVENTS" 2>&1); grc=$?
    case $grc in
      0) ;;
      1) to=$(jq -r .to <<<"$row"); r=(--code 300 --kind record.routed --to "$to" --note "$(printf 'held %s %s (%s): %s' "$kind" "$code" "$id" "$why" | cut -c1-240)" --evidence "${f#"$REPO"/}")
         [ "$ticket" = - ] || r+=(--ticket "$ticket"); emit "${r[@]}" || log "could not write the receipt for $id"; echo "held $when" > "$LEDGER/$id"; return ;;
      *) trouble "$id" "$ticket" "route failed for $kind $code, record $id: gate.sh when $when failed (exit $grc): $(tail -n 1 <<<"$why" | cut -c1-100)"; echo failed > "$LEDGER/$id"; return ;;
    esac
  fi
  if why=$(perform "$row" "$id" "$ticket" "$rec"); then
    to=$(jq -r .to <<<"$row"); act=$(jq -r .do <<<"$row"); down=$(jq -r '.down // empty' <<<"$row")
    local r=(--code 300 --kind record.routed --to "$to" --note "routed $kind $code ($id): $act $to${down:+, down $down}" --evidence "${f#"$REPO"/}"); [ "$ticket" = - ] || r+=(--ticket "$ticket")
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
  # BREADCRUMB 2026-10-12 - WO-20261011-4db1. What broke: this test was `-le`, so a belt exactly stale_seconds old read
  #   "running", while the header of this file (line 9) and AC-H6 of WO-20261011-38c7 say running means FRESHER than
  #   stale_seconds. Found when factory case 06-belt failed on 49ab55b (record 20261012T132330Z-422-hyds1): a belt backdated
  #   61 s read "running (touched 60s ago)" after the host clock stepped back about a second (see the breadcrumb in
  #   factory/tests/cases/06-belt.test.sh). Why this fix: `-lt` makes the comparison say what the contract says, and the
  #   case now pins 59, 60 and 61 with a fixed `date +%s`. Rejected: leaving `-le` and only widening the test margin, which
  #   keeps a one second contradiction between code and contract. Cost: a belt touched exactly stale_seconds ago now reads
  #   stopped, one second sooner than before; flow.sh takes its belt verdict from this exit code and moves with it (the board
  #   in report/loop reads the file age itself against belt_max_age_seconds and does not).
  status) age=$(belt_age) || { echo "belt: stopped (no belt file at $BELT)"; exit 1; }
    if [ "$age" -lt "$STALE" ]; then echo "belt: running (touched ${age}s ago)"; else echo "belt: stopped (last touched ${age}s ago, stale after ${STALE}s)"; exit 1; fi ;;
  once) start; tick ;;
  run) start; trap 'log "stopping"; exit 0' TERM INT; log "running: events $EVENTS, routes $ROUTES, every ${POLL}s"
    # `read -t` rather than `sleep`: bash defers a trap until the foreground command ends, so a TERM sent during a sleep waited
    #   out the whole poll interval before the runner stopped. read is interrupted by the signal and the trap runs at once.
    while true; do tick; read -r -t "$POLL" <> <(:) || true; done ;;
esac
