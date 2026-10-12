#!/usr/bin/env bash
# seat-lib.sh - helpers shared by seat.sh, retire.sh, monitors.sh, bringup.sh and recover.sh (SPEC-04).
# Ported 2026-10-10 from ~/tools/bearings-v2/bin/seat-lib.sh and the parts of bin/lib.sh those scripts used.
# Every tunable comes from herdr/config/herdr.json (COQ_HERDR_CONFIG overrides the path; COQ_HERDR_SESSION and
# COQ_STATE override session and state_dir). No function here carries a default of its own.
#
#   sl_cfg KEY                  jq path into the config, hard error when missing
#   sl_h ARGS...                herdr --session <session> ARGS   (every herdr call names its session; Rule 18)
#   sl_mut ARGS...              the same, printed and skipped under DRY_RUN=1
#   sl_ws_id                    workspace id by label, empty when absent
#   sl_tab_id WS LABEL          tab id by label inside WS, empty when absent
#   sl_panes_of_tab WS TAB      JSON [{pane_id,label}] in herdr's order
#   sl_grid_step I ROWS COLS    "<right|down> <from-index> <ratio>" for the i-th cell, row major (equal columns)
#   sl_record KIND CODE SEAT [--ticket T] [--pane P] [--note N]   one event through events/bin/event.sh
#   sl_role_file ROLE           roles/<role>.json or die
#   sl_seat_dir NAME            <state_dir>/seats/<name>, created
#   sl_exempt RULE SEAT PANE    exit 0 when herdr/config/exemptions.json lifts RULE for that seat or pane, now
#   sl_pane_claude_pid PANE     pid of the claude process in that pane's foreground, empty when none
#   sl_pane_session PANE        the Claude session id running in that pane right now, empty when none (WO-20261012-ee9c)
#   sl_guard_targets            "<pane>\t<name>" for every pane the guard watchers govern: open seat records, then live exemptions
#
# BREADCRUMB - this library sets no shell options (bearings-v2 seat-lib.sh, same reasoning). What broke there: a
#   sourced `set -euo pipefail` handed -e to watcher ticks built from checks that fail most of the time, so the first
#   expected non-match killed the loop silently. Why this fix: a library that sets nothing cannot change its caller's
#   error handling. Cost: every caller repeats one `set` line.

SL_HERE="${SL_HERE:-$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)}"
SL_HERDR="$(cd "$SL_HERE/.." && pwd)"
SL_REPO="$(cd "$SL_HERDR/.." && pwd)"
SL_CONFIG="${COQ_HERDR_CONFIG:-$SL_HERDR/config/herdr.json}"
DRY="${DRY_RUN:-0}"

