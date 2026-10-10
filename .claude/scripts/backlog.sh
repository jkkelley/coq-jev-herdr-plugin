#!/usr/bin/env bash
#
# backlog.sh - manage a project's backlog/ tree: one entry file per item.
#
# Buckets are directories: backlog/now/, backlog/next/, backlog/later/ hold
# live work, and backlog/done/YYYY/MM/ is month-sharded because Done is the
# only bucket that accumulates. A move is a rename between bucket directories;
# done is a rename into the done shard plus a `completed:` line in the
# metadata. Every item has its own path, so two agents working two items
# never touch the same file - the property monolithic BACKLOG.md could not
# provide (dotfiles #95).
#
# Ambiguity is still refused, not guessed: a suffix that matches two files
# stops the run.
#
# scaffold-version: 1

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

readonly BUCKETS=(now next later done)
readonly DONE_WINDOW=10

usage() {
  cat <<'EOF'
backlog.sh - manage the backlog/ tree (add | move | done | list | migrate | check)

Usage:
  backlog.sh add     [--project DIR] --title T --why T --done-when T [--bucket B] [--json]
  backlog.sh move    [--project DIR] --id SUFFIX --to BUCKET [--json]
  backlog.sh done    [--project DIR] --id SUFFIX [--json]
  backlog.sh list    [--project DIR] [--bucket BUCKET] [--json]
  backlog.sh migrate [--project DIR] [--json]
  backlog.sh check   [--project DIR] [--json]

Buckets are directories: now/ next/ later/ hold live work; done/YYYY/MM/ is
month-sharded because Done is the only bucket that accumulates.
add defaults to later.

add:
  --title      one line, what the item is
  --why        why it matters - the reason it earned a slot
  --done-when  a check someone can run without asking you

move:
  --to         destination bucket. Moving to the current bucket is a reported
               no-op. Moving to done stamps completion, same as `done`.

done:
  Renames the item into the done shard with the completion time as its new
  filename timestamp (the shard must match the name), and records
  `completed:` in the metadata rather than the title.

list:
  now / next / later in full - that is live work. done is a sliding window:
  the newest 10, then stop.

migrate:
  Convert the old monoliths - BACKLOG.md and ISSUES.md together, in one run -
  into entry files, preserving each item's recorded timestamp as its
  filename. One map covers both, so refs across the trees are rewritten too.
  Every timestamp is checked before anything is written, and a failure undoes
  the whole run. Renames each monolith to <name>.migrated. Same verb as
  `log-issue.sh migrate`. Refuses to run twice.

check:
  Validate the tree: shapes, shards, metadata, duplicate suffixes, dangling
  refs, and no monolith beside the directories.

Common:
  --project DIR   project directory (default: .)
  --json          machine-readable output on stdout
  --help

Exit codes: 0 ok, 2 usage, 3 validation/ambiguous/bad-bucket, 4 io, 6 id not found
EOF
}

(($#)) || { usage; exit "$PS_USAGE"; }

# --help must be handled before subcommand dispatch, or it is consumed as the
# command name and reported as an unknown command.
case ${1-} in --help | -h) usage; exit "$PS_OK" ;; esac

command="$1"; shift

title=""; why=""; done_when=""; bucket=""; id=""; to=""

while (($#)); do
  case $1 in
    --project) PS_PROJECT="${2-}"; shift 2 ;;
    --json) PS_JSON=1; shift ;;
    --title) title="${2-}"; shift 2 ;;
    --why) why="${2-}"; shift 2 ;;
    --done-when) done_when="${2-}"; shift 2 ;;
    --bucket) bucket="${2-}"; shift 2 ;;
    --id) id="${2-}"; shift 2 ;;
    --to) to="${2-}"; shift 2 ;;
    --help | -h) usage; exit "$PS_OK" ;;
    *) PS_JSON=0; ps_die "$PS_USAGE" "unknown_flag" "unknown flag: $1 (try --help)" ;;
  esac
done

project=$(ps_resolve_project "${PS_PROJECT:-.}")
tree="$project/backlog"

# A monolith beside the directories is two sources of truth. Refuse at write
# time, not just at check time, or the agent that caused it never finds out.
refuse_monolith() {
  if [[ -f $project/BACKLOG.md ]]; then
    ps_die "$PS_VALIDATION" "monolith_present" \
      "$project/BACKLOG.md is the old monolith format - run: backlog.sh migrate --project $project"
  fi
}

