#!/usr/bin/env bash
# Catches (WO-20261012-9b2c): an escalation with a policy and no answer by its deadline not producing the default and a record that
# names the policy (AC-H1); an escalation with no policy being touched (AC-H2); a default taken before its deadline, over an
# answer, over another ticket's answer, twice for one escalation, or past limit_per_ticket; a break.glass row being accepted; a dead
# seat or a refused prompt losing the record; the first start judging the old log; and a policies.json row that no routes.json
# escalation covers or that cites a decision the graph does not hold.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "${REPO_ROOT:-/repo}/herdr/tests/lib/assert.sh"; . "$HERE/../lib/world.sh"
T=WO-20261012-aaaa; U=WO-20261012-bbbb; V=WO-20261012-cccc
SEAT_T=worker-wo-20261012-aaaa
world_up policy; policy_world
nrec() { policy_records | grep -c .; }
n500() { "$R/events/bin/event.sh" list --json | jq -c 'select(.seat == "policy-watch" and .code == 500)' | grep -c .; }

echo "-- AC-H1: a blocked 423 with a policy and no answer past its deadline gets the default, and a record names the policy"
b=$(rec blocked 423 "$SEAT_T" "$T"); backdate "$b" 2000
policy_once; assert_eq "exit 0" "$?" 0
assert_eq "one policy.applied record" "$(nrec)" 1
r=$(policy_records)
assert_eq "it is code 200 from policy-watch, to the worker, on the ticket" "$(jq -r '[.code, .seat, .to, .ticket] | join(" ")' <<<"$r")" "200 policy-watch worker $T"
assert_eq "it names the policy and the record it answers as fields" "$(jq -r '[.policy, .answer] | join(" ")' <<<"$r")" "POL-blocked-land-it $b"
assert_match "the note carries the default" "$(jq -r .note <<<"$r")" "^default POL-blocked-land-it: Owner default: land the PR on its criteria"
pid=$(jq -r .id <<<"$r")
assert_eq "the blocked seat is woken with the record and its role's playbook" "$(cat "$HLOG")" "--session stable agent prompt $SEAT_T record $pid playbook $R/playbooks/worker.md"
assert_eq "the record carries the new kind and both new fields" "$("$R/events/bin/event.sh" list --json | jq -s 'map(select(.kind == "policy.applied" and (.policy | test("^POL-")))) | length')" 1

echo "-- the default is taken once: a second tick writes nothing and wakes nobody"
policy_once; policy_once
assert_eq "still one record" "$(nrec)" 1; assert_eq "still one herdr call" "$(hcalls)" 1

# BREADCRUMB 2026-10-12 - WO-20261012-da52 (a flake found on its PR, not caused by it). What broke: test.failed 422 3h504 (tester,
#   PR 25 head 30b1c93): "an answer on the ticket after the escalation" gave WO-20261012-aaaa a default although a pr.opened followed
#   its blocked, so the 12-policy line below this comment (the `sleep 1` before each answer) failed once in a run that passed on
#   the same tree minutes earlier. The policy watch orders an answer after an escalation by record id, which is the UTC second
#   plus a random suffix, so two records in one second sort by chance. The wall clock on this WSL2 host steps back about 1.05 s every
#   ~35 s (factory/tests/cases/06-belt.test.sh breadcrumb), so a `sleep 1` between them can span less than one clock second and
#   write both in the same second. Why this fix: every ordering sleep in this case is 3 s, so even with a 1.05 s step the two ids
#   are at least 1.95 s apart on the wall clock, which always crosses a second boundary. Rejected: ordering by file time or a
#   counter in the test (policy.sh orders by id, and the test must exercise that), and a clock stub (the script reads real ids).
#   Cost: about eight more seconds of waiting per run.
echo "-- limit_per_ticket: a repeat blocked on the same ticket waits for the owner"
sleep 3; b2=$(rec blocked 423 "$SEAT_T" "$T"); backdate "$b2" 2000
policy_once; assert_eq "no second default" "$(nrec)" 1
echo "-- two escalations of one ticket in one tick: one default, not two"
world_up policy2; policy_world
b1=$(rec blocked 423 "worker-wo-20261012-bbbb" "$U"); sleep 3; b2=$(rec blocked 423 "worker-wo-20261012-bbbb" "$U"); backdate "$b1" 2000; backdate "$b2" 2000
policy_once; assert_eq "one record for two escalations" "$(nrec)" 1

