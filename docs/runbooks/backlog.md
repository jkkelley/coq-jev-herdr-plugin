# Runbook: the backlog is GitHub issues

## Contents

- Purpose
- The model
- Add an item
- Read the backlog
- Change a priority
- Finish an item
- Find an item by its old id
- Move an old backlog tree into issues
- When something goes wrong
- Prove the script
- GOOD and NEVER

Diataxis mode: **how-to**.
Last reviewed: 2026-10-12.
Ticket: WO-20261012-6c76 - Roadmap H - Backlog lives in GitHub issues: each backlog item becomes an issue with a priority label and backlog/ leaves git.
Script: `bin/backlog.sh`.
Owner card: C14 in `ROADMAP.md`.

## Purpose

A backlog item used to be a file under `backlog/`, so adding one needed a branch and a pull request.
Now an item is one GitHub issue, and adding, moving or finishing one changes no file in git.
Nothing about the backlog rides a pull request, so it can never put a second pull request on a file that one already holds.

## The model

| Thing          | Where it lives                                                                                  |
| -------------- | ----------------------------------------------------------------------------------------------- |
| An item        | one GitHub issue with the label `backlog`                                                       |
| Its title      | the issue title, one line                                                                       |
| Why, done-when | the issue body, as `**Why:**` and `**Done when:**`                                              |
| Its priority   | exactly one label of `priority: critical`, `priority: now`, `priority: next`, `priority: later` |
| Done           | the issue is closed as completed                                                                |
| Its old id     | `<!-- backlog-id: SUFFIX -->` on the first line of the body, only on migrated items             |

The old buckets map one to one: `now/` is `priority: now`, `next/` is `priority: next`, `later/` is `priority: later`.
`critical` is new, because the owner called one item critical in its why line and the tree had no field for it.
A closed issue keeps no priority that means anything; `done/` items were filed closed with none.

The script talks to the repository `gh` resolves from the current checkout.
Set `COQ_BACKLOG_REPO=OWNER/NAME` to name another one.

## Add an item

```sh
bin/backlog.sh add --title "One line, what the item is" --why "Why it earned a slot" --done-when "A check someone can run without asking" [--priority critical|now|next|later]
```

It prints `#N`, the issue number, and creates the labels it needs the first time.
The default priority is `later`.
Do not write a file; `git status` is unchanged after it.

## Read the backlog

```sh
bin/backlog.sh list                      # open items, one line each: number, priority, state, old id, title
bin/backlog.sh list --priority critical  # one priority
bin/backlog.sh list --state all --json   # every item, open and closed, as a JSON array
```

The window rule of `AGENTS.md` still holds: every open item in full, and the newest ten closed items only.

## Change a priority

```sh
bin/backlog.sh move --id 12 --to now
```

It swaps the priority label and nothing else.
It refuses a closed issue (exit 3), because a closed item has no priority to move.
Moving to the priority the issue already has is a reported no-op.

## Finish an item

```sh
bin/backlog.sh done --id 12
```

It closes the issue as completed.
A second `done` on a closed issue is a reported no-op.
Reference the issue in the pull request that finished it (`Closes #12`) when that is easier; the effect is the same.

## Find an item by its old id

Source comments cite items by the five-character suffix they had under `backlog/`, for example "backlog disva".
Every migrated issue carries that suffix, and `--id` takes it:

```sh
bin/backlog.sh list --state all | grep disva
bin/backlog.sh move --id disva --to next
```

## Move an old backlog tree into issues

This is a one-time job per tree, and it is safe to run again.
`migrate` reads every item of each source, checks all of them before it files anything, then files the items oldest first, so issue numbers follow the order the items were added.
An item whose old id is already on an issue is skipped, so a run that stopped halfway is finished by running it again.

```sh
bin/backlog.sh migrate --from-dir PATH/TO/backlog --dry-run     # shows each item and the priority it would get, files nothing
bin/backlog.sh migrate --from-dir PATH/TO/backlog               # files them
bin/backlog.sh migrate --from-ref SOME_BRANCH --from-dir PATH/TO/backlog
```

A source is `--from-dir DIR`, where DIR holds `now/ next/ later/ done/`, or `--from-ref REF`, a commit or branch whose tree has `backlog/`.
Give both when the items are spread across a branch and a working copy.
Sources are read in the order given and the first copy of an id wins.
`done/` items are filed closed, and an item whose why line contains the word `critical` is filed `priority: critical`.
Read the dry run before the real run, because the word rule is a guess a person should look at.

Never run two `migrate` commands at once; the skip check reads the issues once at the start.

## When something goes wrong

| Exit | Meaning                                                                      | Do                                                         |
| ---- | ---------------------------------------------------------------------------- | ---------------------------------------------------------- |
| 2    | a flag is missing or wrong, or a priority is not one of the four             | read the usage with `bin/backlog.sh`                       |
| 3    | a migrate source holds a file that is not an item, or `move` on a closed one | the message names the file or the issue; nothing was filed |
| 4    | `gh` or `git` failed, a ref is not a commit, or a source is not a directory  | read the message; for `migrate`, run it again              |
| 6    | `--id` names no backlog issue                                                | `bin/backlog.sh list --state all`                          |

If `gh` is not signed in, every verb exits 4 at the first call; fix that with the owner's `gh auth` before anything else.
`.claude/scripts/backlog.sh` is the old scaffold script for the `backlog/` tree.
It still exists in the repository, it is a managed file, and running it recreates the tree this runbook retires; do not run it.

## Prove the script

```sh
bash bin/backlog.sh selftest
```

It runs every verb against a stub `gh` in a scratch directory, with no network and no real issue created, and it checks that a scratch git checkout is unchanged after each write.
It exits 3 and names each failed case.
`make lint` runs `shellcheck` over the script.

## GOOD and NEVER

GOOD: `bin/backlog.sh add ...` for a new idea, then carry on; the issue is the whole record.
GOOD: `migrate --dry-run` first, then the real run, then `list --state all` to compare the count with the source.
NEVER: adding a file under `backlog/`, or `git add -f` on one.
NEVER: editing the `backlog-id` comment on an issue; `migrate` and `--id SUFFIX` read it.
NEVER: closing an issue by hand to file a different one in its place; `move` and `done` are the two ways it changes.
