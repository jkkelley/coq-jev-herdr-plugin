#!/usr/bin/env bash
# paths.sh - sourced by route.sh, flow.sh, policy.sh and gate.sh: where the belt reads records and keeps its own files.
# It adds nothing to the resolver; it only lets a factory/config/*.json value name a directory through bin/state-root.sh.
#
#   fx_expand STRING        STRING with ${repo} replaced by $REPO and ${tree:NAME} by that tree under the state root
#                           (NAME one of records logs tests checkpoints plans ledger seats run, as config/state.json lists them)
#   fx_set_root DIR         use DIR as the state root for this process and every child it starts (exports COQ_STATE)
#   fx_readme DIR TEXT      write DIR/README.md once, never over an existing one: what writes the directory, what reads it, how to clean it
# The caller sets REPO before fx_expand. Return codes follow the resolver: 3 validation (a relative root, an unknown tree), 4 io.
#
# BREADCRUMB 2026-10-13 - WO-20261012-0229 (Roadmap A2, owner cards C10 and C11). What broke: route.sh, flow.sh and policy.sh each
#   named their records and their own files with ${repo} in factory/config/*.json (events_dir ${repo}/events, state_dir
#   ${repo}/factory/state), so every treehouse slot read a different log and a record had to be copied between slots; gate.sh
#   defaulted to <repo>/events the same way. Why this fix: one placeholder, ${tree:NAME}, that asks bin/state-root.sh for the tree,
#   so the configs say "the records tree" and no script or config holds a root of its own (AC-H4 of WO-20261012-7e13). Rejected:
#   a COQ_STATE default written into each script (four copies of the rule) and letting --state mean only the run directory (the
#   ledger and the records would then name two roots). Cost: a config value that holds ${tree:...} cannot be read without this
#   file, so a copy of factory/bin must carry it with bin/state-root.sh and config/state.json (factory/tests/lib/world.sh does).
_fx_here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
_fx_resolver=$_fx_here/../../bin/state-root.sh
# shellcheck source=../../bin/state-root.sh
. "$_fx_resolver" || return 4

fx_set_root() {
  [[ ${1:-} == /* ]] || { printf 'paths: the state root must be an absolute path, got %s\n' "${1:-}" >&2; return 3; }
  export COQ_STATE=${1%/}
}
fx_expand() {
  local v=${1//\$\{repo\}/${REPO:-}} t re='\$\{tree:([a-z]+)\}' tok
  while [[ $v =~ $re ]]; do
    tok=${BASH_REMATCH[0]}
    t=$(coq_tree "${BASH_REMATCH[1]}") || return $?
    v=${v//"$tok"/$t}
  done
  printf '%s' "$v"
}
fx_readme() {
  [ -d "$1" ] || return 0
  ( set -C; printf '%s\n' "$2" > "$1/README.md" ) 2>/dev/null || true
}
