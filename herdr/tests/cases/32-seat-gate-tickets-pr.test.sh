#!/usr/bin/env bash
# Catches: the belt (factory/bin/route.sh, `seat.sh --ticket T --role tester|reviewer`) being refused for a tickets-only pull
# request, because the ticket was never started and its frontmatter branch is null; seat.sh took the branch from the ticket and
# nowhere else, so PRs 89, 96 and 98 sat in rework while the orchestrator seated their gates by hand with --worktree
# (WO-20261013-a0e2, cause f, record b5yad). A seat for a ticket with a null branch now takes the head ref of the open pull request
# titled with the ticket id, from gh, and its slot is put on that branch.
# AC-H1: a tester and a reviewer seated for a null-branch ticket with an open pull request come up with no --worktree and no hand
#        step, in a slot on the pull request's head, tracking origin; this fails without the fix (the refusal "has no branch yet").
# Also: no pull request, a pull request titled for another ticket, and a head that no origin has all still refuse with exit 3 and
# leave no lease behind; a ticket that has a branch never asks gh.
# The pool is the stub treehouse and the pull requests are the stub gh (tests/stubs), so nothing real is leased or fetched.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/assert.sh"; . "$HERE/../lib/world.sh"
world_up gatepr || exit 1
export TREEHOUSE_STUB_LOG="$WORLD/treehouse.log"; : > "$TREEHOUSE_STUB_LOG"
export GH_STUB_LOG="$WORLD/gh.log" GH_STUB_PRS="$WORLD/prs.json"; : > "$GH_STUB_LOG"
T=WO-20261010-d354; NT=tester-wo-20261010-d354; NR=reviewer-wo-20261010-d354   # a fixture ticket whose branch is null
OTHER=WO-20261010-8777; HEAD=feat/tickets-only-pr
pool() { treehouse status --json; }
gh_calls() { wc -l < "$GH_STUB_LOG" | tr -d ' '; }
tfile() { find "$REPO/work-orders" -name "$1-*.md" -not -path '*/archive/*' | head -1; }
branch_of() { awk '/^---$/{c++; next} c==1' "$(tfile "$1")" | jq -r .branch; }
slot_branch() { git -C "$1" rev-parse --abbrev-ref HEAD; }
prs() { jq -nc "$1" > "$GH_STUB_PRS"; }
ORIGIN="$WORLD/origin.git"; SEED="$WORLD/seed"
git init -q --bare "$ORIGIN"; git clone -q "$ORIGIN" "$SEED" 2>/dev/null
git -C "$SEED" commit -q --allow-empty -m "seed main" && git -C "$SEED" push -q origin main || { echo "case 32: could not seed the origin"; exit 1; }
git -C "$SEED" checkout -q -b "$HEAD" main && git -C "$SEED" commit -q --allow-empty -m "tickets only" && git -C "$SEED" push -q origin "$HEAD" && git -C "$SEED" checkout -q main
export TREEHOUSE_STUB_ORIGIN="$ORIGIN"
assert_eq "the fixture ticket has no branch, as a tickets-only pull request's does" "$(branch_of "$T")" null

echo "-- no pull request: refused as before, exit 3, nothing leased"
"$SEAT" --ticket "$T" --role tester >/dev/null 2>"$WORLD/err"; rc=$?
assert_eq "exit 3" "$rc" 3
assert_match "the refusal names the ticket and the missing branch" "$(cat "$WORLD/err")" "ticket $T has no branch yet"
assert_eq "no slot was leased" "$(pool | jq length)" 0

echo "-- a pull request titled for another ticket does not count"
prs "[{number:5,title:\"$OTHER - something else\",headRefName:\"feat/other\"},{number:6,title:\"x $T - mentions it\",headRefName:\"feat/mention\"},{number:7,title:\"${T}9 - near\",headRefName:\"feat/near\"}]"
"$SEAT" --ticket "$T" --role tester >/dev/null 2>"$WORLD/err"; rc=$?
assert_eq "exit 3" "$rc" 3
assert_eq "no slot was leased" "$(pool | jq length)" 0

echo "-- AC-H1: the open pull request titled with the ticket gives the tester its branch"
prs "[{number:5,title:\"$OTHER - something else\",headRefName:\"feat/other\"},{number:98,title:\"$T - Tickets: test speed\",headRefName:\"$HEAD\"}]"
out="$("$SEAT" --ticket "$T" --role tester)"; rc=$?
assert_eq "exit 0" "$rc" 0
slot="$(jq -r .worktree <<<"$out")"
assert_match "the tester's worktree is a slot of the pool" "$slot" "^$HOME/.treehouse-stub/slots/[0-9]+$"
assert_eq "the slot is on the pull request's head" "$(slot_branch "$slot")" "$HEAD"
assert_eq "that branch tracks origin" "$(git -C "$slot" rev-parse --abbrev-ref "$HEAD@{upstream}")" "origin/$HEAD"
assert_eq "the slot holds the tip origin has for it" "$(git -C "$slot" rev-parse HEAD)" "$(git -C "$ORIGIN" rev-parse "refs/heads/$HEAD")"
assert_eq "the ticket's own frontmatter is untouched" "$(branch_of "$T")" null
assert_eq "seat.json lease is the ticket's, owned by the seat" "$(jq -c '[.lease.holder, .lease.owned]' "$STATE/seats/$NT/seat.json")" "[\"$T\",true]"

echo "-- the reviewer of the same pull request gets it the same way"
"$SEAT" --down "$NT" >/dev/null; assert_eq "the tester is taken down" "$?" 0
out="$("$SEAT" --ticket "$T" --role reviewer)"; rc=$?
assert_eq "exit 0" "$rc" 0
slot="$(jq -r .worktree <<<"$out")"
assert_eq "the reviewer's slot is on the head" "$(slot_branch "$slot")" "$HEAD"
"$SEAT" --down "$NR" >/dev/null; assert_eq "the reviewer is taken down" "$?" 0
assert_eq "the pool is empty again" "$(pool | jq length)" 0

echo "-- a head that origin does not have is refused, and the lease it took is given back"
prs "[{number:98,title:\"$T - Tickets: test speed\",headRefName:\"feat/never-pushed\"}]"
"$SEAT" --ticket "$T" --role tester >/dev/null 2>"$WORLD/err"; rc=$?
assert_eq "exit 3" "$rc" 3
assert_match "the refusal names the branch" "$(cat "$WORLD/err")" "could not be put on feat/never-pushed for $T"
assert_eq "the pool is empty again" "$(pool | jq length)" 0

echo "-- a ticket that has a branch never asks gh"
git -C "$SEED" checkout -q -b feat/has-branch main && git -C "$SEED" commit -q --allow-empty -m "w" && git -C "$SEED" push -q origin feat/has-branch && git -C "$SEED" checkout -q main
f="$(tfile "$OTHER")"
{ echo '---'; awk 'c<2 && /^---$/{c++; next} c==1' "$f" | jq '.branch="feat/has-branch"'; echo '---'; awk 'c<2 && /^---$/{c++; next} c>=2' "$f"; } > "$f.tmp" && mv "$f.tmp" "$f"
before=$(gh_calls)
"$SEAT" --ticket "$OTHER" --role tester >/dev/null; assert_eq "exit 0" "$?" 0
assert_eq "gh was not called" "$(gh_calls)" "$before"
"$SEAT" --down "tester-wo-20261010-8777" >/dev/null
case_done
