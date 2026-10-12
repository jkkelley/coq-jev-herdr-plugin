#!/usr/bin/env bash
# recwatch.sh - prompts the architect through herdr when a gate record lands in the checkout or in any treehouse slot. Runs in the
# reserved monitor slot 4.1.2.
#   recwatch.sh [--ticks N]      poll every watches.record_poll_seconds forever (N ticks then exit 0, for tests)
# One prompt per new record whose kind is in watches.record_kinds: "REC <checkout|slotN> <id> <seat> <kind> <code>: read the record, act per playbooks."
# Exit: 0 ok (only with --ticks), 2 usage.
#
# BREADCRUMB 2026-10-12 - WO-20261012-b800, backlog 60l24. What broke: the interim copy (~/.cache/coq-watch/record-watch.sh) listed
#   events/2026/10 by hand, so on 1 November it would have watched nothing, and it typed the slot root and the checkout path
#   in. Why this fix: every events/YYYY/MM/*.json under the checkout and under each slot `treehouse status --json` lists is
#   read, so a month turning needs no edit and a new slot is picked up on its first poll. A file name is announced once across
#   all roots: a record born in a slot is first seen there, and its copy in the checkout (the record bus, WO-20261012-da52)
#   is not announced again; a record whose `at` is older than this watcher's start is never announced, so a fresh slot full
#   of copies of main's history says nothing. Rejected: inotify (not on every filesystem WSL mounts) and one watcher per slot
#   (a pane per slot). Cost: a poll lists every record file under every root, which is a few thousand names, and a record
#   written in a slot and removed before the next poll is missed.
set -uo pipefail
. "$(dirname "$(readlink -f "$0")")/seat-lib.sh"
sl_require jq herdr

ticks=0
while [ $# -gt 0 ]; do case "$1" in
  --ticks) ticks="${2:?--ticks needs a number}"; shift 2 ;;
  -h|--help) sed -n '2,5p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2 ;; *) sl_die "unknown argument $1" ;; esac; done

architect="$(sl_cfg .watches.architect_agent)"; poll="$(sl_cfg .watches.record_poll_seconds)"
kinds="$(sl_cfg '.watches.record_kinds | map("\"" + . + "\"") | join(",")')"
started="$(sl_now)"
declare -A seen
# roots: the checkout, then each slot path treehouse lists, one "<where>\t<dir>" per line.
roots() {
  printf 'checkout\t%s\n' "$SL_REPO"
  command -v treehouse >/dev/null 2>&1 || return 0
  (cd "$SL_REPO" && treehouse status --json 2>/dev/null) | jq -r '.[]? | select(.path != null) | [(.name // "?"), .path] | @tsv' \
    | while IFS=$'\t' read -r nm p; do [ "$p" = "$SL_REPO" ] || printf 'slot%s\t%s\n' "$nm" "$p"; done
}
scan() { # scan <announce 0|1>
  local where dir f b line
  while IFS=$'\t' read -r where dir; do
    [ -d "$dir/events" ] || continue
    for f in "$dir"/events/20??/??/*.json; do
      [ -f "$f" ] || continue
      b="${f##*/}"; [ -z "${seen[$b]:-}" ] || continue
      seen[$b]=1
      [ "$1" = 1 ] || continue
      line="$(jq -r --arg w "$where" --arg s "$started" --argjson k "[$kinds]" \
        'select(.at >= $s and (.kind as $x | $k | index($x) != null)) | "REC \($w) \(.id) \(.seat) \(.kind) \(.code)"' "$f" 2>/dev/null)" || continue
      [ -n "$line" ] || continue
      echo "$(date -u +%H:%M:%SZ) $line"
      sl_h agent prompt "$architect" "$line: read the record, act per playbooks." >/dev/null 2>&1 || echo "$(date -u +%H:%M:%SZ) prompt to $architect failed"
    done
  done < <(roots)
}
scan 0; n=0
while :; do
  sleep "$poll"
  scan 1
  n=$((n + 1)); [ "$ticks" = 0 ] || [ "$n" -lt "$ticks" ] || exit 0
done
