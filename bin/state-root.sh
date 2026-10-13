#!/usr/bin/env bash
# state-root.sh - the one resolver for where runtime data lives (ROADMAP.md, Where runtime data lives; owner cards C10, C11).
# Every script that writes a record, a log, a test output, a checkpoint or a cache asks this script; none carries a root of its own.
#
#   state-root.sh state            the state root: $COQ_STATE, else <XDG state home>/coq/<repo>
#   state-root.sh cache            the cache root: $COQ_CACHE, else <XDG cache home>/coq/<repo>; safe to delete
#   state-root.sh tree NAME        <state root>/<tree>, NAME one of records logs tests checkpoints plans ledger seats run
#   state-root.sh get KEY          one scalar of config/state.json (name_max), so a writer reads its limit from the same place
#   state-root.sh [all] [--json]   state, cache and repo, one per line, or as a JSON object
# Sourced instead of run, it defines coq_state_root, coq_cache_root, coq_tree and coq_state_get with the same meanings.
# Every default comes from config/state.json (schema: config/state.schema.json); this file holds only the rule that reads it.
# Exit codes: 0 ok, 2 usage, 3 validation (a relative COQ_STATE, an unknown tree, a config that lacks a key), 4 io (no jq, no HOME, no config).
#
# BREADCRUMB 2026-10-12 - WO-20261012-7e13 (Roadmap A1). What broke: events/bin/event.sh wrote every record into the repository, and
#   the seat scripts each read their own state directory (herdr/config/herdr.json state_dir "~/.local/state/coq", no repo name), so
#   there was no single answer to "where does runtime data go" and 2,689 record files rode one pull request on 2026-10-12.
#   Why this fix: one resolver, defaults in a schema-validated config file, COQ_STATE and COQ_CACHE winning when set. The repo name is
#   COQ_REPO's basename when seat.sh exported it, else the parent of the git common directory (so every treehouse slot of one
#   repository resolves to ONE root, never to the slot's number), else the checkout's directory name. Rejected: reading
#   herdr.json (a herdr-only file that every other tool would have to find) and a default written into each script (AC-H4).
#   Cost: herdr.json state_dir still says ~/.local/state/coq, which is not this root until roadmap item A2 points the seats here;
#   a relative COQ_STATE is refused rather than guessed at, so a typo cannot scatter files under the current directory.
_sr_here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
_sr_repo=$(cd "$_sr_here/.." && pwd)
_sr_config=$_sr_repo/config/state.json
_sr_die() { local c=$1; shift; printf 'state-root: %s\n' "$*" >&2; return "$c"; }
_sr_have_jq() { command -v jq >/dev/null || _sr_die 4 "jq is required"; }
_sr_cfg() { # _sr_cfg JQ-PATH: one scalar of the config, a validation error when it is missing
  local v; [ -f "$_sr_config" ] || { _sr_die 4 "no config $_sr_config"; return; }
  v=$(jq -er "$1" "$_sr_config" 2>/dev/null) || { _sr_die 3 "config $_sr_config has no $1"; return; }
  printf '%s\n' "$v"
}
_sr_repo_name() {
  local common name
  if [ -n "${COQ_REPO:-}" ]; then name=$(basename "$COQ_REPO")
  elif common=$(git -C "$_sr_repo" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) && [ -n "$common" ]; then name=$(basename "$(dirname "$common")")
  else name=$(basename "$_sr_repo"); fi
  [[ $name =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || { _sr_die 3 "repository name '$name' is not usable as a directory name"; return; }
  printf '%s\n' "$name"
}
_sr_root() { # _sr_root state|cache
  local kind=$1 env xdg_env fallback ns val base repo
  _sr_have_jq || return; env=$(_sr_cfg ".$kind.env") || return
  val=${!env:-}
  if [ -n "$val" ]; then
    [[ $val == /* ]] || { _sr_die 3 "$env must be an absolute path, got '$val'"; return; }
    printf '%s\n' "${val%/}"; return
  fi
  xdg_env=$(_sr_cfg ".$kind.xdg_env") || return; fallback=$(_sr_cfg ".$kind.home_fallback") || return; ns=$(_sr_cfg ".$kind.namespace") || return
  base=${!xdg_env:-}
  if [[ $base != /* ]]; then
    [ -n "${HOME:-}" ] || { _sr_die 4 "neither $env, $xdg_env nor HOME is set"; return; }
    base=${HOME%/}/$fallback
  fi
  repo=$(_sr_repo_name) || return
  printf '%s/%s/%s\n' "${base%/}" "$ns" "$repo"
}
coq_state_root() { _sr_root state; }
coq_cache_root() { _sr_root cache; }
coq_tree() { local t s; t=$(_sr_cfg ".trees[\"$1\"]") || return; s=$(_sr_root state) || return; printf '%s/%s\n' "$s" "$t"; }
coq_state_get() { _sr_cfg ".$1"; }

_sr_main() {
  local verb=${1:-all} json=0 a s c r
  for a in "$@"; do [ "$a" != --json ] || json=1; done
  [ "$verb" != --json ] || verb=all
  case $verb in
    state) coq_state_root ;;
    cache) coq_cache_root ;;
    tree) [ $# -ge 2 ] && [[ $2 != --* ]] || { _sr_die 2 "tree needs a name: records logs tests checkpoints plans ledger seats run"; return; }; coq_tree "$2" ;;
    get) [ $# -ge 2 ] && [[ $2 != --* ]] || { _sr_die 2 "get needs a config key, for example name_max"; return; }; coq_state_get "$2" ;;
    all)
      s=$(coq_state_root) || return; c=$(coq_cache_root) || return; r=$(_sr_repo_name) || return
      if [ "$json" = 1 ]; then jq -n --arg s "$s" --arg c "$c" --arg r "$r" '{state:$s, cache:$c, repo:$r}'
      else printf 'state %s\ncache %s\nrepo %s\n' "$s" "$c" "$r"; fi ;;
    *) sed -n '2,9p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' >&2; return 2 ;;
  esac
}
if [ "${BASH_SOURCE[0]}" = "$0" ]; then set -uo pipefail; _sr_main "$@"; exit $?; fi
