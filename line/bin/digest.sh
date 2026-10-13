#!/usr/bin/env bash
# digest.sh - the interim architect digest (ROADMAP guardrail, until item D): one batched prompt every 30 minutes, never one per record.
# Owner 2026-10-12: the per-record watches flooded the architect; this sends only what the architect owns or must tick.
#
#   digest.sh            loops forever: sleep DIGEST_SECONDS (default 1800), read the records of the window, prompt the architect once
#   DIGEST_SECONDS=N     the interval, in seconds
#   DIGEST_ROUNDS=N      stop after N intervals (default 0: never); a test hook, the pane that runs it leaves it unset
#   COQ_HERDR_SESSION    the herdr session the prompt goes to (else HERDR_SESSION, else stable)
# It reads the records tree of the state root (bin/state-root.sh: COQ_STATE, else the default in config/state.json) and writes one file,
# run/digest.last, the start of the next window. Nothing else is written and nothing is read from the repository.
#
# BREADCRUMB 2026-10-13 - WO-20261013-0ffe (Roadmap I, owner message m-20261012224955626-rjghl: every script lives in the project).
#   What broke: this script ran from the owner's watch cache directory, outside git, never tested or reviewed, with the repository path
#   and the state path written into it as literals. Moved here as it was, with both taken from the script's own location and from
#   bin/state-root.sh, so a clone anywhere and a COQ_STATE elsewhere both work. The old copy and its .bak files are archived to the
#   state root and deleted by the orchestrator after the merge (ticket scope, AC-H2).
#   Three lines of the old copy no longer matched the records and are changed to keep it doing what it was written to do, not to do more:
#   1. It read $REPO/events/, which holds no record since roadmap item A1 (records go to <state>/records/YYYY/MM/); it would have found
#      nothing and sent "nothing" for ever. It reads the state root's records tree.
#   2. It cut the window by comparing the file's name to the stamp in digest.last ("20261013T183241Z"). Record files are now named
#      YYYYMMDDHHMMSS-<name>.json with no "T", so every name sorted below the stamp and every record was skipped. The window is cut by
#      the record's own `at` field, turned into the same stamp, and the file name is no longer parsed.
#   3. It counted route failures by the file name pattern '*-500-*'; the code is no longer in the name, so it counts `.code == 500`.
#   Why find -newermt: the old prefilter was `-newer digest.last`, the file's mtime, which is set AFTER the scan, so a record posted
#   during the scan was older than the file and never reported. The prefilter now starts one second before the window's own start stamp,
#   and the `at` test is the exact cut, so the window is [previous now, ...) with nothing lost between two scans. Rejected: dropping the
#   prefilter (jq over every record of the tree every 30 minutes). Cost: a record whose file was rewritten without a new `at` is counted
#   in the window of its `at`, not its mtime.
#   DIGEST_ROUNDS is the one addition: a loop that never ends cannot be a test case, and `timeout` makes the case a race against the sleep.
set -uo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd); REPO=$(cd "$HERE/../.." && pwd)
. "$REPO/bin/state-root.sh" || { printf 'digest: bin/state-root.sh is missing or failed; nothing here may guess a state root\n' >&2; exit 4; }
REC=$(coq_tree records) || exit 4; ST=$(coq_tree run) || exit 4
mkdir -p "$ST"; LAST=$ST/digest.last
INTERVAL=${DIGEST_SECONDS:-1800}; ROUNDS=${DIGEST_ROUNDS:-0}; SESSION=${COQ_HERDR_SESSION:-${HERDR_SESSION:-stable}}
[ -f "$LAST" ] || date -u +%Y%m%dT%H%M%SZ > "$LAST"
# window_floor STAMP: the stamp (YYYYMMDDTHHMMSSZ) as "YYYY-MM-DD HH:MM:SS UTC" minus one second, the argument of find -newermt
window_floor() { date -u -d "${1:0:4}-${1:4:2}-${1:6:2} ${1:9:2}:${1:11:2}:${1:13:2} UTC - 1 second" '+%Y-%m-%d %H:%M:%S UTC'; }
n=0
while :; do
  sleep "$INTERVAL"
  since=$(cat "$LAST"); now=$(date -u +%Y%m%dT%H%M%SZ)
  found=$(find "$REC" -mindepth 3 -maxdepth 3 -name '*.json' -newermt "$(window_floor "$since")" 2>/dev/null | sort | while read -r f; do
    jq -r --arg since "$since" 'select(((.at // "") | gsub("[-:]"; "")) >= $since) |
      (select(.code == 500) | "F"),
      (select(.seat != "architect" and .seat != "route-runner") |
        select((.to == "architect") or (.kind | IN("escalated","blocked","merged","verified","rejected","test.failed","review.changes","merge.conflict","pr.opened"))) |
        "I \(.id[16:]) \(.kind) \(.ticket // "-") pr=\(.pr // "-")")' "$f" 2>/dev/null; done)
  lines=$(printf '%s\n' "$found" | sed -n 's/^I //p'); fails=$(printf '%s\n' "$found" | grep -c '^F$' || true)
  echo "$now" > "$LAST"
  if [ -z "$lines" ] && [ "$fails" = 0 ]; then echo "$now digest: nothing"
  else
    msg="DIGEST $since..$now: $(printf '%s\n' "$lines" | grep -c .) records for you, $fails route failures. $(printf '%s' "$lines" | head -25 | tr '\n' ';') Read the roadmap progress file, act per playbooks."
    env -u HERDR_PANE_ID -u HERDR_TAB_ID -u HERDR_WORKSPACE_ID -u HERDR_SOCKET_PATH herdr --session "$SESSION" agent prompt architect "${msg:0:1800}" >/dev/null && echo "$now digest sent"
  fi
  n=$((n + 1)); [ "$ROUNDS" = 0 ] || [ "$n" -lt "$ROUNDS" ] || break
done
