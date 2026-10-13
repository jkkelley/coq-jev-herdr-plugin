#!/usr/bin/env bash
# suites.sh - the test commands a pull request's changed files make necessary (WO-20261013-f1ff). It reads git and
# factory/config/suites.json and prints one command per line; it runs nothing and writes nothing.
#
#   suites.sh plan [--base B] [--head H]   the commands for the files changed between B and H (defaults origin/main and HEAD)
#   suites.sh full                         the full set, which is what a path no row maps plans
# Flags: --repo DIR (default: the checkout this script is in)   --config FILE (default: factory/config/suites.json)
# Exit: 0 plan printed, 2 usage, 3 a config key missing or unknown, or a path pattern invalid (the reason is on stderr),
#       4 io (no jq, no git, no config file, a ref that does not resolve).
#
# A changed path plans the union of the suites of every row it matches, so a row only ever adds; a path no row matches plans the full
# set. Commands print once each, in the order of the config's `full` list, whatever order the files came in. A pattern is a bash glob
# where `*` also crosses `/`; a bare directory or a trailing `/` is its subtree (the same rule as claims.sh).
#
# BREADCRUMB 2026-10-13 - WO-20261013-f1ff. What broke: the tester ran each suite its ticket's test plan named, whole, so a tickets-only
#   pull request ran whole suites and a pull request ran again what main already ran (owner 2026-10-13: test suites cannot be the
#   bottleneck). The first idea, one suite per directory, was refused in the architect's ruling b99ta (record 7c3dq): 32fc429 changed
#   events/bin and broke the factory suite, which a per-directory map would not have run.
#   Why this fix: the map is data (config/suites.json), the choice is a script, and a row names every suite that loads the path -
#   found by reading what each suite copies or sources (herdr's world copies the whole repo, factory's copies events/bin and roles,
#   line's merge.sh calls event.sh and state-root.sh) - and factory/tests/cases/19-suites-map.test.sh pins the cross-suite rows.
#   Choices that look arbitrary:
#   1. A path no row matches plans the full set, not nothing: a gap in the map costs time and never a missed suite. Cost: a new
#      top-level path runs everything until someone adds its row.
#   2. Rows union instead of first-match wins: a more specific row can never hide the suites a broader one demands. Cost: no row can
#      take a suite away, so the broad `herdr/*` row cannot be narrowed by a later one.
#   3. `make lint` is in `always`, so a tickets-only diff plans exactly lint and reindex; lint is the one check that reads every file.
#   4. A diff is `merge-base(B,H)..H` with renames split into delete and add, so a file moved out of a mapped path still plans it.
#   5. The plan names commands; it never runs them (verify-main.sh runs the full set, the tester runs the plan).
#   6. work-order.sh is the managed skill copy, which is gitignored: the reindex command names the project path, and a worktree
#      without it fails at run time; bin/aggregates.sh has the lookup that finds the machine copy.
set -uo pipefail
export LC_ALL=C
HERE=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)
REPO=$(cd "$HERE/../.." && pwd); CONFIG=""; BASE=origin/main; HEAD_REF=HEAD
die() { local c=$1; shift; printf 'suites: %s\n' "$*" >&2; exit "$c"; }
usage() { sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2; }
VERB=${1:-}; shift || true
while [ $# -gt 0 ]; do case $1 in
  --repo) [ -n "${2:-}" ] || usage; REPO=$(cd "$2" && pwd) || die 4 "no such --repo"; shift 2;;
  --config) [ -n "${2:-}" ] || usage; CONFIG=$2; shift 2;;
  --base) [ -n "${2:-}" ] || usage; BASE=$2; shift 2;; --head) [ -n "${2:-}" ] || usage; HEAD_REF=$2; shift 2;;
  *) die 2 "unknown argument $1";; esac; done
