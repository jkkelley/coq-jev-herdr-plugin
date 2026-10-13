#!/usr/bin/env bash
# Catches: a pr.opened 100 record not waking the tester seat, a wake prompt carrying more than the record id and the playbook
# path, a missing record.routed 300, and a failed wake vanishing instead of becoming a 500 to the monitor (AC-H1).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "${REPO_ROOT:-/repo}/herdr/tests/lib/assert.sh"; . "$HERE/../lib/world.sh"
T=WO-20261011-aaaa
world_up wake

echo "-- AC-H1: a pr.opened 100 record wakes the tester and is receipted"
id=$(rec pr.opened 100 worker-wo-20261011-aaaa $T)
run_once; assert_eq "exit 0" "$?" 0
assert_eq "one herdr call" "$(hcalls)" 1
assert_match "agent prompt to the tester seat: the record id and the playbook path, nothing else" "$(cat "$HLOG")" "^--session stable agent prompt tester-wo-20261011-aaaa record $id playbook $R/playbooks/tester.md$"
rid=$(ids_of record.routed); assert_eq "one record.routed" "$(printf '%s\n' "$rid" | grep -c .)" 1
r=$(rec_json "$rid")
assert_eq "receipt code" "$(jq -r .code <<<"$r")" 300
assert_eq "receipt seat is the runner" "$(jq -r .seat <<<"$r")" route-runner
assert_eq "receipt is addressed to the tester" "$(jq -r .to <<<"$r")" tester
assert_eq "receipt carries the ticket" "$(jq -r .ticket <<<"$r")" $T
assert_match "receipt names the record it routed" "$(jq -r .note <<<"$r")" "$id"

echo "-- a wake herdr refuses becomes a 500 to the monitor, with no receipt"
touch "$W/herdr.fail"; sleep 1
id2=$(rec pr.opened 100 worker-wo-20261011-aaaa $T)
run_once; assert_eq "exit 0" "$?" 0
assert_eq "herdr was asked" "$(hcalls)" 2
assert_eq "still one receipt" "$(ids_of record.routed | grep -c .)" 1
n=$(files_code 500 | head -1); r=$(cat "$n")
assert_eq "500 is a note to the monitor" "$(jq -r '[.kind, .to, .seat] | join(" ")' <<<"$r")" "note monitor route-runner"
assert_match "it names the record and the reason" "$(jq -r .note <<<"$r")" "route failed for pr.opened 100, record $id2: herdr agent prompt tester-wo-20261011-aaaa failed"
case_done
