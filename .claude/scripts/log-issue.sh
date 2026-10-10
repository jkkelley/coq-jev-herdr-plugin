#!/usr/bin/env bash
#
# log-issue.sh - record an issue as one entry file under issues/YYYY/MM/.
#
# Every entry is its own file, named <UTC-timestamp>-<suffix>.md. Two agents
# writing at the same second mint different names, so concurrent writers never
# touch the same file and trunk merges never collide - the property the old
# monolithic ISSUES.md could not provide (dotfiles #95). Nothing already
# written is ever modified: a fix for an earlier issue is a NEW entry carrying
# `resolves: <suffix>`, so an agent reading newest-first meets the resolution
# before the problem it closed.
#
# scaffold-version: 1

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

usage() {
  cat <<'EOF'
log-issue.sh - record an issue as one entry file under issues/YYYY/MM/

Usage:
  log-issue.sh [--project DIR] --title T --severity S --area A \
               --symptom T --trigger T --cause T --fix T --verify T \
               [--tags a,b] [--refs x7q2m] [--resolves a3f9c2] [--json]
  log-issue.sh migrate [--project DIR] [--json]
  log-issue.sh check   [--project DIR] [--json]

Required (for logging):
  --title      one-line summary of what happened
  --severity   low | medium | high
  --area       the part of the project it touches
  --symptom    what was observed
  --trigger    what makes it happen
  --cause      why it happens
  --fix        what was changed (or "pending")
  --verify     how it was confirmed (or "none yet")

Optional:
  --tags       comma-separated labels
  --refs       related entry suffixes, comma-separated
  --resolves   the suffix of an earlier entry this one closes (must exist)
  --project    project directory (default: .)
  --json       emit one JSON object on stdout instead of the bare suffix
  --help       this text

migrate  convert the old monoliths - ISSUES.md and BACKLOG.md together, in
         one run - into entry files, preserving each entry's recorded
         timestamp as its filename and shard. One map covers both, so refs
         across the trees (an issue naming BK-0003) are rewritten too. Every
         timestamp is checked before anything is written, and a failure
         undoes the whole run. Renames each monolith to <name>.migrated.
         Same verb as `backlog.sh migrate`. Refuses to run twice.
check    validate the tree: shapes, shards, metadata, duplicate suffixes,
         dangling refs, and no monolith beside the directories.

With no flags on a terminal, the fields are collected interactively.
Without a terminal, a missing required field is an error - never a prompt.

Exit codes: 0 ok, 2 usage, 3 validation, 4 io, 6 id not found
EOF
}

# A bare first token that names a verb dispatches; anything else is logging.
case ${1-} in
  --help | -h) usage; exit "$PS_OK" ;;
  migrate | check) command="$1"; shift ;;
  *) command="log" ;;
esac

title=""; severity=""; area=""
symptom=""; trigger=""; cause=""; fix=""; verify=""
tags=""; refs=""; resolves=""

while (($#)); do
  case $1 in
    --project) PS_PROJECT="${2-}"; shift 2 ;;
    --json) PS_JSON=1; shift ;;
    --title) title="${2-}"; shift 2 ;;
    --severity) severity="${2-}"; shift 2 ;;
    --area) area="${2-}"; shift 2 ;;
    --symptom) symptom="${2-}"; shift 2 ;;
    --trigger) trigger="${2-}"; shift 2 ;;
    --cause) cause="${2-}"; shift 2 ;;
    --fix) fix="${2-}"; shift 2 ;;
    --verify) verify="${2-}"; shift 2 ;;
    --tags) tags="${2-}"; shift 2 ;;
    --refs) refs="${2-}"; shift 2 ;;
    --resolves) resolves="${2-}"; shift 2 ;;
    --help | -h) usage; exit "$PS_OK" ;;
    *) PS_JSON=0; ps_die "$PS_USAGE" "unknown_flag" "unknown flag: $1 (try --help)" ;;
  esac
done

project=$(ps_resolve_project "${PS_PROJECT:-.}")

# A monolith beside the directories is two sources of truth. Refuse at write
# time, not just at check time, or the agent that caused it never finds out.
refuse_monolith() {
  if [[ -f $project/ISSUES.md ]]; then
    ps_die "$PS_VALIDATION" "monolith_present" \
      "$project/ISSUES.md is the old monolith format - run: log-issue.sh migrate --project $project"
  fi
}

# ---------------------------------------------------------------------------

