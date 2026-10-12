#!/usr/bin/env bash
# Catches (WO-20261012-0677): a ticket started on a file an open PR already changes (AC-H1, PRs 25, 28, 29, 30, 31 on 2026-10-12); a PR
# whose diff strays outside its ticket's files field, or carries an aggregate (AC-H2); two PRs cut from one main that conflict in
# CHANGELOG.md when merged in either order (AC-H3); two PRs that each add SOP-0003 (AC-H4, PR 31); a ticket that declares no files
# starting anyway; a live ticket on a branch that main cannot see being missed.
set -uo pipefail
SRC="${REPO_ROOT:-/repo}"
. "$SRC/herdr/tests/lib/assert.sh"
W="${COQ_CASE_WORK:-${WORK_ROOT:-/tmp}}/claims"; R="$W/repo"; rm -rf "$W"; mkdir -p "$R/factory/bin" "$R/factory/config" "$R/bin" "$R/work-orders/EPIC" "$R/docs/sops"
cp "$SRC/factory/bin/claims.sh" "$R/factory/bin/"; cp "$SRC/factory/config/claims.json" "$R/factory/config/"; cp "$SRC/bin/changelog.sh" "$R/bin/"; cp "$SRC/.gitignore" "$R/"
C="$R/factory/bin/claims.sh"
git -C "$R" init -q -b main; git -C "$R" config user.email t@example.invalid; git -C "$R" config user.name t
ticket() { # ID STATUS BRANCH [files-json]
  printf -- '---\n{\n  "id": "%s",\n  "title": "t",\n  "status": "%s",\n  "branch": "%s"%s\n}\n---\n\n# body\n' "$1" "$2" "$3" "${4:+,
  \"files\": $4}" > "$R/work-orders/EPIC/$1-slug.md"; }
ticket WO-20261012-aaaa ready feat/aaaa; ticket WO-20261012-bbbb ready feat/bbbb
echo base > "$R/herdr-seat.txt"; mkdir -p "$R/herdr/bin" "$R/docs/sops"; echo s > "$R/herdr/bin/seat.sh"; echo "# SOP-0001" > "$R/docs/sops/SOP-0001-first.md"
git -C "$R" add -A; git -C "$R" commit -q -m base; git -C "$R" update-ref refs/remotes/origin/main HEAD

echo "-- set and get: the files field is written into the frontmatter and the body is untouched"
out=$($C set --id WO-20261012-aaaa --files 'herdr/bin' 'docs/sops/*' 'factory/bin/' --repo "$R"); assert_eq "set exits 0" "$?" 0
out=$($C get --id WO-20261012-aaaa --repo "$R"); assert_eq "get prints the three patterns" "$(tr '\n' ' ' <<<"$out")" "herdr/bin docs/sops/* factory/bin/ "
assert_eq "the body below the frontmatter is unchanged" "$(tail -n 2 "$R/work-orders/EPIC/WO-20261012-aaaa-slug.md" | tr '\n' ' ')" " # body "
out=$($C get --id WO-20261012-bbbb --repo "$R"); assert_eq "a ticket with no files: get exits 3" "$?" 3

echo "-- AC-H1: start refuses an overlap with an open PR and names the PR and the file"
PRS="$W/prs.json"
cat > "$PRS" <<'EOF'
[{"number":31,"title":"scoped guard","headRefName":"feat/scoped","files":[{"path":"herdr/bin/seat.sh"},{"path":"herdr/bin/monitors.sh"}]},
 {"number":40,"title":"unrelated","headRefName":"feat/unrelated","files":[{"path":"report/loop/x.sh"}]},
 {"number":41,"title":"this ticket's own","headRefName":"feat/aaaa","files":[{"path":"herdr/bin/seat.sh"}]}]
