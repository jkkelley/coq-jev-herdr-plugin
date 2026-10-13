#!/usr/bin/env bash
# 16 - the board shows the live line: open pull requests and ticket branches over the main checkout, a stale in-progress ticket
# fails validate, and the belt is judged from the runner's real belt file (WO-20261013-89c7, AC-H1 to AC-H3).
. "$(dirname "$0")/../lib/assert.sh"
. "$(dirname "$0")/../lib/world.sh"
world_init
A=WO-20261012-7e13; B=WO-20261013-0b0b

# AC-H1: a ticket whose status on main is ready and whose work is on a branch with an open pull request is a live line with both.
ticket "$A" ready feat/a1-state-root null "State root"
live '[{"number":83,"headRefName":"feat/a1-state-root","title":"WO-20261012-7e13 - State root"}]' '["feat/a1-state-root"]'
t "collect with a live pull request" collect
RESULT_JQ "the ticket with an open pull request is a line" '(.lines | length) == 1 and .lines[0].ticket == "WO-20261012-7e13"'
RESULT_JQ "and the line names its branch and pull request" '.lines[0].sub == "in-review · feat/a1-state-root · PR 83"'
RESULT_JQ "and the sources line says what was read" '.sources | contains("1 open pull requests, 1 branches")'

# A ticket started in the fixture (its branch is on origin, no pull request yet) shows the same way, as in progress.
ticket "$B" ready feat/started null "Started one"
live '[]' '["feat/started"]'
collect
RESULT_JQ "a ready ticket whose branch is on origin is a line in progress" '.lines | map(select(.ticket == "WO-20261013-0b0b")) | .[0].sub == "in-progress · feat/started"'

# A pull request for a ticket main has no file for is drawn from its title.
live '[{"number":90,"headRefName":"feat/unknown","title":"WO-20261013-c0de - Not on main yet"}]' '[]'
collect
RESULT_JQ "a pull request names a ticket main lacks, and it is a line" '.lines | any(.ticket == "WO-20261013-c0de" and .name == "Not on main yet" and (.sub | contains("PR 90")))'

# Live line unavailable: nothing is promoted and the board says so.
rm -f "$W/live.json"; collect
RESULT_JQ "without the live line the ready ticket stays off the floor" '.lines | map(.ticket) | index("WO-20261012-7e13") == null'
RESULT_JQ "and the sources line says the pull requests are unavailable" '.sources | contains("pull requests unavailable")'

# AC-H2: in-progress on main with no branch and no pull request is stale; validate names it and exits 3, then 0 once it is closed.
world_init
S=WO-20261010-dead
ticket "$S" in-progress "" null "Left behind"
live '[]' '[]'
collect
RESULT_JQ "the stale ticket is listed" '.stale == ["WO-20261010-dead"]'
RESULT_JQ "and the headline counts it" '.headline | contains("1 stale")'
t "a stale entry still renders, so the board does not go dark" "$LOOP" render --in "$W/entry.json" --out "$W/page"
expect_exit 3 "validate fails on the stale ticket" "$LOOP" validate "$W/entry.json"
has "and names the ticket" "$W/.out" 'WO-20261010-dead is in-progress with no branch'
ticket "$S" "done" "" null "Left behind"
collect
RESULT_JQ "closed, the stale list is empty" '.stale == []'
expect_exit 0 "validate passes once the ticket is closed" "$LOOP" validate "$W/entry.json"
# A ticket with a branch that is gone from origin is stale too; with a live branch it is not.
ticket "$S" in-progress feat/gone null "Left behind"
live '[]' '[]'; t "collect with the live line ok and an in-progress ticket that has a branch" collect
RESULT_JQ "an in-progress ticket whose branch is gone from origin is stale" '.stale == ["WO-20261010-dead"]'
live '[]' '["feat/gone"]'; t "collect with the in-progress ticket's branch on origin" collect
RESULT_JQ "and not stale while its branch is on origin" '.stale == []'

# The repository's own tickets: none in progress on main may lack a branch (the check that fails the test run on one).
LOOP_ROOT="$REPO_ROOT" "$LOOP" collect --now "$NOW" --no-panes --no-live --out "$W/repo-entry.json" 2>"$W/.err" || { cat "$W/.err" >&2; }
expect_exit 0 "no in-progress ticket on main lacks a branch" "$LOOP" validate "$W/repo-entry.json"

# AC-H3: the belt is the runner's real belt file, judged against belt_max_age_seconds.
world_init
ticket WO-20261011-0050 in-progress feat/b null "Belt one"
belt 5; collect
RESULT_JQ "a belt touched 5 s ago is running" '.lines[0].belt == "live" and (.headline | contains("belt running"))'
belt 31; collect
RESULT_JQ "a belt touched 31 s ago is stopped" '.lines[0].belt == "stopped" and (.headline | contains("belt stopped"))'
rm -f "$ROOT_FIX/factory/state/belt"; collect
RESULT_JQ "no belt file is stopped" '.lines[0].belt == "stopped"'
# After roadmap A2 state_dir is ${tree:run}: the same belt, found under the state root.
echo '{"state_dir": "${tree:run}"}' > "$ROOT_FIX/factory/config/runner.json"
export COQ_STATE="$W/state"; mkdir -p "$COQ_STATE/run"; : > "$COQ_STATE/run/belt"
touch -d "@$(($(date -u -d "$NOW" +%s) - 5))" "$COQ_STATE/run/belt"
collect
RESULT_JQ "state_dir tree run finds the belt under the state root" '.lines[0].belt == "live"'
unset COQ_STATE
done_case
