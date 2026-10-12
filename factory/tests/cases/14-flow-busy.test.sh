#!/usr/bin/env bash
# Catches: the flow watch noting a gate record as stalled while the consumer seat is in the middle of its turn (three false alarms on
# 2026-10-12, records ch471, 0ui6q and 06gu1; WO-20261012-3bb0); a working seat being skipped for good instead of judged again on the
# next tick; a seat stuck in "working" past busy_grace_seconds never being noted; an idle or missing seat no longer being noted.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "${REPO_ROOT:-/repo}/herdr/tests/lib/assert.sh"; . "$HERE/../lib/world.sh"
T=WO-20261011-aaaa
world_up flowbusy; flow_world

echo "-- a test.passed 201 older than stall_seconds while the reviewer seat is working: no note, and the seat asked about is the reviewer's"
g=$(rec test.passed 201 tester "$T"); backdate "$g" 100
agent_state working; flow_once; assert_eq "exit 0" "$?" 0
assert_eq "no note" "$(flow_notes | grep -c .)" 0
assert_match "herdr was asked about the reviewer seat for the ticket" "$(cat "$HLOG")" "agent get reviewer-wo-20261011-aaaa"
flow_once; assert_eq "still none on the next tick" "$(flow_notes | grep -c .)" 0

echo "-- the seat goes idle with still no record: the same gate record is noted, once"
agent_state idle; flow_once
assert_eq "one note" "$(flow_notes | grep -c .)" 1
assert_match "it names the record and the missing role" "$(flow_notes | jq -r .note)" "test.passed 201 $g has no reviewer record"
flow_once; assert_eq "and only once" "$(flow_notes | grep -c .)" 1

echo "-- no such agent: judged as before, noted"
world_up flowgone; flow_world
g=$(rec test.passed 201 tester "$T"); backdate "$g" 100
agent_state gone; flow_once; assert_eq "one note" "$(flow_notes | grep -c .)" 1

echo "-- a seat stuck in working past busy_grace_seconds is noted"
world_up flowstuck; flow_world
grace=$(jq -r .busy_grace_seconds "$R/factory/config/flow.json")
g=$(rec test.passed 201 tester "$T"); backdate "$g" $((grace + 60))
agent_state working; flow_once; assert_eq "one note" "$(flow_notes | grep -c .)" 1

echo "-- the merger seat has no ticket in its name: the label is used as it is"
world_up flowmerger; flow_world
g=$(rec review.passed 201 reviewer "$T"); backdate "$g" 100
agent_state working; flow_once; assert_eq "no note while the merger works" "$(flow_notes | grep -c .)" 0
assert_match "herdr was asked about merger" "$(cat "$HLOG")" "agent get merger$"
case_done
