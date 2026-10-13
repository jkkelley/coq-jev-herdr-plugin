#!/usr/bin/env bash
# route-retry.sh (WO-20261013-acbf, AC-H1): line/bin/route-retry.sh against a fake herdr and fixture ledger and records, in a scratch state root.
#   max_seats      a failed gate record whose trouble note says max_seats is cleared when a seat of that role is free, left when none is
#   max_agents     one whose note says max_agents is cleared only while fewer than max_agents seat records have a live agent
#   other          a failure that is neither (no branch) is never retried
#   pending        three failed testers and one free tester slot clear one entry, not three
#   paths          the script carries no /home/luna and no .cache/coq-watch, and with COQ_STATE set it writes nothing outside it
# The stubs live here: a fake herdr that answers `agent list` from $W/agents, and the fixtures the belt would have left in the state root.
# Self-wrapping: run bare (bash line/tests/cases/route-retry.sh) it re-runs itself in Podman through line/tests/run.sh; make -C line test
# runs it inside the container with the rest of the suite.
set -uo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
if [ "${COQ_TEST_IN_CONTAINER:-0}" != 1 ]; then exec env CASES=route-retry bash "$HERE/../run.sh"; fi
. "$HERE/../lib/assert.sh"
REPO=${REPO_ROOT:-/repo}; SCRIPT=$REPO/line/bin/route-retry.sh
W=${COQ_CASE_WORK:-$(mktemp -d /tmp/coq-route-retry-XXXX)}; mkdir -p "$W/bin" "$W/state" "$W/home"
export PATH="$W/bin:$PATH" COQ_STATE="$W/state" HOME="$W/home" COQ_HERDR_SESSION=t-retry ROUTE_RETRY_ONCE=1
LEDGER=$W/state/ledger/routed; RECS=$W/state/records/2026/10; mkdir -p "$LEDGER" "$RECS" "$W/state/seats"

cat > "$W/bin/herdr" <<'FAKE'
#!/usr/bin/env bash
[ "$1 $2 $3" = "--session t-retry agent" ] && [ "$4" = list ] || { echo "fake herdr: unexpected: $*" >&2; exit 1; }
jq -Rn '{result: {agents: [inputs | select(length > 0) | {name: .}]}}' < "$(dirname "$0")/../agents"
FAKE
chmod +x "$W/bin/herdr"

# agents NAME...: the agents herdr reports live
agents() { printf '%s\n' "$@" > "$W/agents"; }
# seat_record NAME [ended]: a seat record in the state root's seats tree
seat_record() { mkdir -p "$W/state/seats/$1"; jq -n --arg n "$1" --arg e "${2:-}" '{name: $n, ended_at: (if $e == "" then null else $e end)}' > "$W/state/seats/$1/seat.json"; }
# failed N ROLE REASON: a failed ledger entry for a pr.opened record, and the 500 note the route runner left for it
failed() {
  local key; key=$(printf '2026101319%04d-pr-opened-pr-%d-wo-20261013-aa%02d' "$1" "$1" "$1")
  jq -n --arg id "$(printf '20261013T19%04dZ-100-r%04d' "$1" "$1")" '{id: $id, seat: "worker-x", kind: "pr.opened", code: 100, ticket: "WO-20261013-aa00"}' > "$RECS/$key.json"
  jq -n --arg id "$(printf '20261013T19%04dZ-100-r%04d' "$1" "$1")" --arg n "route failed for pr.opened 100, record $(printf '20261013T19%04dZ-100-r%04d' "$1" "$1"): seat.sh --ticket WO-20261013-aa00 --role $2 failed (exit 3): $3" \
    '{id: ("20261013T195900Z-500-n" + $id[-4:]), seat: "route-runner", kind: "note", code: 500, note: $n}' > "$RECS/2026101319590$1-note-wo-20261013-aa00.json"
  echo failed > "$LEDGER/$key"; printf '%s' "$key"
}
state_of() { cat "$LEDGER/$1" 2>/dev/null || echo gone; }
run() { bash "$SCRIPT" 2>&1; }

