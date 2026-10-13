#!/usr/bin/env bash
# start-tickets.sh (WO-20261013-af23, AC-H1): line/bin/start-tickets.sh against a scratch repository, a bare origin and stub wo-start, make and seat.
#   order     each id is started in the order given: a worktree, the start, the step, the push, the ticket copied into the checkout, the seat
#   paths     the worktree is cut under COQ_CACHE and removed before the seat; the log is one file under the state root's logs tree
#   refusal   an id whose start is refused (claims or status) is reported FAIL, is never seated, and does not stop the next id
#   branch    each ticket branch is cut from origin/main and pushed to origin
#   hostfree  the script carries no /home/luna and no .cache/coq-watch, and with COQ_STATE and COQ_CACHE set it writes nothing outside them
# The stubs live here: bin/wo-start.sh (cuts the branch, marks the ticket in-progress, refuses ids listed in $W/refuse), a make that commits
# like `make step`, and herdr/bin/seat.sh (logs its argv and, when it runs, whether the ticket's worktree still existed).
# git is the real git, on a local bare origin, so the branch and the push are real.
# Self-wrapping: run bare (bash line/tests/cases/start-tickets.sh) it re-runs itself in Podman through line/tests/run.sh; make -C line test
# runs it inside the container with the rest of the suite.
set -uo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
if [ "${COQ_TEST_IN_CONTAINER:-0}" != 1 ]; then exec env CASES=start-tickets bash "$HERE/../run.sh"; fi
. "$HERE/../lib/assert.sh"
REAL=${REPO_ROOT:-/repo}; SCRIPT_SRC=$REAL/line/bin/start-tickets.sh
W=${COQ_CASE_WORK:-$(mktemp -d /tmp/coq-start-tickets-XXXX)}; mkdir -p "$W/bin" "$W/home"
export PATH="$W/bin:$PATH" HOME="$W/home" COQ_STATE="$W/state" COQ_CACHE="$W/cache"
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null
unset COQ_REPO
CK=$W/ck; ORIGIN=$W/origin.git
LOGDIR=$COQ_STATE/logs/start-tickets
A=WO-20261013-aa01; B=WO-20261013-aa02; C=WO-20261013-aa03

# the scratch repository: the script and the resolver it sources at their real paths, a skills dir to copy, stub wo-start and seat
git init -q --bare -b main "$ORIGIN"
git init -q -b main "$CK"
mkdir -p "$CK/line/bin" "$CK/bin" "$CK/config" "$CK/herdr/bin" "$CK/.claude/skills" "$CK/work-orders/E"
cp "$SCRIPT_SRC" "$CK/line/bin/start-tickets.sh"; cp "$REAL/bin/state-root.sh" "$CK/bin/"; cp "$REAL/config/state.json" "$CK/config/"
echo skill > "$CK/.claude/skills/marker"
for id in $A $B $C; do printf -- '---\nstatus: ready\n---\n# %s\n' "$id" > "$CK/work-orders/E/$id-ticket.md"; done
cat > "$CK/bin/wo-start.sh" <<'STUB'
#!/usr/bin/env bash
# stub wo-start: --id ID; refused (exit 3) while the id is listed in $REFUSE; else cuts feat/ID from the checked-out commit and marks the ticket
[ "$1" = --id ] || exit 2
id=$2; if grep -qx "$id" "${REFUSE:?}" 2>/dev/null; then exit 3; fi
git switch -q -c "feat/$id" && sed -i 's/^status: ready/status: in-progress/' work-orders/E/"$id"-*.md
STUB
cat > "$CK/herdr/bin/seat.sh" <<'STUB'
#!/usr/bin/env bash
# stub seat: logs its argv and whether the ticket's worktree still existed when it ran
id=$2; wt=${COQ_CACHE:?}/start-tickets/wt-$id
printf 'seat %s present=%s\n' "$*" "$([ -e "$wt" ] && echo yes || echo no)" >> "${SEATLOG:?}"
echo "seated $id"
STUB
printf '#!/usr/bin/env bash\n# stub make: `make step ... TICKET=ID` commits what wo-start changed, as make step does\n[ "$1" = step ] || exit 2\ngit add -A && git commit -q -m "$2"\n' > "$W/bin/make"
chmod +x "$W/bin/make" "$CK/bin/wo-start.sh" "$CK/herdr/bin/seat.sh" "$CK/line/bin/start-tickets.sh"
git -C "$CK" add -A && git -C "$CK" commit -q -m seed && git -C "$CK" remote add origin "$ORIGIN" && git -C "$CK" push -q origin main
export REFUSE=$W/refuse SEATLOG=$W/seat.log; : > "$REFUSE"; : > "$SEATLOG"
# the checkout stays on a branch with a commit that is not on origin/main, so a ticket branch cut from the checkout instead of origin/main would show
git -C "$CK" switch -q -c elsewhere && echo extra > "$CK/extra.txt" && git -C "$CK" add -A && git -C "$CK" commit -q -m "a commit that is not on origin/main"
run() { bash "$CK/line/bin/start-tickets.sh" "$@" 2>&1; }

