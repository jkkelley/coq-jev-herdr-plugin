#!/usr/bin/env bash
# bus.sh - the record bus (WO-20261012-da52). A seat writes its records into its own treehouse slot's events/, and route.sh
# watches only the checkout's, so a gate record sat unrouted until the architect copied it by hand. This copies every new record
# of every slot into the checkout's events/, byte for byte, once, so the belt routes it.
#
#   bus.sh once  [flags]     one tick: copy every new slot record into the checkout, exit
#   bus.sh run   [flags]     ticks forever, every poll_seconds; run it in a labelled herdr pane, never as a background job
#   bus.sh slots [flags]     print the slot paths treehouse lists, one per line; exit 4 when treehouse cannot be read
# Flags: --config FILE (default factory/config/bus.json)   --repo DIR (what ${repo} means; treehouse runs there)   --state DIR
# Slots come from `treehouse status --json` run in the repo, never from a typed path, so a pool that grows or moves needs no edit.
# Exit: 0 ok, 2 usage, 3 validation, 4 io.
#
# BREADCRUMB 2026-10-12 - WO-20261012-da52. What broke: event.sh writes into the events/ of the tree it lives in, so a seat in
#   a slot wrote its gate records to <slot>/events/ while route.sh reads only <checkout>/events/ (route.sh line 85, REPO from
#   --repo); every hand-off waited for the architect to copy the file, and from 13:16Z to 13:53Z on 2026-10-12 the line sat
#   idle while the architect was down. An interim loop ran from a script in the user cache directory in monitor slot 2.3.3 with a
#   hard-coded slot base, a hard-coded checkout and a held list kept outside the repo; this file replaces it and the loop is gone
#   (AC-H2: nothing under herdr/ or factory/ names a path in the user cache directory, and case 12 greps for it).
#   Why this shape: (1) a copied ledger under state/copied/<id>, claimed after the copy, is what makes "once" true. The interim
#   skipped a record already in the checkout, so a record the architect moved out of a records commit (a pr/sha field the
#   checkout lint refused) came straight back on the next tick, which is why it needed a hand-made held list. A ledger entry says
#   "copied once, ever", so a record removed on purpose stays removed and nothing outside the repo holds the list. A kill between
#   the copy and the claim is repaired by the next tick: the checkout already holds the identical file, so it is claimed
#   without a second copy. (2) the copy goes to <name>.tmp and is renamed, so the runner, which reads *.json, never sees half a
#   record; event.sh does the same. A slot file that does not parse is left for the next tick, because it may be mid-write on
#   a filesystem that shows the file before its bytes. (3) the first start copies nothing older than lookback_seconds: a slot's
#   events/ also holds every committed record of its branch, and the whole history is not new. Later starts keep the first
#   boundary, so a restart loses nothing a seat wrote while the bus was down. (4) poll_seconds is capped at 5 by the schema
#   because the ticket promises ten seconds.
#   Rejected: a file watcher (inotify is not in the test image and a pool slot can appear at any time, so the poll has to
#   re-list the slots anyway); git to tell new from committed (a record committed in the slot and merged is the same bytes, and
#   asking git makes a copy depend on a commit race). A differing file of the same name is never overwritten: the id carries
#   a random suffix, so a clash is a fault to read, and it is logged and claimed so it is not logged every tick.
#   Cost: a record a seat commits and merges through its PR also arrives here untracked, so a `git pull` on the checkout can
#   refuse until the architect's records commit takes it (the same hazard the interim loop had); and a restart of the whole
#   pool after more than lookback_seconds of bus downtime leaves the oldest records for a hand copy.
set -uo pipefail
export LC_ALL=C
HERE=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd); FACTORY=$(cd "$HERE/.." && pwd)
REPO=$(cd "$FACTORY/.." && pwd); CONFIG=$FACTORY/config/bus.json; STATE=""
die() { local c=$1; shift; printf 'bus: %s\n' "$*" >&2; exit "$c"; }
log() { printf '%s bus: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" >&2; }
command -v jq >/dev/null || die 4 "jq is required"
VERB=${1:-}; shift || true
while [ $# -gt 0 ]; do case $1 in
  --config) CONFIG=${2:?}; shift 2;; --repo) REPO=$(cd "${2:?}" && pwd) || die 4 "no such --repo"; shift 2;;
  --state) STATE=${2:?}; shift 2;; *) die 2 "unknown flag $1";; esac; done