echo "-- max_seats: a tester is free, so the entry is cleared"
k1=$(failed 1 tester "seat.sh: seat tester-wo-20261013-aa00 refused: 4 tester seats already live (max_seats 4)")
agents tester-a tester-b worker-c
out=$(run)
assert_eq "the entry is deleted for the belt to route again" "$(state_of "$k1")" gone
assert_match "one line says which entry and the role's count" "$out" "retry $k1 \(tester 2/4\)$"

echo "-- max_seats: the role is full, so the entry is left"
k2=$(failed 2 tester "seat.sh: seat tester-wo-20261013-aa00 refused: 4 tester seats already live (max_seats 4)")
agents tester-a tester-b tester-c tester-d
out=$(run)
assert_eq "the entry stays failed" "$(state_of "$k2")" failed
assert_eq "nothing is printed" "$out" ""

echo "-- the same entry once a seat frees"
agents tester-a tester-b tester-c
out=$(run)
assert_eq "now it is deleted" "$(state_of "$k2")" gone

echo "-- another role does not borrow a tester's slot"
k3=$(failed 3 reviewer "seat.sh: seat reviewer-wo-20261013-aa00 refused: 4 reviewer seats already live (max_seats 4)")
agents reviewer-a reviewer-b reviewer-c reviewer-d tester-a
run >/dev/null
assert_eq "four reviewers live: left" "$(state_of "$k3")" failed

echo "-- other failures are for a person"
k4=$(failed 4 worker "seat.sh: no branch for WO-20261013-aa00")
agents worker-a
run >/dev/null
assert_eq "no branch: left" "$(state_of "$k4")" failed

echo "-- max_agents: eight live seat records hold the entry, seven release it"
rm -f "$W/state/seats"/*/seat.json
k5=$(failed 5 reviewer "seat.sh: seat reviewer-wo-20261013-aa00 refused: 8 agents already live (max_agents 8)")
names=(); for i in 1 2 3 4 5 6 7 8; do names+=("worker-$i"); seat_record "worker-$i"; done
agents "${names[@]}"
run >/dev/null
assert_eq "8 of 8 live: left" "$(state_of "$k5")" failed
seat_record worker-8 2026-10-13T19:00:00Z
run >/dev/null
assert_eq "an ended seat record does not count: released" "$(state_of "$k5")" gone

echo "-- max_agents: a seat record whose agent herdr no longer lists does not count"
k6=$(failed 6 reviewer "seat.sh: seat reviewer-wo-20261013-aa00 refused: 8 agents already live (max_agents 8)")
seat_record worker-8
agents "${names[@]:0:7}"
run >/dev/null
assert_eq "7 live agents of 8 records: released" "$(state_of "$k6")" gone

echo "-- three failed testers, one free slot: one entry is cleared"
rm -f "$LEDGER"/* "$RECS"/*
ka=$(failed 11 tester "refused: 4 tester seats already live (max_seats 4)")
kb=$(failed 12 tester "refused: 4 tester seats already live (max_seats 4)")
kc=$(failed 13 tester "refused: 4 tester seats already live (max_seats 4)")
agents tester-a tester-b tester-c
run >/dev/null
assert_eq "the oldest is cleared" "$(state_of "$ka")" gone
assert_eq "the second waits" "$(state_of "$kb")" failed
assert_eq "the third waits" "$(state_of "$kc")" failed

echo "-- entries older than ROUTE_RETRY_SINCE are not looked at"
agents tester-a
out=$(ROUTE_RETRY_SINCE=20261013195959 run)
assert_eq "left" "$(state_of "$kb")" failed
assert_eq "nothing printed" "$out" ""

echo "-- the script holds no host path and writes only under the state root"
assert_eq "no /home/luna in the script" "$(grep -c '/home/luna' "$SCRIPT")" 0
assert_eq "no .cache/coq-watch in the script" "$(grep -c '\.cache/coq-watch' "$SCRIPT")" 0
assert_eq "HOME stayed empty" "$(find "$W/home" -mindepth 1 | wc -l | tr -d ' ')" 0
case_done
