#!/usr/bin/env bash
# Catches (WO-20261011-8fb3, AC-H3): --resume not reaching the claude it starts (a fresh session where the owner asked for a
# transcript back), the resumed session being handed the full brief again (it would post a second work.started), the flag being
# accepted for a runtime that has no session to resume or with a value that is not a session id, and the normal start path
# changing for anyone who does not pass it.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/assert.sh"; . "$HERE/../lib/world.sh"
world_up resume || exit 1
T=WO-20261010-8777; N=worker-wo-20261010-8777; SID=0b1f6c2e-4d52-4c0e-9a77-5f1d3e8a9c10
# BREADCRUMB 2026-10-13 - WO-20261013-0904 (test speed, polls part 4; design d-shape 5). What broke: two fixed `sleep 1` after a seat came
#   up (the lines before "the first prompt says the session was resumed" and "the brief is the first prompt"), each a guess at when the
#   stub agent had received and echoed its first prompt: a slow container read the screen too early and failed, a fast one idled the second.
#   Why this fix: wait_until on what the next assertion reads, the prompt text on the agent's recent output (agent_shows), for at most
#   15 s; the assertions are unchanged, so a prompt that never arrives still fails them, after wait_until names the pattern it waited for.
#   Rejected: a longer sleep (a cost on every run, forever) and dropping the wait (an early read is an empty screen). Cost: none.
agent_shows() { h agent read "$1" --source recent-unwrapped --lines 200 | grep -qE "$2"; }

echo "-- refusals build nothing"
"$SEAT" --ticket "$T" --role worker --runtime codex --resume "$SID" --worktree "$REPO" >/dev/null 2>"$WORLD/err"; rc=$?
assert_eq "codex has no claude session to resume, exit 3" "$rc" 3
assert_match "the refusal says so" "$(cat "$WORLD/err")" "runtime codex has none"
"$SEAT" --ticket "$T" --role worker --resume 'a b;c' --worktree "$REPO" >/dev/null 2>&1; assert_eq "a value that is not a session id is a usage error, exit 2" "$?" 2
"$SEAT" --ticket "$T" --role worker --resume >/dev/null 2>&1; rc=$?
check "--resume with no value is refused (exit $rc)" "$([ "$rc" != 0 ] && echo 1 || echo 0)"
assert_eq "nothing was built" "$(h workspace list | jq '[.result.workspaces[] | select(.label == "coq")] | length')" 0

echo "-- door 1: --ticket $T --role worker --resume $SID"
out="$("$SEAT" --ticket "$T" --role worker --resume "$SID" --worktree "$REPO")"; rc=$?
assert_eq "exits 0" "$rc" 0
agent="$(jq -r .agent <<<"$out")"
argv="$(h pane process-info --pane "$agent" | jq -r '[.result.process_info.foreground_processes[].argv | join(" ")] | join("; ")')"
assert_match "claude was started with the role's flags and --resume" "$argv" \
  "claude --model claude-sonnet-5-5 --effort high --permission-mode bypassPermissions --settings $STATE/seats/$N/settings.json --resume $SID"
wait_until 15 agent_shows "$N" "resumed session $SID as the worker seat $N on $T\\. Playbook playbooks/worker\\.md"
screen="$(h agent read "$N" --source recent-unwrapped --lines 200)"
assert_match "the first prompt says the session was resumed and names the playbook" "$screen" "resumed session $SID as the worker seat $N on $T\\. Playbook playbooks/worker\\.md"
assert_eq "the full brief was not sent" "$(grep -c 'Post your first record before anything else' <<<"$screen")" 0
"$SEAT" --check "$N" >/dev/null; assert_eq "--check exits 0" "$?" 0
"$SEAT" --down "$N" >/dev/null; assert_eq "--down exits 0" "$?" 0

echo "-- door 1 without --resume is as before"
out="$("$SEAT" --ticket "$T" --role worker --worktree "$REPO")"; rc=$?
assert_eq "exits 0" "$rc" 0
agent="$(jq -r .agent <<<"$out")"
argv="$(h pane process-info --pane "$agent" | jq -r '[.result.process_info.foreground_processes[].argv | join(" ")] | join("; ")')"
assert_eq "no --resume on the command line" "$(grep -c -- '--resume' <<<"$argv")" 0
wait_until 15 agent_shows "$N" "Playbook playbooks/worker\\.md"
assert_match "the brief is the first prompt" "$(h agent read "$N" --source recent-unwrapped --lines 200)" "Playbook playbooks/worker\\.md"
"$SEAT" --down "$N" >/dev/null; assert_eq "--down exits 0" "$?" 0

echo "-- door 2: --role merger --task .. --resume"
out="$("$SEAT" --role merger --task "merge ready pull requests" --resume "$SID" --worktree "$REPO")"; rc=$?
assert_eq "exits 0" "$rc" 0
agent="$(jq -r .agent <<<"$out")"; mn="$(jq -r .name <<<"$out")"
argv="$(h pane process-info --pane "$agent" | jq -r '[.result.process_info.foreground_processes[].argv | join(" ")] | join("; ")')"
assert_match "claude was started with --resume" "$argv" "claude .* --resume $SID"
"$SEAT" --down "$mn" >/dev/null; assert_eq "--down exits 0" "$?" 0
case_done
