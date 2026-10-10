#!/usr/bin/env bash
# unfreeze.sh - break glass for a compaction-guard lease. A seat whose guard phase is armed or compacting has every
# write tool refused ("a compaction is pending") until the lease, binding freeze_seconds (default 180), runs out; the
# guard only checks that lease on the seat's next tool call, so a seat that is answering in text, or waiting, sits
# frozen with nobody to wake it. This script releases the lease and wakes the seat with one prompt.
#   unfreeze.sh <seat-name|pane-id> [--force]    release that seat's guard session when its lease has expired; --force
#                                                 releases it whatever its age (the owner's break glass)
#   unfreeze.sh --all                             one pass over every seat of the herdr session: release what has expired
#   unfreeze.sh --watch [SECONDS]                 --all every SECONDS (default 30), one line per tick, never a daemon
# Lines: released <pane> <name> (<phase> <age>s, lease <freeze>s) | ok <pane> <name> (<phase>) | refused <pane> (<why>)
# Exit: 0 when nothing is left frozen, 1 when a frozen seat was not released, 2 usage, 3 refused.
#
# BREADCRUMB 2026-10-10 21:4x UTC, owner: "Fucking guard lease, better have some break glass shit." What broke:
#   bin/step.sh queued "/compact" into the architect pane after every step; four steps landed in a row, the second and
#   later compacts answered "Not enough messages to compact", which fires the guard's PreCompact (phase compacting,
#   armed_by manual) and never a PostCompact, so the phase never closed. The lease expired at 21:00:20Z but the guard
#   applies it lazily, inside PreToolUse, and the seat had nothing to do but answer in text, so it stayed dark until the
#   owner typed "wtf is going on?" at 21:36Z. Why this fix: the guard's own `release` verb is the right lever, and a
#   governed seat is refused from pulling it on itself (tamper_check, RES-410), so the lever has to be pulled from
#   outside: a tool pane, the owner's shell, or the lease watcher in monitors 1. Rejected: patching the guard (a promoted
#   release with its own suite; a change there is its owner's), and a longer lease (the stall was not slowness).
#   Cost: --force can release a compaction that is genuinely still running; the guard then re-arms at the next turn end.
set -uo pipefail
. "$(dirname "$(readlink -f "$0")")/seat-lib.sh"
sl_require jq herdr compaction-guard
GUARD_STATE="${COMPACTION_GUARD_STATE:-$HOME/.local/state/compaction-guard}"

target=""; force=0; all=0; watch=0; every=30
while [ $# -gt 0 ]; do case "$1" in
  --force) force=1; shift ;; --all) all=1; shift ;;
  --watch) watch=1; all=1; shift; [[ "${1:-}" =~ ^[0-9]+$ ]] && { every=$1; shift; } ;;
  -h|--help) sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2 ;;
  -*) sl_die "unknown argument $1" ;; *) target="$1"; shift ;; esac; done
