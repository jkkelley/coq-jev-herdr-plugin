#!/usr/bin/env bash
# seat-queue (WO-20261013-ca12, AC-H1): line/bin/seat-queue.sh against a stub git ls-remote and a stub seat.sh, in a scratch copy of the
# repository layout, so the real script runs from a place of its own and finds its root from its own location.
#   source    the file names no home directory and no cache directory of the old copy
#   branch    a branch that is not on origin yet is waited for, and the ticket is not seated before it appears
#   refusal   seat.sh refuses once for max_seats: the queue waits, retries, seats the ticket on the retry, prints SEATED once
#   order     two tickets are seated one after the other, in the order given; a ticket that exists only in the archive is not seated
#   state     the seat.sh the queue calls sees the state root bin/state-root.sh resolves; the queue writes no file of its own
set -uo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
. "$HERE/../lib/assert.sh"
REPO=${REPO_ROOT:-/repo}
W=${COQ_CASE_WORK:?COQ_CASE_WORK is set by line/tests/run.sh}; mkdir -p "$W"
S=$W/repo; mkdir -p "$S/line/bin" "$S/bin" "$S/config" "$S/herdr/bin" "$S/work-orders/WO-X" "$S/work-orders/archive" "$W/bin" "$W/state"
REAL_GIT=$(command -v git)

echo "-- the source names no home directory and no cache directory"
assert_eq "no /home/luna in the file" "$(grep -c '/home/luna' "$REPO/line/bin/seat-queue.sh")" 0
assert_eq "no old cache directory in the file" "$(grep -c '\.cache/coq-watch' "$REPO/line/bin/seat-queue.sh")" 0

cp "$REPO/line/bin/seat-queue.sh" "$S/line/bin/"; cp "$REPO/bin/state-root.sh" "$S/bin/"; cp "$REPO/config/state.json" "$S/config/"
: > "$S/work-orders/WO-X/WO-20261013-0001-first-ticket.md"; : > "$S/work-orders/WO-X/WO-20261013-0002-second-ticket.md"
: > "$S/work-orders/archive/WO-20261013-0004-archived-only.md"; : > "$S/work-orders/WO-X/WO-20261013-0003-live-ticket.md"

