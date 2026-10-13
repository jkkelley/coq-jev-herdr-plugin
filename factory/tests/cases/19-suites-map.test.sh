#!/usr/bin/env bash
# Catches (WO-20261013-f1ff): a path-to-suite map that maps a path to the suite under it and no further. 32fc429 changed events/bin and broke the
# factory suite, which a per-directory map would not have run (architect ruling b99ta, record 7c3dq). AC-H1: a change to events/bin/event.sh or
# events/schema plans the events, factory and herdr suites (and line, whose merge.sh calls event.sh), and dropping one from the row fails this
# case. AC-H2: a changelog-only diff plans lint and reindex only, a tickets or graph diff also plans herdr case 12 and not the whole herdr suite (architect ruling 18:24Z on PR 109: case 12's blueprint server reads them, nothing else in herdr does), a path no row maps plans the full set, a missing key exits 3. Also: a command in
# the map that does not exist, a suite on disk that no command runs, and the plan depending on the order git lists the files.
set -uo pipefail
SRC="${REPO_ROOT:-/repo}"
. "$SRC/herdr/tests/lib/assert.sh"
W="${COQ_CASE_WORK:-${WORK_ROOT:-/tmp}}/suites"; R="$W/repo"; rm -rf "$W"; mkdir -p "$R" "$W/tool/factory/bin" "$W/tool/factory/config"
# The script and its config sit beside the repository, not in it, so a case can rewrite the config without dirtying the tree it diffs.
cp "$SRC/factory/bin/suites.sh" "$W/tool/factory/bin/"; cp "$SRC/factory/config/suites.json" "$W/tool/factory/config/"
S="$W/tool/factory/bin/suites.sh"; CFG="$W/tool/factory/config/suites.json"
git -C "$R" init -q -b main; git -C "$R" config user.email t@example.invalid; git -C "$R" config user.name t
mkdir -p "$R/events/bin" "$R/work-orders/EPIC"; echo e > "$R/events/bin/event.sh"; echo t > "$R/work-orders/EPIC/WO-20261013-aaaa-t.md"
git -C "$R" add -A; git -C "$R" commit -q -m base

# The commands, read from the config so the case follows a renamed command and still pins which suite each row names.
cmd() { jq -r --arg n "$1" '.commands[$n]' "$SRC/factory/config/suites.json"; }
LINT=$(cmd lint); REINDEX=$(cmd reindex); EVENTS=$(cmd events); FACTORY=$(cmd factory); HERDR=$(cmd herdr); LINE=$(cmd line)
BEARINGS=$(cmd bearings); LOOP=$(cmd loop); SCHED=$(cmd scheduler); SCHEDHOST=$(cmd scheduler-host)
has() { grep -qxF -- "$2" <<<"$1" && echo 1 || echo 0; }          # OUT COMMAND: the command is a whole line of OUT
n_lines() { [ -z "$1" ] && echo 0 || grep -c '' <<<"$1"; }
# plan FILE...: a commit on a branch off main that adds or changes those files; sets OUT, ERR and RC from `suites.sh plan` against main.
plan() {
  git -C "$R" checkout -q -B t main
  local f; for f in "$@"; do mkdir -p "$R/$(dirname "$f")"; echo "$f $RANDOM" >> "$R/$f"; done
  git -C "$R" add -A; git -C "$R" commit -q -m t
  OUT=$("$S" plan --base main --head HEAD --repo "$R" 2>"$W/err"); RC=$?; ERR=$(cat "$W/err")
}

echo "-- AC-H1: events/bin/event.sh plans the events, factory, herdr and line suites; so does events/schema"
plan events/bin/event.sh; assert_eq "exit 0" "$RC" 0
check "events suite planned" "$(has "$OUT" "$EVENTS")"; check "factory suite planned" "$(has "$OUT" "$FACTORY")"
check "herdr suite planned" "$(has "$OUT" "$HERDR")"; check "line suite planned (merge.sh calls event.sh)" "$(has "$OUT" "$LINE")"
check "lint is planned too" "$(has "$OUT" "$LINT")"
check "the suites of the other trees are not" "$([ "$(has "$OUT" "$BEARINGS")$(has "$OUT" "$LOOP")$(has "$OUT" "$REINDEX")" = 000 ] && echo 1 || echo 0)"
plan events/schema/event.schema.json
check "events/schema plans events, factory and herdr" "$([ "$(has "$OUT" "$EVENTS")$(has "$OUT" "$FACTORY")$(has "$OUT" "$HERDR")" = 111 ] && echo 1 || echo 0)"
plan events/tests/cases/02-add.test.sh
check "the events suite's own case plans events and not herdr" "$([ "$(has "$OUT" "$EVENTS")$(has "$OUT" "$HERDR")" = 10 ] && echo 1 || echo 0)"

