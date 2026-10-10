# shellcheck shell=bash
#
# common.sh - shared foundation for every project-scaffold tool.
#
# Sourced, never executed. Every function is prefixed ps_ so a project's own
# shell environment cannot collide with it.
#
# The invariants this file exists to guarantee:
#   - user input is written literally, never evaluated
#   - writes are atomic: build in a temp file, rename over the target
#   - concurrent writers never share a file, so none of them needs a lock
#   - a multi-step write that fails part way is undone, never left half done
#   - every temp path is removed on exit, whether the run passed or failed
#   - stdout carries data only; every human word goes to stderr

# ---------------------------------------------------------------------------
# Exit codes. Agents branch on these numbers, never on message text.
# ---------------------------------------------------------------------------
readonly PS_OK=0
readonly PS_USAGE=2      # bad flag, missing required flag, empty required value
readonly PS_VALIDATION=3 # bad enum value, missing sentinel, malformed file
readonly PS_IO=4         # unreadable / unwritable path
readonly PS_NOTFOUND=6   # referenced ID does not exist
# 5 was "lock timeout". S-05 L6: nothing has taken a lock since entries became
# one file each, so 5 could never be returned; it stays unassigned rather than
# being reused, because an agent written against the old table must never read
# a new meaning into it.

readonly PS_SCHEMA_VERSION=1
readonly PS_TOOL_VERSION=1

# Set by ps_parse_common; consulted by ps_emit_* .
PS_JSON=0
PS_PROJECT=""

# ---------------------------------------------------------------------------
# Output. Data on stdout, everything else on stderr.
# ---------------------------------------------------------------------------

ps_info() { printf '%s\n' "$*" >&2; }
ps_warn() { printf 'warning: %s\n' "$*" >&2; }

# ps_die <exit-code> <error-slug> <human message>
# In --json mode the slug is what an agent reads; the human message is for you.
ps_die() {
  local code="$1" slug="$2"
  shift 2
  if ((PS_JSON)); then
    printf '{"ok":false,"code":%d,"error":"%s","message":%s}\n' \
      "$code" "$slug" "$(ps_json_string "$*")"
  else
    printf 'error: %s\n' "$*" >&2
  fi
  exit "$code"
}

# ---------------------------------------------------------------------------
# JSON. Hand-rolled because the test image has no jq and we refuse to add a
# runtime dependency to a tool whose whole point is being always available.
# ---------------------------------------------------------------------------

# ps_json_string <text> -> a quoted, escaped JSON string
ps_json_string() {
  local s=${1-} out='' i ch
  for ((i = 0; i < ${#s}; i++)); do
    ch=${s:i:1}
    case $ch in
      '"') out+='\"' ;;
      '\') out+='\\' ;;
      $'\n') out+='\n' ;;
      $'\r') out+='\r' ;;
      $'\t') out+='\t' ;;
      *)
        # Escape remaining C0 control characters as \u00XX; pass everything
        # else (including UTF-8) through untouched.
        if [[ $ch < $'\x20' ]]; then
          printf -v ch '\\u%04x' "'$ch"
        fi
        out+=$ch
        ;;
    esac
  done
  printf '"%s"' "$out"
}

# ---------------------------------------------------------------------------
# Time. Injectable so determinism is provable rather than asserted.
# ---------------------------------------------------------------------------

ps_now() {
  if [[ -n ${SCAFFOLD_NOW-} ]]; then
    printf '%s' "$SCAFFOLD_NOW"
  else
    date -Iseconds
  fi
}

ps_today() {
  if [[ -n ${SCAFFOLD_NOW-} ]]; then
    printf '%s' "${SCAFFOLD_NOW%%T*}"
  else
    date -I
  fi
}

# ---------------------------------------------------------------------------
# Scratch space. One temp dir per run, removed on every exit path.
# ---------------------------------------------------------------------------

PS_SCRATCH=""

ps_scratch_init() {
  # Guarded with if/fi rather than `[[ ... ]] && return 0`: under `set -e` a
  # trailing false test would take the whole script down.
  if [[ -n $PS_SCRATCH ]]; then return 0; fi
  PS_SCRATCH=$(mktemp -d "${TMPDIR:-/tmp}/project-scaffold.XXXXXX") || {
    printf 'error: could not create a temporary directory\n' >&2
    exit "$PS_IO"
  }
  # Only the top-level shell installs the cleanup traps. Every caller reaches
  # this through `tmp=$(ps_tempfile)`, and bash runs an EXIT trap set inside a
  # command substitution when that substitution closes. That deleted the scratch
  # directory, and the file just created inside it, before the caller could use
  # the path it had printed. Leaking a temp directory is survivable; handing back
  # a path to a file that no longer exists is not.
  # INT and TERM re-raise after cleanup so the caller sees a real signal death.
  if [[ ${BASHPID:-$$} == "$$" ]]; then
    trap 'ps_cleanup' EXIT
    trap 'ps_undo; ps_cleanup; trap - INT; kill -INT $$' INT
    trap 'ps_undo; ps_cleanup; trap - TERM; kill -TERM $$' TERM
  fi
}

# ---------------------------------------------------------------------------
# Undo log. A step that must not be left half done records how to reverse
# itself here, and clears the record once it has finished. A run that exits
# non-zero, whether by ps_die, set -e or a signal, replays whatever is still
# recorded.
#
# BREADCRUMB - S-05 H2 and M2 (review: ~/.local/state/dotfiles/execution/S-05-review.md).
# What broke: migrate wrote entries one at a time and ps_die'd at the first bad
# one (the old log-issue.sh:305-311, backlog.sh:463-467), leaving half a tree
# that made every rerun refuse as already_migrated. backlog.sh done/move had
# nothing to put back if a step after the claim failed.
# Why this fix: one mechanism, in the one place every exit path already passes
# through, instead of a hand-written rollback at each ps_die site - any of which
# a later edit could miss. Rejected: a staging directory renamed into place,
# which cannot be one rename when issues/ and backlog/ already exist (scaffold
# creates them), so it degrades into this same per-file undo anyway.
# Cost: a SIGKILL skips every trap, so it can still strand a half write; check
# names the leftovers, and a claim file is visible as an unexpected file.
# ---------------------------------------------------------------------------

PS_UNDO_RM=()      # files to remove
PS_UNDO_MV_FROM=() # renames to reverse, replayed newest first:
PS_UNDO_MV_TO=()   #   PS_UNDO_MV_FROM[i] goes back to PS_UNDO_MV_TO[i]

