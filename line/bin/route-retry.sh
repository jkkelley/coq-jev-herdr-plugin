#!/usr/bin/env bash
# route-retry.sh - the failed-route retry (Roadmap I; ticket WO-20261013-acbf, born 2026-10-12 as a loose script in the owner's cache directory, coq-watch).
# Every 30 seconds it looks at the route runner's ledger for entries that say `failed`. A failed route is one whose seat-up was
# refused for want of a slot (max_seats of a role, or max_agents of the whole line). When a seat of that role is free again it deletes
# the ledger entry, so the belt (factory/bin/route.sh) routes that record once more. Any other failure is for a person and is left.
#
#   route-retry.sh              loop forever, one pass every ROUTE_RETRY_SECONDS (default 30)
#   ROUTE_RETRY_ONCE=1 route-retry.sh    one pass and exit (tests)
# ROUTE_RETRY_SINCE=<14-digit UTC stamp> is the oldest ledger entry looked at (default 20261012170000, the stamp the interim script
# used, written as a record file name starts: YYYYMMDDHHMMSS). COQ_HERDR_CONFIG, COQ_HERDR_SESSION and COQ_STATE are read the way
# herdr/bin/seat-lib.sh reads them. One line per retry on stdout: HH:MM:SSZ retry KEY (ROLE LIVE/MAX).
# The only thing this script changes is a ledger file it deletes; nothing else is written, anywhere.
#
# BREADCRUMB 2026-10-12 - interim script, 17:38Z. What broke: factory/bin/route.sh marks a route failed in its ledger and never retries
#   it, so a pr.opened whose tester seat-up was refused for max_seats (4 testers live) waited forever: PR 24 b7sgc and WO-20261012-8f4f
#   2dmxn (GitHub issue 76). Why this fix: clear the ledger entry once a seat of the role is free, so the belt does the routing; the
#   script never routes, wakes or starts a seat itself. Durable fix: backlog (route.sh retries a seat-refused route when a slot frees).
# BREADCRUMB 2026-10-12 23:50Z - what broke: a max_agents refusal (seat.sh:515, the 8-agent cap) was never retried, so PR 80's merger
#   waited 17 minutes (record h7h10) until the owner asked. It is retried only when a slot is free, counted the way seat-lib.sh
#   sl_live_seats counts (open seat records whose agent is live), so a full line causes no refusal loop. Only a max_seats or
#   max_agents refusal is retried at all: cwzvb looped at 17:42Z when "no branch" and "bad record" failures were retried too.
# BREADCRUMB 2026-10-13 - WO-20261013-acbf (Roadmap I, owner message m-20261012224955626-rjghl, architect ruling ykne9). What broke:
#   this ran from the owner's cache directory (coq-watch), outside git, never tested or reviewed, with the owner's home path written into it
#   (the checkout, factory/state/routed, events/2026/10, $HOME/.local/state/coq/seats). Why this fix: it moves here with its test
#   (line/tests/cases/route-retry.sh) and finds everything from its own location: the repository from this file, the ledger and the
#   records through bin/state-root.sh (the trees factory/config/runner.json names: ledger_dir ${tree:ledger}, events_dir
#   ${tree:records}), the seats the way herdr/bin/seat-lib.sh does (COQ_STATE, else herdr.json state_dir), the cap from herdr.json
#   and the role cap from roles/<role>.json. Choices that look arbitrary and are kept from the interim script:
#   1. A ledger entry is named like the record FILE (route.sh route_file: key=basename), while the failure note names the record's
#      id, so the key is mapped to its record file and that file's id before the note is searched. The interim script treated the
#      key as the id, which was true only before roadmap item A2 moved the ledger onto file names. Cost: a failed entry whose record
#      file is gone is skipped, never retried.
#   2. After a retry the role gets a phantom `ROLE-pending` agent for the rest of the pass, so three failed testers and one free
#      tester slot clear one entry, not three. Cost: the count is only as fresh as the pass; the next pass re-reads herdr.
#   3. The pass reads herdr once per pass, not per entry. Rejected: per-entry reads (a hundred failed entries would be a hundred
#      herdr calls a pass). Cost: an agent that dies mid-pass is counted live until the next pass.
#   4. No `set -e`: a grep that finds nothing is the normal answer on most lines. Cost: a failure of jq or herdr is silent on that
#      entry; the entry stays `failed` and the next pass looks again.
set -uo pipefail
HERE=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd); REPO=$(cd "$HERE/../.." && pwd)
die() { local c=$1; shift; printf 'route-retry: %s\n' "$*" >&2; exit "$c"; }
command -v jq >/dev/null || die 4 "jq is required"
command -v herdr >/dev/null || die 4 "herdr is required"
# shellcheck source=../../bin/state-root.sh
. "$REPO/bin/state-root.sh" || die 4 "cannot load bin/state-root.sh"
LEDGER=$(coq_tree ledger) || die 4 "the state root is unresolved"
RECS=$(coq_tree records) || die 4 "the state root is unresolved"
HCONF=${COQ_HERDR_CONFIG:-$REPO/herdr/config/herdr.json}
[ -f "$HCONF" ] || die 4 "no herdr config $HCONF"
SESSION=${COQ_HERDR_SESSION:-$(jq -r .session "$HCONF")}
MAX_AGENTS=$(jq -r .max_agents "$HCONF")
# the seats directory, the way seat-lib.sh builds STATE: COQ_STATE, else herdr.json state_dir with a leading ~/ expanded
sd=${COQ_STATE:-$(jq -r .state_dir "$HCONF")}; case $sd in [~]/*) sd=$HOME/${sd#[~]/};; esac
SEATS=$sd/seats
SINCE=${ROUTE_RETRY_SINCE:-20261012170000}; EVERY=${ROUTE_RETRY_SECONDS:-30}

pass() {
  local agents f key rec id note role live live_all max s n
  agents=$(herdr --session "$SESSION" agent list 2>/dev/null | jq -r '.result.agents[].name // empty')
  for f in $(grep -l '^failed$' "$LEDGER"/* 2>/dev/null); do
    key=$(basename "$f"); [[ $key > "$SINCE" ]] || continue
    # the record the entry is named after, then the id the failure note names (breadcrumb 1)
    rec=$RECS/${key:0:4}/${key:4:2}/$key.json; [ -f "$rec" ] || continue
    id=$(jq -r '.id // empty' "$rec" 2>/dev/null); [ -n "$id" ] || continue
    note=$(grep -h -- "route failed for .*record $id" "$RECS/${key:0:4}/${key:4:2}"/*.json 2>/dev/null | tail -1)
    # only a max_seats or max_agents refusal is retried; any other failure (no branch, bad record) is for a person
    grep -qE 'max_seats|max_agents' <<<"$note" || continue
    role=$(grep -o -- '--role [a-z]*' <<<"$note" | head -1 | cut -d' ' -f2)
    [ -n "$role" ] || continue
    if grep -q 'max_agents' <<<"$note"; then
      live_all=0
      for s in "$SEATS"/*/seat.json; do
        [ -f "$s" ] || continue
        n=$(jq -r 'select(.ended_at==null).name' "$s" 2>/dev/null); [ -n "$n" ] || continue
        grep -Fxq -- "$n" <<<"$agents" && live_all=$((live_all + 1))
      done
      [ "$live_all" -lt "$MAX_AGENTS" ] || continue
    fi
    live=$(grep -c "^$role-" <<<"$agents"); max=$(jq -r .max_seats "$REPO/roles/$role.json" 2>/dev/null); [ "$live" -lt "${max:-1}" ] || continue
    rm -f "$f"; echo "$(date -u +%H:%M:%SZ) retry $key ($role $live/$max)"
    agents="$agents"$'\n'"$role-pending"
  done
}

while :; do
  pass
  [ "${ROUTE_RETRY_ONCE:-0}" != 1 ] || exit 0
  sleep "$EVERY"
done
