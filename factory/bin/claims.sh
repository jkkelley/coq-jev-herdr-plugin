#!/usr/bin/env bash
# claims.sh - no file is ever touched by two open PRs (WO-20261012-0677). A ticket declares the files it will change, start refuses an
# overlap, and the gate refuses a diff that strays. It reads tickets, git and `gh pr list`; the only thing it writes is a ticket's files field.
#
#   claims.sh set   --id ID --files PATH_OR_GLOB...   write the ticket's files field (the architect, at cut)
#   claims.sh get   --id ID                           print the files field, one per line; exit 3 when the ticket declares none
#   claims.sh start --id ID                           0 the files are free   3 an open PR or a live ticket holds one: each overlap is printed
#   claims.sh diff  --id ID [--base REF] [--head REF] 0 the diff stays inside the files field   3 a path strays, or is an aggregate: printed
#   claims.sh ids   [--base REF] [--head REF]         0 every doc number the diff adds is unique   3 a number is taken by main or an open PR
# Flags: --repo DIR (default: the checkout this script is in)   --config FILE (default: factory/config/claims.json)
# Env: COQ_CLAIMS_PRS_JSON=FILE reads the open PRs from FILE (the shape of `gh pr list --json number,title,headRefName,files`) instead of gh.
# Exit: 0 ok, 2 usage, 3 refused (the reason is on stdout, one line per path), 4 io (no jq, no gh, no ticket).
#
# A pattern matches with bash globbing, where `*` also crosses `/`, so `herdr/bin/*` is the whole subtree; a bare directory
# (`herdr/bin`) or a trailing `/` also means the subtree. Two patterns overlap when either matches the other's literal prefix.
#
# BREADCRUMB 2026-10-12 - WO-20261012-0677. What broke: on 2026-10-12 PRs 25, 28, 29, 30 and 31 all edited herdr/bin/seat.sh,
#   factory/config/routes.json, herdr/config/herdr.json, monitors.json or factory/RUNBOOK.md, PR 31 added a second SOP-0003, and
#   every PR rewrote CHANGELOG.md, CONTEXT_STATE.md and work-orders/INDEX.md, so each merge forced the next PR into a conflict, a
#   main merge and a full re-test. Nothing stopped two tickets being cut onto one file; the architect kept the list in their head.
#   Why this fix: the claim is data on the ticket (a files field), checked by a script at the two places it can be broken: start
#   (before the branch exists) and the gate (before the merge). Aggregates are not claimed at all: they are gitignored (.gitignore),
#   and this script still refuses one in a diff, so a force-add cannot slip one back. A new file is a claim too: a PR adding
#   docs/sops/SOP-0003-x.md needs docs/sops/* in its ticket's files, and `ids` refuses two PRs taking one number.
#   Choices that look arbitrary:
#   1. A ticket with no files field cannot start and its diff fails. Cost: every ready ticket cut before today needs `set` once.
#   2. Live tickets are found through `git worktree list`, not main, because work-order start flips status on the ticket's branch
#      only: main never shows an in-progress ticket. Cost: a seat on another machine is invisible, and so is a branch with no worktree.
#   3. Own ticket file, changelog/ and events/ are free in every diff: each entry is a new unique file, the one shape that cannot clash.
#   4. exempt_branches skips the whole diff check for the architect's records PR, which belongs to no one ticket and carries the
#      tickets, specs and records of many (config/claims.json). Cost: one hole, named in the config; its files still show in `start`.
#   5. gh being unreachable is exit 4, not "free": a claim that cannot be proved is not granted.
set -uo pipefail
export LC_ALL=C
HERE=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)
REPO=$(cd "$HERE/../.." && pwd); CONFIG=""; ID=""; BASE=""; HEAD_REF=HEAD; FILES=()
die() { local c=$1; shift; printf 'claims: %s\n' "$*" >&2; exit "$c"; }
command -v jq >/dev/null || die 4 "jq is required"
VERB=${1:-}; shift || true
while [ $# -gt 0 ]; do case $1 in
  --repo) REPO=$(cd "${2:?}" && pwd) || die 4 "no such --repo"; shift 2;; --config) CONFIG=${2:?}; shift 2;; --id) ID=${2:?}; shift 2;;
  --base) BASE=${2:?}; shift 2;; --head) HEAD_REF=${2:?}; shift 2;;
  --files) shift; while [ $# -gt 0 ] && [[ $1 != --* ]]; do FILES+=("$1"); shift; done;;
  *) die 2 "unknown argument $1";; esac; done
case $VERB in set|get|start|diff|ids) ;; *) sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2;; esac
[ -n "$CONFIG" ] || CONFIG=$HERE/../config/claims.json
[ -f "$CONFIG" ] || CONFIG=$REPO/factory/config/claims.json
[ -f "$CONFIG" ] || die 4 "no claims.json"