EOF
out=$(COQ_CLAIMS_PRS_JSON=$PRS $C start --id WO-20261012-aaaa --repo "$R"); assert_eq "overlap: exit 3" "$?" 3
assert_match "it names PR 31 and herdr/bin/seat.sh" "$out" "PR 31 .*changes herdr/bin/seat.sh"
assert_match "a bare directory claim catches monitors.sh under it" "$(COQ_CLAIMS_PRS_JSON=$PRS $C start --id WO-20261012-aaaa --repo "$R")" "PR 31 .*herdr/bin/monitors.sh"
out=$(COQ_CLAIMS_PRS_JSON=$PRS $C start --id WO-20261012-aaaa --repo "$R"); check "the PR on this ticket's own branch is not an overlap" "$([ -z "$(grep 'PR 41' <<<"$out")" ] && echo 1 || echo 0)"
check "an unrelated PR is not named" "$([ -z "$(grep 'PR 40' <<<"$out")" ] && echo 1 || echo 0)"
$C set --id WO-20261012-bbbb --files 'report/*.md' --repo "$R" >/dev/null
out=$(COQ_CLAIMS_PRS_JSON=$PRS $C start --id WO-20261012-bbbb --repo "$R"); assert_eq "no overlap: exit 0" "$?" 0
assert_eq "and nothing is printed" "$out" ""
ticket WO-20261012-cccc ready feat/cccc; out=$(COQ_CLAIMS_PRS_JSON=$PRS $C start --id WO-20261012-cccc --repo "$R"); assert_eq "a ticket with no files cannot start: exit 3" "$?" 3
assert_match "and the message says how to fix it" "$out" "declares no files: set them first"
out=$(PATH=/nonexistent:/usr/bin:/bin $C start --id WO-20261012-bbbb --repo "$R" 2>&1); check "gh unreachable is not a grant: exit 4 or 3" "$([ "$?" -ge 3 ] && echo 1 || echo 0)"

echo "-- a live ticket on a branch main cannot see: found through git worktree list"
git -C "$R" branch feat/live; git -C "$R" worktree add -q "$W/slot" feat/live
ticket WO-20261012-dddd in-progress feat/live '["herdr/bin/*", "report/x.md"]'; cp "$R/work-orders/EPIC/WO-20261012-dddd-slug.md" "$W/slot/work-orders/EPIC/"; rm "$R/work-orders/EPIC/WO-20261012-dddd-slug.md"
echo '[]' > "$W/none.json"
out=$(COQ_CLAIMS_PRS_JSON=$W/none.json $C start --id WO-20261012-aaaa --repo "$R"); assert_eq "overlap with a live ticket: exit 3" "$?" 3
assert_match "it names the ticket, its status and both patterns" "$out" "ticket WO-20261012-dddd \(in-progress\) claims herdr/bin/\*, which overlaps"
out=$(COQ_CLAIMS_PRS_JSON=$W/none.json $C start --id WO-20261012-bbbb --repo "$R"); assert_eq "report/*.md against report/x.md: glob overlap, exit 3" "$?" 3

echo "-- AC-H2: the gate refuses a diff outside the files field, and an aggregate, and names the path"
git -C "$R" add -A; git -C "$R" commit -q -m "tickets cut with their files"; git -C "$R" update-ref refs/remotes/origin/main HEAD
git -C "$R" checkout -q -b feat/aaaa
mkdir -p "$R/changelog/2026/10" "$R/events/2026/10" "$R/factory/bin"
echo x > "$R/herdr/bin/seat.sh"; echo e > "$R/changelog/2026/10/20261012-x.md"; echo '{}' > "$R/events/2026/10/e.json"; echo y > "$R/factory/bin/new.sh"
git -C "$R" add -A; git -C "$R" commit -q -m inscope
out=$($C diff --id WO-20261012-aaaa --repo "$R"); rc=$?; assert_eq "claimed directory, changelog entry, event record, claimed directory: exit 0 ($out)" "$rc" 0
echo z > "$R/herdr/layout.json"; mkdir -p "$R/herdr/config"; echo z > "$R/herdr/config/herdr.json"; git -C "$R" add -A; git -C "$R" commit -q -m stray
out=$($C diff --id WO-20261012-aaaa --repo "$R"); assert_eq "a path outside the field: exit 3" "$?" 3
assert_match "the path is named" "$out" "herdr/config/herdr.json is outside the files field of WO-20261012-aaaa"
git -C "$R" rm -q -f herdr/layout.json herdr/config/herdr.json; git -C "$R" commit -q -m unstray
echo agg > "$R/CHANGELOG.md"; git -C "$R" add -f CHANGELOG.md; git -C "$R" commit -q -m forceadd
out=$($C diff --id WO-20261012-aaaa --repo "$R"); assert_eq "a force-added aggregate: exit 3" "$?" 3
assert_match "CHANGELOG.md is named as an aggregate" "$out" "CHANGELOG.md is an aggregate"
git -C "$R" rm -q -f CHANGELOG.md; git -C "$R" commit -q -m unadd
out=$($C diff --id WO-20261012-aaaa --repo "$R"); rc=$?; assert_eq "gone again: exit 0 ($out)" "$rc" 0
git -C "$R" checkout -q -b chore/architect-records-1 main; echo r > "$R/anywhere.txt"; git -C "$R" add -A; git -C "$R" commit -q -m rec
$C diff --id WO-20261012-aaaa --repo "$R" >/dev/null; assert_eq "the architect records branch is exempt: exit 0" "$?" 0
git -C "$R" checkout -q feat/aaaa; $C diff --id WO-20261012-cccc --repo "$R" >/dev/null; assert_eq "a ticket with no files: the diff fails, exit 3" "$?" 3

