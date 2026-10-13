#!/usr/bin/env bash
# merge-watch: line/bin/merge-watch.sh against a stub gh and a stub herdr, in a scratch state root (WO-20261013-7719, AC-H1).
#   seed      the first run records every merge already done and prompts nobody
#   one       one new merge gives exactly one prompt, to the target seat, naming the pull request and its merge commit
#   again     later ticks, and a restart, repeat nothing: the seen set lives in the state root
#   batch     two merges in one tick give one prompt, not two
#   gh down   a failing gh gives no prompt and no exit; when it works again the watch carries on
#   one only  a second instance exits at once and says so
#   fix       the merge of the fix ticket ends the watch and closes its pane
#   halt      the halt flag ends the watch, closes its pane and removes the pid file
#   files     every file the script writes is under the state root (HOME is empty and stays empty)
# The stubs live here, not in lib/world.sh (that file belongs to the board cases). The script runs unmodified from the read-only repo
# mount; MERGE_WATCH_SECONDS=1 makes a tick a second, and `timeout` bounds each run of the loop.
set -uo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
. "$HERE/../lib/assert.sh"
REPO=${REPO_ROOT:-/repo}; SCRIPT=$REPO/line/bin/merge-watch.sh
W=${COQ_CASE_WORK:?COQ_CASE_WORK is set by line/tests/run.sh}; mkdir -p "$W/bin" "$W/gh" "$W/state" "$W/home"
: > "$W/herdr.log"; : > "$W/gh/merged.tsv"
export PATH="$W/bin:$PATH" HOME="$W/home" COQ_STATE="$W/state" GH_FAKE_DIR="$W/gh" HERDR_FAKE_LOG="$W/herdr.log"
export MERGE_WATCH_SECONDS=1 MERGE_WATCH_TO=target-seat
unset COQ_CACHE XDG_STATE_HOME XDG_CACHE_HOME
RUN=$W/state/run; SEEN=$RUN/merge-watch.seen

# ---- a stub gh: `gh pr list --state merged ... --jq FILTER` prints the lines the filter would, one "number<TAB>sha<TAB>title" each ----
cat > "$W/bin/gh" <<'FAKE'
#!/usr/bin/env bash
echo "$*" >> "$GH_FAKE_DIR/calls.log"
[ ! -e "$GH_FAKE_DIR/fail" ] || { echo "gh: HTTP 502 Bad Gateway" >&2; exit 1; }
case "$1 $2 $3 $4" in "pr list --state merged") cat "$GH_FAKE_DIR/merged.tsv" ;; *) echo "gh: this stub only lists merged pull requests" >&2; exit 1 ;; esac
FAKE
# ---- a stub herdr: logs its argv after the session flags, one line per call ----
cat > "$W/bin/herdr" <<'FAKE'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$HERDR_FAKE_LOG"
FAKE
chmod +x "$W/bin/gh" "$W/bin/herdr"

merge_add() { printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> "$W/gh/merged.tsv"; }  # merge_add NUMBER SHA7 TITLE
prompts() { grep -c ' agent prompt ' "$W/herdr.log" || true; }
# watch SECONDS [PANE]: run the loop for at most SECONDS; stdout is the log, the exit code is timeout's 124 if the loop was still going
watch() { local s=$1; shift; timeout -k 2 "$s" bash "$SCRIPT" "$@" 2>&1; }

echo "-- the first run seeds the merges already done and prompts nobody"
merge_add 1 aaaaaaa "WO-20261013-0001 - first"; merge_add 2 bbbbbbb "WO-20261013-0002 - second"
out=$(watch 3); rc=$?
assert_eq "it was still looping when the bound ended it" "$rc" 124
assert_match "it says it seeded two" "$out" "seeded with 2 merges already done"
assert_eq "no prompt" "$(prompts)" 0
assert_eq "the seen set holds both" "$(tr '\n' ' ' < "$SEEN")" "1 2 "
assert_eq "its log is under the state root's logs tree" "$(find "$W/state/logs" -name '*-merge-watch-one-minute.log' | wc -l | tr -d ' ')" 1
assert_match "gh was asked for merged pull requests" "$(head -1 "$W/gh/calls.log")" "^pr list --state merged "