# stub git: ls-remote answers from files in $W (a branch listed in $W/remote exists; the first N looks for a branch in $W/ls-fail fail),
# everything else is the real git, because bin/state-root.sh asks it for the repository name
cat > "$W/bin/git" <<STUB
#!/usr/bin/env bash
if [ "\$1" = ls-remote ]; then
  echo "\$*" >> "$W/ls.log"
  ref=\${!#}; ref=\${ref#refs/heads/}
  [ -e "$W/remote/\${ref//\//_}" ] || exit 2
  exit 0
fi
exec "$REAL_GIT" "\$@"
STUB
# stub seat.sh: refuses (exit 3, the max_seats refusal) while $W/refuse holds a count above zero, counting it down; else seats
cat > "$S/herdr/bin/seat.sh" <<STUB
#!/usr/bin/env bash
echo "\$* state=\${COQ_STATE:-unset}" >> "$W/seat.log"
if [ -s "$W/refuse" ] && [ "\$(cat "$W/refuse")" -gt 0 ]; then echo \$((\$(cat "$W/refuse") - 1)) > "$W/refuse"; echo "seat: refused, max_seats" >&2; exit 3; fi
exit 0
STUB
chmod +x "$W/bin/git" "$S/herdr/bin/seat.sh" "$S/line/bin/seat-queue.sh"
export PATH="$W/bin:$PATH" COQ_STATE="$W/state" SEAT_QUEUE_BRANCH_WAIT=1 SEAT_QUEUE_SLOT_WAIT=1
mkdir -p "$W/remote"; : > "$W/ls.log"; : > "$W/seat.log"
queue() { bash "$S/line/bin/seat-queue.sh" "$@" 2>&1; }
before=$(cd "$S" && find . -type f | LC_ALL=C sort)

echo "-- seat.sh refuses once for max_seats: the ticket is seated on the retry, SEATED printed once"
: > "$W/remote/feat_first-ticket"; echo 1 > "$W/refuse"
out=$(queue WO-20261013-0001)
assert_eq "SEATED is printed once" "$(printf '%s\n' "$out" | grep -c '^SEATED WO-20261013-0001$')" 1
assert_eq "one waiting line, for the one refusal" "$(printf '%s\n' "$out" | grep -c 'WO-20261013-0001 waiting for a worker slot$')" 1
assert_eq "seat.sh was called twice, refused then seated" "$(grep -c -- '--ticket WO-20261013-0001 --role worker' "$W/seat.log")" 2
assert_eq "the queue ends empty" "$(printf '%s\n' "$out" | tail -1)" QUEUE-EMPTY
assert_match "it looked for the branch named by the ticket file's slug" "$(cat "$W/ls.log")" "refs/heads/feat/first-ticket$"

echo "-- a ticket seated at once prints no waiting line"
: > "$W/seat.log"; echo 0 > "$W/refuse"
out=$(queue WO-20261013-0001)
assert_eq "no waiting line" "$(printf '%s\n' "$out" | grep -c 'waiting for a worker slot')" 0
assert_eq "seat.sh called once" "$(wc -l < "$W/seat.log" | tr -d ' ')" 1

echo "-- a branch that is not on origin yet is waited for; the ticket is not seated before it appears"
rm -f "$W/remote/feat_first-ticket"; : > "$W/ls.log"; : > "$W/seat.log"
( sleep 3; : > "$W/remote/feat_first-ticket" ) &
out=$(queue WO-20261013-0001); wait
assert_eq "it looked for the branch more than once" "$([ "$(wc -l < "$W/ls.log" | tr -d ' ')" -gt 1 ] && echo yes || echo no)" yes
assert_eq "it was seated once, after the branch appeared" "$(grep -c -- '--ticket WO-20261013-0001' "$W/seat.log")" 1
assert_eq "SEATED printed" "$(printf '%s\n' "$out" | grep -c '^SEATED WO-20261013-0001$')" 1

echo "-- two tickets are seated in the order given; a ticket only in the archive is not looked up"
: > "$W/remote/feat_second-ticket"; : > "$W/remote/feat_live-ticket"; : > "$W/seat.log"; : > "$W/ls.log"
out=$(queue WO-20261013-0002 WO-20261013-0001 WO-20261013-0003)
assert_eq "the order of SEATED lines follows the arguments" "$(printf '%s\n' "$out" | grep '^SEATED' | tr '\n' ' ')" "SEATED WO-20261013-0002 SEATED WO-20261013-0001 SEATED WO-20261013-0003 "
assert_match "the third ticket's branch comes from its live file" "$(cat "$W/ls.log")" "refs/heads/feat/live-ticket$"
# a ticket that exists only in work-orders/archive has no live file: its slug must never be looked up (no order-dependence: it has
# one file). The queue would wait for the branch forever, so it runs under timeout and the look-ups are read afterwards.
: > "$W/ls.log"; : > "$W/seat.log"; timeout 3 bash "$S/line/bin/seat-queue.sh" WO-20261013-0004 >/dev/null 2>&1
assert_no_match "an archived ticket's slug is never looked up" "$(cat "$W/ls.log")" "archived-only"
assert_eq "an archived ticket is never seated" "$(wc -l < "$W/seat.log" | tr -d ' ')" 0

echo "-- the state root"
: > "$W/seat.log"
want=$(cd "$S" && bash bin/state-root.sh state)
assert_eq "COQ_STATE set: seat.sh sees it" "$(queue WO-20261013-0001 >/dev/null; sed -n 's/.*state=//p' "$W/seat.log" | head -1)" "$W/state"
: > "$W/seat.log"
got=$(unset COQ_STATE; export XDG_STATE_HOME="$W/xdg"; queue WO-20261013-0001 >/dev/null; sed -n 's/.*state=//p' "$W/seat.log" | head -1)
want=$(unset COQ_STATE; export XDG_STATE_HOME="$W/xdg"; cd "$S" && bash bin/state-root.sh state)
assert_eq "COQ_STATE unset: seat.sh sees what bin/state-root.sh resolves" "$got" "$want"
assert_match "that root is under the state home, never under the repository" "$got" "^$W/xdg/coq/"
assert_eq "the queue wrote no file into the repository layout" "$(cd "$S" && find . -type f | LC_ALL=C sort)" "$before"
case_done
