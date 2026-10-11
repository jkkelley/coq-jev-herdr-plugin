#!/usr/bin/env bash
# 07 - watch rewrites the page only when the floor changed, never leaves a half-written page, and survives a bad pass (AC-H4).
. "$(dirname "$0")/../lib/assert.sh"
. "$(dirname "$0")/../lib/world.sh"
world_init
OUT="$W/out"
T=WO-20261011-0007; S=worker-wo-20261011-0007
ticket "$T" in-progress feat/watch null "Watch the floor"
ev 2026-10-11T14:00:00Z "$S" seat.up 100 "$T" wD3:p5 "up"
ev 2026-10-11T14:01:00Z "$S" note 100 "$T" wD3:p5 "work.started: begins"
panes "$S=wD3:p5"
belt 100   # a stopped belt: its state file is older than belt_max_age_seconds

# watch NOWSTAMP [ARGS]: one pass against the world at that time. --sleep 0 and --iterations are the seam: no real wait, no background.
watch() { local now=$1; shift; LOOP_ROOT="$ROOT_FIX" LOOP_CONFIG="$W/board.json" "$LOOP" watch --out "$OUT" --root "$ROOT_FIX" --now "$now" --panes "$W/panes.json" --sleep 0 --iterations 1 "$@"; }
# stamp: inode, mtime to the nanosecond and size of every file the page is made of, so a rewrite shows even when the bytes match.
stamp() { stat -c '%n %i %y %s' "$OUT/index.html" "$OUT/data.json" "$OUT/.watch.json"; }

t "the first pass builds the page" watch 2026-10-11T15:00:00Z
eq "data.json is build 1" "1" "$(jq .number "$OUT/data.json")"
eq "the build number is kept beside the page" "1" "$(jq .number "$OUT/.watch.json")"
t "the page it wrote validates" "$LOOP" validate "$OUT/data.json"
has "and index.html carries the entry" "$OUT/index.html" 'id="loop-data"'
eq "no scratch directory is left in the out directory" "0" "$(find "$OUT" -name '.watch.??????' -o -name '.render.*' | wc -l | tr -d ' ')"

# Nothing changed, a minute later: every file keeps its inode, mtime and size.
first=$(stamp); sleep 1
t "a pass with nothing new runs" watch 2026-10-11T15:01:00Z
eq "nothing changed, so no file was touched" "$first" "$(stamp)"
eq "and the build number did not move" "1" "$(jq .number "$OUT/data.json")"
eq "and the page still says the minute it was built" "2026-10-11T15:00:00Z" "$(jq -r .at "$OUT/data.json")"

# The stopped belt sits stale and its age grows every pass; that must not read as a change (the age is not in the entry).
second=$(stamp); sleep 1
t "a pass with the belt older still runs" watch 2026-10-11T15:09:00Z
eq "an ageing stale belt is not a change" "$second" "$(stamp)"

# A new record is a change: the page is rebuilt, the number counts up, and `at` is the new time.
ev 2026-10-11T15:10:00Z "$S" note 100 "$T" wD3:p5 "pr.opened: PR 3 at abc1234"
t "a pass after a new record runs" watch 2026-10-11T15:11:00Z
eq "the new record is build 2" "2" "$(jq .number "$OUT/data.json")"
eq "and the entry is stamped with the new time" "2026-10-11T15:11:00Z" "$(jq -r .at "$OUT/data.json")"
eq "and the work is at the tester" "tester" "$(jq -r '.lines[0].here' "$OUT/data.json")"
has "and the page was redrawn with it" "$OUT/index.html" 'pr.opened 100'

# The number survives losing its record: it falls back to the page's own.
rm -f "$OUT/.watch.json"
ev 2026-10-11T15:20:00Z "$S" note 100 "$T" wD3:p5 "test.failed: nope"
t "a pass with the build record gone runs" watch 2026-10-11T15:21:00Z
eq "the count carries on from the page" "3" "$(jq .number "$OUT/data.json")"

# A pass that cannot collect keeps the last good page and says why; a finite run reports it.
good=$(stamp)
echo '{ not json' > "$ROOT_FIX/factory/config/routes.json"
expect_exit 4 "a pass with a broken routes table fails" watch 2026-10-11T15:30:00Z
eq "the failed pass left the page alone" "$good" "$(stamp)"
has "and the failure is said, with the page kept" "$W/.out" 'keeping the last page'
cp "$REPO_ROOT/factory/config/routes.json" "$ROOT_FIX/factory/config/routes.json"

# Several passes in one run: only the first writes.
rm -rf "$OUT"
t "three passes in one run" env LOOP_ROOT="$ROOT_FIX" LOOP_CONFIG="$W/board.json" "$LOOP" watch --out "$OUT" --root "$ROOT_FIX" --now 2026-10-11T16:00:00Z --panes "$W/panes.json" --sleep 0 --iterations 3
eq "three passes over one world are one build" "1" "$(jq .number "$OUT/data.json")"
eq "and the run said so once" "1" "$(grep -c 'written' "$W/.out")"

# Usage.
expect_exit 2 "a non-numeric --iterations is refused" "$LOOP" watch --out "$OUT" --iterations soon
expect_exit 2 "an unknown option is refused" "$LOOP" watch --nope
done_case
