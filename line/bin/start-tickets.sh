#!/usr/bin/env bash
# start-tickets.sh - the ticket starter: starts tickets from origin/main through bin/wo-start.sh (claims check), pushes, copies the
# started ticket into the checkout (interim until roadmap item B: seat.sh reads the branch from the checkout copy), then seats a worker. One at a time.
#
#   start-tickets.sh WO-... [WO-...]...    each id in the order given; a failed id is reported (FAIL id reason) and the next one runs
# One line per id on stdout and in the log: STARTED id branch sha, SEATED id, or FAIL id reason; ALL-DONE at the end.
# Where it writes (nothing else, anywhere):
#   <logs tree>/start-tickets/YYYY/MM/YYYYMMDDHHMMSS-start-tickets[-PID].log    one log per run
#   <cache root>/start-tickets/wt-<id>                                          the ticket's worktree; removed before the seat is up
#   the ticket file copied into the checkout, and the branch and commit pushed to origin
#
# BREADCRUMB 2026-10-12 - interim script (named start-roadmap.sh), first written in the owner's cache directory (coq-watch). It started
#   roadmap tickets one at a time so each branch was cut from origin/main and not from whatever the checkout held (work-order.sh start
#   branches from the checkout HEAD: six branches were cut from the records branch on 2026-10-11). The worktree
#   is removed before seat.sh runs because a worktree that holds the branch makes the seat fail (seat.sh exit 3).
# BREADCRUMB 2026-10-13 - WO-20261013-af23 (Roadmap I, WO-20261012-90ce split, architect ruling ykne9, owner message
#   m-20261012224955626-rjghl). What broke: this ran the line from the owner's cache directory, outside git, never tested or reviewed,
#   with the owner's checkout path written into it as an absolute path under the home directory, and it kept its log in the cache directory and its
#   worktrees directly under the home cache. Why this fix: the file moves here, renamed start-tickets.sh (it starts any ticket, not only
#   the roadmap's), with the same steps in the same order; the repository is found from this file's location (line/bin/..), the log goes
#   under the state root's logs tree and the worktrees under the cache root, both through bin/state-root.sh, the one resolver
#   (COQ_STATE and COQ_CACHE, then the ROADMAP.md defaults). Rejected: a symlink from the cache to this file (the cache copy would
#   still be a second place to edit) and a REPO variable (the location already answers it). Changes that are not behaviour: every
#   expansion is quoted, and the log is one dated file per run (AGENTS.md, dated entry files) and not one file appended forever.
#   Cost: none in behaviour. An id that fails keeps its worktree under the cache root until the next start of that id removes it.
#   Run from a treehouse slot, the "checkout" is that slot, so run it from the main checkout.
#   The cache copy and its .bak copies are archived to the state root and deleted after the merge, by the orchestrator (AC-H2).
#   Test: line/tests/cases/start-tickets.sh. Record: WO-20261013-af23.
set -u
HERE=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd); ck=$(cd "$HERE/../.." && pwd)
# shellcheck source=../../bin/state-root.sh
. "$ck/bin/state-root.sh" || { echo "start-tickets: bin/state-root.sh missing or unusable" >&2; exit 4; }
LOGS=$(coq_tree logs) && CACHE=$(coq_cache_root) || { echo "start-tickets: the state root did not resolve; set COQ_STATE" >&2; exit 4; }
stamp=$(date -u +%Y%m%d%H%M%S); logdir=$LOGS/start-tickets/${stamp:0:4}/${stamp:4:2}; mkdir -p "$logdir" "$CACHE/start-tickets" || exit 4
log=$logdir/$stamp-start-tickets.log; [ ! -e "$log" ] || log=$logdir/$stamp-start-tickets-$$.log
exec > >(tee -a "$log") 2>&1
cd "$ck" && git fetch -q origin
for id in "$@"; do
  wt=$CACHE/start-tickets/wt-$id; rm -rf "$wt"; git -C "$ck" worktree prune
  git -C "$ck" worktree add -q --detach "$wt" origin/main || { echo "FAIL $id worktree"; continue; }
  cd "$wt" || continue; mkdir -p .claude && cp -r "$ck/.claude/skills" .claude/
  bash bin/wo-start.sh --id "$id" >/dev/null || { echo "FAIL $id start (claims or status)"; cd "$ck" || exit; continue; }
  make step MSG="$id started from origin/main" TYPE=chore TITLE="$id started" TICKET="$id" >/dev/null 2>&1 || { echo "FAIL $id step"; cd "$ck" || exit; continue; }
  br=$(git branch --show-current); git push -q -u origin HEAD || { echo "FAIL $id push"; cd "$ck" || exit; continue; }
  f=$(git ls-files "work-orders/*$id-*.md" | head -1); cp "$f" "$ck/$f"
  echo "STARTED $id $br $(git rev-parse --short HEAD)"
  cd "$ck" || exit; git worktree remove --force "$wt"  # must precede seat.sh: a worktree holding the branch makes the seat fail
  bash herdr/bin/seat.sh --ticket "$id" --role worker 2>&1 | tail -1
  echo "SEATED $id"
done
echo ALL-DONE