echo "-- AC-H1: the case fails if a suite is dropped from the row (the assertion above is not vacuous)"
cp "$CFG" "$W/full.json"; jq '(.rows[] | select(.paths | index("events/bin/*")) | .suites) -= ["herdr"]' "$W/full.json" > "$CFG"
plan events/bin/event.sh
assert_eq "with herdr dropped from the events/bin row the plan lacks herdr" "$(has "$OUT" "$HERDR")" 0
check "which is the failure the three checks above would report" "$([ "$(has "$OUT" "$EVENTS")$(has "$OUT" "$FACTORY")" = 11 ] && echo 1 || echo 0)"
cp "$W/full.json" "$CFG"

echo "-- the shared state root and the shared assert library reach every suite that loads them"
plan bin/state-root.sh
check "state-root.sh plans events, factory, herdr, line, bearings and loop" "$([ "$(has "$OUT" "$EVENTS")$(has "$OUT" "$FACTORY")$(has "$OUT" "$HERDR")$(has "$OUT" "$LINE")$(has "$OUT" "$BEARINGS")$(has "$OUT" "$LOOP")" = 111111 ] && echo 1 || echo 0)"
plan herdr/tests/lib/assert.sh
check "assert.sh plans herdr, events, factory and line" "$([ "$(has "$OUT" "$HERDR")$(has "$OUT" "$EVENTS")$(has "$OUT" "$FACTORY")$(has "$OUT" "$LINE")" = 1111 ] && echo 1 || echo 0)"
plan factory/bin/gate.sh
check "gate.sh plans factory, herdr and line" "$([ "$(has "$OUT" "$FACTORY")$(has "$OUT" "$HERDR")$(has "$OUT" "$LINE")" = 111 ] && echo 1 || echo 0)"
plan scheduler/internal/core/x.go
assert_eq "a scheduler Go change plans lint and the Go suite only" "$(tr '\n' '|' <<<"$OUT")" "$LINT|$SCHED|"
plan scheduler/host/bin/run.sh
assert_eq "a scheduler host change plans lint and the host suite only (make -C scheduler test does not run it)" "$(tr '\n' '|' <<<"$OUT")" "$LINT|$SCHEDHOST|"
plan scheduler/config/scheduler.json
check "scheduler config plans both scheduler suites (host/lib/config.sh reads it)" "$([ "$(has "$OUT" "$SCHED")$(has "$OUT" "$SCHEDHOST")" = 11 ] && echo 1 || echo 0)"

echo "-- AC-H2: a changelog-only diff plans lint and reindex and nothing else"
plan changelog/2026/10/20261013-x.md
assert_eq "exit 0" "$RC" 0
assert_eq "exactly lint then reindex" "$(tr '\n' '|' <<<"$OUT")" "$LINT|$REINDEX|"
assert_eq "no complaint on stderr" "$ERR" ""

