#!/usr/bin/env bash
# board.sh - the board: the single intake of the line (SPEC-17 s-board, s-lanes; roadmap item K1).
# A directory of items in the state root, one file per item, one subdirectory per lane. Post is a write, pull is a lease field with a
# deadline, done is a move into the done tree. No lock: distinct file names and atomic mv, the contract of queue/bin/queue.sh.
# A seat learns of work by pulling its lane and by nothing else; the nudge carries a lane and a count, never a record's content.
#
#   board.sh post    --id RECORD-ID --lane L --kind K --code NNN [--ticket WO-ID] [--priority p0..p3] [--due ISO] [--attempt N]
#                    --record FILE reads id, kind, code and ticket from a record; a flag beside it wins
#   board.sh pull    --lane L --holder SEAT [--json]   leases the oldest item of the highest priority, prints its id (or the item)
#   board.sh renew   --id ID --holder SEAT             pushes the lease deadline out by lease_seconds
#   board.sh done    --id ID --result RECORD-ID [--by SEAT]   moves the item to the done tree, stamped with the result record
#   board.sh release --id ID --holder SEAT             back to open, attempt unchanged
#   board.sh sweep                                     expired leases back to open (the third expiry of one item is printed as a finding);
#                                                      done items older than retention_days are pruned
#   board.sh list    [--lane L] [--json]               open and leased items, p0 first, oldest first
#   board.sh digest  --lane L                          the open items of a lane grouped by ticket, oldest first, as one text block
#   board.sh nudge   --lane L --seat SEAT              sends "board: N items in lane L, pull" unless one went within the interval
#   board.sh health                                    writes and prints the health line (per lane open, leased, oldest age, stalls;
#                                                      running, draining or halted; counters)
#   board.sh check                                     the config, and every item's name against its content
# BOARD_CONFIG=<path> points at another config (tests). Exit: 0 ok, 2 usage, 3 validation, 4 io, 6 nothing to pull.
#
# The nudge verb is the rate limiter and the sender; WHEN to call it (the seat is idle, the lane has open items) is the health watch,
# roadmap item K2. A busy seat is never nudged: that check is K2's, because only it reads the seat's screen.
#
# BREADCRUMB 2026-10-13 - WO-20261013-f268 (Roadmap K1). What broke: records reached seats through watches, copies and prompts that carry
#   content (route.sh wakes "record <id> playbook <path>"), which flooded the architect on 2026-10-12 and replayed stale after its
#   compaction (SPEC-17 s-inventory H23). Why this fix: one board every record lands on and every seat pulls from, built on queue.sh's
#   own mechanics so there is one contract to learn.
#   Choices that look arbitrary:
#   1. Every mutation claims the item first by renaming it to <name>.claim.<epoch>.<pid> and puts it back when done. queue.sh rewrites
#      in place with no claim, so two concurrent pulls can both lease one item and a sweep can resurrect an item the holder just moved
#      to the done tree. rename(2) is atomic, so exactly one caller wins; the loser sees the item gone. Cost: for a few milliseconds the
#      item is in no list; a crash inside that window leaves a .claim file, which sweep restores after lease_seconds and check reports.
#   2. An item that expires counts in `expiries`, a field beside `attempt`. attempt is the record's own attempt number as the router
#      passed it and release leaves it unchanged (s-lanes), so it cannot also be the expiry counter.
#   3. Keys beyond the ticket's list: board_dir, done_dir, nudge_dir, halt_flag, drain_flag, digest_lanes. Each is a path or a name the
#      spec uses and a script may not carry as a literal (DEC-no-hardcode-config-s3). The halt and drain flag paths are only READ here
#      (health prints the state); the commands that write them are roadmap item K4, which can move the keys without touching this file.
#   4. The nudge rate limit is one stamp file per seat and lane, claimed by rename like an item, so fifty callers at once send one prompt.
#      A failed prompt puts the old stamp back, so the next call retries at once instead of waiting a whole interval.
#   5. A keyed lane such as worker-<seat> (s-lanes) is not built: lanes are the config's list, exactly. The router (K7) decides the key.
#   Not done: items_dir of queue/config/queue.json does not move under the state root. queue.sh substitutes only ${repo}, so the move needs
#   a one-line change in queue/bin/queue.sh, a file this ticket does not declare, and gate.sh pr-files refuses a diff that strays. Left
#   as it was rather than point queue.sh at a directory literally named ${state}; the ticket's note names the follow-up.
set -euo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd); ROOT=$(cd "$HERE/.." && pwd); REPO=$(cd "$ROOT/.." && pwd)
die() { local c=$1; shift; printf 'board: %s\n' "$*" >&2; exit "$c"; }
command -v jq >/dev/null || die 4 "jq required"
CFG=${BOARD_CONFIG:-$ROOT/config/board.json}; SCHEMA=$ROOT/config/board.schema.json
[ -f "$CFG" ] || die 4 "config $CFG missing"; [ -f "$SCHEMA" ] || die 4 "schema $SCHEMA missing"