# ticket_file ID: the ticket's file, live or archived.
ticket_file() { find "$REPO/work-orders" -name "$1-*.md" -not -name README.md 2>/dev/null | head -n 1; }
# fm FILE: the ticket's frontmatter as JSON (the block between the first two --- lines).
fm() { awk '/^---$/{n++; next} n==1' "$1"; }
need_ticket() {
  [ -n "$ID" ] || die 2 "$VERB needs --id"; [[ $ID =~ ^WO-[0-9]{8}-[0-9a-f]{4}$ ]] || die 2 "bad ticket id $ID"
  TF=$(ticket_file "$ID"); [ -n "$TF" ] || die 4 "no ticket $ID under $REPO/work-orders"
}
# claims_of FILE: the files field, one pattern per line.
claims_of() { fm "$1" | jq -r '(.files // [])[]' 2>/dev/null; }
cfg_list() { jq -r --arg k "$1" '.[$k][]' "$CONFIG"; }
# has_glob PAT: 0 when the pattern has a glob character.
has_glob() { [[ $1 == *[\*\?\[]* ]]; }
# matches PATH PATTERN: bash glob, `*` crossing `/`; a bare directory or a trailing `/` is its subtree.
matches() {
  local p=$1 pat=${2%/}
  # shellcheck disable=SC2053
  [[ $p == $pat || $p == $pat/* ]]
}
# literal PAT: the text before the first glob character.
literal() { local x=$1; x=${x%%[\*\?\[]*}; printf '%s' "$x"; }
# overlap A B: 0 when the two patterns can name one path.
overlap() {
  local a=${1%/} b=${2%/} la lb
  if ! has_glob "$a" && ! has_glob "$b"; then [[ $a == "$b" || $a == "$b"/* || $b == "$a"/* ]]; return; fi
  la=$(literal "$a"); lb=$(literal "$b")
  [[ $la == "$lb"* || $lb == "$la"* ]]
}

case $VERB in
  set)
    need_ticket; [ "${#FILES[@]}" -gt 0 ] || die 2 "set needs --files PATH..."
    arr=$(printf '%s\n' "${FILES[@]}" | jq -R . | jq -s .)
    # The frontmatter is the JSON block between the first two --- lines; the body below it is copied byte for byte.
    new=$(fm "$TF" | jq --argjson f "$arr" '.files=$f') || die 4 "frontmatter of $TF is not JSON"
    tmp=$(mktemp "$TF.XXXXXX") || die 4 "cannot write beside $TF"
    { printf -- '---\n%s\n---\n' "$new"; awk '/^---$/{n++; if(n==2){f=1; next}} f' "$TF"; } > "$tmp" && mv "$tmp" "$TF" || die 4 "cannot write $TF"
    printf '%s files: %s\n' "$ID" "${FILES[*]}" ;;
  get)
    need_ticket; out=$(claims_of "$TF"); [ -n "$out" ] || { printf '%s declares no files\n' "$ID"; exit 3; }; printf '%s\n' "$out" ;;
  start)
    need_ticket; mapfile -t mine < <(claims_of "$TF")
    [ "${#mine[@]}" -gt 0 ] || { printf '%s declares no files: set them first (claims.sh set --id %s --files PATH...)\n' "$ID" "$ID"; exit 3; }
    own=$(fm "$TF" | jq -r '.branch // empty'); hits=0
    # Open PRs: every changed path of every PR but this ticket's own, against every pattern.
    if [ -n "${COQ_CLAIMS_PRS_JSON:-}" ]; then prs=$(cat "$COQ_CLAIMS_PRS_JSON") || die 4 "cannot read $COQ_CLAIMS_PRS_JSON"
    else command -v gh >/dev/null || die 4 "gh is required to read the open PRs"
      prs=$(cd "$REPO" && gh pr list --state open --limit 200 --json number,title,headRefName,files 2>/dev/null) || die 4 "gh pr list failed, so the open PRs cannot be checked"; fi
    while IFS=$'\t' read -r n br path; do
      [ -n "$path" ] || continue; [ "$br" != "$own" ] || continue
      for pat in "${mine[@]}"; do
        if matches "$path" "$pat"; then printf 'PR %s (%s) changes %s, which %s claims as %s\n' "$n" "$br" "$path" "$ID" "$pat"; hits=1; break; fi
      done
    done < <(jq -r '.[] | .number as $n | .headRefName as $b | (.files // [])[] | [$n, $b, .path] | @tsv' <<<"$prs")
    # Live tickets: in-progress or in-review in any worktree of this repo (main never shows them, see choice 2).
    while IFS= read -r wt; do
      [ -d "$wt/work-orders" ] || continue
      while IFS= read -r tf; do
        tid=$(fm "$tf" | jq -r '.id // empty'); [ -n "$tid" ] && [ "$tid" != "$ID" ] || continue
        st=$(fm "$tf" | jq -r '.status // empty'); [[ $st == in-progress || $st == in-review ]] || continue
        mapfile -t theirs < <(claims_of "$tf")
        for t in "${theirs[@]}"; do for pat in "${mine[@]}"; do
          if overlap "$t" "$pat"; then printf 'ticket %s (%s) claims %s, which overlaps %s claimed by %s\n' "$tid" "$st" "$t" "$pat" "$ID"; hits=1; fi
        done; done
      done < <(find "$wt/work-orders" -name 'WO-*.md' -not -path '*/archive/*' -not -name README.md 2>/dev/null)
    done < <(git -C "$REPO" worktree list --porcelain 2>/dev/null | sed -n 's/^worktree //p')
    exit $((hits ? 3 : 0)) ;;
  diff)
    need_ticket
    [ -n "$BASE" ] || BASE=$(git -C "$REPO" rev-parse --verify --quiet origin/main || echo main)
    branch=$(git -C "$REPO" rev-parse --abbrev-ref "$HEAD_REF" 2>/dev/null || echo "$HEAD_REF")
    while IFS= read -r ex; do [ -n "$ex" ] || continue
      # shellcheck disable=SC2053
      if [[ $branch == $ex ]]; then exit 0; fi; done < <(cfg_list exempt_branches)
    mb=$(git -C "$REPO" merge-base "$BASE" "$HEAD_REF" 2>/dev/null) || die 4 "no merge base of $BASE and $HEAD_REF"
    mapfile -t mine < <(claims_of "$TF"); mapfile -t aggs < <(cfg_list aggregates); mapfile -t free < <(cfg_list implicit)
    [ "${#mine[@]}" -gt 0 ] || { printf '%s declares no files, so no path of its diff is in scope\n' "$ID"; exit 3; }
    bad=0
    # --no-renames: a rename is a delete and an add, so both paths are checked against the claim.
    while IFS=$'\t' read -r st path; do
      [ -n "$path" ] || continue; hit=0
      for a in "${aggs[@]}"; do
        if matches "$path" "$a"; then hit=1; [ "$st" = D ] || { printf '%s is an aggregate (%s): it is rendered after the merge and never rides a PR\n' "$path" "$a"; bad=1; }; break; fi
      done
      [ "$hit" = 0 ] || continue
      [[ $(basename "$path") == "$ID"-* && $path == work-orders/* ]] && continue
      for f in "${free[@]}"; do if matches "$path" "$f"; then hit=1; break; fi; done
      [ "$hit" = 0 ] || continue
      for f in "${mine[@]}"; do if matches "$path" "$f"; then hit=1; break; fi; done
      [ "$hit" = 1 ] || { printf '%s is outside the files field of %s\n' "$path" "$ID"; bad=1; }
    done < <(git -C "$REPO" diff --no-renames --name-status "$mb" "$HEAD_REF" | awk -F'\t' '{print $1 "\t" $2}')
    exit $((bad ? 3 : 0)) ;;
  ids)
    [ -n "$BASE" ] || BASE=$(git -C "$REPO" rev-parse --verify --quiet origin/main || echo main)
    mb=$(git -C "$REPO" merge-base "$BASE" "$HEAD_REF" 2>/dev/null) || die 4 "no merge base of $BASE and $HEAD_REF"
    # A doc id is PREFIX-NNNN at the start of a file name under a directory the config names; the diff may only add ids main does not have.
    bad=0
    while IFS=$'\t' read -r dir pre; do
      while IFS= read -r added; do
        [ -n "$added" ] || continue; num=$(basename "$added" | sed -n "s/^$pre-\([0-9]\{4\}\)-.*/\1/p"); [ -n "$num" ] || continue
        # Taken by main: another file under the same directory, at the base, with the same number.
        if git -C "$REPO" ls-tree -r --name-only "$BASE" -- "$dir" 2>/dev/null | grep -q "/$pre-$num-"; then
          printf '%s-%s is already taken on %s: %s\n' "$pre" "$num" "$BASE" "$added"; bad=1; continue; fi
        # Taken by another open PR.
        if [ -n "${COQ_CLAIMS_PRS_JSON:-}" ]; then prs=$(cat "$COQ_CLAIMS_PRS_JSON"); else prs=$(cd "$REPO" && gh pr list --state open --limit 200 --json number,headRefName,files 2>/dev/null) || die 4 "gh pr list failed"; fi
        own=$(git -C "$REPO" rev-parse --abbrev-ref "$HEAD_REF" 2>/dev/null)
        other=$(jq -r --arg own "$own" --arg d "$dir/" --arg p "$pre-$num-" --arg me "$added" \
          '.[] | select(.headRefName != $own) | .number as $n | (.files // [])[] | select(.path != $me and (.path | startswith($d)) and (.path | ltrimstr($d) | startswith($p))) | "PR \($n) adds \(.path)"' <<<"$prs" | head -n 1)
        [ -z "$other" ] || { printf '%s-%s is taken by %s: %s\n' "$pre" "$num" "$other" "$added"; bad=1; }
      done < <(git -C "$REPO" diff --no-renames --diff-filter=A --name-only "$mb" "$HEAD_REF" -- "$dir")
    done < <(jq -r '.doc_ids[] | [.dir, .prefix] | @tsv' "$CONFIG")
    exit $((bad ? 3 : 0)) ;;
esac
