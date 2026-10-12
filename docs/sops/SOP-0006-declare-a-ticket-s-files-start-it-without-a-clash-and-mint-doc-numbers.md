# SOP-0006: Declare a ticket's files, start it without a clash, and mint doc numbers

## Contents

- Purpose
- When to run this
- Steps
- Verification
- GOOD and NEVER

Diataxis mode: **how-to**.
Last reviewed: 2026-10-12.

## Purpose

No file is ever changed by two open PRs. A ticket declares the files it will change, start refuses an overlap, the gate refuses a stray path, and generated aggregates never ride a PR (WO-20261012-0677).

## When to run this

When you cut a ticket (declare its files), start one (wo-start.sh), write a SOP or an ADR (new-sop.sh), or find CHANGELOG.md, work-orders/INDEX.md or CONTEXT_STATE.md missing from a fresh checkout.

## Steps

1. At cut, the architect declares the files: `factory/bin/claims.sh set --id WO-... --files PATH_OR_GLOB...`. A bare directory or a trailing slash means its subtree; `*` crosses `/`. Commit the ticket with it.
2. Start with `bin/wo-start.sh --id WO-...`, never `work-order.sh start` directly. It runs `claims.sh start` first: exit 3 names each open PR or live ticket that holds a file. A ticket that declares no files cannot start.
3. On exit 3, do not start. Re-cut the ticket so its files differ, or wait for the PR to merge.
4. Before the PR is opened, run `factory/bin/gate.sh pr-files --ticket WO-...`. Exit 1 prints every path outside the files field, every aggregate and every doc number another PR already has.
5. Write a SOP with `bin/new-sop.sh` (the arguments of `docs.sh sop`). It takes the number from `bin/mint-id.sh sop`, which no other slot or open PR can hold.
6. CHANGELOG.md, work-orders/INDEX.md, the work-orders READMEs and CONTEXT_STATE.md are gitignored. Render them with `make aggregates`; never add them to a PR. `claims.sh diff` refuses a force-added one.

## Verification

Each line is a command and what it printed when it worked, from the runs recorded as evidence on WO-20261012-0677.

- `factory/bin/claims.sh start --id WO-...` on a ticket whose file an open PR changes exits 3 and prints `PR 31 (feat/scoped) changes herdr/bin/seat.sh, which WO-20261012-aaaa claims as herdr/bin/seat.sh`. With free files it exits 0 and prints nothing.
- `bin/wo-start.sh --id WO-...` on that ticket exits 3 and never calls `work-order.sh`; with free files it calls `work-order.sh start --project DIR --id WO-...`.
- `factory/bin/gate.sh pr-files --ticket WO-...` on a clean diff exits 0 and prints nothing. On a stray path and a force-added aggregate it exits 1 with one line: `factory/config/routes.json is outside the files field of WO-20261012-aaaa; CHANGELOG.md is an aggregate (CHANGELOG.md): it is rendered after the merge and never rides a PR`.
- `bin/mint-id.sh sop` with SOP-0002 in the tree and SOP-0003 in an open PR printed `SOP-0004`, then `SOP-0005` on the next call; four calls at the same moment printed four different numbers.
- `factory/bin/claims.sh ids` on a diff that adds a number an open PR holds exits 3 and prints `SOP-0002 is taken by PR 31 adds docs/sops/SOP-0002-b.md`.
- `git check-ignore CHANGELOG.md CONTEXT_STATE.md work-orders/INDEX.md` prints all three paths, and `git ls-files` lists none of them.

## GOOD and NEVER

GOOD: a ticket whose files field is `herdr/bin/seat.sh`, started with `bin/wo-start.sh` only when no open PR changes that file.
GOOD: a SOP written with `bin/new-sop.sh`, so its number is one no other slot or open PR holds.
GOOD: `factory/bin/gate.sh pr-files --ticket WO-...` run before the PR is opened, until it exits 0.
NEVER: `git add -f CHANGELOG.md`, `CONTEXT_STATE.md` or `work-orders/INDEX.md`, because an aggregate in a diff is what made every merge conflict the next PR.
NEVER: start a ticket with `work-order.sh start` directly, because it skips the overlap check and only the gate catches that PR, one step later.
NEVER: write a SOP with `docs.sh sop` directly, because it numbers from its own working tree and two PRs take the same number.