sl_die() { printf '%s: %s\n' "$(basename "$0")" "$*" >&2; exit "${SL_EXIT:-2}"; }
sl_now() { date -u +%Y-%m-%dT%H:%M:%SZ; }
sl_log() { printf '%s %s\n' "$(sl_now)" "$*" >&2; }
# jq -e exits 1 on false as well as null, so a boolean false key read as "missing" (first live run, 2026-10-10); only null is missing.
sl_cfg() { local v; [ -f "$SL_CONFIG" ] || sl_die "no configuration at $SL_CONFIG"; v="$(jq -r "$1 | if . == null then \"__MISSING__\" else . end" "$SL_CONFIG" 2>/dev/null)" || v=__MISSING__; [ "$v" != __MISSING__ ] || sl_die "config $SL_CONFIG has no $1"; printf '%s' "$v"; }
# Only a leading ~ is expanded; [~] rather than "~/" keeps shellcheck SC2088 quiet without a suppression.
sl_expand() { case "$1" in [~]/*) printf '%s/%s' "$HOME" "${1#[~]/}" ;; *) printf '%s' "$1" ;; esac; }
sl_require() { local t; for t in "$@"; do command -v "$t" >/dev/null 2>&1 || sl_die "$t is required on PATH"; done; }

HS="${COQ_HERDR_SESSION:-$(sl_cfg .session)}"
WS_LABEL="$(sl_cfg .workspace_label)"
STATE="$(sl_expand "${COQ_STATE:-$(sl_cfg .state_dir)}")"
# shellcheck disable=SC2034  # read by seat.sh and monitors.sh after sourcing
SL_PROMPT_RE="$(sl_cfg .prompt_regex)"

# BREADCRUMB - every herdr call names its session (bearings-v2 F-14). What broke there: a bare `herdr` acts on the
#   session of whoever ran it, so a watcher started from one session closed panes by id in another; a pane id names
#   nothing outside its own session. HERDR_PANE_ID and friends are unset for the call so `--current` can never leak
#   into the caller's own pane (SPEC-04 s-testing).
sl_h() { env -u HERDR_PANE_ID -u HERDR_TAB_ID -u HERDR_WORKSPACE_ID -u HERDR_SOCKET_PATH herdr --session "$HS" "$@"; }
sl_mut() { if [ "$DRY" = 1 ]; then printf 'DRY: herdr --session %s %s\n' "$HS" "$*" >&2; else sl_h "$@"; fi; }
sl_run() { if [ "$DRY" = 1 ]; then printf 'DRY:'; printf ' %q' "$@"; printf '\n' >&2; else "$@"; fi; }

sl_ws_id() { sl_h workspace list 2>/dev/null | jq -r --arg l "$WS_LABEL" 'first((.result.workspaces // [])[] | select(.label == $l) | .workspace_id) // empty'; }
sl_tab_id() { sl_h tab list --workspace "$1" 2>/dev/null | jq -r --arg l "$2" 'first((.result.tabs // [])[] | select(.label == $l) | .tab_id) // empty'; }
sl_panes_of_tab() { sl_h pane list --workspace "$1" 2>/dev/null | jq -c --arg t "$2" '[(.result.panes // [])[] | select(.tab_id == $t) | {pane_id, label: (.label // "")}]'; }
sl_agent_live() { sl_h agent get "$1" >/dev/null 2>&1; }

# sl_grid_step <i> <rows> <cols>: for the i-th cell in row-major order (i >= 1) which direction to split, which cell
# to split, and the ratio that leaves n columns (or rows) equal. Row 0 splits right from the left neighbour; every
# later row splits down from the cell above, which keeps each column's width. --ratio is the share the OLD pane keeps.
sl_grid_step() {
  local i="$1" rows="$2" cols="$3" dir from rem
  if [ "$i" -lt "$cols" ]; then dir=right; from=$((i - 1)); rem=$((cols - i + 1))
  else dir=down; from=$((i - cols)); rem=$((rows - i / cols + 1)); fi
  awk -v d="$dir" -v f="$from" -v n="$rem" 'BEGIN { printf "%s %d %.4g\n", d, f, 1 / n }'
}

# sl_record KIND CODE SEAT [--ticket T] [--pane P] [--note N]: one line in the event log, never fatal to the caller.
sl_record() {
  local kind="$1" code="$2" seat="$3"; shift 3
  if [ "$DRY" = 1 ]; then printf 'DRY: event %s %s %s %s\n' "$kind" "$code" "$seat" "$*" >&2; return 0; fi
  "$SL_REPO/events/bin/event.sh" add --kind "$kind" --code "$code" --seat "$seat" "$@" >/dev/null || sl_log "record $kind $code for $seat failed"
}

sl_role_file() { local f="$SL_REPO/roles/$1.json"; [ -f "$f" ] || sl_die "no role file $f"; printf '%s' "$f"; }
sl_seat_dir() { local d="$STATE/seats/${1//[^A-Za-z0-9_-]/_}"; mkdir -p "$d"; printf '%s' "$d"; }
sl_seat_record() { printf '%s/seats/%s/seat.json' "$STATE" "${1//[^A-Za-z0-9_-]/_}"; }

# sl_exempt RULE SEAT PANE: an exemption in herdr/config/exemptions.json whose until is still ahead of now.
sl_exempt() {
  local f="$SL_HERDR/config/exemptions.json" now; now="$(sl_now)"
  [ -f "$f" ] || return 1
  jq -e --arg r "$1" --arg s "${2:-}" --arg p "${3:-}" --arg now "$now" \
    'any(.exemptions[]; .rule == $r and .until > $now and ((.seat? // "") == $s and $s != "" or (.pane? // "") == $p and $p != ""))' "$f" >/dev/null 2>&1
}

# sl_live_seats [ROLE]: names of seat records with no ended_at whose agent herdr still answers for, optionally one role.
sl_live_seats() {
  local f n
  for f in "$STATE"/seats/*/seat.json; do
    [ -f "$f" ] || continue
    [ -z "$(jq -r '.ended_at // empty' "$f")" ] || continue
    [ -z "${1:-}" ] || [ "$(jq -r .role "$f")" = "$1" ] || continue
    n="$(jq -r .name "$f")"
    sl_agent_live "$n" && printf '%s\n' "$n"
  done
  return 0
}

