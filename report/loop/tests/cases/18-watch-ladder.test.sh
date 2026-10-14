#!/usr/bin/env bash
# 18 - the watch ladder (WO-20261013-10d8, cause ad): 3 failed passes in a row post one 500 and end the watch, and the board age check pages when data.json is stale.
# AC-H1: a watch whose collect fails 3 passes in a row posts one 500 record and exits non-zero; one failed pass then a good pass posts nothing;
#        the age check flags a data.json older than 2 minutes, once per stale spell, and says nothing while it is fresh.
# World: case 07's (a broken routes table is the failing collect). A stub `sleep` first on PATH is the seam that changes the world between
# passes: loop.sh calls `sleep` once between passes, and the stub applies the next word of $W/plan (bad or good routes table) instead of waiting.
. "$(dirname "$0")/../lib/assert.sh"
. "$(dirname "$0")/../lib/world.sh"
world_init
OUT="$W/out"
T=WO-20261013-0018; S=worker-wo-20261013-0018
ticket "$T" in-progress feat/ladder null "Climb the ladder"
ev 2026-10-13T14:00:00Z "$S" seat.up 100 "$T" wD3:p5 "up"
panes "$S=wD3:p5"
belt 100

ROUTES=$ROOT_FIX/factory/config/routes.json
GOOD=$W/routes.good; cp "$ROUTES" "$GOOD"
mkdir -p "$W/bin"
cat > "$W/bin/sleep" <<STUB
#!/usr/bin/env bash
# the seam: pop the next word of the plan and make the routes table good or bad for the next pass
w=\$(head -n 1 "$W/plan" 2>/dev/null); sed -i 1d "$W/plan" 2>/dev/null
case \$w in bad) echo '{ not json' > "$ROUTES" ;; good) cp "$GOOD" "$ROUTES" ;; esac
STUB
chmod +x "$W/bin/sleep"

# watch PLAN [ARGS]: the world starts with the first word's table; each sleep applies the next word. 0 iterations never stops by itself.
watch() {
  local plan=$1; shift
  printf '%s\n' $plan > "$W/plan"; local first; first=$(head -n 1 "$W/plan"); sed -i 1d "$W/plan"
  if [ "$first" = bad ]; then echo '{ not json' > "$ROUTES"; else cp "$GOOD" "$ROUTES"; fi
  PATH="$W/bin:$PATH" timeout 60 env LOOP_ROOT="$ROOT_FIX" LOOP_CONFIG="$W/board.json" "$LOOP" watch --out "$OUT" --root "$ROOT_FIX" --now 2026-10-13T15:00:00Z --panes "$W/panes.json" --sleep 0 "$@"
}
# recs: every 500 record in the world's state root, as one JSON array
recs() { find "$W/state/records" -name '*.json' -exec cat {} + 2>/dev/null | jq -s '[.[] | select(.code == 500)]'; }
reset_recs() { find "$W/state/records" -name '*.json' -path '*-note-*' -delete 2>/dev/null; }

# Three failed passes in a row, run until stopped (the way the monitor runs it): it posts one 500 and ends.
reset_recs
expect_exit 4 "three failed passes in a row end an unbounded watch with a non-zero exit" watch "bad bad bad bad bad" --iterations 0
eq "and exactly one 500 record was posted" "1" "$(recs | jq length)"
eq "addressed to the architect" "architect" "$(recs | jq -r '.[0].to')"
eq "from the board watch seat" "board-watch" "$(recs | jq -r '.[0].seat')"
eq "on the third pass, not before" "3" "$(grep -c 'failed (4)' "$W/.out")"
eq "naming the failed passes and the last error" "1" "$(recs | jq '.[0].note | (test("3 failed passes")) and (test("routes"))' | grep -c true)"

# One failed pass, then a good one: nothing is posted, the count starts again, and two more failures still do not reach 3.
reset_recs; rm -rf "$OUT"
expect_exit 4 "fail, pass, fail, fail is a finite run that ends on the last pass's failure" watch "bad good bad bad" --iterations 4
eq "two failures after a good pass are not three in a row: no record" "0" "$(recs | jq length)"
reset_recs; rm -rf "$OUT"
t "a single failed pass followed by good passes exits 0" watch "bad good good" --iterations 3
eq "and posts nothing" "0" "$(recs | jq length)"
eq "and the page was built by the good pass" "1" "$(jq .number "$OUT/data.json")"

# fail fail pass fail fail fail: the pass in the middle resets the count, so the post comes on the sixth pass.
reset_recs; rm -rf "$OUT"
expect_exit 4 "fail, fail, pass, fail, fail, fail ends on the sixth pass" watch "bad bad good bad bad bad" --iterations 0
eq "one record, not two" "1" "$(recs | jq length)"
eq "after six passes" "6" "$(grep -c 'watch: .* pass [0-9]* failed\|watch: .* build [0-9]* written' "$W/.out" | tr -d ' ')"

# --- the age check ---
# age [ARGS]: loop.sh age at the fixed NOW against $OUT, with the world's state root
age() { LOOP_ROOT="$ROOT_FIX" LOOP_CONFIG="$W/board.json" "$LOOP" age --out "$OUT" --now 2026-10-13T15:00:00Z "$@"; }
NOWE=$(date -u -d 2026-10-13T15:00:00Z +%s)
mkdir -p "$OUT"; echo '{}' > "$OUT/data.json"
reset_recs
touch -d "@$((NOWE - 30))" "$OUT/data.json"
expect_exit 0 "a data.json 30 seconds old is fresh" age
eq "and posts nothing" "0" "$(recs | jq length)"
touch -d "@$((NOWE - 119))" "$OUT/data.json"
expect_exit 0 "119 seconds is still inside the 2 minute limit" age
touch -d "@$((NOWE - 200))" "$OUT/data.json"
expect_exit 1 "a data.json 200 seconds old is stale" age
eq "and pages with one 500 record" "1" "$(recs | jq length)"
eq "addressed to the orchestrator" "orchestrator" "$(recs | jq -r '.[0].to')"
eq "naming the age and the limit" "1" "$(recs | jq '.[0].note | (test("200")) and (test("120"))' | grep -c true)"
expect_exit 1 "the next tick of the same stale spell is still stale" age
eq "but pages only once" "1" "$(recs | jq length)"
touch -d "@$((NOWE - 5))" "$OUT/data.json"
expect_exit 0 "the board moving again is fresh" age
touch -d "@$((NOWE - 300))" "$OUT/data.json"
expect_exit 1 "and a new stale spell is stale" age
eq "and pages again" "2" "$(recs | jq length)"
rm -f "$OUT/data.json"
expect_exit 1 "no data.json at all is stale" age
touch -d "@$((NOWE - 150))" "$OUT/data.json"
expect_exit 0 "a wider --max accepts a 150 second old file" age --max 200
expect_exit 2 "a non-numeric --max is refused" age --max soon
expect_exit 2 "an unknown option is refused" age --nope
done_case
