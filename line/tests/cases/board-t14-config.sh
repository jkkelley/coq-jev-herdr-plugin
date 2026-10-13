#!/usr/bin/env bash
# T14 config (SPEC-17 s-tests; AC-H3 of WO-20261013-f268): a missing key or a literal path fails the board verbs with exit 3 naming the key.
# Every required key of line/config/board.schema.json is removed in turn, so a key added to the schema is tested without editing this case.
set -uo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
. "$HERE/../lib/assert.sh"; . "$HERE/../lib/world.sh"; world_init

echo "-- the shipped config passes"
board check >/dev/null 2>&1; assert_eq "check exits 0" "$?" 0

echo "-- every required key, removed, is exit 3 naming that key (on check and on health)"
while IFS= read -r k; do
  jq --arg k "$k" 'del(.[$k])' "$REPO/line/config/board.json" > "$BOARD_CONFIG"
  for v in check health; do
    err=$(board "$v" 2>&1 >/dev/null); rc=$?
    assert_eq "$v without $k: exit 3" "$rc" 3
    assert_match "$v names $k" "$err" "config key $k missing"
  done
done < <(jq -r '.required[]' "$REPO/line/config/board.schema.json")

echo "-- a literal path is exit 3 naming the key"
for k in state_root board_dir done_dir health_file nudge_dir halt_flag drain_flag; do
  cfg_reset; cfg_set "$k" '"/var/lib/literal"'
  err=$(board check 2>&1 >/dev/null); rc=$?
  assert_eq "a literal $k: exit 3" "$rc" 3
  assert_match "it names $k" "$err" "config key $k holds a literal path"
done
cfg_reset; cfg_set lanes '["tester", "/etc/lane"]'
err=$(board check 2>&1 >/dev/null); assert_eq "a path hiding in lanes: exit 3" "$?" 3; assert_match "it names lanes" "$err" "config key lanes holds a literal path"
cfg_reset; cfg_set board_dir '"~/board"'
err=$(board check 2>&1 >/dev/null); assert_eq "a home path: exit 3" "$?" 3; assert_match "it names board_dir" "$err" "config key board_dir"

echo "-- a wrong type, an unknown key, an unknown variable, a bad default"
cfg_reset; cfg_set lease_seconds '"soon"'
err=$(board check 2>&1 >/dev/null); assert_eq "a string lease_seconds: exit 3" "$?" 3; assert_match "it names lease_seconds" "$err" "config key lease_seconds"
cfg_reset; cfg_set surprise '1'
err=$(board check 2>&1 >/dev/null); assert_eq "an unknown key: exit 3" "$?" 3; assert_match "it names surprise" "$err" "config key surprise"
cfg_reset; cfg_set board_dir '"${nowhere}/board"'
err=$(board check 2>&1 >/dev/null); assert_eq "an unknown variable: exit 3" "$?" 3; assert_match "it names board_dir" "$err" "config key board_dir"
cfg_reset; cfg_set default_priority '"p9"'
err=$(board check 2>&1 >/dev/null); assert_eq "a default priority outside priorities: exit 3" "$?" 3; assert_match "it names default_priority" "$err" "config key default_priority"

echo "-- check also reads the items: a renamed item is a mismatch, a stray claim is reported"
cfg_reset; A=$(rid 1); board post --id "$A" --lane tester --kind note --code 100 >/dev/null
mv "$W/state/board/tester/p2-$A.json" "$W/state/board/tester/p0-$A.json"
err=$(board check 2>&1 >/dev/null); assert_eq "name and content disagree: exit 3" "$?" 3; assert_match "it names the file" "$err" "name/content mismatch"
mv "$W/state/board/tester/p0-$A.json" "$W/state/board/tester/p2-$A.json"; board check >/dev/null 2>&1; assert_eq "put back: exit 0" "$?" 0
mv "$W/state/board/tester/p2-$A.json" "$W/state/board/tester/p2-$A.json.claim.1.2"   # a caller that crashed between the claim and the put
err=$(board check 2>&1 >/dev/null); assert_eq "a claim left behind: exit 3" "$?" 3; assert_match "it says so" "$err" "claim left behind"
sweep=$(board sweep); assert_match "sweep restores the stale claim" "$sweep" "restored stale claim"
board check >/dev/null 2>&1; assert_eq "and check passes again" "$?" 0
case_done
