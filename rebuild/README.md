# Factory rebuild plan

## Contents

1. What this directory is
2. Files in the repository
3. Outputs outside the repository
4. Validator used on this machine
5. Commands
6. Not built
7. Cleanup

## 1. What this directory is

This directory holds the Factory Rebuild Plan, ten steps R-01 to R-10 from today's factory to a factory that no agent or human drives.
The plan is XML, validated against its own XSD.
It stands beside the binding 2026-10-12 roadmap and never replaces or edits it.
Everything under `plan.json` and `side.html` is generated from the XML and is never hand-edited.

## 2. Files in the repository

- `factory-rebuild-plan.xml` is the plan, at most 1000 lines, validated on every write.
- `schema/factory-rebuild-plan.xsd` is its schema.
- `bin/plan-validate.sh` validates the XML against the XSD, then runs the checks XSD 1.0 cannot express, and exits non-zero on any error.
- `bin/plan-to-rail.sh` generates `plan.json` and `side.html` from the XML, and `--check` fails if either has drifted.
- `plan.json` is the execution rail's plan, an ordered array of `{id, t, who, gate, owner}`, generated and committed.
- `side.html` holds the rail's folded panels for the status code map, the build mode rule, the failure cases and the recovery section, generated and committed.
- `rail.sh` calls the execution-rail skill with every path wired, and refuses to build if the generated files have drifted.

## 3. Outputs outside the repository

All of these live under `~/.local/state/coq/coq-jev-herdr-plugin/rebuild/2026/10/plan/` and none is ever committed.

- `ledger.tsv` is appended only by `~/.claude/skills/execution-rail/bin/ledger.sh` with `RIME_LEDGER` pointing at it.
- `page.html` is the built rail page.
- `.approved` is written by the build with `--approved`.

Related locations under `~/.local/state/coq/coq-jev-herdr-plugin/rebuild/`:

- `venv/` is the python environment for the XSD validator.
- `wt/plan-and-rail/` is the worktree this plan was authored in.
- `2026/10/briefs/`, `2026/10/investigation/`, `2026/10/decisions/` and `2026/10/proofs/` hold the briefs and the step outputs.

A pointer to the plan sits at `~/.local/state/coq/coq-jev-herdr-plugin/plans/2026/10/20261014-factory-rebuild-plan.md`.

## 4. Validator used on this machine

On 2026-10-14 `xmllint` is not installed, and neither `lxml` nor `xmlschema` is importable from the system python.
The validator is therefore the python package `xmlschema` in the venv at `~/.local/state/coq/coq-jev-herdr-plugin/rebuild/venv`.
`bin/plan-validate.sh` prefers `xmllint` when it exists, and otherwise creates the venv itself with up to three install attempts.

## 5. Commands

- Validate: `rebuild/bin/plan-validate.sh`
- Generate: `rebuild/bin/plan-to-rail.sh`
- Check for drift: `rebuild/bin/plan-to-rail.sh --check`
- Log a ledger row: `RIME_LEDGER=~/.local/state/coq/coq-jev-herdr-plugin/rebuild/2026/10/plan/ledger.tsv RIME_SEAT=<seat> ~/.claude/skills/execution-rail/bin/ledger.sh <step> <status> "<text>" [ref]`
- Build the page: `rebuild/rail.sh` and add `--approved` once the owner gives the signal.
- Publish: give the printed `page.html` path to the Artifact tool, to the same URL after the first time.

## 6. Not built

`bin/plan-render.sh`, the optional markdown view of the XML, was skipped.
The XML is readable on its own and the rail page is the generated view, so a second view was not worth a second thing to keep true.

## 7. Cleanup

To remove every untracked output of this directory:

```sh
rm -rf ~/.local/state/coq/coq-jev-herdr-plugin/rebuild/2026/10/plan ~/.local/state/coq/coq-jev-herdr-plugin/rebuild/venv
```

To remove the authoring worktree after the pull request merges:

```sh
git worktree remove ~/.local/state/coq/coq-jev-herdr-plugin/rebuild/wt/plan-and-rail
```