case $VERB in once|run|slots) ;; *) sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2;; esac

[ -f "$CONFIG" ] || die 4 "config $CONFIG missing"
cfg() { local v; v=$(jq -r --arg k "$1" '.[$k] // empty' "$CONFIG") || die 3 "config $CONFIG is not JSON"; [ -n "$v" ] || die 3 "config key $1 missing"; printf '%s' "${v//\$\{repo\}/$REPO}"; }
POLL=$(cfg poll_seconds); LOOKBACK=$(cfg lookback_seconds); EVENTS=$(cfg events_dir); SUB=$(cfg slot_events_subdir)
[ -n "$STATE" ] || STATE=$(cfg state_dir)
SINCE=$STATE/since; COPIED=$STATE/copied

stamp() { date -u -d "-$LOOKBACK seconds" +%Y%m%dT%H%M%SZ; }
slots() { # the pool's slot paths; status 1 when treehouse cannot be read or answers something that is not the slot list
  local out; command -v treehouse >/dev/null 2>&1 || return 1
  out=$(cd "$REPO" && treehouse status --json 2>/dev/null) || return 1
  jq -r '.[].path // empty' <<<"$out" 2>/dev/null || return 1
}
# claim FILE: create it, or fail when it exists; the ledger is one empty file per record id.
claim() { ( set -C; : > "$1" ) 2>/dev/null; }
copy_one() { # SLOT_EVENTS FILE; prints the copied line
  local base=$1 f=$2 rel name id dst
  name=${f##*/}; id=${name%.json}; rel=${f#"$base"/}; dst=$EVENTS/$rel
  [[ "$name" > "$(cat "$SINCE")" ]] || return 0
  [ ! -e "$COPIED/$id" ] || return 0
  jq -e .id "$f" >/dev/null 2>&1 || return 0
  if [ -e "$dst" ]; then
    cmp -s "$f" "$dst" || log "$dst exists and differs from $f; left alone"
    claim "$COPIED/$id"; return 0
  fi
  mkdir -p "${dst%/*}" && cp "$f" "$dst.tmp" && mv "$dst.tmp" "$dst" || { rm -f "$dst.tmp"; log "could not copy $f to $dst"; return 0; }
  claim "$COPIED/$id" || true
  printf '%s bus %s -> %s\n' "$(date -u +%H:%M:%SZ)" "${base%/"$SUB"}" "$name" >&2
}
tick() {
  local s list f
  list=$(slots) || { [ -z "${SLOTS_DOWN:-}" ] && log "treehouse status failed; no slot read this tick"; SLOTS_DOWN=1; return 0; }
  SLOTS_DOWN=""
  while IFS= read -r s; do
    [ -n "$s" ] && [ -d "$s/$SUB" ] && [ "$s" != "$REPO" ] || continue
    for f in "$s/$SUB"/20??/??/*.json; do
      [ -f "$f" ] || continue
      copy_one "$s/$SUB" "$f"
    done
  done <<<"$list"
}
start() {
  mkdir -p "$COPIED" "$EVENTS" || die 4 "cannot create $COPIED or $EVENTS"
  [ -f "$SINCE" ] || stamp > "$SINCE"
}
case $VERB in
  slots) slots || die 4 "treehouse status --json did not list the pool" ;;
  once) start; tick ;;
  run) start; trap 'log "stopping"; exit 0' TERM INT; log "running: slots from treehouse, into $EVENTS, every ${POLL}s"
    # `read -t` rather than `sleep`: bash defers a trap until the foreground command ends, so a TERM sent during a sleep waited
    #   out the whole poll interval (route.sh breadcrumb, 2026-10-11).
    while true; do tick; read -r -t "$POLL" <> <(:) || true; done ;;
esac
