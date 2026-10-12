#!/usr/bin/env bash
# Catches: a script answering "where does runtime data live" on its own (WO-20261012-7e13 AC-H4), a COQ_STATE or COQ_CACHE that does not win,
# a relative path guessed at, and a slot of one repository resolving to its own root instead of the repository's.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "${REPO_ROOT:-/repo}/herdr/tests/lib/assert.sh"; . "$HERE/../lib/world.sh"
world_up resolver

echo "-- defaults come from the XDG homes and the repository name"
assert_eq "state default" "$("$SR" state)" "$W/home/.local/state/coq/repo"
assert_eq "cache default" "$("$SR" cache)" "$W/home/.cache/coq/repo"
assert_eq "the records tree" "$("$SR" tree records)" "$W/home/.local/state/coq/repo/records"
assert_eq "the routed ledger tree is the name the config gives it" "$("$SR" tree ledger)" "$W/home/.local/state/coq/repo/ledger/routed"
assert_eq "name_max is read from the config" "$("$SR" get name_max)" 55
assert_eq "no argument prints the roots and the repository" "$("$SR" | tr '\n' ' ')" "state $W/home/.local/state/coq/repo cache $W/home/.cache/coq/repo repo repo "
assert_eq "--json is an object with the same three" "$("$SR" --json | jq -c .)" "{\"state\":\"$W/home/.local/state/coq/repo\",\"cache\":\"$W/home/.cache/coq/repo\",\"repo\":\"repo\"}"

echo "-- with no XDG variable the home fallback in the config is used"
assert_eq "state under HOME/.local/state" "$(env -u XDG_STATE_HOME "$SR" state)" "$W/home/.local/state/coq/repo"
assert_eq "cache under HOME/.cache" "$(env -u XDG_CACHE_HOME "$SR" cache)" "$W/home/.cache/coq/repo"
assert_eq "a relative XDG variable is ignored, as the XDG specification says" "$(XDG_STATE_HOME=relative/dir "$SR" state)" "$W/home/.local/state/coq/repo"

echo "-- COQ_STATE and COQ_CACHE win, and COQ_REPO names the repository"
assert_eq "COQ_STATE" "$(COQ_STATE="$W/s" "$SR" state)" "$W/s"
assert_eq "a trailing slash is dropped" "$(COQ_STATE="$W/s/" "$SR" state)" "$W/s"
assert_eq "COQ_CACHE" "$(COQ_CACHE="$W/c" "$SR" cache)" "$W/c"
assert_eq "COQ_STATE moves the trees with it" "$(COQ_STATE="$W/s" "$SR" tree logs)" "$W/s/logs"
assert_eq "COQ_REPO's basename is the repository" "$(COQ_REPO=/somewhere/else/my-repo "$SR" state)" "$W/home/.local/state/coq/my-repo"

echo "-- every treehouse slot of one repository resolves to one root"
# A stub git answers the one question the resolver asks, with the common directory of the main checkout, as `git worktree` does for a
# slot: the answer is the main checkout's .git whichever slot asks. The lint image has no git, and the rule is what is under test.
printf '#!/usr/bin/env bash\ncase "$*" in *--git-common-dir*) echo /srv/checkouts/the-repo/.git ;; *) exit 1 ;; esac\n' > "$W/bin/git"; chmod +x "$W/bin/git"
assert_eq "the parent of the git common directory names the repository" "$("$SR" state)" "$W/home/.local/state/coq/the-repo"
assert_eq "COQ_REPO still wins over it" "$(COQ_REPO=/x/explicit "$SR" state)" "$W/home/.local/state/coq/explicit"
printf '#!/usr/bin/env bash\nexit 128\n' > "$W/bin/git"
assert_eq "not a git checkout: the directory name is used" "$("$SR" state)" "$W/home/.local/state/coq/repo"
rm "$W/bin/git"

echo "-- bad input is refused with the documented exit codes"
COQ_STATE=relative "$SR" state >/dev/null 2>"$W/err"; assert_eq "relative COQ_STATE exit" "$?" 3
assert_match "it says why" "$(cat "$W/err")" "COQ_STATE must be an absolute path"
"$SR" tree nope >/dev/null 2>"$W/err"; assert_eq "unknown tree exit" "$?" 3
"$SR" tree >/dev/null 2>"$W/err"; assert_eq "tree with no name exit" "$?" 2
"$SR" get >/dev/null 2>"$W/err"; assert_eq "get with no key exit" "$?" 2
"$SR" bogus >/dev/null 2>"$W/err"; assert_eq "unknown verb exit" "$?" 2
env -u HOME -u XDG_STATE_HOME "$SR" state >/dev/null 2>"$W/err"; assert_eq "no HOME and no XDG exit" "$?" 4

echo "-- AC-H4: a default is the config's, so changing the config changes it"
jq '.state.namespace = "other" | .state.home_fallback = "st" | .name_max = 40 | .trees.records = "rec"' "$R/config/state.json" > "$W/s.json" && mv "$W/s.json" "$R/config/state.json"
assert_eq "namespace and fallback from the file" "$(env -u XDG_STATE_HOME "$SR" state)" "$W/home/st/other/repo"
assert_eq "tree name from the file" "$(env -u XDG_STATE_HOME "$SR" tree records)" "$W/home/st/other/repo/rec"
assert_eq "name_max from the file" "$("$SR" get name_max)" 40
rm "$R/config/state.json"; "$SR" state >/dev/null 2>"$W/err"; assert_eq "a missing config is an io error, not a guess" "$?" 4

echo "-- AC-H4: no script carries a default of its own"
src="${REPO_ROOT:-/repo}"
for f in "$src/bin/state-root.sh" "$src/events/bin/event.sh"; do
  code=$(grep -v '^[[:space:]]*#' "$f")
  for needle in '.local/state' '.cache' '/coq/' 'XDG_STATE_HOME' 'XDG_CACHE_HOME' 'COQ_STATE' 'COQ_CACHE'; do
    check "$(basename "$f") has no '$needle' outside comments" "$(printf '%s' "$code" | grep -qF -- "$needle" && echo 0 || echo 1)"
  done
done
python3 -c 'import json,jsonschema,sys; jsonschema.validate(json.load(open(sys.argv[1])), json.load(open(sys.argv[2])))' "$src/config/state.json" "$src/config/state.schema.json" 2>/dev/null; assert_eq "config/state.json validates against its schema" "$?" 0
case_done