# find_item <suffix> -> SRC (the one matching path), or dies.
find_item() {
  local want="$1"
  [[ $want =~ ^[a-z0-9]{5}$ ]] || \
    ps_die "$PS_USAGE" "bad_id_format" "--id takes a 5-char suffix (got: $want)"
  local -a matches=()
  mapfile -t matches < <(ps_find_suffix "$want" "$tree")
  if ((${#matches[@]} == 0)); then
    ps_die "$PS_NOTFOUND" "id_not_found" "$want is not in $tree"
  fi
  if ((${#matches[@]} > 1)); then
    ps_die "$PS_VALIDATION" "id_ambiguous" \
      "$want matches ${#matches[@]} files (${matches[*]}) - a human needs to resolve that before I touch it"
  fi
  SRC="${matches[0]}"
}

# bucket_of <path> -> the bucket a path sits in, derived from its directory.
bucket_of() {
  local rel=${1#"$tree"/}
  case $rel in
    now/*) printf 'now' ;;
    next/*) printf 'next' ;;
    later/*) printf 'later' ;;
    done/*) printf 'done' ;;
    *) printf '?' ;;
  esac
}

# claim_item <src-path> -> sets CLAIM to the path SRC now sits at, or returns 1
# when another run got there first.
#
# BREADCRUMB - S-05 M2 (review: ~/.local/state/dotfiles/execution/S-05-review.md).
# What broke: done and move found SRC, read it, then wrote the destination and
# removed SRC. A racer that finished in between had already removed SRC, but
# the late racer's ln into done still succeeded, because its file name carried
# a later second - the old RACED branch caught only same-second racers. Two
# files then held one suffix (done racing done), or the item sat in next/ and
# done/ at once (move racing done), and check went red.
# Why this fix: rename is atomic, so renaming SRC to a private name is a claim
# exactly one racer can win; the loser's rename fails because SRC is gone, and
# it reports rather than writes. The claim name does not end in .md, so no
# lookup or window walk sees it. Rejected: a lock file, which Rule 17 rules out
# (flock is absent from Git Bash) and which the entry-per-file design exists
# to avoid.
# Cost: a loser that arrives after the winner has claimed but before it has
# landed sees id_not_found (exit 6) rather than "already done". The claim is in
# the undo log, so a run that fails after claiming puts SRC back; only a
# SIGKILL can strand one, and check names it as an unexpected file.
CLAIM=""
claim_item() {
  local src="$1"
  local claim; claim="$(dirname -- "$src")/.$(basename -- "$src").claim.$$"
  mv -- "$src" "$claim" 2>/dev/null || return 1
  CLAIM=$claim
  PS_UNDO_MV_FROM+=("$claim"); PS_UNDO_MV_TO+=("$src")
}

# ---------------------------------------------------------------------------

cmd_add() {
  refuse_monolith
  ps_require_value title "$title"
  ps_require_value why "$why"
  ps_require_value done-when "$done_when"
  bucket=${bucket:-later}
  ps_require_enum bucket "$bucket" "${BUCKETS[@]}"

  local s_title s_why s_done
  s_title=$(ps_sanitize_line "$title")
  s_why=$(ps_sanitize_line "$why")
  s_done=$(ps_sanitize_line "$done_when")

  local ts added
  ts=$(ps_now_utc_compact)
  added=$(ps_now_utc)

  # done is sharded because it accumulates; the live buckets stay flat
  # because their discipline caps how many items they ever hold.
  local dir
  if [[ $bucket == done ]]; then
    dir="$tree/done/${ts:0:4}/${ts:4:2}"
  else
    dir="$tree/$bucket"
  fi
  mkdir -p "$dir" || ps_die "$PS_IO" "mkdir_failed" "cannot create $dir"

  # ps_mint_unique hands back a suffix no entry in either tree holds (S-05 M1).
  local suffix dst="" attempt
  for attempt in 1 2 3 4 5; do
    ps_mint_unique "$project"
    suffix=$PS_MINTED
    dst="$dir/${ts}-${suffix}.md"
    local entry; entry=$(ps_tempfile)
    {
      printf '# %s\n\n' "$s_title"
      printf '<!-- item\n'
      printf 'id: %s\n' "$suffix"
      printf 'added: %s\n' "$added"
      printf -- '-->\n\n'
      printf -- '- why: %s\n' "$s_why"
      printf -- '- done-when: %s\n' "$s_done"
    } >"$entry"
    if ps_atomic_create "$entry" "$dst"; then break; fi
    dst=""
  done
  [[ -n $dst ]] || ps_die "$PS_IO" "name_collision" \
    "could not mint a unique entry name after 5 attempts"

  if ((PS_JSON)); then
    printf '{"ok":true,"id":"%s","bucket":"%s","file":%s,"added":%s}\n' \
      "$suffix" "$bucket" "$(ps_json_string "$dst")" "$(ps_json_string "$added")"
  else
    printf '%s\n' "$suffix"
  fi
}

# land_in_done <src-path> - the shared tail of `move --to done` and `done`.
# The filename is re-stamped with the completion time: the done shard a file
# sits in must be the shard its own name implies, and "when it finished" is
# the only ordering Done has ever meant.
land_in_done() {
  local src="$1"
  local base; base=$(basename -- "$src")
  local suffix=${base##*-}; suffix=${suffix%.md}

  if ! claim_item "$src"; then
    # Another run claimed it first. If that run has landed it in done, this is
    # the reported no-op it always was; otherwise the item is mid-flight or
    # gone, and guessing where would be worse than saying so.
    local -a raced=()
    mapfile -t raced < <(ps_find_suffix "$suffix" "$tree/done")
    if ((${#raced[@]} > 0)); then
      if ((PS_JSON)); then
        printf '{"ok":true,"id":"%s","bucket":"done","moved":false,"note":"already done"}\n' "$suffix"
      else
        ps_info "$suffix is already done - nothing to do"
        printf '%s\n' "$suffix"
      fi
      return 0
    fi
    ps_die "$PS_NOTFOUND" "id_not_found" \
      "$suffix is no longer where it was - another agent may have moved it"
  fi

  local ts completed
  ts=$(ps_now_utc_compact)
  completed=$(ps_now_utc)
  local shard="$tree/done/${ts:0:4}/${ts:4:2}"
  mkdir -p "$shard" || ps_die "$PS_IO" "mkdir_failed" "cannot create $shard"

  # Insert completed: into the metadata block - not the title, where it would
  # leak into every parse of the item's name.
  local staged; staged=$(ps_tempfile)
  awk -v c="completed: $completed" '
    /^-->$/ && !stamped { print c; stamped = 1 }
    { print }
  ' "$CLAIM" >"$staged"

  # Holding the claim, nothing else can be landing this item, so an existing
  # file at the destination is a real duplicate: refuse, and the undo log puts
  # SRC back.
  local dst="$shard/${ts}-${suffix}.md"
  ps_atomic_create "$staged" "$dst" || ps_die "$PS_VALIDATION" "duplicate_name" \
    "$dst already exists - the tree has a duplicate name; run: backlog.sh check --project $project"

  rm -f -- "$CLAIM"
  ps_undo_clear

  if ((PS_JSON)); then
    printf '{"ok":true,"id":"%s","bucket":"done","completed":%s}\n' \
      "$suffix" "$(ps_json_string "$completed")"
  else
    printf '%s\n' "$suffix"
  fi
}

cmd_move() {
  refuse_monolith
  ps_require_value id "$id"
  ps_require_value to "$to"
  ps_require_enum to "$to" "${BUCKETS[@]}"

  find_item "$id"
  local cur; cur=$(bucket_of "$SRC")

  if [[ $cur == "$to" ]]; then
    if ((PS_JSON)); then
      printf '{"ok":true,"id":"%s","bucket":"%s","moved":false,"note":"already in that bucket"}\n' "$id" "$to"
    else
      ps_info "$id is already in $to - nothing to do"
      printf '%s\n' "$id"
    fi
    return 0
  fi

  if [[ $to == done ]]; then
    land_in_done "$SRC"
    return 0
  fi

  local dir="$tree/$to"
  mkdir -p "$dir" || ps_die "$PS_IO" "mkdir_failed" "cannot create $dir"
  local dst="$dir/$(basename -- "$SRC")"

  # Claim first (S-05 M2, see claim_item), so a racing done or move cannot
  # also land this item. Then link-then-unlink rather than mv: ln refuses to
  # overwrite atomically, so a same-named file in the target bucket can never
  # be clobbered. On any failure the undo log puts SRC back.
  claim_item "$SRC" || ps_die "$PS_NOTFOUND" "id_not_found" \
    "$id is no longer where it was - another agent may have moved it"
  if ln -- "$CLAIM" "$dst" 2>/dev/null; then
    rm -f -- "$CLAIM"
    ps_undo_clear
  else
    if [[ -e $dst ]]; then
      ps_die "$PS_VALIDATION" "duplicate_name" \
        "$dst already exists - the tree has a duplicate name; run: backlog.sh check --project $project"
    fi
    ps_die "$PS_IO" "move_failed" "could not move $SRC to $dst"
  fi

  if ((PS_JSON)); then
    printf '{"ok":true,"id":"%s","from":"%s","to":"%s","moved":true}\n' "$id" "$cur" "$to"
  else
    printf '%s\n' "$id"
  fi
}

cmd_done() {
  refuse_monolith
  ps_require_value id "$id"
  find_item "$id"

  if [[ $(bucket_of "$SRC") == done ]]; then
    if ((PS_JSON)); then
      printf '{"ok":true,"id":"%s","bucket":"done","moved":false,"note":"already done"}\n' "$id"
    else
      ps_info "$id is already done - nothing to do"
      printf '%s\n' "$id"
    fi
    return 0
  fi

  land_in_done "$SRC"
}

cmd_list() {
  [[ -n $bucket ]] && ps_require_enum bucket "$bucket" "${BUCKETS[@]}"

  local -a files=()
  local b
  if [[ -n $bucket ]]; then
    if [[ $bucket == done ]]; then
      mapfile -t files < <(ps_newest_entries "$tree/done" "$DONE_WINDOW")
    else
      mapfile -t files < <(ps_newest_entries "$tree/$bucket" 0)
    fi
  else
    for b in now next later; do
      local -a bf=()
      mapfile -t bf < <(ps_newest_entries "$tree/$b" 0)
      files+=("${bf[@]}")
    done
    local -a df=()
    mapfile -t df < <(ps_newest_entries "$tree/done" "$DONE_WINDOW")
    files+=("${df[@]}")
  fi

  local first=1 f
  if ((PS_JSON)); then printf '['; fi
  for f in ${files[@]+"${files[@]}"}; do
    local item_id item_title item_why item_done cur base
    item_id=$(ps_meta "$f" id)
    [[ -n $item_id ]] || { base=$(basename -- "$f"); item_id=${base##*-}; item_id=${item_id%.md}; }
    item_title=$(sed -n '1s/^# //p' "$f")
    item_why=$(ps_body_field "$f" why)
    item_done=$(ps_body_field "$f" done-when)
    cur=$(bucket_of "$f")
    if ((PS_JSON)); then
      if ((first == 0)); then printf ','; fi
      first=0
      printf '{"id":"%s","bucket":"%s","title":%s,"why":%s,"done_when":%s}' \
        "$item_id" "$cur" "$(ps_json_string "$item_title")" \
        "$(ps_json_string "$item_why")" "$(ps_json_string "$item_done")"
    else
      printf '%-7s %-6s %s\n' "$item_id" "$cur" "$item_title"
    fi
  done
  if ((PS_JSON)); then printf ']\n'; fi
  return 0
}

# ---------------------------------------------------------------------------

# Both monoliths, one map: see ps_migrate in lib/common.sh (S-05 H1, H2).
cmd_migrate() {
  ps_migrate "$project"
}

cmd_check() {
  ps_check_tree "$project" backlog || true
  ps_check_report
}

# ---------------------------------------------------------------------------

ps_scratch_init
[[ -d $project ]] || ps_die "$PS_IO" "project_missing" "no such directory: $project"

case $command in
  add) [[ -w $project ]] || ps_die "$PS_IO" "dir_not_writable" "directory is not writable: $project"
       cmd_add ;;
  move) [[ -w $project ]] || ps_die "$PS_IO" "dir_not_writable" "directory is not writable: $project"
        cmd_move ;;
  done) [[ -w $project ]] || ps_die "$PS_IO" "dir_not_writable" "directory is not writable: $project"
        cmd_done ;;
  list) cmd_list ;;
  migrate) [[ -w $project ]] || ps_die "$PS_IO" "dir_not_writable" "directory is not writable: $project"
        cmd_migrate ;;
  check) cmd_check ;;
  *) ps_die "$PS_USAGE" "unknown_command" "unknown command: $command (add | move | done | list | migrate | check)" ;;
esac
