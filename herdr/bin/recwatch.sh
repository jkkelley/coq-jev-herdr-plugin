#!/usr/bin/env bash
# recwatch.sh - prompts the architect through herdr when a gate record lands in the records tree of the state root. Runs in the
# reserved monitor slot 4.1.2.
#   recwatch.sh [--ticks N]      poll every watches.record_poll_seconds forever (N ticks then exit 0, for tests)
# One prompt per new record whose kind is in watches.record_kinds: "REC state <id> <seat> <kind> <code>: read the record, act per playbooks."
# Exit: 0 ok (only with --ticks), 2 usage.
#
# BREADCRUMB 2026-10-12 - WO-20261012-b800, backlog 60l24. What broke: the interim copy (~/.cache/coq-watch/record-watch.sh) listed
#   events/2026/10 by hand, so on 1 November it would have watched nothing, and it typed the slot root and the checkout path
#   in. Why this fix: every YYYY/MM/*.json under the records tree is read, so a month turning needs no edit. A record whose `at`
#   is older than this watcher's start is never announced, so a tree full of history says nothing. Rejected: inotify (not on
#   every filesystem WSL mounts). Cost: a poll lists every record file, which is a few thousand names, and a record written
#   and removed before the next poll is missed.
# BREADCRUMB 2026-10-13 - WO-20261013-f9f2 (Roadmap A3). What broke: this watcher listed events/ under the checkout and under every
#   slot `treehouse status --json` names, and de-duplicated by file name across those roots, because records were once committed
#   files that a slot's copy carried into the checkout (herdr/bin/recwatch.sh before this change, the roots() function). Since A1
#   (WO-20261012-7e13) events/bin/event.sh writes each record once, under the state root's records tree, so the slot scan read
#   copies of git history and a record posted by a seat was seen only when the checkout tree happened to hold it: it announced
#   nothing for a record that A1 wrote. Why this fix: scan the one tree `bin/state-root.sh tree records` resolves (COQ_STATE, else
#   the default in config/state.json), the same resolver the writer uses, and drop the slot scan and the cross-root de-duplication.
#   Rejected: keeping the checkout scan as a fallback (a stale events/ left in git would be announced again) and reading
#   $STATE/records from seat-lib (herdr.json state_dir is not this root until A2). Cost: a record still written to a slot's or the
#   checkout's events/ by an old script is no longer announced; the REC line says `state` where it said `checkout` or `slotN`.
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
tree="$("$SL_REPO/bin/state-root.sh" tree records)" || sl_die "cannot resolve the records tree of the state root"
scan() { # scan <announce 0|1>
  local f line
  for f in "$tree"/20??/??/*.json; do
    [ -f "$f" ] || continue
    [ -z "${seen[$f]:-}" ] || continue
    seen[$f]=1
    [ "$1" = 1 ] || continue
    line="$(jq -r --arg s "$started" --argjson k "[$kinds]" \
      'select(.at >= $s and (.kind as $x | $k | index($x) != null)) | "REC state \(.id) \(.seat) \(.kind) \(.code)"' "$f" 2>/dev/null)" || continue
    [ -n "$line" ] || continue
    echo "$(date -u +%H:%M:%SZ) $line"
    sl_h agent prompt "$architect" "$line: read the record, act per playbooks." >/dev/null 2>&1 || echo "$(date -u +%H:%M:%SZ) prompt to $architect failed"
  done
}
scan 0; n=0
while :; do
  sleep "$poll"
  scan 1
  n=$((n + 1)); [ "$ticks" = 0 ] || [ "$n" -lt "$ticks" ] || exit 0
done
