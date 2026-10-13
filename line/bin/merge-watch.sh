#!/usr/bin/env bash
# merge-watch.sh - the interim merge watch: asks GitHub once a minute which pull requests merged, and prompts the acting orchestrator once per new batch.
# 2026-10-13 01:10Z: target moved from the architect to the acting orchestrator (sched-worker-1, MERGE_WATCH_TO overrides); owner: "you are the gate".
# 16:32Z (architect): target moved to sched-worker-2, the cleanup and verify lane (owner m-3d6g0 split). Backup .bak-1632.
#
# Why it exists: owner, 2026-10-12 22:44Z (m-20261012224455779-gxn68): "until the fix is in, better get some kind of
# 1 min monitoring going that cleans itself up and is non disruptive".
# What broke: factory/config/routes.json routes kind "merged" to the architect, but the belt builds the seat name
# architect-wo-<id>, which does not exist, so the route fails; the only thing that reached the architect was the
# 30-minute digest, and a merge made outside the merger seat posts no record at all.
# Why GitHub and not records: GitHub is the one place every merge shows up, whoever made it.
# Rejected: a per-record watch, which is what flooded the architect at 20:32Z (retro in $COQ_STATE/plans/2026/10).
#
# Non-disruptive by construction:
#   - prompts only when a merge it has not seen appears; one prompt per tick, however many merged; never on errors
#   - the seen set lives in $COQ_STATE/run, so a restart or a compaction replays nothing
#   - first start seeds the seen set with every merge already done, so it never announces old merges
#   - one instance only (flock)
# Cleans itself up: exits and closes its own pane when the ticket WO-20261012-6f13 (roadmap B, the merger verifies
# on main) has merged, when the halt flag $COQ_STATE/run/line.halted exists (USERHALT), or after 7 days as a backstop.
#
# BREADCRUMB 2026-10-13 - WO-20261013-7719 (Roadmap I, WO-20261012-90ce split, architect ruling ykne9). What broke: this script ran the
#   line from a loose copy in the owner's home cache, outside git, so it was never tested or reviewed, and it hardcoded
#   the repository path as an absolute path under the owner's home and a state default of its own (owner m-20261012224955626-rjghl, 22:49Z: every
#   script lives in the project, only its artifacts outside). Why this fix: the file moves here unchanged in behaviour; the repository
#   root is found from this file's location (line/bin/..), and the state root and its run and logs trees come from bin/state-root.sh,
#   the one resolver (COQ_STATE, then the ROADMAP.md default), so every file it writes lands under the state root. Rejected: a
#   symlink from the cache to this file (the cache copy would still be a second place to edit) and keeping REPO overridable by an
#   environment variable (the location already answers it, and a second answer is how the cache copy drifted).
#   Cost: none in behaviour. The cache copy and its .bak copies are archived to the state root and deleted after the merge, by the
#   orchestrator (AC-H2). Test: line/tests/cases/merge-watch.sh. Record: WO-20261013-7719.
set -uo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd); REPO=$(cd "$HERE/../.." && pwd)
# shellcheck source=../../bin/state-root.sh
. "$REPO/bin/state-root.sh" || { echo "merge-watch: bin/state-root.sh missing or unusable" >&2; exit 4; }
RUN=$(coq_tree run) || exit 4; mkdir -p "$RUN"
LOGS=$(coq_tree logs) || exit 4
SEEN=$RUN/merge-watch.seen
HALT=$RUN/line.halted
FIX_TICKET=WO-20261012-6f13
INTERVAL=${MERGE_WATCH_SECONDS:-60}
MAX_AGE=$((7 * 24 * 3600))
PANE=${1:-}
H=(env -u HERDR_PANE_ID -u HERDR_TAB_ID -u HERDR_WORKSPACE_ID -u HERDR_SOCKET_PATH herdr --session stable)

start=$(date -u +%s)
LOG=$LOGS/$(date -u +%Y/%m)/$(date -u +%Y%m%d%H%M%S)-merge-watch-one-minute.log
mkdir -p "$(dirname "$LOG")"
log() { echo "$(date -u +%FT%TZ) $*" | tee -a "$LOG"; }

exec 9>"$RUN/merge-watch.lock"
flock -n 9 || { echo "merge-watch already running; not starting a second one"; exit 0; }

finish() {
  log "exit: $1"
  rm -f "$RUN/merge-watch.pid"
  [ -n "$PANE" ] && "${H[@]}" pane close "$PANE" >/dev/null 2>&1
  exit 0
}
echo $$ > "$RUN/merge-watch.pid"

merged() { cd "$REPO" && gh pr list --state merged --limit 50 --json number,title,mergedAt,mergeCommit \
  --jq '.[] | "\(.number)\t\(.mergeCommit.oid[0:7])\t\(.title)"'; }

if [ ! -s "$SEEN" ]; then
  merged | cut -f1 | sort -n > "$SEEN" || { log "seed failed; will retry next tick"; : > "$SEEN"; }
  log "seeded with $(wc -l < "$SEEN") merges already done"
fi
log "start pid $$, every ${INTERVAL}s, exits when $FIX_TICKET merges, on $HALT, or after 7 days"

failing=0
while :; do
  [ -e "$HALT" ] && finish "halt flag present"
  [ $(( $(date -u +%s) - start )) -gt $MAX_AGE ] && finish "7-day backstop reached"
  if out=$(merged 2>/dev/null); then
    [ "$failing" = 1 ] && log "github reachable again"; failing=0
    # An empty seen set would make every past merge look new; seed instead of announcing 50 old merges.
    if [ ! -s "$SEEN" ]; then printf '%s\n' "$out" | cut -f1 | sort -n > "$SEEN"; log "seeded late"; sleep "$INTERVAL"; continue; fi
    new=$(printf '%s\n' "$out" | awk -F'\t' 'NR==FNR{s[$1]=1;next} $1!="" && !s[$1]' "$SEEN" -)
    if [ -n "$new" ]; then
      printf '%s\n' "$new" | cut -f1 >> "$SEEN"
      summary=$(printf '%s\n' "$new" | awk -F'\t' '{printf "PR %s at %s (%s); ", $1, $2, substr($3,1,90)}')
      log "merged: $summary"
      "${H[@]}" agent prompt "${MERGE_WATCH_TO:-sched-worker-2}" "MERGE WATCH: ${summary}Verify main and do the post-merge cleanup, as acting orchestrator." >/dev/null \
        && log "architect prompted" || log "prompt failed (architect not reachable); merges kept in the log"
      printf '%s\n' "$new" | cut -f3 | grep -q "^$FIX_TICKET" && finish "$FIX_TICKET merged; ticket B owns merge verification now"
    fi
  else
    [ "$failing" = 0 ] && log "gh pr list failed; staying quiet until it works"; failing=1
  fi
  sleep "$INTERVAL"
done
