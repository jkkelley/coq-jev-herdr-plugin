#!/usr/bin/env bash
# Catches (WO-20261012-8fb2): a compacted seat not seeing its own newest CONTEXT_STATE.md checkpoint (the hook printing nothing, the
# wrong seat's, or an older one than the top), the hook failing the compact turn instead of saying what was missing (a missing
# worktree, checkpoint, seat record, pane id or checkpoint.sh), an ended seat record that reused the pane id winning over the live
# one, the SessionStart entry firing on startup or resume instead of compact only, the entry missing from either settings file or
# spelled differently in the two (it would run twice), and break glass replacing the hooks key and dropping the entry.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/assert.sh"; . "$HERE/../lib/world.sh"
world_up resumecp || exit 1
T=WO-20261010-8777; N=worker-wo-20261010-8777
HOOK="$REPO/herdr/bin/resume-checkpoint.sh"
CPSH="$REPO/.claude/skills/context-compaction/scripts/checkpoint.sh"
# WO-20261012-e36e: .claude/skills/ is gitignored (skill-sync installs it), so a clean checkout has no checkpoint.sh. The world
# gets the tracked fixture at the path the hook falls back to, whatever the copy held; the real hook then runs unmodified.
mkdir -p "$(dirname "$CPSH")"; cp "$REPO/herdr/tests/fixtures/checkpoint.sh" "$CPSH"
WT="$WORLD/wt"; mkdir -p "$WT"

# run_hook PANE: the hook's stdout and exit code with a private HOME, so only COQ_CHECKPOINT_SH or the repo copy can answer.
run_hook() { out="$(HERDR_PANE_ID="$1" "$HOOK" 2>"$WORLD/hook.err")"; rc=$?; }
# seatrec NAME PANE WORKTREE STARTED ENDED: a seat record as seat.sh writes it, with the fields the hook reads.
seatrec() {
  mkdir -p "$STATE/seats/$1"
  jq -n --arg n "$1" --arg p "$2" --arg w "$3" --arg s "$4" --arg e "$5" '{name:$n,pane:$p,worktree:$w,started_at:$s,ended_at:(if $e == "" then null else $e end)}' > "$STATE/seats/$1/seat.json"
}

echo "-- the wiring: compact only, in both settings files, spelled the same (AC-H3)"
P="$REPO/.claude/settings.json"
assert_eq "the project file has exactly one SessionStart entry with matcher compact" "$(jq '[.hooks.SessionStart[] | select(.matcher == "compact")] | length' "$P")" 1
assert_eq "no SessionStart entry names startup or resume" "$(jq '[.hooks.SessionStart[].matcher | select(test("startup|resume|clear"))] | length' "$P")" 0
assert_eq "the guard's entry is still first" "$(jq -r '.hooks.SessionStart[0].hooks[0].command' "$P")" "/home/luna/.local/bin/compaction-guard hook"
assert_eq "the compact entry comes after the guard's" "$(jq -r '.hooks.SessionStart | map(.matcher) | index("compact")' "$P")" 1
PCMD="$(jq -r '.hooks.SessionStart[] | select(.matcher == "compact") | .hooks[0].command' "$P")"

echo "-- seat up: the rendered settings carry the same entry (the seat.sh half of the wiring)"
out="$("$SEAT" --ticket "$T" --role worker --worktree "$REPO")"; rc=$?
assert_eq "seat.sh exits 0" "$rc" 0
agent="$(jq -r .agent <<<"$out")"
S="$STATE/seats/$N/settings.json"
assert_eq "one compact entry in the rendered settings" "$(jq '[.hooks.SessionStart[] | select(.matcher == "compact")] | length' "$S")" 1
assert_eq "no other SessionStart entry in the rendered settings" "$(jq '.hooks.SessionStart | length' "$S")" 1
assert_eq "the command is the project file's, character for character" "$(jq -r '.hooks.SessionStart[0].hooks[0].command' "$S")" "$PCMD"
CFGT="$(jq -r .resume_checkpoint.hook_timeout_seconds "$REPO/herdr/config/herdr.json")"
assert_eq "the rendered timeout is the config's, not a literal" "$(jq -r '.hooks.SessionStart[0].hooks[0].timeout' "$S")" "$CFGT"
assert_eq "the project file's timeout agrees with the config" "$(jq -r '.hooks.SessionStart[] | select(.matcher == "compact") | .hooks[0].timeout' "$P")" "$CFGT"
assert_eq "the command names the hook script that exists" "$([ -x "$REPO/herdr/bin/resume-checkpoint.sh" ] && echo yes)" yes
"$SEAT" --check "$N" >/dev/null; assert_eq "--check exits 0 on the fresh render" "$?" 0