echo "-- the blueprint dev server reads graph/ and work-orders/, so herdr case 12 runs for them and the rest of herdr does not (architect ruling 18:24Z)"
CASE12=$(jq -r '.case_commands.herdr | sub("{cases}"; "12")' "$SRC/factory/config/suites.json")
assert_eq "the case command is the herdr runner limited to case 12" "$CASE12" "CASES=12 bash herdr/tests/run.sh"
plan work-orders/EPIC/WO-20261013-aaaa-t.md work-orders/archive/y.md
assert_eq "a tickets-only diff plans lint, reindex and herdr case 12" "$(tr '\n' '|' <<<"$OUT")" "$LINT|$REINDEX|$CASE12|"
assert_eq "and not the whole herdr suite" "$(has "$OUT" "$HERDR")" 0
plan graph/nodes/n.json
assert_eq "a graph/ diff plans lint, herdr case 12 and loop" "$(sort <<<"$OUT" | tr '\n' '|')" "$(printf '%s\n' "$LINT" "$CASE12" "$LOOP" | sort | tr '\n' '|')"
assert_eq "and not the whole herdr suite" "$(has "$OUT" "$HERDR")" 0
plan work-orders/EPIC/WO-20261013-aaaa-t.md herdr/bin/seat.sh
check "a ticket plus a herdr/ change plans the whole herdr suite" "$(has "$OUT" "$HERDR")"
assert_eq "and the case line is not printed beside it" "$(has "$OUT" "$CASE12")" 0
cp "$CFG" "$W/full.json"
jq '(.rows[] | select(.paths | index("graph/*"))) |= (.suites += ["herdr"] | del(.cases))' "$W/full.json" > "$CFG"
plan graph/nodes/n.json
check "the case FAILS the row if graph/ maps to the whole herdr suite (the check above is not vacuous)" "$(has "$OUT" "$HERDR")"
jq '(.rows[] | select(.paths | index("work-orders/*"))) |= (.suites += ["herdr"] | del(.cases))' "$W/full.json" > "$CFG"
plan work-orders/EPIC/WO-20261013-aaaa-t.md
check "and the same for work-orders/ mapped to the whole herdr suite" "$(has "$OUT" "$HERDR")"
jq '(.rows[] | select(.paths | index("graph/*")) | .cases) = {}' "$W/full.json" > "$CFG"
plan graph/nodes/n.json
assert_eq "with the cases dropped from the graph/ row the plan has no herdr line at all" "$(has "$OUT" "$HERDR")$(has "$OUT" "$CASE12")" 00
jq '(.rows[] | select(.paths | index("work-orders/*")) | .cases.herdr) = ["12", "14"]' "$W/full.json" > "$CFG"
plan work-orders/EPIC/WO-20261013-aaaa-t.md
assert_eq "two cases print as one quoted CASES list" "$(sed -n 3p <<<"$OUT")" 'CASES="12 14" bash herdr/tests/run.sh'
cp "$W/full.json" "$CFG"
jq '.rows[0].cases = {"nonesuch": ["1"]}' "$W/full.json" > "$W/bad.json"; out=$("$S" full --config "$W/bad.json" 2>&1); assert_eq "cases of a suite with no case_commands entry: exit 3" "$?" 3
assert_match "and the message names the suite" "$out" "nonesuch"
jq '.rows[0].cases = {"herdr": []}' "$W/full.json" > "$W/bad.json"; "$S" full --config "$W/bad.json" >/dev/null 2>&1; assert_eq "an empty case list: exit 3" "$?" 3
jq '.rows[0].cases = {"herdr": ["1; rm -rf /"]}' "$W/full.json" > "$W/bad.json"; "$S" full --config "$W/bad.json" >/dev/null 2>&1; assert_eq "a case id with shell metacharacters: exit 3" "$?" 3

echo "-- AC-H2: a path no row maps plans the full set, and the message names the path"
plan Jenkinsfile; assert_eq "exit 0" "$RC" 0
assert_eq "the plan is the full set" "$OUT" "$("$S" full --repo "$R")"
assert_eq "the full set is every command in the map" "$(n_lines "$OUT")" "$(jq '.full | length' "$CFG")"
assert_match "stderr names the unmapped path" "$ERR" "Jenkinsfile matches no row"
plan work-orders/EPIC/x.md Jenkinsfile
assert_eq "one unmapped path among mapped ones still plans the full set" "$OUT" "$("$S" full --repo "$R")"

echo "-- an empty diff plans the always set; the order of the files does not change the plan"
git -C "$R" checkout -q -B t main; OUT=$("$S" plan --base main --head HEAD --repo "$R"); assert_eq "an empty diff plans lint only" "$OUT" "$LINT"
plan herdr/bin/seat.sh events/bin/event.sh; a=$OUT
plan events/bin/event.sh herdr/bin/seat.sh; assert_eq "the same plan whichever file comes first" "$OUT" "$a"
assert_eq "and lint comes before the suites, as in the map's full list" "$(head -n 1 <<<"$OUT")" "$LINT"
git -C "$R" checkout -q -B t main; mkdir -p "$R/docs"; git -C "$R" mv events/bin/event.sh docs/event.sh; git -C "$R" commit -q -m mv
OUT=$("$S" plan --base main --head HEAD --repo "$R")
check "a file moved out of events/bin into docs/ still plans events (the old path counts)" "$(has "$OUT" "$EVENTS")"
check "and its new path adds nothing beyond lint (docs/ needs lint only)" "$([ "$(has "$OUT" "$BEARINGS")$(has "$OUT" "$LOOP")$(has "$OUT" "$REINDEX")" = 000 ] && echo 1 || echo 0)"

