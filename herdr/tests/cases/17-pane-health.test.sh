#!/usr/bin/env bash
# Catches (WO-20261012-b800, backlog m2jhs): bringup.sh --check calling a reserved monitor pane ok because its label is right
# while the command in it is dead (six panes for 40 minutes after the 2026-10-12 reboot), --apply not restarting such a pane, a
# slot labelled open that a human is working in being restarted over their job, one stuck pane stopping the panes after it,
# and a failure that stays down writing a 500 record on every run instead of once.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/assert.sh"; . "$HERE/../lib/world.sh"
world_up pane-health '.bringup_gate=true' || exit 1
BU="$REPO/herdr/bin/bringup.sh"; MON="$REPO/herdr/bin/monitors.sh"

slot_pane() { "$MON" status | sed -nE "s/^ +$1 .*\[([^]]+)\] +(in use|open)$/\1/p"; }
# BREADCRUMB 2026-10-13 - WO-20261013-2b64 (test speed, polls part 2). What broke: wait_health was a hand-rolled poll (30 looks, 0.5 s
#   apart) and four fixed `sleep 1` sat in the set +m section below, each paid in full on every run. Why this fix: wait_health keeps its
#   15 s and its two arguments but polls through wait_until (0.2 s apart, and a timeout names the health line it wanted); the sleeps
#   become wait_until on what each stood for: the pane being a bare shell, then the sleep job showing in (and leaving) its foreground.
#   Rejected: polling `h pane read` for the prompt (the prompt is the shell's, not what the case asserts on). Cost: none; the asserts
#   are unchanged.
# wait_health NAME STATE: poll monitors.sh health for up to 15 s until NAME reads ok or FAILED.
# The output goes through a variable: `health | grep -q` closes the pipe on the first match and pipefail reports the SIGPIPE.
health_reads() { local hl; hl="$("$MON" health 2>/dev/null)"; grep -qE "^$2 $1( |\$)" <<<"$hl"; }
wait_health() { wait_until 15 health_reads "$1" "$2"; }
# pane_bare PANE: the pane's foreground is its own shell and nothing else (the events loop's `sleep 15` is not a shell, so a live monitor is not bare).
pane_bare() { h pane process-info --pane "$1" | jq -e '.result.process_info | .foreground_process_group_id == .shell_pid and all(.foreground_processes[]?; ((.argv // [.name])[0] | split("/") | last | ltrimstr("-")) | IN("bash", "zsh", "sh"))' >/dev/null; }
# fg_has PANE NAME BOOL: whether the pane's foreground processes include one whose argv[0] is NAME reads BOOL (true or false).
fg_has() { [ "$(h pane process-info --pane "$1" | jq -r --arg n "$2" '[.result.process_info.foreground_processes[].argv[0]] | any(. == $n)')" = "$3" ]; }

echo "-- a fresh bringup leaves every reserved pane healthy"
"$BU" --worktree "$REPO" > "$WORLD/out" 2>&1; assert_eq "bringup exits 0" "$?" 0
"$MON" health > "$WORLD/health" 2>&1; assert_eq "monitors.sh health exits 0" "$?" 0
assert_eq "health says ok for every reserved slot that has a command, and says nothing else" "$(grep -vc '^ok ' "$WORLD/health")" 0
assert_match "events and queue are among them" "$(tr '\n' ' ' < "$WORLD/health")" "ok events.*ok queue"

echo "-- a dead command under a correct label is FAILED, in --check and in health"
ep="$(slot_pane '2\.1\.1')"; qp="$(slot_pane '2\.1\.2')"
h pane send-keys "$ep" C-c >/dev/null; h pane send-keys "$ep" C-c >/dev/null
wait_health events FAILED; assert_eq "health turns FAILED events within 15 s" "$?" 0
"$MON" health > "$WORLD/health" 2>&1; rc=$?
assert_eq "monitors.sh health exits 1" "$rc" 1
assert_match "health names the bare shell" "$(cat "$WORLD/health")" "FAILED events \\(pane $ep is a bare shell"
assert_match "the label still reads in use, which is what bringup used to trust" "$("$MON" status)" "2\\.1\\.1 event log tail - events  \\[$ep\\]  in use"
"$BU" --check --worktree "$REPO" > "$WORLD/out" 2>&1; rc=$?; out="$(tr '\n' ' ' < "$WORLD/out")"
assert_eq "--check exits 1" "$rc" 1
assert_match "--check prints FAILED pane-events and still judges the panes after it" "$out" "FAILED pane-events \\(pane $ep is a bare shell.*ok pane-queue.*ok pane-board"
assert_eq "--check wrote no 500 record" "$(event_count note 500)" 0

