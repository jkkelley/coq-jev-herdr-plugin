#!/usr/bin/env bash
# break-glass-guard.sh - the Claude Code hook that makes a break glass exactly one command (WO-20261011-4562).
#   break-glass-guard.sh pre  STATEFILE    PreToolUse on Bash: allow the one authorised command once, deny any other command
#                                          that holds the head of a deny rule the break glass lifted
#   break-glass-guard.sh post STATEFILE    PostToolUse on Bash: the authorised command finished, so write break.glass 201 and
#                                          ask seat.sh to put the role settings back
# Reads the hook JSON on stdin (tool_name, tool_input.command). STATEFILE is <state>/break-glass/<request id>.json, written by
# seat.sh --break-glass. Exit 0 lets the call go on to the permission rules, 2 blocks it and the message on stderr reaches the seat.
#
# BREADCRUMB 2026-10-11 - WO-20261011-4562. What broke: nothing yet; this is the half of "a second command is still denied" that
#   settings.json cannot say. seat.sh lifts the deny rule that covers the action (Claude Code checks deny before allow, so an
#   allow rule cannot open a hole in it), and under bypassPermissions that leaves every command the lifted rule covered open.
#   Why this fix: the hook closes that territory again. A Bash command is "in the territory" when it holds the head of a lifted
#   rule (the text before its first *, e.g. gh pr merge). The first such command that is exactly the action wins the used
#   marker (mkdir is atomic, so two parallel calls cannot both win) and runs; every other one, and the same command a second
#   time, is blocked. A command that holds no head is not this script's business and meets the role's own rules.
#   Rejected: matching the whole command only (echo ok; gh pr merge 99 would pass) and a pattern per rule (the heads are the
#   same set, computed once by seat.sh). Cost: a command that merely mentions a head, for example echo "gh pr merge", is
#   blocked while the break glass lasts; the ttl bounds that. An expired break glass keeps denying until seat.sh restores.
set -uo pipefail
mode=${1:-}; sf=${2:-}
[ -f "$sf" ] && jq -e . "$sf" >/dev/null 2>&1 || exit 0
in=$(cat); [ "$(jq -r '.tool_name // empty' <<<"$in")" = Bash ] || exit 0
cmd=$(jq -r '.tool_input.command // empty' <<<"$in")
action=$(jq -r .action "$sf"); req=$(jq -r .request "$sf"); seat=$(jq -r .seat "$sf")
case $mode in
  pre)
    hit=0
    while IFS= read -r h; do case $cmd in *"$h"*) hit=1 ;; esac; done < <(jq -r '.heads[]' "$sf")
    [ "$hit" = 1 ] || exit 0
    now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    if [ "$cmd" = "$action" ] && [[ $now < $(jq -r .expires_at "$sf") ]] && mkdir "$sf.used" 2>/dev/null; then
      jq --arg now "$now" '.used_at = $now' "$sf" > "$sf.tmp" && mv -f "$sf.tmp" "$sf"; exit 0
    fi
    printf 'break glass %s allows exactly one command, once: %s\n' "$req" "$action" >&2; exit 2 ;;
  post)
    [ "$cmd" = "$action" ] && [ -d "$sf.used" ] && [ "$(jq -r '.done_at // empty' "$sf")" = "" ] || exit 0
    now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    jq --arg now "$now" '.done_at = $now' "$sf" > "$sf.tmp" && mv -f "$sf.tmp" "$sf"
    t=$(jq -r '.ticket // empty' "$sf")
    COQ_EVENTS_ROOT=$(jq -r .events_root "$sf") "$(jq -r .events_bin "$sf")" add --code 201 --seat "$seat" --kind break.glass \
      ${t:+--ticket "$t"} --action "$action" --answer "$req" --note "the one authorised command finished" >/dev/null
    "$(dirname "$(readlink -f "$0")")/seat.sh" --break-glass-restore "$seat" --why "done" >/dev/null 2>&1 || true
    exit 0 ;;
  *) exit 0 ;;
esac
