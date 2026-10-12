#!/usr/bin/env bash
# Catches: bringup.sh not plugging in the three blueprint server panes (dev, uat, stable), --check calling a pane ok on its label
# alone after its server process was killed, recover.sh --check changing anything, and recover.sh --apply leaving a killed server
# dead (AC-H3 of WO-20261011-ceea). The servers are the real report/blueprint/serve.sh in the world's copy of the repo; a pane's
# label outlives its process, so the monitors.json `check` (serve.sh --check TIER) is what tells a live pane from a dead one.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/assert.sh"; . "$HERE/../lib/world.sh"
world_up blueprintpanes '.bringup_gate=true' || exit 1
# The world is a copy of the checkout, gitignored build output included: start from a tree where nothing was ever promoted.
rm -rf "$REPO/report/blueprint/out"
BU="$REPO/herdr/bin/bringup.sh"; RC="$REPO/herdr/bin/recover.sh"; SERVE="$REPO/report/blueprint/serve.sh"
serving() { for _ in $(seq 1 40); do "$SERVE" --check "$1" >/dev/null 2>&1 && return 0; sleep 1; done; return 1; }
dead() { for _ in $(seq 1 20); do "$SERVE" --check "$1" >/dev/null 2>&1 || return 0; sleep 1; done; return 1; }

echo "-- bringup plugs in the three servers and they answer"
"$BU" --worktree "$REPO" >/dev/null 2>&1; assert_eq "bringup exits 0" "$?" 0
for tier in dev uat stable; do serving "$tier"; assert_eq "the $tier server answers" "$?" 0; done
assert_match "dev serves a built page" "$("$SERVE" --check dev 2>&1)" "^ok dev build [0-9]+$"
assert_match "uat is up with nothing promoted yet" "$("$SERVE" --check uat 2>&1)" "^ok uat up, no page yet"
chk="$("$BU" --check --worktree "$REPO" 2>&1)"; rc=$?
assert_eq "--check exits 0" "$rc" 0
assert_match "the three server panes read ok" "$(tr '\n' ' ' <<<"$chk")" "ok pane-blueprint-dev ok pane-blueprint-uat ok pane-blueprint-stable"

echo "-- a killed server: the label stays, the check fails, recover restarts it"
pkill -f 'server.py --tier dev'; dead dev; assert_eq "the dev server is dead" "$?" 0
assert_match "its slot is still labelled in use" "$("$REPO/herdr/bin/monitors.sh" status)" "3\.3\.1 blueprint dev server - blueprint-dev  \[[^]]+\]  in use"
chk="$("$BU" --check --worktree "$REPO" 2>&1)"; rc=$?
assert_eq "bringup --check now exits 1" "$rc" 1
assert_match "and names the dead server" "$chk" "FAILED pane-blueprint-dev \(slot blueprint-dev is up but its check failed\)"
out="$("$RC" --check 2>&1)"; rc=$?
assert_eq "recover --check exits 1" "$rc" 1
assert_match "recover --check reports the dead server" "$out" "^FAILED pane-blueprint-dev \(slot is up but its check failed\)$"
"$SERVE" --check dev >/dev/null 2>&1; assert_eq "--check repaired nothing" "$?" 1
out="$("$RC" --apply 2>&1)"
assert_match "recover --apply restarts it" "$out" "^fixed pane-blueprint-dev \(blueprint dev server restarted\)$"
assert_match "and leaves the other two alone" "$(tr '\n' ' ' <<<"$out")" "ok pane-blueprint-uat ok pane-blueprint-stable"
serving dev; assert_eq "the dev server answers again" "$?" 0
out="$("$RC" --check 2>&1)"
assert_match "recover --check now reads the dev server ok" "$out" "^ok pane-blueprint-dev$"
case_done