echo "-- before the deadline nothing happens, and status says when"
world_up policy3; policy_world
b=$(rec blocked 423 "$SEAT_T" "$T"); backdate "$b" 100
policy_once; assert_eq "no record" "$(nrec)" 0; assert_eq "no herdr call" "$(hcalls)" 0
out=$("$POLICY" status --from-start --repo "$R" --state "$PSTATE"); assert_eq "status exits 0 while nothing is overdue" "$?" 0
assert_match "status names the policy, the ticket and the record" "$out" "^waiting POL-blocked-land-it $T $b: default in 1[0-9]{3}s$"

echo "-- an answer on the ticket after the escalation means no default; another ticket's answer does not"
world_up policy4; policy_world
b=$(rec blocked 423 "$SEAT_T" "$T"); backdate "$b" 2000; sleep 3; rec pr.opened 100 "$SEAT_T" "$T" >/dev/null
c=$(rec blocked 423 "worker-wo-20261012-cccc" "$V"); backdate "$c" 2000; sleep 3; rec pr.opened 100 "worker-wo-20261012-bbbb" "$U" >/dev/null
policy_once; assert_eq "one default, for the ticket nobody answered" "$(jq -r .ticket <<<"$(policy_records)")" "$V"
assert_eq "and only one" "$(nrec)" 1

echo "-- AC-H2: an escalation with no policy still waits for the owner, however old"
world_up policy5; policy_world
t3=$(rec test.failed 422 tester-wo-20261012-aaaa "$T" 3); backdate "$t3" 86400
r3=$(rec review.changes 422 reviewer-wo-20261012-aaaa "$U" 3); backdate "$r3" 86400
e=$(rec escalated 423 route-runner "$V"); backdate "$e" 86400
g=$("$R/events/bin/event.sh" add --code 300 --seat worker-wo-20261012-aaaa --kind break.glass --ticket "$T" --action 'gh pr merge 17 --squash'); backdate "$g" 86400
policy_once; assert_eq "exit 0" "$?" 0
assert_eq "no policy.applied record" "$(nrec)" 0; assert_eq "no herdr call" "$(hcalls)" 0; assert_eq "no 500" "$(n500)" 0
out=$("$POLICY" status --from-start --repo "$R" --state "$PSTATE"); assert_eq "status exits 0: nothing a policy covers is overdue" "$?" 0
assert_eq "and prints nothing" "$out" ""

echo "-- status exits 1 for a covered escalation past its deadline, and writes nothing"
world_up policy6; policy_world
b=$(rec blocked 423 "$SEAT_T" "$T"); backdate "$b" 2000
out=$("$POLICY" status --from-start --repo "$R" --state "$PSTATE"); assert_eq "exit 1" "$?" 1
assert_match "it says overdue" "$out" "^overdue POL-blocked-land-it $T $b: 20[0-9]s past its deadline, not applied$"
assert_eq "no record" "$(nrec)" 0

echo "-- the route runner has a row for the record: a receipt to the monitor, not a no-route 500"
world_up policyroute; policy_world
b=$(rec blocked 423 "$SEAT_T" "$T"); backdate "$b" 2000; policy_once; pid=$(jq -r .id <<<"$(policy_records)")
run_once; assert_eq "runner exit 0" "$?" 0
assert_match "a receipt names the policy.applied record and the monitor" "$("$R/events/bin/event.sh" list --json | jq -r 'select(.kind == "record.routed") | .note')" "routed policy.applied 200 \\($pid\\): none monitor"
assert_eq "no 500 for it" "$("$R/events/bin/event.sh" list --json | jq -c 'select(.code == 500 and (.note | test("policy.applied")))' | grep -c .)" 0

echo "-- a seat with no role: the record stands, no wake, one 500 to the monitor"
world_up policy7; policy_world
b=$(rec blocked 423 some-other-seat "$T"); backdate "$b" 2000
policy_once; assert_eq "the policy.applied record is written" "$(nrec)" 1
assert_eq "without an addressee" "$(jq -r '.to // "none"' <<<"$(policy_records)")" none
assert_eq "no herdr call" "$(hcalls)" 0; assert_eq "one 500" "$(n500)" 1
assert_match "the 500 names the policy and the record" "$("$R/events/bin/event.sh" list --json | jq -r 'select(.code == 500) | .note')" "policy POL-blocked-land-it on record $b: no seat or role"