echo "-- AC-H3: two PRs cut from one main, each with a changelog entry, merge in either order with no conflict"
git -C "$R" checkout -q main
for b in one two; do git -C "$R" checkout -q -b "feat/$b" main; (cd "$R" && bash bin/changelog.sh add --type feat --title "entry $b" >/dev/null); git -C "$R" add -A; git -C "$R" commit -q -m "$b"; git -C "$R" checkout -q main; done
check "CHANGELOG.md was rendered locally and is not tracked" "$([ -f "$R/CHANGELOG.md" ] && [ -z "$(git -C "$R" ls-files CHANGELOG.md)" ] && echo 1 || echo 0)"
git -C "$R" checkout -q -b m1 main; git -C "$R" merge -q --no-edit feat/one && git -C "$R" merge -q --no-edit feat/two; assert_eq "one then two: merges clean" "$?" 0
git -C "$R" checkout -q -b m2 main; git -C "$R" merge -q --no-edit feat/two && git -C "$R" merge -q --no-edit feat/one; assert_eq "two then one: merges clean" "$?" 0
git -C "$R" checkout -q main

echo "-- AC-H4: two PRs adding a SOP with the same number are caught; a number main already has is caught"
git -C "$R" checkout -q -b feat/sopa main; echo a > "$R/docs/sops/SOP-0002-a.md"; git -C "$R" add -A; git -C "$R" commit -q -m sopa
cat > "$W/sopprs.json" <<'EOF'
[{"number":31,"headRefName":"feat/sopb","files":[{"path":"docs/sops/SOP-0002-b.md"}]},{"number":32,"headRefName":"feat/sopa","files":[{"path":"docs/sops/SOP-0002-a.md"}]}]
EOF
out=$(COQ_CLAIMS_PRS_JSON=$W/sopprs.json $C ids --repo "$R"); assert_eq "SOP-0002 is in PR 31 too: exit 3" "$?" 3
assert_match "it names the number, the PR and the file" "$out" "SOP-0002 is taken by PR 31 adds docs/sops/SOP-0002-b.md"
git -C "$R" checkout -q -b feat/sopc main; echo c > "$R/docs/sops/SOP-0001-dup.md"; git -C "$R" add -A; git -C "$R" commit -q -m sopc
out=$(COQ_CLAIMS_PRS_JSON=$W/none.json $C ids --repo "$R"); assert_eq "SOP-0001 is already on main: exit 3" "$?" 3
assert_match "it says so" "$out" "SOP-0001 is already taken on"
git -C "$R" checkout -q -b feat/sopd main; echo d > "$R/docs/sops/SOP-0003-d.md"; git -C "$R" add -A; git -C "$R" commit -q -m sopd
COQ_CLAIMS_PRS_JSON=$W/sopprs.json $C ids --repo "$R" >/dev/null; assert_eq "a free number: exit 0" "$?" 0
case_done