echo "-- AC-H2: a missing key exits 3 and names the key"
for k in commands always full rows; do
  jq --arg k "$k" 'del(.[$k])' "$W/full.json" > "$W/bad.json"; out=$("$S" plan --base main --head HEAD --repo "$R" --config "$W/bad.json" 2>&1); rc=$?
  assert_eq "no $k: exit 3" "$rc" 3; assert_match "no $k: the message names the key" "$out" "no key $k"
done
jq '.rows[0].suites += ["nonesuch"]' "$W/full.json" > "$W/bad.json"; out=$("$S" full --config "$W/bad.json" 2>&1); assert_eq "a suite with no command: exit 3" "$?" 3
assert_match "and the message names it" "$out" "nonesuch"
jq '.rows[0].paths = [""]' "$W/full.json" > "$W/bad.json"; "$S" full --config "$W/bad.json" >/dev/null 2>&1; assert_eq "an empty path pattern: exit 3" "$?" 3
jq '.rows[0].paths = ["/etc/passwd"]' "$W/full.json" > "$W/bad.json"; "$S" full --config "$W/bad.json" >/dev/null 2>&1; assert_eq "an absolute path pattern: exit 3" "$?" 3
jq '.rows[0].paths = ["a/../b"]' "$W/full.json" > "$W/bad.json"; "$S" full --config "$W/bad.json" >/dev/null 2>&1; assert_eq "a .. segment: exit 3" "$?" 3
echo '{' > "$W/bad.json"; "$S" full --config "$W/bad.json" >/dev/null 2>&1; assert_eq "a config that is not JSON: exit 3" "$?" 3

echo "-- usage and io codes"
"$S" >/dev/null 2>&1; assert_eq "no verb: exit 2" "$?" 2
"$S" plan --nonsense >/dev/null 2>&1; assert_eq "an unknown flag: exit 2" "$?" 2
"$S" plan --base no-such-ref --head HEAD --repo "$R" >/dev/null 2>&1; assert_eq "a ref that does not resolve: exit 4" "$?" 4
"$S" full --config "$W/nonesuch.json" >/dev/null 2>&1; assert_eq "no config file: exit 4" "$?" 4

echo "-- every command in the map exists, and every suite on disk has a command"
bad=""
while IFS= read -r c; do
  case $c in
    "make lint") grep -q '^lint:' "$SRC/Makefile" || bad="$bad [$c: no lint target]";;
    "make -C "*" test") d=${c#make -C }; d=${d% test}; grep -q '^test:' "$SRC/$d/Makefile" 2>/dev/null || bad="$bad [$c: no test target in $d/Makefile]";;
    "bash "*) f=${c#bash }; f=${f%% *}
      # The work-order skill copy is managed and gitignored (Makefile aggregates, bin/aggregates.sh): checked when this checkout has it.
      if [ -f "$SRC/$f" ] || [[ $f == .claude/skills/* ]]; then :; else bad="$bad [$c: no file $f]"; fi;;
    *) bad="$bad [$c: not a form this case knows]";;
  esac
done < <(jq -r '.commands[]' "$SRC/factory/config/suites.json")
assert_eq "no command names something that does not exist" "$bad" ""
missing=""
while IFS= read -r d; do
  d=${d#"$SRC"/}; d=${d%/Makefile}; d=${d%/tests/run.sh}
  { [ -n "$d" ] && [ "$d" != Makefile ]; } || continue
  jq -r '.commands[]' "$SRC/factory/config/suites.json" | grep -qE -- "(-C $d test|bash $d/tests/run.sh)" || missing="$missing $d"
done < <({ find "$SRC" -maxdepth 4 -name Makefile -not -path '*/node_modules/*' -not -path '*/.claude/*' -exec grep -l '^test:' {} +; find "$SRC" -maxdepth 4 -path '*/tests/run.sh' -not -path '*/.claude/*'; } | sort -u)
assert_eq "no suite on disk is missing from the map's commands" "$missing" ""
check "every suite a command names is in the full set" "$([ -z "$(jq -r '.commands | keys[]' "$SRC/factory/config/suites.json" | while read -r k; do jq -e --arg k "$k" '.full | index($k)' "$SRC/factory/config/suites.json" >/dev/null || echo "$k"; done)" ] && echo 1 || echo 0)"
case_done
