#!/usr/bin/env bash
# seat-queue.sh - the interim worker queue (backlog 32bb9: seat.sh's max_seats refusal promises a queue that does not exist).
# Seats each ticket in order, retrying every 60 s while seat.sh refuses for max_seats; waits for the ticket's branch on origin first.
#
#   seat-queue.sh WO-ID...      one ticket after another; prints "SEATED WO-ID" as each is seated and QUEUE-EMPTY at the end
# Knobs, for tests and a slow network: SEAT_QUEUE_BRANCH_WAIT (seconds between looks for the branch on origin, default 15) and
# SEAT_QUEUE_SLOT_WAIT (seconds between seat.sh attempts, default 60).
#
# BREADCRUMB 2026-10-13 - WO-20261013-ca12 (Roadmap I, owner order m-20261012224955626-rjghl: every script lives in the project and
#   only its artifacts outside; split from WO-20261012-90ce by architect ruling ykne9). What broke: this queue ran the line from
#   a copy in the owner's cache directory, outside git, never tested or reviewed, with an absolute path to the main checkout
#   hardcoded as its first line. Why that mattered: a copy of the repository anywhere else (a second user, a CI checkout, a
#   treehouse slot) queued tickets against the main checkout's work-orders/ and seat.sh, and nobody could see a change to it in
#   review. Why this fix: the file is moved here with the same behaviour, and it now finds the repository root from its own
#   location (two directories above this file) and the state root through bin/state-root.sh, exporting it so the seat.sh it calls resolves the same
#   root as the queue rather than a root of its own. The script writes no file of its own; everything it starts writes through
#   seat.sh and the event writer, under that root. Rejected: reading COQ_REPO for the root (a queue started by hand has none, and
#   a stale value would point it at another checkout) and a queue log under the state root (a changed behaviour, and the ticket's
#   scope says it is not). Cost: the two sleeps became environment knobs so the test does not wait 15 and 60 seconds; the defaults
#   are the old numbers. The old copy and its .bak files are archived to the state root and deleted by the orchestrator after the
#   merge (AC-H2); nothing runs them today.
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd) || exit 1
cd "$ROOT" || exit 1
COQ_STATE=$(bash "$ROOT/bin/state-root.sh" state) || exit 1; export COQ_STATE
BRANCH_WAIT=${SEAT_QUEUE_BRANCH_WAIT:-15}; SLOT_WAIT=${SEAT_QUEUE_SLOT_WAIT:-60}
for id in "$@"; do
  f=$(find work-orders -path work-orders/archive -prune -o -name "$id-*.md" -print | head -1); slug=$(basename "$f" .md); slug=${slug#$id-}
  until git ls-remote --exit-code origin "refs/heads/feat/$slug" >/dev/null 2>&1; do sleep "$BRANCH_WAIT"; done
  until bash herdr/bin/seat.sh --ticket "$id" --role worker; do echo "$(date -u +%H:%MZ) $id waiting for a worker slot"; sleep "$SLOT_WAIT"; done
  echo "SEATED $id"
done
echo QUEUE-EMPTY