ps_undo() {
  if ((${#PS_UNDO_RM[@]})); then rm -f -- "${PS_UNDO_RM[@]}"; fi
  local i
  for ((i = ${#PS_UNDO_MV_FROM[@]} - 1; i >= 0; i--)); do
    # ln, never mv: putting a file back must not clobber one that appeared at
    # its old path in the meantime. On a refusal the file stays where it is,
    # and check reports it.
    if ln -- "${PS_UNDO_MV_FROM[i]}" "${PS_UNDO_MV_TO[i]}" 2>/dev/null; then
      rm -f -- "${PS_UNDO_MV_FROM[i]}"
    else
      printf 'error: could not put %s back at %s - restore it by hand\n' \
        "${PS_UNDO_MV_FROM[i]}" "${PS_UNDO_MV_TO[i]}" >&2
    fi
  done
  ps_undo_clear
}

ps_undo_clear() { PS_UNDO_RM=(); PS_UNDO_MV_FROM=(); PS_UNDO_MV_TO=(); }

ps_cleanup() {
  local rc=$?
  if ((rc != 0)); then ps_undo; fi
  if [[ -n $PS_SCRATCH && -d $PS_SCRATCH ]]; then
    rm -rf -- "$PS_SCRATCH"
  fi
  PS_SCRATCH=""
}

ps_tempfile() {
  ps_scratch_init
  mktemp "$PS_SCRATCH/tmp.XXXXXX"
}

# Create the scratch directory here, at source time, in the shell that will still
# be alive to clean it up. Left lazy, the first code to reach it was always a
# command substitution, so a subshell became the owner and tore the directory
# down on its way out - every ps_tempfile caller then got a path to a file that
# had already been removed. cmd_close in work-order.sh called this eagerly for
# its own reasons and was the only command that worked; this makes it the rule.
ps_scratch_init

# ---------------------------------------------------------------------------
# Input sanitising.
#
# Values reach the markdown verbatim - no shell ever evaluates them. The only
# transformation is defensive: a literal comment terminator inside a value
# would end the metadata block early and corrupt every downstream parse.
# ---------------------------------------------------------------------------

# The replacements are held in variables and expanded quoted. Bash 5.2 treats a
# bare `&` in a substitution replacement as "whatever the pattern matched", so
# an inline --&gt; would silently produce ---->gt;.
readonly PS_GT_ESCAPE='--&gt;'
readonly PS_LT_ESCAPE='&lt;!--'

# ps_sanitize_line <text> -> single line, comment-terminator neutralised
ps_sanitize_line() {
  local s=${1-}
  s=${s//$'\r'/}
  s=${s//$'\n'/ }
  s=${s//$'\t'/ }
  s=${s//-->/"$PS_GT_ESCAPE"}
  s=${s//<!--/"$PS_LT_ESCAPE"}
  # collapse runs of spaces, then trim
  while [[ $s == *"  "* ]]; do s=${s//  / }; done
  s=${s# }
  s=${s% }
  printf '%s' "$s"
}

# ps_sanitize_body <text> -> newlines preserved, terminator neutralised
ps_sanitize_body() {
  local s=${1-}
  s=${s//$'\r'/}
  s=${s//-->/"$PS_GT_ESCAPE"}
  s=${s//<!--/"$PS_LT_ESCAPE"}
  printf '%s' "$s"
}

# ---------------------------------------------------------------------------
# Atomic write. Never leaves a half-written managed file behind.
# ---------------------------------------------------------------------------

# ps_atomic_install <source-temp-file> <destination>
ps_atomic_install() {
  local src="$1" dst="$2"
  local dstdir
  dstdir=$(dirname -- "$dst")
  [[ -w $dstdir ]] || ps_die "$PS_IO" "dir_not_writable" "directory is not writable: $dstdir"

  # Stage inside the destination directory so the rename cannot cross a
  # filesystem boundary and silently degrade into a copy.
  local staged
  staged=$(mktemp "$dstdir/.project-scaffold.XXXXXX") || \
    ps_die "$PS_IO" "stage_failed" "cannot stage a write in $dstdir"

  if [[ -e $dst ]]; then
    # Preserve the mode of the file being replaced.
    chmod --reference="$dst" "$staged" 2>/dev/null || true
  else
    chmod 0644 "$staged" 2>/dev/null || true
  fi

  cat -- "$src" >"$staged" || { rm -f -- "$staged"; ps_die "$PS_IO" "write_failed" "cannot write to $dstdir"; }
  mv -f -- "$staged" "$dst" || { rm -f -- "$staged"; ps_die "$PS_IO" "rename_failed" "cannot replace $dst"; }
}

# ---------------------------------------------------------------------------
# File helpers.
# ---------------------------------------------------------------------------

# ps_normalize_newlines <file> - strip CR so sentinel matching survives a file
# that has been touched on Windows. Operates on a temp copy, not the original.
ps_strip_cr() {
  local src="$1" out
  out=$(ps_tempfile)
  tr -d '\r' <"$src" >"$out"
  printf '%s' "$out"
}

# ps_has_sentinel <file> <sentinel-text>
ps_has_sentinel() {
  local file="$1" sentinel="$2"
  [[ -f $file ]] || return 1
  grep -qF -- "$sentinel" "$file"
}

# ps_ends_with_newline <file> - false for an empty file too, which is correct:
# appending to it must not assume a leading blank line exists.
ps_ends_with_newline() {
  local file="$1"
  [[ -s $file ]] || return 1
  [[ $(tail -c 1 -- "$file" | od -An -c | tr -d ' ') == '\n' ]]
}

# ---------------------------------------------------------------------------
# Entry files. Issues and backlog items are one file per entry, named
# <UTC-timestamp>-<suffix>.md. This replaced the monolithic ISSUES.md /
# BACKLOG.md plus sequential IDs (ISS-0043) in September 2026 (dotfiles #95):
# allocating a successor ID required a scan AND a lock over one shared file,
# which is exactly what two concurrent agents on a trunk-based workflow collide
# over - and even when the lock held, git still saw one file touched by every
# writer, so merges conflicted. A random 5-char suffix minted at write time
# needs no scan and no lock, and one file per entry means merges never meet.
# The cost: IDs are no longer dense or pronounceable, and "the next number"
# tells you nothing about recency. The timestamp in the filename carries
# ordering instead, which is all the read window ever used the number for.
# ---------------------------------------------------------------------------

# ps_now_utc_compact -> YYYYMMDDTHHMMSSZ, the filename-grade UTC timestamp.
# Filename timestamps fix the month shard, so they must be UTC: two agents in
# different timezones would otherwise mint the same moment into different
# shards, and the shard check would flag one of them.
ps_now_utc_compact() {
  if [[ -n ${SCAFFOLD_NOW-} ]]; then
    date -u -d "$SCAFFOLD_NOW" +%Y%m%dT%H%M%SZ
  else
    date -u +%Y%m%dT%H%M%SZ
  fi
}

# ps_now_utc -> YYYY-MM-DDTHH:MM:SSZ, the metadata-grade UTC timestamp.
ps_now_utc() {
  if [[ -n ${SCAFFOLD_NOW-} ]]; then
    date -u -d "$SCAFFOLD_NOW" +%Y-%m-%dT%H:%M:%SZ
  else
    date -u +%Y-%m-%dT%H:%M:%SZ
  fi
}

# ps_to_utc_compact <any-date-parseable-timestamp> -> YYYYMMDDTHHMMSSZ
# Used by migrate, where the filename must come from the entry's own recorded
# timestamp rather than from now. Prints nothing and returns non-zero when the
# value cannot be parsed, so the caller decides whether to die or skip.
ps_to_utc_compact() {
  date -u -d "$1" +%Y%m%dT%H%M%SZ 2>/dev/null
}

# ps_mint_suffix [attempt] -> 5 random lowercase alphanumerics.
# SCAFFOLD_SUFFIX pins the result for tests, the same role SCAFFOLD_NOW plays
# for the clock. A comma list pins successive attempts - attempt N takes the
# Nth value and the last one repeats - so the re-mint path in ps_mint_unique is
# proven by a test rather than left to 36^5 odds. Callers go through
# ps_mint_unique, which validates and de-duplicates what this returns.
ps_mint_suffix() {
  local attempt=${1:-1}
  if [[ -n ${SCAFFOLD_SUFFIX-} ]]; then
    local -a pins=()
    IFS=, read -ra pins <<<"$SCAFFOLD_SUFFIX"
    local idx=$((attempt - 1))
    ((idx < ${#pins[@]})) || idx=$((${#pins[@]} - 1))
    printf '%s' "${pins[idx]}"
    return 0
  fi
  local s
  # head closes the pipe after 5 chars and tr dies of SIGPIPE; under pipefail
  # that 141 would kill the caller, so the `|| true` is load-bearing, not
  # decoration.
  s=$(tr -dc 'a-z0-9' </dev/urandom 2>/dev/null | head -c 5 || true)
  printf '%s' "$s"
}

# ps_mint_unique <project> [taken-assoc-nameref] -> sets PS_MINTED to a suffix
# that no entry in issues/ or backlog/ holds, and that is not a key of the
# optional taken map (migrate passes the suffixes it has minted but not yet
# written). It sets a variable rather than printing, so its ps_die runs in the
# caller's shell and not in a command substitution that would swallow it.
#
# BREADCRUMB - S-05 M1 (review: ~/.local/state/dotfiles/execution/S-05-review.md).
# What broke: log-issue.sh and backlog.sh retried only when ln met the exact
# same file name. The name carries the timestamp, so that retry fired only for
# the same second AND the same suffix; a suffix already held by an entry from
# any other second was minted again without a word. find_item then refused
# that ID for good (backlog.sh, "id_ambiguous") and check went red.
# Why that mattered: the suffix IS the ID. Its uniqueness across both trees is
# the one property every lookup depends on.
# Why this fix: look the suffix up in both trees before it is used, and re-mint
# on a hit. Rejected: trusting 36^5 - at about 3,000 entries the birthday odds
# of a collision are roughly 7 percent.
# Cost: one find over both trees per entry created. Two writers in different
# seconds that draw the same suffix inside the same instant still both pass
# the lookup; that needs a 1-in-60-million draw at the same moment, and check
# is the backstop that names it.
#
# BREADCRUMB - S-05 L5. What broke: with no readable /dev/urandom the mint came
# back short or empty and was written as-is; log exited 0 with a file name
# check rejects. Why this fix: validate the shape here, the one place every
# mint passes, and fail loud - a re-mint cannot help when the source is gone.
PS_MINTED=""
ps_mint_unique() {
  local project="$1" attempt s
  local -a hits=()
  local -A _no_taken=()
  local -n _taken=${2:-_no_taken}
  for attempt in 1 2 3 4 5 6 7 8 9 10; do
    s=$(ps_mint_suffix "$attempt")
    [[ $s =~ ^[a-z0-9]{5}$ ]] || ps_die "$PS_IO" "mint_failed" \
      "minted suffix '$s' is not 5 lowercase alphanumerics - is /dev/urandom readable?"
    [[ -z ${_taken[$s]-} ]] || continue
    mapfile -t hits < <(ps_find_suffix "$s" "$project/issues" "$project/backlog")
    if ((${#hits[@]} == 0)); then
      PS_MINTED=$s
      return 0
    fi
  done
  ps_die "$PS_IO" "name_collision" \
    "could not mint a suffix that no entry holds after 10 attempts"
}

# ---------------------------------------------------------------------------
# Atomic create-if-absent. The entry-file counterpart of ps_atomic_install.
# ---------------------------------------------------------------------------

# ps_atomic_create <source-temp-file> <destination>
# Returns 1 when the destination already exists so the caller can mint a fresh
# name and retry - a collision is expected input here, not an error. ln is the
# primitive: it is atomic and refuses to overwrite, which mv -n does not
# guarantee on every filesystem.
ps_atomic_create() {
  local src="$1" dst="$2"
  local dstdir
  dstdir=$(dirname -- "$dst")
  [[ -w $dstdir ]] || ps_die "$PS_IO" "dir_not_writable" "directory is not writable: $dstdir"

  local staged
  staged=$(mktemp "$dstdir/.project-scaffold.XXXXXX") || \
    ps_die "$PS_IO" "stage_failed" "cannot stage a write in $dstdir"
  chmod 0644 "$staged" 2>/dev/null || true

  cat -- "$src" >"$staged" || { rm -f -- "$staged"; ps_die "$PS_IO" "write_failed" "cannot write to $dstdir"; }
  if ln -- "$staged" "$dst" 2>/dev/null; then
    rm -f -- "$staged"
    return 0
  fi
  rm -f -- "$staged"
  return 1
}

# ---------------------------------------------------------------------------
# Entry lookup and reading.
# ---------------------------------------------------------------------------

# ps_newest_entries <dir> <count> -> newest-first entry paths, one per line.
# A count of 0 means "all of them" - the live backlog buckets are read in
# full, while issues/ and done/ take a real window. Filenames and shard
# directories both sort chronologically, so a reverse lexical sort of the
# full path IS the chronological order. The read window is a directory walk:
# there is no index file, so there is nothing to go stale.
ps_newest_entries() {
  local dir="$1" n="$2"
  [[ -d $dir ]] || return 0
  if ((n > 0)); then
    find "$dir" -type f -name '*.md' | sort -r | head -n "$n"
  else
    find "$dir" -type f -name '*.md' | sort -r
  fi
}

# ps_find_suffix <suffix> <dir...> -> every entry path carrying that suffix.
# Zero lines means not found; two or more means ambiguous - both are the
# caller's exit codes, not this function's.
ps_find_suffix() {
  local suffix="$1"
  shift
  local d
  for d in "$@"; do
    [[ -d $d ]] || continue
    find "$d" -type f -name "*-${suffix}.md"
  done
}

# ps_meta <file> <key> -> the value from the entry's HTML-comment metadata
# block. Parsing the comment rather than the prose is the whole point of
# writing that block in the first place.
ps_meta() {
  awk -v key="$2" '
    /^<!-- (issue|item)$/ { inblock = 1; next }
    inblock && /^-->$/ { exit }
    inblock && index($0, key ": ") == 1 { print substr($0, length(key) + 3); exit }
  ' "$1"
}

# ps_body_field <file> <key> -> the value of a `- key: value` body line.
ps_body_field() {
  awk -v key="$2" 'index($0, "- " key ": ") == 1 { print substr($0, length(key) + 5); exit }' "$1"
}

# ps_rewrite_tokens <value> <map-nameref> -> comma-separated tokens with any
# token present in the map replaced by its value. Unknown tokens pass through
# unchanged: dropping them would hide information, and `check` names whatever
# does not resolve.
ps_rewrite_tokens() {
  local val="$1"
  local -n _map="$2"
  [[ -z $val || $val == - ]] && { printf '%s' "${val:--}"; return 0; }
  local rest=$val tok out="" first=1
  local -a toks=()
  while [[ $rest == *,* ]]; do toks+=("${rest%%,*}"); rest=${rest#*,}; done
  toks+=("$rest")
  for tok in "${toks[@]}"; do
    tok=${tok// /}
    [[ -z $tok ]] && continue
    local mapped=${_map[$tok]-$tok}
    if ((first)); then out=$mapped; first=0; else out="$out, $mapped"; fi
  done
  printf '%s' "${out:--}"
}

# ---------------------------------------------------------------------------
# Tree validation. The `check` verb on log-issue.sh and backlog.sh funnels
# here. Findings accumulate in PS_CHECK_PROBLEMS; ps_check_report renders them.
# ---------------------------------------------------------------------------

PS_CHECK_PROBLEMS=()

ps_check_note() { PS_CHECK_PROBLEMS+=("$1"); }

# ps_check_refs <file> <census-nameref> <rel-path> - every refs:/resolves:
# token must be a well-formed suffix that exists in the census. A dangling
# target is a pointer to an entry that is not there, which is worse than no
# pointer at all.
ps_check_refs() {
  local f="$1" rel="$3"
  local -n _census="$2"
  local key val rest tok
  for key in refs resolves; do
    val=$(ps_meta "$f" "$key")
    [[ -z $val || $val == - ]] && continue
    rest=$val
    local -a toks=()
    while [[ $rest == *,* ]]; do toks+=("${rest%%,*}"); rest=${rest#*,}; done
    toks+=("$rest")
    for tok in "${toks[@]}"; do
      tok=${tok// /}
      [[ -z $tok || $tok == - ]] && continue
      if [[ ! $tok =~ ^[a-z0-9]{5}$ ]]; then
        ps_check_note "$rel: $key target '$tok' is not a 5-char suffix"
        continue
      fi
      [[ -n ${_census[$tok]-} ]] || \
        ps_check_note "$rel: $key target '$tok' does not exist anywhere in the tree"
    done
  done
}

# ps_check_tree <project> <issues|backlog>
# Validates the scope's subtree, plus the two properties that are only
# meaningful globally: duplicate suffixes and ref resolution, both of which
# span issues/ and backlog/.
ps_check_tree() {
  local project="$1" scope="$2"
  PS_CHECK_PROBLEMS=()

  # A hand-written monolith beside the directories is two sources of truth,
  # and two sources of truth is none. migrate exists precisely for this file.
  if [[ $scope == issues && -f $project/ISSUES.md ]]; then
    ps_check_note "ISSUES.md: old monolith present alongside issues/ - run: log-issue.sh migrate --project <dir>"
  fi
  if [[ $scope == backlog && -f $project/BACKLOG.md ]]; then
    ps_check_note "BACKLOG.md: old monolith present alongside backlog/ - run: backlog.sh migrate --project <dir>"
  fi

  # The suffix census covers BOTH trees regardless of scope: refs point across
  # trees, and a duplicate is ambiguous no matter where the second copy lives.
  declare -A census=()
  local f base suffix
  while IFS= read -r f; do
    base=$(basename -- "$f")
    suffix=${base##*-}
    suffix=${suffix%.md}
    census[$suffix]="${census[$suffix]-}$f "
  done < <(find "$project/issues" "$project/backlog" -type f -name '*.md' 2>/dev/null)

  for suffix in "${!census[@]}"; do
    local -a holders=()
    # The census value is space-separated, but these scripts run with
    # IFS=newline+tab, so the split needs its own IFS.
    # BREADCRUMB - S-05 L4. What broke: this was `local IFS=' '` on its own
    # line, which holds until the function returns - so the rest of
    # ps_check_tree, and ps_check_refs which it calls, ran with IFS=' ' whenever
    # the census was non-empty. Harmless only while every expansion there stays
    # quoted. Why this fix: an assignment prefix scopes IFS to the one read that
    # needs it. Rejected: restoring IFS after the loop, which a later early
    # `continue` or return would skip. Cost: none.
    IFS=' ' read -ra holders <<<"${census[$suffix]}"
    if ((${#holders[@]} > 1)); then
      ps_check_note "suffix '$suffix' is not unique: ${holders[*]}"
    fi
  done

  local root
  if [[ $scope == issues ]]; then root="$project/issues"; else root="$project/backlog"; fi

  if [[ -d $root ]]; then
    # Anything that is not an entry file or a .gitkeep is a hand edit.
    while IFS= read -r f; do
      ps_check_note "${f#"$project"/}: unexpected file - only <UTC-timestamp>-<suffix>.md entries belong here"
    done < <(find "$root" -type f ! -name '*.md' ! -name '.gitkeep')

    while IFS= read -r f; do
      local rel=${f#"$project"/}
      base=$(basename -- "$f")
      if [[ ! $base =~ ^[0-9]{8}T[0-9]{6}Z-[a-z0-9]{5}\.md$ ]]; then
        ps_check_note "$rel: filename is not <UTC-timestamp>-<suffix>.md"
        continue
      fi
      local ts=${base%%-*}
      suffix=${base##*-}
      suffix=${suffix%.md}
      local dirrel
      dirrel=$(dirname -- "$rel")
      # The shard a file sits in must be the shard its filename timestamp
      # implies, or the window walk visits it in the wrong month.
      local want
      if [[ $scope == issues ]]; then
        want="issues/${ts:0:4}/${ts:4:2}"
      else
        case $dirrel in
          backlog/now | backlog/next | backlog/later) want="$dirrel" ;;
          *) want="backlog/done/${ts:0:4}/${ts:4:2}" ;;
        esac
      fi
      if [[ $dirrel != "$want" ]]; then
        ps_check_note "$rel: sits in $dirrel but its timestamp places it in $want"
      fi

      local id; id=$(ps_meta "$f" id)
      if [[ -z $id ]]; then
        ps_check_note "$rel: metadata block has no id"
      elif [[ $id != "$suffix" ]]; then
        ps_check_note "$rel: id '$id' does not match the filename suffix '$suffix'"
      fi

      if [[ $scope == issues ]]; then
        [[ -n $(ps_meta "$f" logged) ]] || ps_check_note "$rel: metadata block has no logged"
        local sev; sev=$(ps_meta "$f" severity)
        case $sev in
          low | medium | high) : ;;
          *) ps_check_note "$rel: severity is missing or not low|medium|high" ;;
        esac
        [[ -n $(ps_meta "$f" area) ]] || ps_check_note "$rel: metadata block has no area"
        local field
        for field in Symptom Trigger Cause Resolution Verification; do
          grep -qF -- "- **${field}** - " "$f" || ps_check_note "$rel: missing the ${field} field"
        done
      else
        [[ -n $(ps_meta "$f" added) ]] || ps_check_note "$rel: metadata block has no added"
        grep -qF -- "- why: " "$f" || ps_check_note "$rel: missing the why field"
        grep -qF -- "- done-when: " "$f" || ps_check_note "$rel: missing the done-when field"
      fi

      ps_check_refs "$f" census "$rel"
    done < <(find "$root" -type f -name '*.md' | sort)
  fi

  ((${#PS_CHECK_PROBLEMS[@]} == 0))
}

# ps_check_report - render PS_CHECK_PROBLEMS and exit: 0 clean, 3 with every
# offending file named on stderr. Branch on the code, never the text.
ps_check_report() {
  if ((${#PS_CHECK_PROBLEMS[@]} == 0)); then
    if ((PS_JSON)); then printf '{"ok":true,"problems":[]}\n'; else ps_info "check: clean"; fi
    exit "$PS_OK"
  fi
  if ((PS_JSON)); then
    printf '{"ok":false,"problems":['
    local i
    for i in "${!PS_CHECK_PROBLEMS[@]}"; do
      ((i > 0)) && printf ','
      ps_json_string "${PS_CHECK_PROBLEMS[i]}"
    done
    printf ']}\n'
  else
    local prob
    for prob in "${PS_CHECK_PROBLEMS[@]}"; do printf 'check: %s\n' "$prob" >&2; done
  fi
  exit "$PS_VALIDATION"
}

# ---------------------------------------------------------------------------
# Migration. `log-issue.sh migrate` and `backlog.sh migrate` are one verb: each
# converts every monolith present - ISSUES.md, BACKLOG.md, or both - in one run.
#
# BREADCRUMB - S-05 H1 (review: ~/.local/state/dotfiles/execution/S-05-review.md).
# What broke: each script migrated its own monolith with its own old-ID map.
# log-issue.sh rewrote refs through the ISS map only and kept BK- tokens as they
# were, and backlog.sh overwrote its old IDs with the new suffixes, so the
# BK -> suffix map was thrown away. The old tool documented `--refs BK-014` as
# normal usage (main:scripts/log-issue.sh:29).
# Why that mattered: `check` rejects a BK- token as "not a 5-char suffix", and
# entries are immutable, so no sanctioned command could ever turn it green - a
# project with --ci went red and stayed red.
# Why this fix: one run, one map holding both ISS- and BK- keys, built before
# anything is written. Rejected: a map file left behind by the first migrate for
# the second to read, which is a second source of truth that outlives its use
# and still depends on the two runs happening in the right order.
# Cost: a project with only one monolith left (its other tree migrated by the
# old per-file tool) keeps its refs into that tree unmapped; check names them.
#
# BREADCRUMB - S-05 H2. What broke: timestamps were parsed during the write
# pass, one entry at a time, so a bad `logged:` on entry N stopped the run
# after N-1 files were written and with the monolith still in place. The rerun
# was refused as already_migrated and logging was refused because the monolith
# was there: stuck, with hand deletion the only way out.
# Why this fix: every value is parsed and checked before the first write, and
# every write and rename is recorded in the undo log, so a failure at any point
# leaves the project exactly as it was. Rejected: stage-then-rename-once, see
# the undo log's breadcrumb. Cost: none; the parse was already done in full.
# ---------------------------------------------------------------------------

# ps_count_heading_like <file> <ISS|BK> - lines that look like an entry heading
# for that prefix: a markdown heading naming the token anywhere, or a list item
# (checkbox and bold optional) that opens with it. Body bullets such as
# "- **Symptom** - see ISS-0001" and metadata lines such as "refs: ISS-0001" do
# not count. See the N1 breadcrumb in ps_migrate.
ps_count_heading_like() {
  local n
  n=$(grep -cE "^#{1,6}[[:space:]].*$2-[0-9]+|^[-*+][[:space:]]+(\[[ xX]\][[:space:]]+)?(\*\*)?$2-[0-9]+" -- "$1") || true
  printf '%s' "${n:-0}"
}

# ps_is_backlog_template <file> - true when a BACKLOG.md is the untouched
# template every scaffold before 967972f wrote: each non-blank line is one of
# that template's own lines or a BACKLOG:/scaffold: marker. The line set is
# the union of both shipped versions (99c4701 and 4c6b696, the second a
# superset); the template file itself was deleted by 967972f, so it lives here.
# See the round 3 R2 breadcrumb in ps_migrate.
ps_is_backlog_template() {
  local known line marker='^<!-- (BACKLOG:[A-Z]+|scaffold:section=[a-z-]+) -->$'
  known=$(cat <<'TMPL'
# BACKLOG
Priority order, top to bottom. Written by `backlog.sh` - `add`, `move`, `done`, `list`.
**Read protocol:** `Now`, `Next` and `Later` in full - that is live work.
`Done` is a sliding window: take the top 10 entries and stop.
Go deeper only when asked, or when an item you are reading references an older ID you need.
`Now` is what is in flight - keep it to 1-3 items or the word stops meaning anything.
Nothing moves up a bucket on its own; promotion is a decision, not a default.
`done-when` is the load-bearing field.
An item whose completion someone has to adjudicate is not ready to be worked - it stays in `Later` until it can be phrased as a check.
## Now
## Next
## Later
## Done
Newest first, trimmed to the last 20. Git holds the rest.
Read the top 10 and stop - the other 10 are kept for the rare lookup, not for routine reading.
TMPL
)
  while IFS= read -r line || [[ -n $line ]]; do
    [[ -z ${line//[[:space:]]/} ]] && continue
    [[ $line =~ $marker ]] && continue
    grep -qxF -- "$line" <<<"$known" || return 1
  done <"$1"
  return 0
}

ps_migrate() {
  local project="$1"
  local iss_mono="$project/ISSUES.md" bk_mono="$project/BACKLOG.md"
  [[ -f $iss_mono || -f $bk_mono ]] || ps_die "$PS_VALIDATION" "nothing_to_migrate" \
    "no ISSUES.md or BACKLOG.md in $project - nothing to migrate"
  local t
  for t in issues backlog; do
    local mono=$iss_mono
    [[ $t == backlog ]] && mono=$bk_mono
    if [[ -f $mono && -d $project/$t ]] && find "$project/$t" -type f -name '*.md' 2>/dev/null | grep -q .; then
      ps_die "$PS_VALIDATION" "already_migrated" \
        "$project/$t already holds entries - refusing to migrate twice over the same output"
    fi
  done

  local line cur in_meta work work_bk=""
  local -a LINES=()

  # --- Pass 1a: split ISSUES.md into entries ----------------------------------
  local -a I_OLD=() I_TITLE=() I_RAW=() I_SEV=() I_AREA=() I_TAGS=() I_REFS=() I_RES=()
  local -a I_SYM=() I_TRI=() I_CAU=() I_FIX=() I_VER=()
  local iss_heads=0 bk_heads=0
  if [[ -f $iss_mono ]]; then
    work=$(ps_strip_cr "$iss_mono")
    iss_heads=$(ps_count_heading_like "$work" ISS)
    mapfile -t LINES <"$work"
    cur=-1 in_meta=0
    for line in ${LINES[@]+"${LINES[@]}"}; do
      if [[ $line =~ ^##\ (ISS-[0-9]{4})\ -\ (.*)$ ]]; then
        cur=$((cur + 1)); in_meta=0
        I_OLD[cur]="${BASH_REMATCH[1]}"; I_TITLE[cur]="${BASH_REMATCH[2]}"
        I_RAW[cur]=""; I_SEV[cur]="medium"; I_AREA[cur]="-"
        I_TAGS[cur]="-"; I_REFS[cur]="-"; I_RES[cur]="-"
        I_SYM[cur]=""; I_TRI[cur]=""; I_CAU[cur]=""; I_FIX[cur]=""; I_VER[cur]=""
        continue
      fi
      ((cur >= 0)) || continue
      if [[ $line == '<!-- issue' ]]; then in_meta=1; continue; fi
      if [[ $line == '-->' ]]; then in_meta=0; continue; fi
      if ((in_meta)); then
        case $line in
          "logged:"*)   I_RAW[cur]="${line#logged: }" ;;
          "severity:"*) I_SEV[cur]="${line#severity: }" ;;
          "area:"*)     I_AREA[cur]="${line#area: }" ;;
          "tags:"*)     I_TAGS[cur]="${line#tags: }" ;;
          "refs:"*)     I_REFS[cur]="${line#refs: }" ;;
          "resolves:"*) I_RES[cur]="${line#resolves: }" ;;
        esac
        continue
      fi
      case $line in
        '- **Symptom** - '*)      I_SYM[cur]="${line#'- **Symptom** - '}" ;;
        '- **Trigger** - '*)      I_TRI[cur]="${line#'- **Trigger** - '}" ;;
        '- **Cause** - '*)        I_CAU[cur]="${line#'- **Cause** - '}" ;;
        '- **Resolution** - '*)   I_FIX[cur]="${line#'- **Resolution** - '}" ;;
        '- **Verification** - '*) I_VER[cur]="${line#'- **Verification** - '}" ;;
      esac
    done
  fi

  # --- Pass 1b: split BACKLOG.md into items -----------------------------------
  # The current bucket comes from the marker lines; an item runs from its
  # checkbox heading to the next boundary. Metadata and body lines are indented
  # two spaces in the old format.
  local -a B_OLD=() B_TITLE=() B_ADDED=() B_COMPLETED=() B_WHY=() B_DONE=() B_BUCKET=()
  if [[ -f $bk_mono ]]; then
    work=$(ps_strip_cr "$bk_mono")
    work_bk=$work
    bk_heads=$(ps_count_heading_like "$work" BK)
    mapfile -t LINES <"$work"
    cur=-1 in_meta=0
    local cur_bucket="" trimmed
    for line in ${LINES[@]+"${LINES[@]}"}; do
      case $line in
        '<!-- BACKLOG:NOW -->')   cur_bucket="now"; continue ;;
        '<!-- BACKLOG:NEXT -->')  cur_bucket="next"; continue ;;
        '<!-- BACKLOG:LATER -->') cur_bucket="later"; continue ;;
        '<!-- BACKLOG:DONE -->')  cur_bucket="done"; continue ;;
      esac
      if [[ $line =~ ^-\ \[[\ x]\]\ \*\*(BK-[0-9]{4})\*\*\ -\ (.*)$ ]]; then
        cur=$((cur + 1)); in_meta=0
        B_OLD[cur]="${BASH_REMATCH[1]}"; B_TITLE[cur]="${BASH_REMATCH[2]}"
        B_ADDED[cur]=""; B_COMPLETED[cur]=""; B_WHY[cur]=""; B_DONE[cur]=""
        B_BUCKET[cur]="${cur_bucket:-later}"
        continue
      fi
      ((cur >= 0)) || continue
      trimmed=${line#"  "}
      if [[ $trimmed == '<!-- item' ]]; then in_meta=1; continue; fi
      if [[ $trimmed == '-->' ]]; then in_meta=0; continue; fi
      if ((in_meta)); then
        case $trimmed in
          "added:"*)     B_ADDED[cur]="${trimmed#added: }" ;;
          "completed:"*) B_COMPLETED[cur]="${trimmed#completed: }" ;;
        esac
        continue
      fi
      case $trimmed in
        '- why: '*)       B_WHY[cur]="${trimmed#'- why: '}" ;;
        '- done-when: '*) B_DONE[cur]="${trimmed#'- done-when: '}" ;;
      esac
    done
  fi

  # --- Pass 1b': every monolith that exists must parse in full --------------
  # BREADCRUMB - S-05 round 2 N1 (review: ~/.local/state/dotfiles/execution/S-05b-review.md).
  # What broke: this function renamed every monolith that existed to .migrated
  # (the rename loop below), whether or not pass 1a/1b parsed a single entry
  # from it. The per-script migrates it replaced (a8b7fcd:scripts/backlog.sh,
  # a8b7fcd:scripts/log-issue.sh) refused an empty parse with exit 3; the merge
  # dropped that guard.
  # Why it mattered: the verb covers both trees, so `log-issue.sh migrate` run
  # for a valid ISSUES.md also took a hand-written BACKLOG.md with it - exit 0,
  # "0 backlog items", backlog/ empty, check green, and refuse_monolith silenced.
  # The backlog survived only in BACKLOG.md.migrated, which no tool reads.
  # Why this fix: refuse, before the first write, any monolith that yields zero
  # entries, and any whose ISS-/BK- heading-like lines outnumber the entries
  # parsed from it - a partial parse is the same loss on a smaller scale. The
  # heading count is deliberately looser than the parser (any markdown heading
  # naming the token, or a list item that opens with it), so a format the
  # parser does not know shows up as a gap instead of as silence. Rejected:
  # migrating the parseable monolith and leaving the other in place, which
  # would leave refuse_monolith blocking the migrated tree with no rerun path.
  # Cost: a monolith with no entries must be removed by hand before migrate
  # will run; the message says so. The pristine BACKLOG.md template is the one
  # exception, see R2 below.
  #
  # BREADCRUMB - S-05 round 3 R2 (review: ~/.local/state/dotfiles/execution/S-05d-review.md).
  # What broke: the N1 guard below refused the untouched BACKLOG.md template
  # that every scaffold before 967972f wrote (markers and prose, no items) as
  # "parsed 0 entries", so a project that logged issues and never used the
  # backlog - the common legacy case - got exit 3 from log-issue.sh migrate
  # until someone deleted BACKLOG.md by hand.
  # Why this fix: that template holds nothing to lose, so when a BACKLOG.md
  # yields 0 entries, has 0 heading-like lines, and ps_is_backlog_template
  # accepts every line, it is empty rather than unread and is renamed aside
  # with the other monolith. Rejected: treating any zero-heading BACKLOG.md as
  # empty, which is exactly P1b's free-text list, still refused; and deleting
  # the template, which the rename-not-delete rule below exists to avoid.
  # Cost: a template someone edited by even one word is refused as before.
  local -a gaps=()
  local bk_template=0
  if [[ -f $bk_mono ]] && ((${#B_OLD[@]} == 0 && bk_heads == 0)) && ps_is_backlog_template "$work_bk"; then
    bk_template=1
  fi
  if [[ -f $iss_mono ]] && ((${#I_OLD[@]} == 0 || iss_heads > ${#I_OLD[@]})); then
    gaps+=("$iss_mono: parsed ${#I_OLD[@]} entries, found $iss_heads heading-like ISS- lines")
  fi
  if [[ -f $bk_mono ]] && ((bk_template == 0)) && ((${#B_OLD[@]} == 0 || bk_heads > ${#B_OLD[@]})); then
    gaps+=("$bk_mono: parsed ${#B_OLD[@]} entries, found $bk_heads heading-like BK- lines")
  fi
  if ((${#gaps[@]})); then
    local IFS=$'\n'
    ps_die "$PS_VALIDATION" "migrate_unparsed_entries" \
      "refused before writing anything - migrating would rename away entries it cannot read:"$'\n'"${gaps[*]}"$'\n'"rewrite those entries in the format log-issue.sh and backlog.sh wrote, or, if a monolith holds nothing worth keeping, remove it, then rerun"
  fi

  # --- Pass 1c: every timestamp, checked before anything is written ----------
  # The filename timestamp comes from the entry's own record, which is what
  # preserves both the shard and the window order the monolith had. Live
  # backlog items take it from `added:`; done items from `completed:`, falling
  # back to `added:`, because the done shard must be the shard the name implies.
  local -a problems=() I_TS=() I_LOGGED=() B_TS=() B_ADDED_OUT=() B_COMPLETED_OUT=()
  local i ts src
  for i in ${I_OLD[@]+"${!I_OLD[@]}"}; do
    if [[ -z ${I_RAW[i]} ]]; then
      problems+=("${I_OLD[i]} has no logged timestamp - cannot place it in a shard")
      continue
    fi
    ts=$(ps_to_utc_compact "${I_RAW[i]}") || ts=""
    if [[ -z $ts ]]; then
      problems+=("${I_OLD[i]} has an unparseable logged value: ${I_RAW[i]}")
      continue
    fi
    I_TS[i]=$ts
    I_LOGGED[i]=$(date -u -d "${I_RAW[i]}" +%Y-%m-%dT%H:%M:%SZ)
  done
  for i in ${B_OLD[@]+"${!B_OLD[@]}"}; do
    if [[ ${B_BUCKET[i]} == done && -n ${B_COMPLETED[i]} ]]; then src=${B_COMPLETED[i]}; else src=${B_ADDED[i]}; fi
    if [[ -z $src ]]; then
      problems+=("${B_OLD[i]} ('${B_TITLE[i]}') has no timestamp - cannot place it")
      continue
    fi
    ts=$(ps_to_utc_compact "$src") || ts=""
    if [[ -z $ts ]]; then
      problems+=("${B_OLD[i]} ('${B_TITLE[i]}') has an unparseable timestamp: $src")
      continue
    fi
    B_TS[i]=$ts
    # A value that is not the stamp source is normalised when it parses and
    # kept verbatim when it does not: dropping it would lose information.
    if [[ -n ${B_ADDED[i]} ]]; then
      B_ADDED_OUT[i]=$(date -u -d "${B_ADDED[i]}" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null) || B_ADDED_OUT[i]=${B_ADDED[i]}
    else
      B_ADDED_OUT[i]="-"
    fi
    B_COMPLETED_OUT[i]=""
    if [[ -n ${B_COMPLETED[i]} ]]; then
      B_COMPLETED_OUT[i]=$(date -u -d "${B_COMPLETED[i]}" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null) || B_COMPLETED_OUT[i]=${B_COMPLETED[i]}
    fi
  done
  if ((${#problems[@]})); then
    local IFS=$'\n'
    ps_die "$PS_VALIDATION" "migrate_bad_timestamp" \
      "refused before writing anything; fix these in the monolith and rerun:"$'\n'"${problems[*]}"
  fi

  # --- One map for both trees ------------------------------------------------
  # Every new suffix is minted before the first write, so refs and resolves
  # can be rewritten through a map that already holds every ISS- and BK- key.
  declare -A MAP=() USED=()
  local -a I_NEW=() B_NEW=()
  for i in ${I_OLD[@]+"${!I_OLD[@]}"}; do
    ps_mint_unique "$project" USED
    USED[$PS_MINTED]=1; I_NEW[i]=$PS_MINTED; MAP[${I_OLD[i]}]=$PS_MINTED
  done
  for i in ${B_OLD[@]+"${!B_OLD[@]}"}; do
    ps_mint_unique "$project" USED
    USED[$PS_MINTED]=1; B_NEW[i]=$PS_MINTED; MAP[${B_OLD[i]}]=$PS_MINTED
  done

  # --- Pass 2: write, with every file recorded in the undo log ---------------
  local entry dir dst
  for i in ${I_OLD[@]+"${!I_OLD[@]}"}; do
    ts=${I_TS[i]}
    dir="$project/issues/${ts:0:4}/${ts:4:2}"
    mkdir -p "$dir" || ps_die "$PS_IO" "mkdir_failed" "cannot create $dir"
    entry=$(ps_tempfile)
    {
      printf '# %s\n\n' "${I_TITLE[i]}"
      printf '<!-- issue\n'
      printf 'id: %s\n' "${I_NEW[i]}"
      printf 'logged: %s\n' "${I_LOGGED[i]}"
      printf 'severity: %s\n' "${I_SEV[i]}"
      printf 'area: %s\n' "${I_AREA[i]}"
      printf 'tags: %s\n' "${I_TAGS[i]}"
      printf 'refs: %s\n' "$(ps_rewrite_tokens "${I_REFS[i]}" MAP)"
      printf 'resolves: %s\n' "$(ps_rewrite_tokens "${I_RES[i]}" MAP)"
      printf -- '-->\n\n'
      printf -- '- **Symptom** - %s\n' "${I_SYM[i]}"
      printf -- '- **Trigger** - %s\n' "${I_TRI[i]}"
      printf -- '- **Cause** - %s\n' "${I_CAU[i]}"
      printf -- '- **Resolution** - %s\n' "${I_FIX[i]}"
      printf -- '- **Verification** - %s\n' "${I_VER[i]}"
    } >"$entry"
    dst="$dir/${ts}-${I_NEW[i]}.md"
    ps_atomic_create "$entry" "$dst" || \
      ps_die "$PS_IO" "name_collision" "name collision during migration at $dst"
    PS_UNDO_RM+=("$dst")
  done
  for i in ${B_OLD[@]+"${!B_OLD[@]}"}; do
    ts=${B_TS[i]}
    if [[ ${B_BUCKET[i]} == done ]]; then
      dir="$project/backlog/done/${ts:0:4}/${ts:4:2}"
    else
      dir="$project/backlog/${B_BUCKET[i]}"
    fi
    mkdir -p "$dir" || ps_die "$PS_IO" "mkdir_failed" "cannot create $dir"
    entry=$(ps_tempfile)
    {
      printf '# %s\n\n' "${B_TITLE[i]}"
      printf '<!-- item\n'
      printf 'id: %s\n' "${B_NEW[i]}"
      printf 'added: %s\n' "${B_ADDED_OUT[i]}"
      [[ -z ${B_COMPLETED_OUT[i]} ]] || printf 'completed: %s\n' "${B_COMPLETED_OUT[i]}"
      printf -- '-->\n\n'
      printf -- '- why: %s\n' "${B_WHY[i]}"
      printf -- '- done-when: %s\n' "${B_DONE[i]}"
    } >"$entry"
    dst="$dir/${ts}-${B_NEW[i]}.md"
    ps_atomic_create "$entry" "$dst" || \
      ps_die "$PS_IO" "name_collision" "name collision during migration at $dst"
    PS_UNDO_RM+=("$dst")
  done

  # Renamed, not deleted: a monolith stays recoverable, but no longer collides
  # with the tree check's "no monolith beside the directories" rule. The
  # renames are in the undo log too, so a failed second one puts the first back.
  local -a renamed=()
  for src in "$iss_mono" "$bk_mono"; do
    [[ -f $src ]] || continue
    mv -- "$src" "$src.migrated" || \
      ps_die "$PS_IO" "rename_failed" "could not rename $src to $src.migrated"
    PS_UNDO_MV_FROM+=("$src.migrated"); PS_UNDO_MV_TO+=("$src")
    renamed+=("$src.migrated")
  done
  ps_undo_clear

  ps_info "migrated ${#I_OLD[@]} issues and ${#B_OLD[@]} backlog items; renamed aside: ${renamed[*]##*/}"
  if ((PS_JSON)); then
    printf '{"ok":true,"migrated":%d,"issues":%d,"backlog":%d,"renamed":[' \
      $((${#I_OLD[@]} + ${#B_OLD[@]})) "${#I_OLD[@]}" "${#B_OLD[@]}"
    for i in "${!renamed[@]}"; do
      ((i > 0)) && printf ','
      ps_json_string "${renamed[i]}"
    done
    printf ']}\n'
  fi
}

# ---------------------------------------------------------------------------
# Project resolution and common flags.
# ---------------------------------------------------------------------------

ps_resolve_project() {
  local p="${1:-.}"
  [[ -d $p ]] || ps_die "$PS_IO" "project_missing" "no such directory: $p"
  (cd -- "$p" && pwd) || ps_die "$PS_IO" "project_unreadable" "cannot enter directory: $p"
}

# ps_require_value <flag-name> <value>
ps_require_value() {
  local name="$1" value="${2-}"
  [[ -n $value ]] || ps_die "$PS_USAGE" "required_empty" "--${name} is required and must not be empty"
}

# ps_require_enum <flag-name> <value> <allowed...>
ps_require_enum() {
  local name="$1" value="$2"
  shift 2
  local allowed=("$@") a
  for a in "${allowed[@]}"; do
    if [[ $value == "$a" ]]; then return 0; fi
  done
  ps_die "$PS_VALIDATION" "invalid_enum" \
    "--${name} must be one of: ${allowed[*]} (got: ${value})"
}

ps_is_tty() { [[ -t 0 && -t 1 ]]; }

# ps_prompt <label> <varname> - interactive fallback, only ever reached on a TTY
ps_prompt() {
  local label="$1" __var="$2" reply=""
  printf '%s: ' "$label" >&2
  IFS= read -r reply || reply=""
  printf -v "$__var" '%s' "$reply"
}
