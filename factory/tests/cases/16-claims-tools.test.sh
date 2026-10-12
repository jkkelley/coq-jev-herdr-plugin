#!/usr/bin/env bash
# Catches (WO-20261012-0677): wo-start.sh running work-order.sh start past an overlap (AC-H1); gate.sh pr-files passing a stray path or
# an aggregate (AC-H2); two seats minting one doc number, in turn or at the same moment (AC-H4, PR 31 took SOP-0003 twice); new-sop.sh
# writing a SOP under a number it did not mint.
set -uo pipefail
SRC="${REPO_ROOT:-/repo}"
. "$SRC/herdr/tests/lib/assert.sh"
W="${COQ_CASE_WORK:-${WORK_ROOT:-/tmp}}/claims-tools"; R="$W/repo"; rm -rf "$W"; mkdir -p "$R/factory/bin" "$R/factory/config" "$R/bin" "$R/work-orders/EPIC" "$R/docs/sops"
cp "$SRC/factory/bin/claims.sh" "$SRC/factory/bin/gate.sh" "$R/factory/bin/"; cp "$SRC/factory/config/claims.json" "$R/factory/config/"; cp "$SRC/bin/mint-id.sh" "$SRC/bin/new-sop.sh" "$SRC/bin/wo-start.sh" "$R/bin/"
export COQ_ID_STATE="$W/ids"
git -C "$R" init -q -b main; git -C "$R" config user.email t@example.invalid; git -C "$R" config user.name t
printf -- '---\n{\n  "id": "WO-20261012-aaaa",\n  "status": "ready",\n  "branch": "feat/aaaa",\n  "files": ["herdr/bin/seat.sh", "docs/sops/*"]\n}\n---\n\n# body\n' > "$R/work-orders/EPIC/WO-20261012-aaaa-slug.md"
echo "# SOP-0001" > "$R/docs/sops/SOP-0001-first.md"; echo "# SOP-0002" > "$R/docs/sops/SOP-0002-second.md"; mkdir -p "$R/herdr/bin"; echo s > "$R/herdr/bin/seat.sh"
git -C "$R" add -A; git -C "$R" commit -q -m base; git -C "$R" update-ref refs/remotes/origin/main HEAD
echo '[{"number":31,"title":"p","headRefName":"feat/scoped","files":[{"path":"herdr/bin/seat.sh"},{"path":"docs/sops/SOP-0003-theirs.md"}]}]' > "$W/prs.json"; echo '[]' > "$W/none.json"

echo "-- AC-H1: wo-start.sh refuses past an overlap and never calls work-order.sh; it calls it when the files are free"
printf '#!/usr/bin/env bash\necho "$*" >> "%s/wo.log"\n' "$W" > "$W/wo-stub.sh"; : > "$W/wo.log"
out=$(WORK_ORDER_SH="$W/wo-stub.sh" COQ_CLAIMS_PRS_JSON="$W/prs.json" bash "$R/bin/wo-start.sh" --id WO-20261012-aaaa --project "$R" 2>&1); assert_eq "overlap with PR 31: exit 3" "$?" 3
assert_match "it names the PR and the file" "$out" "PR 31 .*changes herdr/bin/seat.sh"
assert_eq "work-order.sh was not called" "$(wc -l < "$W/wo.log" | tr -d ' ')" 0
out=$(WORK_ORDER_SH="$W/wo-stub.sh" COQ_CLAIMS_PRS_JSON="$W/none.json" bash "$R/bin/wo-start.sh" --id WO-20261012-aaaa --project "$R" --json 2>&1); assert_eq "free: exit 0" "$?" 0
assert_match "work-order.sh start got the id, the project and the passed flag" "$(cat "$W/wo.log")" "^start --project $R --id WO-20261012-aaaa --json$"