cmd_log() {
  refuse_monolith

  # --- collect -------------------------------------------------------------
  # Prompting is reachable only on a terminal. An agent always supplies flags
  # and therefore always takes the deterministic path.
  if ps_is_tty; then
    [[ -n $title ]]    || ps_prompt "Title" title
    [[ -n $severity ]] || ps_prompt "Severity (low/medium/high)" severity
    [[ -n $area ]]     || ps_prompt "Area" area
    [[ -n $symptom ]]  || ps_prompt "Symptom (what was observed)" symptom
    [[ -n $trigger ]]  || ps_prompt "Trigger (what makes it happen)" trigger
    [[ -n $cause ]]    || ps_prompt "Cause (why it happens)" cause
    [[ -n $fix ]]      || ps_prompt "Resolution (or 'pending')" fix
    [[ -n $verify ]]   || ps_prompt "Verification (or 'none yet')" verify
    [[ -n $tags ]]     || ps_prompt "Tags (optional, comma-separated)" tags
    [[ -n $refs ]]     || ps_prompt "Refs (optional, comma-separated)" refs
  fi

  ps_require_value title "$title"
  ps_require_value severity "$severity"
  ps_require_value area "$area"
  ps_require_value symptom "$symptom"
  ps_require_value trigger "$trigger"
  ps_require_value cause "$cause"
  ps_require_value fix "$fix"
  ps_require_value verify "$verify"
  ps_require_enum severity "$severity" low medium high

  # Refs and resolves are suffixes now, greppable across the whole tree.
  # Comma-split by parameter expansion - IFS here is newline+tab, so an
  # unquoted space-separated expansion would NOT split.
  local tok rest
  local -a idvals=()
  for rest in "$refs" "$resolves"; do
    [[ -z $rest || $rest == - ]] && continue
    while [[ $rest == *,* ]]; do idvals+=("${rest%%,*}"); rest=${rest#*,}; done
    idvals+=("$rest")
  done
  for tok in "${idvals[@]}"; do
    tok=${tok// /}
    [[ -z $tok ]] && continue
    [[ $tok =~ ^[a-z0-9]{5}$ ]] || \
      ps_die "$PS_USAGE" "bad_id_format" "refs and resolves take 5-char suffixes (got: $tok)"
  done

  if [[ -n $resolves ]]; then
    local -a found=()
    mapfile -t found < <(ps_find_suffix "$resolves" "$project/issues" "$project/backlog")
    ((${#found[@]} > 0)) || \
      ps_die "$PS_NOTFOUND" "resolves_not_found" \
        "--resolves $resolves does not exist anywhere in $project/issues or $project/backlog"
  fi

  # Every value is sanitised to a single line. Fixed-size entries are what
  # makes a 10-deep read window meaningful, and a stray newline inside the
  # metadata block would break every downstream grep.
  local s_title s_area s_tags s_refs s_resolves
  s_title=$(ps_sanitize_line "$title")
  s_area=$(ps_sanitize_line "$area")
  s_tags=$(ps_sanitize_line "${tags:--}")
  s_refs=$(ps_sanitize_line "${refs:--}")
  s_resolves=${resolves:--}

  local s_symptom s_trigger s_cause s_fix s_verify
  s_symptom=$(ps_sanitize_line "$symptom")
  s_trigger=$(ps_sanitize_line "$trigger")
  s_cause=$(ps_sanitize_line "$cause")
  s_fix=$(ps_sanitize_line "$fix")
  s_verify=$(ps_sanitize_line "$verify")

  local ts logged
  ts=$(ps_now_utc_compact)
  logged=$(ps_now_utc)
  local shard="$project/issues/${ts:0:4}/${ts:4:2}"
  mkdir -p "$shard" || ps_die "$PS_IO" "mkdir_failed" "cannot create $shard"

  # Mint-and-retry: ps_mint_unique hands back a suffix no entry in either
  # tree holds (S-05 M1), and ln refuses a name that appeared since, so
  # creation takes no lock. A collision just costs another suffix.
  local suffix dst="" attempt
  for attempt in 1 2 3 4 5; do
    ps_mint_unique "$project"
    suffix=$PS_MINTED
    dst="$shard/${ts}-${suffix}.md"
    local entry; entry=$(ps_tempfile)
    {
      printf '# %s\n\n' "$s_title"
      printf '<!-- issue\n'
      printf 'id: %s\n' "$suffix"
      printf 'logged: %s\n' "$logged"
      printf 'severity: %s\n' "$severity"
      printf 'area: %s\n' "$s_area"
      printf 'tags: %s\n' "$s_tags"
      printf 'refs: %s\n' "$s_refs"
      printf 'resolves: %s\n' "$s_resolves"
      printf -- '-->\n\n'
      printf -- '- **Symptom** - %s\n' "$s_symptom"
      printf -- '- **Trigger** - %s\n' "$s_trigger"
      printf -- '- **Cause** - %s\n' "$s_cause"
      printf -- '- **Resolution** - %s\n' "$s_fix"
      printf -- '- **Verification** - %s\n' "$s_verify"
    } >"$entry"
    if ps_atomic_create "$entry" "$dst"; then break; fi
    dst=""
  done
  [[ -n $dst ]] || ps_die "$PS_IO" "name_collision" \
    "could not mint a unique entry name after 5 attempts"

  if ((PS_JSON)); then
    printf '{"ok":true,"id":"%s","file":%s,"logged":%s,"severity":"%s","resolves":%s}\n' \
      "$suffix" \
      "$(ps_json_string "$dst")" \
      "$(ps_json_string "$logged")" \
      "$severity" \
      "$([[ -n $resolves ]] && ps_json_string "$resolves" || printf 'null')"
  else
    printf '%s\n' "$suffix"
  fi
}

# ---------------------------------------------------------------------------

# Both monoliths, one map: see ps_migrate in lib/common.sh (S-05 H1, H2).
cmd_migrate() {
  ps_migrate "$project"
}

cmd_check() {
  ps_check_tree "$project" issues || true
  ps_check_report
}

# ---------------------------------------------------------------------------

ps_scratch_init
[[ -d $project ]] || ps_die "$PS_IO" "project_missing" "no such directory: $project"
case $command in
  log) [[ -w $project ]] || ps_die "$PS_IO" "dir_not_writable" "directory is not writable: $project"
       cmd_log ;;
  migrate) [[ -w $project ]] || ps_die "$PS_IO" "dir_not_writable" "directory is not writable: $project"
       cmd_migrate ;;
  check) cmd_check ;;
esac