# ---- config: validated on every verb, so a missing key or a literal path is exit 3 naming the key (T14) ----
validate_config() {
  local k want got v
  jq -e . "$CFG" >/dev/null 2>&1 || die 3 "config $CFG is not JSON"
  while IFS= read -r k; do jq -e --arg k "$k" 'has($k)' "$CFG" >/dev/null || die 3 "config key $k missing"; done < <(jq -r '.required[]' "$SCHEMA")
  while IFS= read -r k; do jq -e --arg k "$k" '.properties | has($k)' "$SCHEMA" >/dev/null || die 3 "config key $k is not in the schema"; done < <(jq -r 'keys[]' "$CFG")
  while IFS=$'\t' read -r k want; do
    got=$(jq -r --arg k "$k" '.[$k] | type' "$CFG"); [ "$want" != integer ] || want=number
    [ "$got" = "$want" ] || die 3 "config key $k must be $want, is $got"
  done < <(jq -r '.properties | to_entries[] | select(.value.type != null) | [.key, .value.type] | @tsv' "$SCHEMA")
  [ "$(jq -r '.schema_version' "$CFG")" = "$(jq -r '.properties.schema_version.const' "$SCHEMA")" ] || die 3 "config key schema_version differs from the schema's"
  while IFS= read -r k; do   # a path key begins with a variable
    v=$(jq -r --arg k "$k" '.[$k]' "$CFG"); [[ $v == '${'* ]] || die 3 "config key $k holds a literal path: $v"
  done < <(jq -r '.properties | to_entries[] | select(.value["x-path"] == true) | .key' "$SCHEMA")
  while IFS= read -r k; do   # and no other string is a path at all
    die 3 "config key $k holds a literal path"
  done < <(jq -r 'to_entries[] | select((.value | type) == "string" and (.value | test("^(/|~|[A-Za-z]:[\\\\/])"))
    or (.value | type) == "array" and any(.value[]; type == "string" and test("^(/|~|[A-Za-z]:[\\\\/])"))) | .key' "$CFG")
  jq -e '.default_priority as $d | .priorities | index($d) != null' "$CFG" >/dev/null || die 3 "config key default_priority is not in priorities"
  jq -e '.lanes as $l | .digest_lanes | all(. as $x | $l | index($x) != null)' "$CFG" >/dev/null || die 3 "config key digest_lanes names a lane that is not in lanes"
}
validate_config
cfg() { jq -r --arg k "$1" '.[$k]' "$CFG"; }
# shellcheck source=../../bin/state-root.sh
. "$REPO/bin/state-root.sh" 2>/dev/null || die 4 "bin/state-root.sh missing (roadmap item A1)"
STATE=$(coq_state_root) || die 3 "the state root cannot be resolved"
sub() { local v=$1; v=${v//'${state}'/$STATE}; v=${v//'${repo}'/$REPO}; v=${v//'${state_root}'/${STATE_ROOT:-}}; v=${v//'${board_dir}'/${BOARD:-}}; printf '%s' "$v"; }
path() { local v; v=$(sub "$(cfg "$1")"); [[ $v != *'${'* ]] || die 3 "config key $1 uses an unknown variable: $v"; printf '%s' "$v"; }
STATE_ROOT=$(path state_root); BOARD=$(path board_dir); DONE=$(path done_dir); HEALTH=$(path health_file); NUDGE=$(path nudge_dir)
HALT=$(path halt_flag); DRAIN=$(path drain_flag)
LEASE=$(cfg lease_seconds); NUDGE_S=$(cfg nudge_seconds); DIGEST_S=$(cfg digest_seconds); RETAIN=$(cfg retention_days); DEF=$(cfg default_priority)
mapfile -t LANES < <(jq -r '.lanes[]' "$CFG")

now() { date -u +%Y-%m-%dT%H:%M:%SZ; }
epoch() { date -u +%s; }
ID_RE='^[0-9]{8}T[0-9]{6}Z-[0-9]{3}-[a-z0-9]{5}$'
vid() { [[ $1 =~ $ID_RE ]] || die 3 "bad record id '$1' (want 20261013T032423Z-100-ab12c)"; }
is_lane() { [[ " ${LANES[*]} " == *" $1 "* ]]; }   # not printf | grep -q: under pipefail an early grep exit can fail the pipe
vlane() { [ -n "$1" ] || die 3 "a record without a lane is refused"; is_lane "$1" || die 3 "lane $1 is not in the config's lanes"; }
vprio() { jq -e --arg p "$1" '.priorities | index($p) != null' "$CFG" >/dev/null || die 3 "priority $1 is not in the config's priorities"; }
lane_files() { [ -d "$BOARD/$1" ] && find "$BOARD/$1" -maxdepth 1 -name 'p[0-3]-*.json' | LC_ALL=C sort || true; }
item_of() { local l p; for l in "${LANES[@]}"; do for p in p0 p1 p2 p3; do [ -f "$BOARD/$l/$p-$1.json" ] && { printf '%s' "$BOARD/$l/$p-$1.json"; return; }; done; done; true; }
items_json() { lane_files "$1" | xargs -r -d '\n' cat | jq -s '.'; }
# claim FILE: atomic rename, exactly one caller wins; prints the claimed path. Put it back with unclaim, or replace it with put.
claim() { local c; c="$1.claim.$(epoch).$$"; mv -- "$1" "$c" 2>/dev/null && printf '%s' "$c"; }
unclaim() { mv -- "$1" "${1%.claim.*}"; }
put() { local c=$1; shift; jq "$@" "$c" > "$c.tmp" && mv -- "$c.tmp" "${c%.claim.*}" && rm -f -- "$c"; }
deadline() { date -u -d "+$LEASE seconds" +%Y-%m-%dT%H:%M:%SZ; }
herdr_prompt() {
  local s=${COQ_HERDR_SESSION:-${HERDR_SESSION:-}}
  if [ -n "$s" ]; then env -u HERDR_PANE_ID -u HERDR_TAB_ID -u HERDR_WORKSPACE_ID -u HERDR_SOCKET_PATH herdr --session "$s" agent prompt "$1" "$2" >/dev/null 2>&1
  else herdr agent prompt "$1" "$2" >/dev/null 2>&1; fi
}

VERB=${1:-}; shift || true
case $VERB in
  post)
    id=""; lane=""; kind=""; code=""; ticket=""; prio=$DEF; due=""; att=1; rec=""
    while [ $# -gt 0 ]; do case $1 in
      --record) rec=$2; shift 2;; --id) id=$2; shift 2;; --lane) lane=$2; shift 2;; --kind) kind=$2; shift 2;; --code) code=$2; shift 2;;
      --ticket) ticket=$2; shift 2;; --priority) prio=$2; shift 2;; --due) due=$2; shift 2;; --attempt) att=$2; shift 2;; *) die 2 "unknown flag $1";; esac; done
    if [ -n "$rec" ]; then
      [ -f "$rec" ] && jq -e . "$rec" >/dev/null 2>&1 || die 4 "record $rec is missing or not JSON"
      [ -n "$id" ] || id=$(jq -r '.id // empty' "$rec"); [ -n "$kind" ] || kind=$(jq -r '.kind // empty' "$rec")
      [ -n "$code" ] || code=$(jq -r '.code // empty' "$rec"); [ -n "$ticket" ] || ticket=$(jq -r '.ticket // empty' "$rec")
    fi
    [ -n "$id" ] || die 2 "--id (or --record) required"; vid "$id"; vlane "$lane"; vprio "$prio"
    [ -n "$kind" ] || die 3 "--kind required"; [[ $code =~ ^[1-5][0-9]{2}$ ]] || die 3 "--code must be 100 to 599, got '$code'"
    [ -z "$ticket" ] || [[ $ticket =~ ^WO-[0-9]{8}-[0-9a-f]{4}$ ]] || die 3 "bad ticket id $ticket"
    [ -z "$due" ] || [[ $due =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]] || die 3 "--due must be ISO 8601 UTC with a Z suffix, got $due"
    [[ $att =~ ^[1-9][0-9]*$ ]] || die 3 "--attempt must be a positive integer, got $att"
    [ -z "$(item_of "$id")" ] && [ -z "$(find "$DONE" -name "*-${id,,}.json" 2>/dev/null | head -1)" ] || die 3 "$id is already on the board"
    mkdir -p "$BOARD/$lane"; f="$BOARD/$lane/$prio-$id.json"
    jq -n --arg id "$id" --arg kind "$kind" --argjson code "$code" --arg ticket "$ticket" --arg lane "$lane" --arg p "$prio" --arg at "$(now)" --arg due "$due" --argjson att "$att" \
      '{schema_version:"1.0.0", id:$id, kind:$kind, code:$code, ticket:(if $ticket=="" then null else $ticket end), lane:$lane, priority:$p, posted_at:$at,
        due_at:(if $due=="" then null else $due end), attempt:$att, expiries:0, lease:null, done:null}' > "$f.tmp" && mv -- "$f.tmp" "$f"
    printf '%s\n' "$id" ;;
  pull)
    lane=""; holder=""; json=0
    while [ $# -gt 0 ]; do case $1 in --lane) lane=$2; shift 2;; --holder) holder=$2; shift 2;; --json) json=1; shift;; *) die 2 "unknown flag $1";; esac; done
    [ -n "$holder" ] || die 2 "--holder required"; vlane "$lane"
    while IFS= read -r f; do   # p0 before p1, older first within a priority
      [ -n "$f" ] || continue; [ "$(jq -r '.lease // empty' "$f" 2>/dev/null)" = "" ] || continue
      c=$(claim "$f") || continue   # another puller took it between the list and now
      if [ -n "$(jq -r '.lease // empty' "$c")" ]; then unclaim "$c"; continue; fi
      put "$c" --arg h "$holder" --arg at "$(now)" --arg d "$(deadline)" '.lease={holder:$h, acquired:$at, deadline:$d}'
      if [ "$json" = 1 ]; then jq . "${c%.claim.*}"; else basename "${c%.claim.*}" .json | sed 's/^p[0-3]-//'; fi; exit 0
    done < <(lane_files "$lane"); exit 6 ;;
  renew|release)
    id=""; h=""; while [ $# -gt 0 ]; do case $1 in --id) id=$2; shift 2;; --holder) h=$2; shift 2;; *) die 2 "unknown flag $1";; esac; done
    vid "$id"; [ -n "$h" ] || die 2 "--holder required"; f=$(item_of "$id"); [ -n "$f" ] || die 6 "$id is not on the board"
    c=$(claim "$f") || die 6 "$id is not on the board"
    if [ "$(jq -r '.lease.holder // empty' "$c")" != "$h" ]; then unclaim "$c"; die 3 "$id is not leased by $h"; fi
    if [ "$VERB" = renew ]; then put "$c" --arg d "$(deadline)" '.lease.deadline=$d'; else put "$c" '.lease=null'; fi ;;
  done)
    id=""; res=""; by=""; while [ $# -gt 0 ]; do case $1 in --id) id=$2; shift 2;; --result) res=$2; shift 2;; --by) by=$2; shift 2;; *) die 2 "unknown flag $1";; esac; done
    vid "$id"; [ -n "$res" ] || die 2 "--result required"; vid "$res"; f=$(item_of "$id"); [ -n "$f" ] || die 6 "$id is not on the board"
    c=$(claim "$f") || die 6 "$id is not on the board"
    h=$(jq -r '.lease.holder // empty' "$c")
    if [ -n "$h" ] && [ -n "$by" ] && [ "$by" != "$h" ]; then unclaim "$c"; die 3 "$id is leased by $h, not $by"; fi
    d="$DONE/$(date -u +%Y)/$(date -u +%m)"; mkdir -p "$d"; out="$d/$(date -u +%Y%m%d%H%M%S)-${id,,}.json"
    jq --arg at "$(now)" --arg by "${by:-$h}" --arg r "$res" '.done={at:$at, by:(if $by=="" then null else $by end), result:$r}' "$c" > "$out.tmp" && mv -- "$out.tmp" "$out" && rm -f -- "$c"
    printf '%s\n' "$out" ;;
  sweep)
    n=$(now); lim=$(( $(epoch) - LEASE ))
    for l in "${LANES[@]}"; do
      [ -d "$BOARD/$l" ] || continue
      while IFS= read -r c; do [ -n "$c" ] || continue   # a claim a crashed caller left behind
        at=${c#*.claim.}; at=${at%%.*}; if [[ $at =~ ^[0-9]+$ ]] && [ "$at" -lt "$lim" ]; then
          if [ -e "${c%.claim.*}" ]; then rm -f -- "$c"; printf 'dropped stale claim %s: the item is back on the board\n' "$(basename "$c")"   # never overwrite a live item
          else unclaim "$c"; printf 'restored stale claim %s\n' "$(basename "${c%.claim.*}" .json | sed 's/^p[0-3]-//')"; fi
        fi
      done < <(find "$BOARD/$l" -maxdepth 1 -name 'p[0-3]-*.json.claim.*' -not -name '*.tmp')
      while IFS= read -r f; do [ -n "$f" ] || continue
        d=$(jq -r '.lease.deadline // empty' "$f" 2>/dev/null || true); { [ -n "$d" ] && [[ "$d" < "$n" ]]; } || continue
        c=$(claim "$f") || continue
        put "$c" '.lease=null | .expiries += 1'; ex=$(jq -r .expiries "${c%.claim.*}")
        printf 'released expired lease %s lane %s expiry %s\n' "$(jq -r .id "${c%.claim.*}")" "$l" "$ex"
        [ "$ex" -lt 3 ] || printf 'finding lease-expired-%s %s lane %s\n' "$ex" "$(jq -r .id "${c%.claim.*}")" "$l"
      done < <(lane_files "$l")
    done
    if [ -d "$DONE" ]; then p=$(find "$DONE" -name '*.json' -mtime "+$RETAIN" -print -delete | wc -l); [ "$p" = 0 ] || printf 'pruned %s done items\n' "$p"; fi; true ;;
  list)
    lane=""; json=0; while [ $# -gt 0 ]; do case $1 in --lane) lane=$2; shift 2;; --json) json=1; shift;; *) die 2 "unknown flag $1";; esac; done
    [ -z "$lane" ] || vlane "$lane"; ls_=("${LANES[@]}"); [ -z "$lane" ] || ls_=("$lane")
    all='[]'; for l in "${ls_[@]}"; do all=$(jq -c --argjson a "$(items_json "$l")" '. + $a' <<<"$all"); done
    if [ "$json" = 1 ]; then jq . <<<"$all"; else jq -r '.[] | [.priority, .lane, .id, (.ticket // "-"), .posted_at, (.lease.holder // "-"), (.lease.deadline // "-")] | @tsv' <<<"$all"; fi ;;
  digest)
    lane=""; while [ $# -gt 0 ]; do case $1 in --lane) lane=$2; shift 2;; *) die 2 "unknown flag $1";; esac; done; vlane "$lane"
    items_json "$lane" | jq -r --arg lane "$lane" '[.[] | select(.lease == null)] | sort_by(.posted_at, .id) as $s
      | "board digest lane \($lane): \($s | length) open",
        ($s | group_by(.ticket // "no ticket") | sort_by(.[0].posted_at, .[0].id)[]
         | "\(.[0].ticket // "no ticket") (\(length))", (.[] | "  \(.id) \(.kind) \(.code) \(.priority) posted \(.posted_at) due \(.due_at // "-")"))' ;;
  nudge)
    lane=""; seat=""; while [ $# -gt 0 ]; do case $1 in --lane) lane=$2; shift 2;; --seat) seat=$2; shift 2;; *) die 2 "unknown flag $1";; esac; done
    vlane "$lane"; [[ $seat =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || die 2 "--seat required (letters, digits, . _ -)"
    open=$(items_json "$lane" | jq '[.[] | select(.lease == null)] | length'); [ "$open" -gt 0 ] || exit 6
    interval=$NUDGE_S; jq -e --arg l "$lane" '.digest_lanes | index($l) != null' "$CFG" >/dev/null && interval=$DIGEST_S   # the architect hears a digest, not a nudge per minute
    mkdir -p "$NUDGE"; stamp="$NUDGE/$seat.$lane"; last=0
    if [ -f "$stamp" ]; then
      c=$(claim "$stamp") || { echo "suppressed: another nudge to $seat is in flight"; exit 0; }
      last=$(cat "$c" 2>/dev/null || echo 0); [[ $last =~ ^[0-9]+$ ]] || last=0
      if [ $(( $(epoch) - last )) -lt "$interval" ]; then mv -- "$c" "$stamp"; echo "suppressed: $seat was nudged $(( $(epoch) - last ))s ago, interval ${interval}s"; exit 0; fi
    else
      # no stamp is either a first nudge or a stamp another caller holds for a moment: a claim file says which
      compgen -G "$stamp.claim.*" >/dev/null && { echo "suppressed: another nudge to $seat is in flight"; exit 0; }
      # ln, not a redirect with noclobber: a redirect creates the file empty before it writes, and a second caller reading it in that
      # moment would take the empty stamp for "never nudged". ln links a finished file and fails when the stamp already exists.
      c=""; epoch > "$stamp.$$.tmp"; if ln -- "$stamp.$$.tmp" "$stamp" 2>/dev/null; then rm -f -- "$stamp.$$.tmp"; else rm -f -- "$stamp.$$.tmp"; echo "suppressed: another nudge to $seat is in flight"; exit 0; fi
    fi
    txt="board: $open item$([ "$open" = 1 ] || echo s) in lane $lane, pull"
    if herdr_prompt "$seat" "$txt"; then
      epoch > "$stamp.tmp" && mv -- "$stamp.tmp" "$stamp"; [ -z "$c" ] || rm -f -- "$c"; echo "nudged $seat: $txt"
    else
      if [ -n "$c" ]; then mv -- "$c" "$stamp"; else rm -f -- "$stamp"; fi
      die 4 "herdr agent prompt $seat failed"
    fi ;;
  health)
    ep=$(epoch); lanes_obj='{}'
    for l in "${LANES[@]}"; do
      lanes_obj=$(jq -c --arg l "$l" --argjson items "$(items_json "$l")" --argjson now "$ep" '. + {($l): ($items | {
        open: (map(select(.lease == null)) | length), leased: (map(select(.lease != null)) | length),
        oldest_age_seconds: ((map(select(.lease == null) | .posted_at | fromdateiso8601) | min) as $m | if $m == null then null else $now - $m end),
        stalls: (map(select(.expiries >= 3 or (.due_at != null and (.due_at | fromdateiso8601) < $now))) | length)})}' <<<"$lanes_obj")
    done
    st=running; [ ! -e "$DRAIN" ] || st=draining; [ ! -e "$HALT" ] || st=halted   # halt wins over drain
    dn=0; [ ! -d "$DONE" ] || dn=$(find "$DONE" -name '*.json' | wc -l)   # find on a missing tree fails the pipe under pipefail
    mkdir -p "$(dirname "$HEALTH")"
    jq -nc --arg at "$(now)" --arg st "$st" --argjson lanes "$lanes_obj" --argjson dn "$dn" \
      '{schema_version:"1.0.0", at:$at, state:$st, lanes:$lanes, counters:{open:([$lanes[].open]|add), leased:([$lanes[].leased]|add), stalls:([$lanes[].stalls]|add), done:$dn}}' > "$HEALTH.tmp" \
      && mv -- "$HEALTH.tmp" "$HEALTH" && cat "$HEALTH" ;;
  check)
    bad=0; n=0
    for l in "${LANES[@]}"; do
      [ -d "$BOARD/$l" ] || continue
      while IFS= read -r f; do [ -n "$f" ] || continue; n=$((n + 1))
        b=$(basename "$f" .json); p=${b%%-*}; id=${b#*-}
        if ! jq -e . "$f" >/dev/null 2>&1; then echo "not JSON: $f" >&2; bad=1; continue; fi
        [ "$(jq -r .id "$f")" = "$id" ] && [ "$(jq -r .priority "$f")" = "$p" ] && [ "$(jq -r .lane "$f")" = "$l" ] || { echo "name/content mismatch: $f" >&2; bad=1; }
        [[ $id =~ $ID_RE ]] || { echo "item id is not a record id: $f" >&2; bad=1; }
      done < <(lane_files "$l")
      while IFS= read -r c; do [ -z "$c" ] || { echo "claim left behind: $c" >&2; bad=1; }; done < <(find "$BOARD/$l" -maxdepth 1 -name 'p[0-3]-*.json.claim.*' -not -name '*.tmp')
    done
    if [ -d "$BOARD" ]; then
      while IFS= read -r d; do is_lane "$(basename "$d")" || [ "$d" = "$DONE" ] || [ "$d" = "$NUDGE" ] || { echo "directory is not a lane: $d" >&2; bad=1; }; done < <(find "$BOARD" -mindepth 1 -maxdepth 1 -type d)
    fi
    [ "$bad" = 0 ] && echo "board ok: $n items" || exit 3 ;;
  *) sed -n '2,24p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2 ;;
esac
