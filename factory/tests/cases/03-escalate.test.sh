#!/usr/bin/env bash
# Catches: a third test failure waking the worker again instead of escalating, an escalated record without code 423 or the
# architect addressee, attempt 2 not staying with the worker, and a second 423 not becoming an owner line (AC-H3).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "${REPO_ROOT:-/repo}/herdr/tests/lib/assert.sh"; . "$HERE/../lib/world.sh"
A=WO-20261011-aaaa; B=WO-20261011-bbbb
world_up escalate

echo "-- AC-H3: test.failed 422 attempt 3 is an escalated 423 to the architect"
id=$(rec test.failed 422 tester-wo-20261011-aaaa $A 3)
run_once; assert_eq "exit 0" "$?" 0
assert_eq "no herdr call: an escalation is a record" "$(hcalls)" 0
e=$(ids_of escalated); assert_eq "one escalated record" "$(printf '%s\n' "$e" | grep -c .)" 1
r=$(rec_json "$e")
assert_eq "escalated is code 423 to the architect for the ticket" "$(jq -r '[.code, .to, .ticket, .seat] | join(" ")' <<<"$r")" "423 architect $A route-runner"
assert_match "it names the record it escalated" "$(jq -r .note <<<"$r")" "$id"
assert_eq "and one receipt addressed to the architect" "$(rec_json "$(ids_of record.routed)" | jq -r .to)" architect

echo "-- attempt 2 stays with the worker"
sleep 1; id2=$(rec test.failed 422 tester-wo-20261011-aaaa $B 2)
run_once
assert_match "worker woken with the record" "$(cat "$HLOG")" "^--session stable agent prompt worker-wo-20261011-bbbb record $id2 playbook $R/playbooks/worker.md$"

echo "-- a first blocked 423 escalates, a second becomes the owner's decision line"
sleep 1; rec blocked 423 worker-wo-20261011-bbbb $B >/dev/null; run_once
assert_eq "first blocked: one more escalated record for the ticket" "$(ids_of escalated | grep -c .)" 2
assert_eq "still one herdr call" "$(hcalls)" 1
sleep 1; id3=$(rec blocked 423 worker-wo-20261011-bbbb $B); run_once
assert_eq "second blocked: no new escalated record" "$(ids_of escalated | grep -c .)" 2
assert_match "the interface agent gets one decision line" "$(tail -1 "$HLOG")" "^--session stable agent prompt interface record $id3 line decision playbook $R/playbooks/interface-agent.md$"
case_done
