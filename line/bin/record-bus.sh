#!/usr/bin/env bash
# record-bus.sh - the record bus: copies each new record from every treehouse slot's events/ tree, and from the state root's records
# tree, into one target records tree, so the belt and the patrol read one place (roadmap item I; it ran from the watch scripts directory in the cache until
# WO-20261013-1637).
#
#   record-bus.sh [--slots BASE] [--target DIR] [--held DIR] [--window MIN] [--interval SEC] [--once]
#     --slots BASE     the treehouse pool directory that holds the slots <BASE>/<N>/<repo>/events/YYYY/MM/*.json;
#                      default: the parent of the slots in `treehouse status --json`
#     --target DIR     where records land, as DIR/YYYY/MM/<name>.json; default: the state root's records tree
#                      (bin/state-root.sh tree records). Pass <checkout>/events to keep feeding the readers of the checkout's events/
#     --held DIR       records named here are never copied (the architect moved them out of a records commit); default
#                      ~/.cache/coq-held-records, read only
#     --window MIN     only records stamped within MIN minutes before the start are copied; default 60
#     --interval SEC   seconds between ticks; default 5
#     --once           one tick, then exit (tests)
# The state root is $COQ_STATE, else the ROADMAP.md default, through bin/state-root.sh. Every file written is a record under --target
# (a .tmp beside it, then mv); nothing else is written. Output: one line per record copied. Exit: 0 ok, 2 usage, 4 io (no jq, no
# state root).
#
# BREADCRUMB 2026-10-12 - interim, first written in the cache (owner: the architect must not be a gate). What broke: seats
#   write gate records into their slot's events/, route.sh watches only the checkout's events/, so every hand-off waited for the
#   architect to copy or hand-wake (13:16Z to 13:53Z the line sat idle while the architect was down). This copies each new slot record
#   into the checkout so the belt routes it. Records with pr/sha fail checkout lint until PR 21's schema lands; the belt routes them
#   regardless, and the architect holds them out of a records commit.
# BREADCRUMB 2026-10-12 13:35Z (architect, after the 03:32Z crash): seats seated since the restart write with main's event.sh, which
#   files records under $COQ_STATE/records/YYYY/MM/<stamp>-<kind>-...json; the belt read only the checkout events/ until A2 (WO-20261012-0229,
#   PR 88) merged, so K1 and K6 test.passed and the A2 review.passed sat unrouted. The state-root block below bridges them into the
#   target under their record id. Rejected: re-posting by hand (a hand fix; new ids, double records). Cost: the same record lives in
#   two trees while the target is the checkout. 15:35Z: A2 merged and the belt reads the state root since 15:28:59Z, but the block
#   stayed because digest, aq.sh and the architect queue read the checkout events/ until A3 (WO-20261012-541a split, PR 89).
# BREADCRUMB 2026-10-13 - WO-20261013-1637 (Roadmap I). What broke: this ran from the watch scripts directory in the cache, outside git, never
#   tested or reviewed, with the checkout path, the treehouse pool path (its hash suffix included) and
#   the state root path typed into it (owner 2026-10-12 22:49Z, m-20261012224955626-rjghl: every script
#   lives in the project, only its artifacts outside). Why this fix: the logic is moved unchanged; the paths are the only edits.
#   The repo root comes from this file's location, the state root from bin/state-root.sh, the slot base from treehouse, so a second
#   checkout or a renamed pool runs without an edit and a test can point all three at a scratch world.
#   Choices that look arbitrary:
#   1. The default --target is the state root's records tree, not the checkout's events/ the cache copy wrote to. Law: runtime data
#      never lives in git (AGENTS.md), and the ticket's AC-H1 says every file the script writes lands under the state root. Cost: the
#      live instance must be started with --target <checkout>/events for as long as digest.sh and aq.sh read the checkout, or they stop
#      seeing slot records; with the default target the state-root block is skipped (its records are already in the target).
#      Rejected: keeping the checkout as the default, which leaves a script that writes into git by default.
#   2. --held keeps ~/.cache/coq-held-records and is only read; moving it is the architect's, because those files are its hand-made
#      list. The window is fixed at the start (-60 min) as before, never advanced, so a long run still copies what the first tick saw.
#   3. The slot glob is <BASE>/*/*/events/*/*, not a repo name, so the pool does not have to be named after the repository.
set -uo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(cd "$here/../.." && pwd)
# shellcheck source=../../bin/state-root.sh
. "$repo/bin/state-root.sh" || exit 4
usage() { sed -n '2,19p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' >&2; exit 2; }