echo "-- AC-H2: gate.sh pr-files holds a stray path and an aggregate, one line, and passes a clean diff"
git -C "$R" checkout -q -b feat/aaaa; echo n > "$R/herdr/bin/seat.sh"; git -C "$R" commit -q -am ok
out=$(COQ_CLAIMS_PRS_JSON="$W/none.json" "$R/factory/bin/gate.sh" pr-files --ticket WO-20261012-aaaa --repo "$R"); assert_eq "clean diff: exit 0" "$?" 0
mkdir -p "$R/factory/config"; echo x > "$R/factory/config/routes.json"; echo agg > "$R/CHANGELOG.md"; git -C "$R" add -f -A; git -C "$R" commit -q -m stray
out=$(COQ_CLAIMS_PRS_JSON="$W/none.json" "$R/factory/bin/gate.sh" pr-files --ticket WO-20261012-aaaa --repo "$R"); assert_eq "stray path and aggregate: hold, exit 1" "$?" 1
assert_match "the stray path is named" "$out" "factory/config/routes.json is outside the files field"
assert_match "the aggregate is named" "$out" "CHANGELOG.md is an aggregate"
assert_eq "on one line" "$(wc -l <<<"$out" | tr -d ' ')" 1
"$R/factory/bin/gate.sh" pr-files --repo "$R" >/dev/null 2>&1; assert_eq "no --ticket: usage, exit 2" "$?" 2
git -C "$R" checkout -q main

echo "-- AC-H4: mint-id.sh takes the highest of the tree, main, the open PRs and the shared counter, and never repeats"
a=$(COQ_CLAIMS_PRS_JSON="$W/prs.json" bash "$R/bin/mint-id.sh" sop --repo "$R"); assert_eq "tree has 0002, PR 31 adds 0003: the next is SOP-0004" "$a" "SOP-0004"
b=$(COQ_CLAIMS_PRS_JSON="$W/prs.json" bash "$R/bin/mint-id.sh" sop --repo "$R"); assert_eq "asked again before any PR exists: SOP-0005, the counter remembers" "$b" "SOP-0005"
for i in 1 2 3 4; do (COQ_CLAIMS_PRS_JSON="$W/none.json" bash "$R/bin/mint-id.sh" sop --repo "$R" > "$W/par.$i") & done; wait
assert_eq "four seats at the same moment get four different numbers" "$(cat "$W"/par.? | sort -u | wc -l | tr -d ' ')" 4
adr=$(COQ_CLAIMS_PRS_JSON="$W/none.json" bash "$R/bin/mint-id.sh" adr --repo "$R"); assert_eq "the ADR series is its own: ADR-0001" "$adr" "ADR-0001"
bash "$R/bin/mint-id.sh" nope --repo "$R" >/dev/null 2>&1; assert_eq "an unknown series: usage, exit 2" "$?" 2

echo "-- new-sop.sh writes the SOP under the minted number, through the real docs.sh"
DOCS="$SRC/.claude/skills/living-docs/scripts/docs.sh"
if [ -f "$DOCS" ]; then
  id=$(DOCS_SH="$DOCS" COQ_CLAIMS_PRS_JSON="$W/prs.json" bash "$R/bin/new-sop.sh" --project "$R" --title "Two seats one number" --purpose p --when w --steps "1. s"); rc=$?
  assert_eq "exit 0" "$rc" 0
  n=$((10#${id#SOP-})); check "the id is above the tree, main and PR 31 (0003): got $id" "$([ "$n" -ge 4 ] && echo 1 || echo 0)"
  assert_file "the file is in the project, named by the id" "$(ls "$R"/docs/sops/"$id"-two-seats-one-number.md 2>/dev/null | head -1)"
  assert_match "the title line carries the minted id" "$(head -1 "$R"/docs/sops/"$id"-two-seats-one-number.md)" "^# $id: Two seats one number"
  check "no placeholder was left behind" "$([ -z "$(ls "$R"/docs/sops/*placeholder* 2>/dev/null)" ] && echo 1 || echo 0)"
else echo "  skip - no docs.sh in this checkout (the living-docs skill is synced, not tracked)"; fi
case_done
