#!/usr/bin/env bash
# supervisor-units.sh - renders, installs and removes the systemd user units that run supervisor.sh (WO-20261012-b800).
#   supervisor-units.sh render [--dir DIR] [--repo DIR]   write coq-supervisor.service and .timer into DIR (default: print the paths it would use)
#   supervisor-units.sh install [--repo DIR]              render into ~/.config/systemd/user, daemon-reload, enable --now the timer
#   supervisor-units.sh uninstall                         disable --now the timer, remove both unit files, daemon-reload
#   supervisor-units.sh status                            systemctl --user list-timers and the last tick's log
# --repo is the main checkout the units run from; the default is this script's checkout, refused when that is a linked worktree
# (a treehouse slot comes and goes, and a unit pointing into one runs a deleted tree). Host-changing verbs (install, uninstall) are
# for the owner or the architect: `make -C herdr supervisor-install`. A worker seat renders into a scratch directory and stops there.
# Exit: 0 ok, 2 usage, 3 refused, 4 systemctl failed.
set -uo pipefail
. "$(dirname "$(readlink -f "$0")")/seat-lib.sh"
sl_require jq

verb="${1:-}"; [ $# -eq 0 ] || shift
dir=""; repo="$SL_REPO"; repo_given=0
while [ $# -gt 0 ]; do case "$1" in
  --dir) dir="${2:?--dir needs a directory}"; shift 2 ;; --repo) repo="${2:?--repo needs a directory}"; repo_given=1; shift 2 ;;
  -h|--help) sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2 ;; *) sl_die "unknown argument $1" ;; esac; done
UNIT_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
SRC="$SL_HERDR/systemd"

# unit_path: the directories of every command a tick calls, in a fixed order, so the unit does not depend on a login shell's PATH.
unit_path() {
  local c d out="" seen=":"
  for c in jq herdr treehouse compaction-guard node podman claude git gh flock timeout systemctl; do
    d="$(command -v "$c" 2>/dev/null)" || continue; d="$(dirname "$d")"
    case "$seen" in *":$d:"*) ;; *) out="${out:+$out:}$d"; seen="$seen$d:" ;; esac
  done
  printf '%s' "$out:/usr/local/bin:/usr/bin:/bin"
}
render() { # render <dir>
  local d="$1" p; p="$(unit_path)"; mkdir -p "$d" || return 4
  local f
  for f in coq-supervisor.service coq-supervisor.timer; do
    sed -e "s|@REPO@|$repo|g" -e "s|@PATH@|$p|g" "$SRC/$f.in" > "$d/$f.tmp" && mv "$d/$f.tmp" "$d/$f" || return 4
  done
}
# BREADCRUMB 2026-10-12 - WO-20261012-b800. What would break: rendering from a treehouse slot writes ExecStart=<slot>/herdr/bin/supervisor.sh, and
#   the slot is returned when its ticket closes, after which the timer fails every 30 seconds on a missing file and the line
#   has no supervisor, silently, until someone reads the journal. Why this fix: a linked worktree is refused unless --repo
#   names the main checkout on purpose. Rejected: resolving the main checkout automatically from git-common-dir (it would put
#   a path the owner did not choose into a unit) and a symlink (one more thing to keep true). Cost: install is run from the main checkout.
main_check() {
  [ "$repo_given" = 1 ] && return 0
  local g c; g="$(git -C "$repo" rev-parse --absolute-git-dir 2>/dev/null)" || return 0; c="$(git -C "$repo" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || return 0
  [ "$g" = "$c" ] || { echo "supervisor-units.sh: $repo is a linked worktree; run this from the main checkout or pass --repo <main checkout>" >&2; return 3; }
}
case "$verb" in
  render)
    [ -n "$dir" ] || sl_die "render needs --dir"
    main_check || exit 3; render "$dir" || exit 4; printf '%s\n%s\n' "$dir/coq-supervisor.service" "$dir/coq-supervisor.timer" ;;
  install)
    sl_require systemctl; main_check || exit 3
    render "$UNIT_DIR" || exit 4
    systemctl --user daemon-reload && systemctl --user enable --now coq-supervisor.timer || exit 4
    echo "installed: $UNIT_DIR/coq-supervisor.service and .timer; the first tick runs within 20 seconds" ;;
  uninstall)
    sl_require systemctl
    systemctl --user disable --now coq-supervisor.timer >/dev/null 2>&1 || true
    rm -f "$UNIT_DIR/coq-supervisor.service" "$UNIT_DIR/coq-supervisor.timer"; systemctl --user daemon-reload || exit 4
    echo "removed" ;;
  status)
    systemctl --user list-timers coq-supervisor.timer --no-pager 2>&1 | head -5
    "$SL_HERE/supervisor.sh" log ;;
  *) sl_die "unknown verb '$verb'; render, install, uninstall or status" ;;
esac