slots=""; target=""; held="$HOME/.cache/coq-held-records"; window=60; interval=5; once=0
while [ $# -gt 0 ]; do
  case $1 in
    --slots|--target|--held|--window|--interval) [ $# -ge 2 ] || usage ;;&
    --slots) slots=$2; shift 2 ;;
    --target) target=$2; shift 2 ;;
    --held) held=$2; shift 2 ;;
    --window) window=$2; shift 2 ;;
    --interval) interval=$2; shift 2 ;;
    --once) once=1; shift ;;
    *) usage ;;
  esac
done
[[ $window =~ ^[0-9]+$ && $interval =~ ^[0-9]+$ ]] || usage
if [ -z "$target" ]; then target=$(coq_tree records) || exit 4; fi
[[ $target == /* ]] || { echo "record-bus: --target must be an absolute path, got '$target'" >&2; exit 2; }
state_records=$(coq_tree records) || exit 4

# slot_base: the pool directory above the slots; empty when treehouse is missing or lists none (the slot block then idles this tick).
slot_base() {
  local p; command -v treehouse >/dev/null || return 0
  p=$(treehouse status --json 2>/dev/null | sed -n '/^\[/,$p' | jq -r 'first(.[].path) // empty' 2>/dev/null) || return 0
  [ -n "$p" ] && dirname "$(dirname "$p")"
}

start=$(date -u -d "-$window min" +%Y%m%dT%H%M%SZ)
while :; do
  base=${slots:-$(slot_base)}
  if [ -n "$base" ]; then
    for d in "$base"/*/*/events/*/*; do
      [ -d "$d" ] || continue; rel=${d#"$base"/*/*/events/}; slot=${d#"$base"/}; slot=${slot%%/*}
      for f in "$d"/*.json; do
        [ -f "$f" ] || continue; b=$(basename "$f"); [[ "$b" > "$start" ]] || continue
        [ -e "$target/$rel/$b" ] && continue
        # held: a record the architect moved out of a records commit (pr/sha fields) must not come back.
        [ -e "$held/$b" ] && continue
        jq -e .id "$f" >/dev/null 2>&1 || continue
        mkdir -p "$target/$rel"; cp "$f" "$target/$rel/$b.tmp" && mv "$target/$rel/$b.tmp" "$target/$rel/$b"
        echo "$(date -u +%H:%M:%SZ) bus $slot -> $b"
      done
    done
  fi
  # The state root's own records, by record id, into the target. Skipped while the target IS the state root's records tree: those files
  # are named <stamp>-<kind>.json, so the by-id check below would never find them and every record would be copied back in twice.
  for f in "$state_records"/2*/*/*.json; do
    [ "$target" != "$state_records" ] || break
    [ -f "$f" ] || continue; [[ "$(basename "$f")" > "${start:0:8}${start:9:6}" ]] || continue
    id=$(jq -r '.id // empty' "$f" 2>/dev/null); [ -n "$id" ] || continue
    rel=${id:0:4}/${id:4:2}; [ -e "$target/$rel/$id.json" ] && continue
    [ -e "$held/$id.json" ] && continue
    mkdir -p "$target/$rel"; cp "$f" "$target/$rel/$id.json.tmp" && mv "$target/$rel/$id.json.tmp" "$target/$rel/$id.json"
    echo "$(date -u +%H:%M:%SZ) bus state-root -> $id"
  done
  [ "$once" = 0 ] || break
  sleep "$interval"
done
