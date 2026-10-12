#!/usr/bin/env bash
# belt.sh - is the belt moving? The route runner pane runs its command and the belt file is fresh (config .belt); otherwise restart the
# runner in its own slot. One object, one line: `ok belt` | `fixed belt (what)` | `FAILED belt (why)`. Used by recover.sh (node 5) and
# supervisor.sh, which both need the same verdict and the same repair.
#   belt.sh --check      report only
#   belt.sh --apply      restart the runner slot through monitors.sh take, wait for a fresh belt
# Exit: 0 ok or fixed, 1 FAILED, 2 usage. DRY_RUN=1 prints what it would restart and restarts nothing.
#
# Moved out of recover.sh on 2026-10-12 (WO-20261012-b800) so the supervisor runs the same node without recover.sh's guard step.
# The belt (WO-20261011-6842). The runner pane is in use (the monitors.sh status line for the slot) and config .belt.status
#    exits 0. Repair is the same call bringup.sh makes for that slot, so the pane, label and command come from monitors.json.
# BREADCRUMB 2026-10-11 - WO-20261011-6842. What broke: 2026-10-11 18:01Z to 18:23Z the route runner was not running, so every
#   gate record sat unrouted and recover.sh printed ok for everything it checked, because it checked health and not flow.
#   Why this fix: a node that asks monitors.sh whether the runner slot is in use and route.sh status whether the belt moves, and
#   restarts the slot through monitors.sh take (it hands a running job back clean first, so a hung runner restarts in its own
#   pane). Rejected: killing the runner by pid (a process under no pane is the thing the herdr-first law forbids) and a
#   second definition of stale here (route.sh status owns stale_seconds). Cost: a restart does not replay the interrupted record,
#   route.sh writes a 500 for it on start; and the settle wait is a sleep loop of at most .belt.settle_seconds.
set -uo pipefail
. "$(dirname "$(readlink -f "$0")")/seat-lib.sh"
sl_require jq herdr
MON="$SL_HERE/monitors.sh"
mode=""
while [ $# -gt 0 ]; do case "$1" in
  --check) mode=check; shift ;; --apply) mode=apply; shift ;;
  -h|--help) sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2 ;; *) sl_die "unknown argument $1" ;; esac; done
[ -n "$mode" ] || { sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2; }
okb() { echo "ok belt"; exit 0; }
fixedb() { printf 'fixed belt (%s)\n' "$1"; exit 0; }
failb() { printf 'FAILED belt (%s)\n' "$1"; exit 1; }
bslot="$(sl_cfg .belt.slot)"; bsettle="$(sl_cfg .belt.settle_seconds)"; bstat="$(sl_cfg .belt.status)"; bstat="${bstat//\$\{repo\}/$SL_REPO}"
MC="${COQ_MONITORS_CONFIG:-$SL_HERDR/config/monitors.json}"
bwhat="$(jq -r --arg n "$bslot" '[.tabs[].reserved[] | select(.name == $n)] | first | .what // empty' "$MC")"
bcmd="$(jq -r --arg n "$bslot" '[.tabs[].reserved[] | select(.name == $n)] | first | .command // empty' "$MC")"; bcmd="${bcmd//\$\{repo\}/$SL_REPO}"
# belt_state: 0 when the runner pane is in use and the belt is fresh; else 1 with BELT_WHY.
belt_state() {
  local st out bs hl why
  st="$("$MON" health 2>/dev/null)"
  read -ra bs <<<"$bstat"
  if ! grep -qE "^ok $bslot\$" <<<"$st"; then
    hl="$(grep -m1 "^FAILED $bslot " <<<"$st")"; why="$(sed -E 's/^FAILED [^ ]+ \((.*)\)$/\1/' <<<"$hl")"
    # A pane that is there but runs nothing while the belt file has gone stale is a stopped belt first (the 2026-10-11 outage), and
    # says which pane; a pane that is not there at all, or a belt that still moves, is a missing runner.
    if [[ "$why" != *"no pane"* && "$why" != *"not built"* ]] && ! out="$("${bs[@]}" 2>&1)"; then
      BELT_WHY="belt $(head -n 1 <<<"$out" | sed -E 's/^belt: //') (runner pane: $why)"; return 1
    fi
    BELT_WHY="runner pane missing (slot $bslot is not running $bwhat: $why)"; return 1
  fi
  if out="$("${bs[@]}" 2>&1)"; then BELT_WHY=""; return 0; fi
  BELT_WHY="belt $(head -n 1 <<<"$out" | sed -E 's/^belt: //')"; return 1
}
if [ -z "$bwhat" ] || [ -z "$bcmd" ]; then failb "monitors.json has no slot $bslot with a command"
elif belt_state; then okb
elif [ "$mode" != apply ]; then failb "$BELT_WHY"
else
  why="$BELT_WHY"
  if [ "$DRY" = 1 ]; then fixedb "dry run: would restart slot $bslot ($why)"
  elif "$MON" take "$bslot" "$bslot" -- "$bcmd" >/dev/null 2>&1; then
    for ((i = 0; i < bsettle; i++)); do belt_state && break; sleep 1; done
    if belt_state; then fixedb "runner restarted through monitors.sh take $bslot ($why)"
    else failb "restart left no fresh belt in ${bsettle}s: $BELT_WHY"; fi
  else failb "monitors.sh take $bslot failed ($why)"; fi
fi