echo "-- a refused prompt: the record stands, one 500, and the next tick does not retry"
world_up policy8; policy_world; : > "$W/herdr.fail"
b=$(rec blocked 423 "$SEAT_T" "$T"); backdate "$b" 2000
policy_once; policy_once
assert_eq "one record" "$(nrec)" 1; assert_eq "one herdr call" "$(hcalls)" 1; assert_eq "one 500" "$(n500)" 1
assert_match "the 500 says the prompt failed" "$("$R/events/bin/event.sh" list --json | jq -r 'select(.code == 500) | .note')" "herdr agent prompt $SEAT_T failed"

echo "-- the first start judges only records written after it"
world_up policy9; policy_world
b=$(rec blocked 423 "$SEAT_T" "$T"); backdate "$b" 2000; sleep 3
"$POLICY" once --repo "$R" --state "$PSTATE"; assert_eq "exit 0" "$?" 0; assert_eq "no record for the old escalation" "$(nrec)" 0

echo "-- a table that covers break.glass is refused at start"
world_up policy10; policy_world
jq '.policies[0].match.kind = "break.glass" | .policies[0].match.code = 300' "$R/factory/config/policies.json" > "$W/bad.json"
"$POLICY" once --config "$W/bad.json" --repo "$R" --state "$PSTATE" 2> "$W/err"; assert_eq "exit 3" "$?" 3
assert_match "it says why" "$(cat "$W/err")" "matches break.glass; the owner authorises every break glass by hand"
echo "-- a table with two rows of one id is refused at start"
jq '.policies += [.policies[0]]' "$R/factory/config/policies.json" > "$W/dup.json"
"$POLICY" once --config "$W/dup.json" --repo "$R" --state "$PSTATE" 2> "$W/err"; assert_eq "exit 3" "$?" 3; assert_match "it says why" "$(cat "$W/err")" "policy ids are not unique"

echo "-- event.sh: policy.applied needs --policy and --answer, and neither belongs to another kind"
EV="$R/events/bin/event.sh"
"$EV" add --code 200 --seat policy-watch --kind policy.applied --ticket "$T" >/dev/null 2>&1; assert_eq "policy.applied without them: exit 2" "$?" 2
"$EV" add --code 100 --seat worker-x --kind note --policy POL-x >/dev/null 2>&1; assert_eq "--policy on a note: exit 2" "$?" 2
"$EV" add --code 100 --seat worker-x --kind note --answer 20261012T000000Z-300-abcde >/dev/null 2>&1; assert_eq "--answer on a note: exit 2" "$?" 2
"$EV" add --code 200 --seat policy-watch --kind policy.applied --policy pol-x --answer 20261012T000000Z-300-abcde >/dev/null 2>&1; assert_eq "a malformed policy id: exit 3" "$?" 3

echo "-- the shipped table: every row is an escalation routes.json sends on, and cites a decision the graph holds"
P="$R/factory/config/policies.json"; RT="$R/factory/config/routes.json"; GN="${REPO_ROOT:-/repo}/graph/nodes"
while IFS=$'\t' read -r id kind code dec; do
  hit=$(jq --arg k "$kind" --argjson c "$code" '[.routes[] | select(.match.kind == $k and .match.code == $c and (.do == "escalate" or (.do == "notify_owner" and .line == "decision")))] | length' "$RT")
  check "$id covers an escalation routes.json sends to the architect or the owner ($kind $code)" "$([ "$hit" -ge 1 ] && echo 1 || echo 0)"
  check "$id cites $dec, which graph/nodes holds" "$([ -f "$GN/$dec.json" ] && echo 1 || echo 0)"
  roles=$(jq -r '.default.to' <<<"$(jq -c --arg i "$id" '.policies[] | select(.id == $i)' "$P")")
  check "$id wakes source or a role the playbooks hold" "$([ "$roles" = source ] || [ -f "$R/playbooks/$roles.md" ] && echo 1 || echo 0)"
done < <(jq -r '.policies[] | [.id, .match.kind, .match.code, .decision] | @tsv' "$P")
assert_eq "no row matches break.glass" "$(jq '[.policies[] | select(.match.kind == "break.glass")] | length' "$P")" 0
case_done