# BREADCRUMB 2026-10-12 - WO-20261012-ee9c, pane to session. What broke: compaction-guard watch (monitors.json slot 1.1.2) and
#   unfreeze.sh sessions_of (before this change) walked every binding under ~/.local/state/compaction-guard/sessions/ and
#   acted on any session whose binding.json named a pane, live or dead. A pane keeps its id across restarts, so 231 bindings
#   at 15:45Z on 2026-10-12 (115 from other projects) mapped to a few dozen panes, and the 02:16Z restart typed about 189
#   GOV-100 memos into the architect pane wD3:p2, one per second; backlog lh51y. Why this fix: the pane is the truth, so each
#   tick asks herdr which claude process is in the pane (`pane process-info`), reads that pid's own session file that Claude
#   Code writes (<claude_sessions_dir>/<pid>.json, key sessionId) and hands exactly that id to the guard. Rejected: reading the
#   binding's own pane field (it is the stale thing), `herdr agent get` agent_session (set only for seats herdr reported a
#   session for; a hand-started pane has none), and a change to the guard (not this repo's, and its --session verb already
#   scopes a tick). Cost: one process-info call and one file read per pane per tick; a claude that has not written its file
#   yet (the first second after start) reads as "no session" and is picked up on the next tick.
# A claude process is named claude (the real one), or is a script whose path ends in /claude run by an interpreter (the suite's
# stub: argv bash /repo/herdr/tests/stubs/claude). Anything else that merely matches reads as "no session file" below.
sl_pane_claude_pid() {
  sl_h pane process-info --pane "$1" 2>/dev/null | jq -r \
    'def base: split("/") | last; first((.result.process_info.foreground_processes // [])[] | select(.name == "claude" or ((.argv[0]? // "") | base) == "claude" or ((.argv[1]? // "") | base) == "claude") | .pid) // empty'
}
sl_pane_session() {
  local pid dir f
  pid="$(sl_pane_claude_pid "$1")"; [ -n "$pid" ] || return 0
  dir="$(sl_expand "$(sl_cfg .claude_sessions_dir)")"; f="$dir/$pid.json"; [ -f "$f" ] || return 0
  jq -r --argjson pid "$pid" 'select(.pid == $pid) | .sessionId // empty' "$f" 2>/dev/null
  return 0
}
# sl_guard_targets: the panes whose guard session the watchers act on. Open seat records first (their pane field), then the
# hand-started panes only exemptions.json names (the architect), as unfreeze.sh --all always did.
sl_guard_targets() {
  local f n p
  {
    for f in "$STATE"/seats/*/seat.json; do
      [ -f "$f" ] || continue; [ -z "$(jq -r '.ended_at // empty' "$f")" ] || continue
      n="$(jq -r .name "$f")"; p="$(jq -r '.pane // empty' "$f")"; [ -n "$p" ] || continue
      printf '%s\t%s\n' "$p" "$n"
    done
    # BREADCRUMB 2026-10-10 - WO-20261010-8fa8. What broke: this filter read `.until > now_iso`, a call to a jq function
    #   that does not exist (the --arg variable is $now_iso), so jq failed to compile, 2>/dev/null hid it, and --all and
    #   --watch never visited the hand-started architect pane wD3:p2, the one seat that froze on 2026-10-10 (unfreeze.sh
    #   header). Why this fix: $now_iso is the one-character repair and case 06 now freezes an exempt pane and expects it
    #   released. Rejected: dropping the 2>/dev/null, which would print a jq error on every 30 second tick if
    #   exemptions.json is ever malformed. Cost: none; the stderr stays hidden, so case 06 is what proves this loop works.
    #   (Moved here from unfreeze.sh pass() by WO-20261012-ee9c so guardwatch.sh and unfreeze.sh list the same panes.)
    jq -r --arg now_iso "$(sl_now)" '.exemptions[] | select(.pane? and .until > $now_iso) | [.pane, (.seat // .pane)] | @tsv' "$SL_HERDR/config/exemptions.json" 2>/dev/null | sort -u
  } | awk -F'\t' '!seen[$1]++'
}