echo "-- --apply restarts it, in its own pane, and says so once"
"$BU" --worktree "$REPO" > "$WORLD/out" 2>&1; rc=$?; out="$(tr '\n' ' ' < "$WORLD/out")"
assert_eq "--apply exits 0" "$rc" 0
assert_match "fixed pane-events says why" "$out" "fixed pane-events \\(event log tail plugged in: pane $ep is a bare shell"
wait_health events ok; assert_eq "health reads ok again" "$?" 0
assert_eq "the same pane runs it" "$(slot_pane '2\.1\.1')" "$ep"
assert_eq "the queue pane was not touched" "$(slot_pane '2\.1\.2')" "$qp"

echo "-- a slot labelled open that a human is working in is left alone, and the panes after it are still repaired"
h pane rename "$ep" "2.1.1 OPEN - event log tail" >/dev/null
h pane send-keys "$qp" C-c >/dev/null; h pane send-keys "$qp" C-c >/dev/null
wait_health queue FAILED; assert_eq "queue is dead" "$?" 0
"$MON" health > "$WORLD/health" 2>&1
assert_match "health says the open slot runs a job and is left alone" "$(cat "$WORLD/health")" "FAILED events \\(slot 2\\.1\\.1 is labelled open but pane $ep runs .*left alone"
"$BU" --worktree "$REPO" > "$WORLD/out" 2>&1; rc=$?; out="$(tr '\n' ' ' < "$WORLD/out")"
assert_eq "apply exits 1 while a pane is stuck" "$rc" 1
assert_match "the stuck pane is FAILED, not taken" "$out" "FAILED pane-events \\(slot 2\\.1\\.1 is labelled open"
assert_match "the queue pane after it is still repaired" "$out" "fixed pane-queue"
assert_eq "the open slot's job was not interrupted" "$(h pane process-info --pane "$ep" | jq -r '.result.process_info | .foreground_process_group_id != .shell_pid')" true
n1="$(event_count note 500)"; assert_eq "one 500 record for the stuck pane" "$n1" 1
"$BU" --worktree "$REPO" > /dev/null 2>&1
assert_eq "a repeat inside 15 minutes writes no second 500" "$(event_count note 500)" "$n1"
h pane rename "$ep" "2.1.1 event log tail - events" >/dev/null
"$BU" --check --worktree "$REPO" > "$WORLD/out" 2>&1; assert_eq "labelled right again, --check exits 0" "$?" 0

echo "-- a busy slot labelled for another job is FAILED and is taken back by --apply"
h pane rename "$qp" "2.1.2 queue list - turnwatch" >/dev/null
"$MON" health > "$WORLD/health" 2>&1
assert_match "health names the wrong holder" "$(cat "$WORLD/health")" "FAILED queue \\(slot 2\\.1\\.2 holds '2\\.1\\.2 queue list - turnwatch', not queue\\)"
"$BU" --worktree "$REPO" > "$WORLD/out" 2>&1; assert_eq "apply exits 0" "$?" 0
assert_match "the slot is restored to its owner" "$("$MON" status)" "2\\.1\\.2 queue list - queue  \\[$qp\\]  in use"
echo "-- a job in the shell's own process group is still a job (WO-20261012-277d)"
# set +m keeps the background job in the shell's group (fg group = shell pid), the way bearings' node wait.mjs ran on the live host.
h pane send-keys "$ep" C-c >/dev/null; h pane send-keys "$ep" C-c >/dev/null
wait_until 10 pane_bare "$ep"
h pane run "$ep" 'set +m; sleep 600 & p=$!; wait' >/dev/null
wait_until 10 fg_has "$ep" sleep true
h pane rename "$ep" "2.1.1 OPEN - event log tail" >/dev/null
assert_eq "precondition: the job's group is the shell's group" "$(h pane process-info --pane "$ep" | jq -r '.result.process_info | .foreground_process_group_id == .shell_pid')" true
"$MON" health > "$WORLD/health" 2>&1
assert_match "health says the open slot runs a job, not that it is a bare shell" "$(cat "$WORLD/health")" "FAILED events \\(slot 2\\.1\\.1 is labelled open but pane $ep runs .*; left alone"
assert_eq "the job was not interrupted" "$(h pane process-info --pane "$ep" | jq -r '[.result.process_info.foreground_processes[].argv[0]] | any(. == "sleep")')" true
echo "-- and a bare shell in the same slot still reads idle"
h pane send-keys "$ep" C-c >/dev/null; h pane run "$ep" 'kill $p; set -m' >/dev/null
wait_until 10 fg_has "$ep" sleep false
"$MON" health > "$WORLD/health" 2>&1
assert_match "health says the open slot is a bare shell" "$(cat "$WORLD/health")" "FAILED events \\(slot 2\\.1\\.1 is open and its pane is a bare shell"

case_done