case $VERB in plan|full) ;; *) usage;; esac
command -v jq >/dev/null || die 4 "jq is required"
[ -n "$CONFIG" ] || CONFIG=$HERE/../config/suites.json
[ -f "$CONFIG" ] || die 4 "no suites.json at $CONFIG"
jq -e . "$CONFIG" >/dev/null 2>&1 || die 3 "$CONFIG is not JSON"

# Every key present with its type, every suite name a row, always or full uses defined in commands, every pattern valid.
for k in commands always full rows; do jq -e --arg k "$k" 'has($k)' "$CONFIG" >/dev/null || die 3 "suites.json has no key $k"; done
jq -e '(.commands|type=="object") and (.always|type=="array") and (.full|type=="array") and (.rows|type=="array")' "$CONFIG" >/dev/null ||
  die 3 "suites.json: commands must be an object and always, full and rows arrays"
jq -e '(.full|length) > 0' "$CONFIG" >/dev/null || die 3 "suites.json: full is empty"
jq -e 'all(.rows[]; type=="object" and has("paths") and has("suites") and (.paths|type=="array") and (.suites|type=="array"))' "$CONFIG" >/dev/null ||
  die 3 "suites.json: every row needs a paths array and a suites array"
unknown=$(jq -r '.commands as $c | ([.always[], .full[], (.rows[].suites[])] | unique[] | select(. as $n | ($c|has($n)|not)))' "$CONFIG")
[ -z "$unknown" ] || die 3 "suites.json names a suite with no command: $(tr '\n' ' ' <<<"$unknown")"
while IFS= read -r pat; do
  { [ -n "$pat" ] && [[ $pat != /* ]] && [[ /$pat/ != *//* ]] && [[ /$pat/ != */../* ]] && [[ $pat != *[[:space:]]* ]]; } ||
    die 3 "suites.json: path pattern '$pat' is invalid (empty, absolute, with a .. segment, or with a space)"
done < <(jq -r '.rows[].paths[] | tostring' "$CONFIG")

# matches PATH PATTERN: bash glob, `*` crossing `/`; a bare directory or a trailing `/` is its subtree.
matches() {
  local p=$1 pat=${2%/}
  # shellcheck disable=SC2053
  [[ $p == $pat || $p == $pat/* ]]
}
# emit NAME...: print the command of every wanted suite once, in the order of the config's full list.
emit() {
  local want=" $* " n
  while IFS= read -r n; do [[ $want == *" $n "* ]] && jq -r --arg n "$n" '.commands[$n]' "$CONFIG"; done < <(jq -r '.full[]' "$CONFIG")
  return 0   # the loop's last test is false whenever the last suite is not wanted; that is not a failure
}
mapfile -t ALWAYS < <(jq -r '.always[]' "$CONFIG")
mapfile -t FULL < <(jq -r '.full[]' "$CONFIG")

if [ "$VERB" = full ]; then emit "${FULL[@]}"; exit 0; fi

command -v git >/dev/null || die 4 "git is required"
mb=$(git -C "$REPO" merge-base "$BASE" "$HEAD_REF" 2>/dev/null) || die 4 "no merge base of $BASE and $HEAD_REF in $REPO"
files=$(git -C "$REPO" diff --name-only --no-renames "$mb" "$HEAD_REF" 2>/dev/null) || die 4 "git diff of $BASE and $HEAD_REF failed"
# One jq call flattens the rows to "pattern<TAB>suite suite" lines, so a diff of any size is matched in bash alone.
mapfile -t PAIRS < <(jq -r '.rows[] | .suites as $s | .paths[] | "\(.)\t\($s | join(" "))"' "$CONFIG")
want=("${ALWAYS[@]}")
while IFS= read -r f; do
  [ -n "$f" ] || continue
  hit=0
  for pair in "${PAIRS[@]}"; do
    if matches "$f" "${pair%%$'\t'*}"; then hit=1; want+=("${pair#*$'\t'}"); fi
  done
  if [ "$hit" = 0 ]; then printf 'suites: %s matches no row: the full set\n' "$f" >&2; emit "${FULL[@]}"; exit 0; fi
done <<<"$files"
emit "${want[@]}"