echo "-- two ids, started and seated in the order given"
out=$(run $A $B)
assert_match "A is started on its branch" "$out" "^STARTED $A feat/$A [0-9a-f]{7}"
assert_match "B is started on its branch" "$out" "^STARTED $B feat/$B [0-9a-f]{7}"
assert_eq "A starts before B, then each seats after its own start" "$(grep -E '^(STARTED|SEATED)' <<<"$out" | awk '{print $1" "$2}' | tr '\n' ',')" "STARTED $A,SEATED $A,STARTED $B,SEATED $B,"
assert_match "the run ends with ALL-DONE" "$(tail -1 <<<"$out")" "^ALL-DONE$"
assert_eq "seat.sh ran for A then B with the worker role" "$(cut -d' ' -f1-5 "$SEATLOG" | tr '\n' ',')" "seat --ticket $A --role worker,seat --ticket $B --role worker,"
assert_eq "the worktree was already gone when seat.sh ran" "$(grep -c 'present=no' "$SEATLOG")" 2

echo "-- branches are cut from origin/main and pushed"
for id in $A $B; do
  assert_eq "$id is on origin" "$(git -C "$ORIGIN" rev-parse --verify -q "refs/heads/feat/$id" >/dev/null && echo yes || echo no)" yes
  assert_eq "$id branch is origin/main plus its start commit" "$(git -C "$ORIGIN" rev-parse "refs/heads/feat/$id~1")" "$(git -C "$ORIGIN" rev-parse refs/heads/main)"
  assert_eq "$id branch did not take the checkout's unpushed commit" "$(git -C "$ORIGIN" ls-tree -r --name-only "refs/heads/feat/$id" | grep -c '^extra.txt$')" 0
  assert_eq "$id start commit carries the in-progress ticket" "$(git -C "$ORIGIN" show "refs/heads/feat/$id:work-orders/E/$id-ticket.md" | grep -c 'status: in-progress')" 1
  assert_eq "$id ticket copied into the checkout" "$(grep -c 'status: in-progress' "$CK/work-orders/E/$id-ticket.md")" 1
done
assert_eq "the checkout's own branch was not moved" "$(git -C "$CK" branch --show-current)" elsewhere

echo "-- the worktree is under COQ_CACHE, the log under the state root"
assert_no_file "no worktree is left behind for A" "$COQ_CACHE/start-tickets/wt-$A"
assert_eq "git has no worktree entry left but the checkout's" "$(git -C "$CK" worktree list | wc -l | tr -d ' ')" 1
assert_eq "one log file for the run, on the dated layout" "$(find "$LOGDIR" -type f | sed "s|$LOGDIR/||" | grep -cE '^[0-9]{4}/[0-9]{2}/[0-9]{14}-start-tickets(-[0-9]+)?\.log$')" 1
assert_match "the log holds what the run printed" "$(cat "$(find "$LOGDIR" -type f | head -1)")" "STARTED $B feat/$B"
assert_no_file "no old-style log in the cache directory" "$HOME/.cache/coq-watch/start-roadmap.log"

echo "-- a refused start is reported, never seated, and does not stop the next id"
: > "$SEATLOG"; echo "$C" > "$REFUSE"
out=$(run $C)
assert_match "FAIL names the id and the reason" "$out" "^FAIL $C start \(claims or status\)$"
assert_no_match "not STARTED" "$out" "^STARTED $C"
assert_eq "seat.sh was not called" "$(wc -c < "$SEATLOG" | tr -d ' ')" 0
assert_match "the run still ends" "$(tail -1 <<<"$out")" "^ALL-DONE$"
assert_file "a failed id leaves its worktree under COQ_CACHE (as the interim script did)" "$COQ_CACHE/start-tickets/wt-$C/bin/wo-start.sh"
: > "$REFUSE"
out=$(run $C)
assert_match "the same id starts once the claim is free, over the leftover worktree" "$out" "^STARTED $C feat/$C"
assert_no_file "and the worktree is gone again" "$COQ_CACHE/start-tickets/wt-$C"

echo "-- the script holds no host path and writes only under COQ_STATE and COQ_CACHE"
assert_eq "no /home/luna in the script" "$(grep -c '/home/luna' "$SCRIPT_SRC")" 0
assert_eq "no .cache/coq-watch in the script" "$(grep -c '\.cache/coq-watch' "$SCRIPT_SRC")" 0
assert_eq "HOME stayed empty" "$(find "$W/home" -mindepth 1 | wc -l | tr -d ' ')" 0
case_done