echo "-- one new merge: exactly one prompt, to the target seat, with the pull request and its merge commit"
merge_add 3 ccccccc "WO-20261013-0003 - third"
out=$(watch 4); rc=$?
assert_eq "still looping" "$rc" 124
assert_eq "one prompt in all, though the loop ticked four times" "$(prompts)" 1
assert_match "through the stable session, to the target seat" "$(cat "$W/herdr.log")" "^--session stable agent prompt target-seat MERGE WATCH: PR 3 at ccccccc \(WO-20261013-0003 - third\); "
assert_match "it asks for the post-merge cleanup" "$(cat "$W/herdr.log")" "Verify main and do the post-merge cleanup"
assert_match "the log says what merged" "$out" "merged: PR 3 at ccccccc"
assert_eq "the seen set holds three" "$(tr '\n' ' ' < "$SEEN")" "1 2 3 "

echo "-- a restart repeats nothing"
out=$(watch 3)
assert_eq "still one prompt" "$(prompts)" 1
assert_no_match "it did not seed again" "$out" "seeded"

echo "-- two merges in one tick: one prompt naming both"
merge_add 4 ddddddd "WO-20261013-0004 - fourth"; merge_add 5 eeeeeee "WO-20261013-0005 - fifth"
watch 3 >/dev/null
assert_eq "two prompts in all" "$(prompts)" 2
assert_match "the second names both pull requests" "$(tail -1 "$W/herdr.log")" "PR 4 at ddddddd .*; PR 5 at eeeeeee "

echo "-- gh down: no prompt, no exit; when it is back the new merge is announced"
touch "$W/gh/fail"; merge_add 6 fffffff "WO-20261013-0006 - sixth"
out=$(watch 3); rc=$?
assert_eq "still looping while gh fails" "$rc" 124
assert_match "it says it is staying quiet" "$out" "gh pr list failed; staying quiet until it works"
assert_eq "no prompt while gh is down" "$(prompts)" 2
rm -f "$W/gh/fail"
out=$(watch 3)
assert_match "the log names the merge made while gh was down" "$out" "merged: PR 6 at fffffff"
assert_eq "the merge made while gh was down is announced once" "$(prompts)" 3

echo "-- a second instance exits at once"
( watch 4 >/dev/null ) & first=$!
sleep 1
out=$(timeout -k 2 5 bash "$SCRIPT" 2>&1); rc=$?
assert_eq "the second exits 0, not 124" "$rc" 0
assert_match "it says one is running" "$out" "merge-watch already running; not starting a second one"
wait "$first"
flock -w 3 "$RUN/merge-watch.lock" true  # a killed loop's orphaned sleep holds the lock for up to one tick

echo "-- a failed prompt is logged and the loop carries on"
printf '#!/usr/bin/env bash\nexit 1\n' > "$W/bin/herdr"
merge_add 7 1111111 "WO-20261013-0007 - seventh"
out=$(watch 3); rc=$?
assert_eq "still looping" "$rc" 124
assert_match "the log keeps the merge" "$out" "merged: PR 7 at 1111111"
assert_match "the log says the prompt failed" "$out" "prompt failed"
printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$*" >> "$HERDR_FAKE_LOG"\n' > "$W/bin/herdr"

echo "-- the merge of the fix ticket ends the watch and closes its pane"
: > "$W/herdr.log"
merge_add 8 2222222 "WO-20261012-6f13 - the merger verifies on main"
out=$(watch 5 pane-x); rc=$?
assert_eq "it ended by itself" "$rc" 0
assert_match "it says why" "$out" "exit: WO-20261012-6f13 merged"
assert_match "it closed its own pane" "$(cat "$W/herdr.log")" "^--session stable pane close pane-x$"
assert_no_file "no pid file left" "$RUN/merge-watch.pid"

echo "-- the halt flag ends the watch, closes its pane and removes the pid file"
: > "$W/herdr.log"; touch "$RUN/line.halted"
out=$(watch 5 pane-y); rc=$?
assert_eq "it ended by itself" "$rc" 0
assert_match "it says why" "$out" "exit: halt flag present"
assert_match "it closed its own pane" "$(cat "$W/herdr.log")" "^--session stable pane close pane-y$"
assert_no_file "no pid file left" "$RUN/merge-watch.pid"
assert_eq "it prompted nobody" "$(prompts)" 0
rm -f "$RUN/line.halted"

echo "-- every file it wrote is under the state root"
assert_eq "HOME stayed empty" "$(find "$W/home" -type f | wc -l | tr -d ' ')" 0
assert_file "the seen set" "$SEEN"
assert_file "the lock" "$RUN/merge-watch.lock"
case_done