echo "-- the live seat gets its own newest checkpoint (AC-H1)"
top="$(bash "$CPSH" read --project "$REPO" --top 1)"
check "the world's CONTEXT_STATE.md has a checkpoint to show" "$([ -n "$top" ] && echo 1 || echo 0)"
run_hook "$agent"
assert_eq "exits 0" "$rc" 0
assert_match "the output opens by saying whose checkpoint it is" "$out" "^resume-checkpoint: your own newest checkpoint from $REPO/CONTEXT_STATE.md"
check "the output holds the top checkpoint verbatim" "$([[ "$out" == *"$top"* ]] && echo 1 || echo 0)"
second="$(bash "$CPSH" read --project "$REPO" --top 2 | awk '/^## Checkpoint /{n++} n==2' | head -1)"
check "and not the second one" "$([ -n "$second" ] && [[ "$out" != *"$second"* ]] && echo 1 || echo 0)"
assert_eq "the one checkpoint heading appears once" "$(grep -c '^## Checkpoint ' <<<"$out")" 1

echo "-- two seat records share a pane id: the live, newest one answers"
mkdir -p "$WORLD/wt-old" "$WORLD/wt-new"
printf '# CONTEXT_STATE.md\n\n## Checkpoint 2026-10-12 01:00 OLD\nold seat resume line\n' > "$WORLD/wt-old/CONTEXT_STATE.md"
printf '# CONTEXT_STATE.md\n\n## Checkpoint 2026-10-12 02:00 NEW\nnew seat resume line\n\n## Checkpoint 2026-10-12 01:30 OLDER\nolder line\n' > "$WORLD/wt-new/CONTEXT_STATE.md"
seatrec ended-seat w9:p1 "$WORLD/wt-old" 2026-10-12T03:00:00Z 2026-10-12T04:00:00Z
seatrec older-live w9:p1 "$WORLD/wt-old" 2026-10-12T01:00:00Z ""
seatrec newer-live w9:p1 "$WORLD/wt-new" 2026-10-12T02:00:00Z ""
run_hook w9:p1
assert_eq "exits 0" "$rc" 0
assert_match "the newest live seat's checkpoint is shown" "$out" "new seat resume line"
check "an older checkpoint of that seat is not" "$([[ "$out" != *"older line"* ]] && echo 1 || echo 0)"
check "an ended record's worktree is not used" "$([[ "$out" != *"old seat resume line"* ]] && echo 1 || echo 0)"

echo "-- every missing piece exits 0 with one line (AC-H2)"
one_line() { assert_eq "$1: exits 0" "$rc" 0; assert_eq "$1: one line on stdout" "$(printf '%s\n' "$out" | wc -l | tr -d ' ')" 1; assert_match "$1: says what was missing" "$out" "^resume-checkpoint: .*$2"; }
mkdir -p "$WORLD/wt-empty"; seatrec nocp w9:p2 "$WORLD/wt-empty" 2026-10-12T02:00:00Z ""
run_hook w9:p2; one_line "a worktree with no CONTEXT_STATE.md" "no checkpoint in $WORLD/wt-empty"
printf '# CONTEXT_STATE.md\n\nno checkpoints yet\n' > "$WORLD/wt-empty/CONTEXT_STATE.md"
run_hook w9:p2; one_line "a CONTEXT_STATE.md with no checkpoint" "no checkpoint in $WORLD/wt-empty"
seatrec gone w9:p3 "$WORLD/does-not-exist" 2026-10-12T02:00:00Z ""
run_hook w9:p3; one_line "a worktree that is gone" "worktree $WORLD/does-not-exist of pane w9:p3 is missing"
run_hook w9:p9; one_line "a pane no live seat holds" "no live seat record names pane w9:p9"
out="$(env -u HERDR_PANE_ID "$HOOK" 2>/dev/null)"; rc=$?; one_line "no HERDR_PANE_ID" "HERDR_PANE_ID is unset"
out="$(COQ_STATE="$WORLD/nostate" HERDR_PANE_ID=w9:p1 "$HOOK" 2>/dev/null)"; rc=$?; one_line "no seat records at all" "no seat records under $WORLD/nostate"
mv "$CPSH" "$WORLD/checkpoint.sh.away"
run_hook w9:p1; one_line "no checkpoint.sh anywhere" "checkpoint.sh was not found"
mv "$WORLD/checkpoint.sh.away" "$CPSH"
out="$(COQ_CHECKPOINT_SH="$WORLD/nope.sh" HERDR_PANE_ID=w9:p1 "$HOOK" 2>/dev/null)"; rc=$?
assert_eq "an override that does not exist falls through to the repo copy" "$rc" 0
assert_match "and the checkpoint still shows" "$out" "new seat resume line"

echo "-- --down leaves the world clean"
"$SEAT" --down "$N" >/dev/null; assert_eq "--down exits 0" "$?" 0
case_done
