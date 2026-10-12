# SOP-0006: Declare a ticket's files, start it without a clash, and mint doc numbers

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

A step that cannot be verified is a wish.
Record what the successful run actually printed.