[ "$all" = 1 ] || [ -n "$target" ] || { sed -n '6,9p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2; }
[ "$all" = 0 ] || [ "$force" = 0 ] || sl_die "--force takes one seat; --all releases expired leases only"

# pane_of <seat-name|pane-id>: a pane id as given, else the pane the seat record names.
pane_of() {
  case "$1" in *:*) printf '%s' "$1"; return 0 ;; esac
  local r; r="$(sl_seat_record "$1")"; [ -f "$r" ] || sl_die "no seat record for $1"
  jq -r '.pane // empty' "$r"
}
# sessions_of <pane>: every guard session bound to that pane of this herdr session, newest binding last.
sessions_of() {
  local d
  for d in "$GUARD_STATE"/sessions/*/; do
    [ -f "$d/binding.json" ] || continue
    jq -e --arg p "$1" --arg hs "$HS" '.driver == "herdr" and .pane == $p and (.herdr_session // "stable") == $hs' "$d/binding.json" >/dev/null 2>&1 || continue
    printf '%s\n' "$(basename "$d")"
  done
}
# one <pane> <name>: release the frozen sessions of one pane. Prints one line per frozen session; sets LEFT=1 when a
# frozen one was left in place.
one() {
  local pane="$1" name="$2" sid phase armed age freeze any=0
  if [ "$pane" = "${HERDR_PANE_ID:-}" ]; then printf 'refused %s (a seat never releases itself; run this from a tool pane or the owner shell)\n' "$pane"; LEFT=1; return 0; fi
  while IFS= read -r sid; do
    [ -n "$sid" ] || continue
    phase="$(jq -r '.phase // "idle"' "$GUARD_STATE/sessions/$sid/phase.json" 2>/dev/null)"
    case "$phase" in armed|compacting) ;; *) continue ;; esac
    any=1
    armed="$(jq -r '.armed_at // empty' "$GUARD_STATE/sessions/$sid/phase.json")"
    age=$(( $(date +%s) - $(date -u -d "${armed:-1970-01-01T00:00:00Z}" +%s 2>/dev/null || echo 0) ))
    freeze="$(jq -r '.freeze_seconds // 180' "$GUARD_STATE/sessions/$sid/binding.json")"
    if [ "$force" = 1 ] || [ "$age" -gt "$freeze" ]; then
      if [ "$DRY" = 1 ]; then printf 'DRY: compaction-guard release %s\n' "$sid" >&2
      else compaction-guard release "$sid" >/dev/null 2>&1 || { printf 'FAILED %s %s (compaction-guard release %s)\n' "$pane" "$name" "$sid"; LEFT=1; continue; }; fi
      sl_mut agent prompt "$pane" "guard lease released by unfreeze.sh at $(sl_now) after ${age}s in phase $phase; no compaction ran; continue your next step" >/dev/null 2>&1 || true
      sl_record note 100 unfreeze --pane "$pane" --note "released $name ($phase ${age}s, lease ${freeze}s, force=$force)"
      printf 'released %s %s (%s %ss, lease %ss)\n' "$pane" "$name" "$phase" "$age" "$freeze"
    else printf 'ok %s %s (%s %ss, lease %ss not yet up)\n' "$pane" "$name" "$phase" "$age" "$freeze"; LEFT=1; fi
  done < <(sessions_of "$pane")
  [ "$any" = 1 ] || printf 'ok %s %s (not frozen)\n' "$pane" "$name"
}
pass() {
  LEFT=0
  if [ "$all" = 1 ]; then
    local f n p
    for f in "$STATE"/seats/*/seat.json; do
      [ -f "$f" ] || continue; [ -z "$(jq -r '.ended_at // empty' "$f")" ] || continue
      n="$(jq -r .name "$f")"; p="$(jq -r '.pane // empty' "$f")"; [ -n "$p" ] || continue
      one "$p" "$n"
    done
    # The architect seat is hand-started and exempt (herdr/config/exemptions.json), so it has no seat record.
    # BREADCRUMB 2026-10-10 - WO-20261010-8fa8. What broke: this filter read `.until > now_iso`, a call to a jq function
    #   that does not exist (the --arg variable is $now_iso), so jq failed to compile, 2>/dev/null hid it, and --all and
    #   --watch never visited the hand-started architect pane wD3:p2, the one seat that froze on 2026-10-10 (this file's
    #   header). Why this fix: $now_iso is the one-character repair and case 06 now freezes an exempt pane and expects it
    #   released. Rejected: dropping the 2>/dev/null, which would print a jq error on every 30 second tick if
    #   exemptions.json is ever malformed. Cost: none; the stderr stays hidden, so case 06 is what proves this loop works.
    while IFS=$'\t' read -r p n; do [ -n "$p" ] && one "$p" "$n"; done < <(jq -r --arg now_iso "$(sl_now)" '.exemptions[] | select(.pane? and .until > $now_iso) | [.pane, (.seat // .pane)] | @tsv' "$SL_HERDR/config/exemptions.json" 2>/dev/null | sort -u)
  else one "$(pane_of "$target")" "$target"; fi
  return "$LEFT"
}
if [ "$watch" = 1 ]; then
  while :; do out="$(pass)"; rc=$?; printf '%s tick: %s\n' "$(sl_now)" "$(grep -c '^released' <<<"$out") released, $(grep -c '^ok' <<<"$out") ok, rc $rc"; grep -v '^ok' <<<"$out" | grep . || true; sleep "$every"; done
else pass; fi
