#!/usr/bin/env bash
# Execution ledger appender - the only writer of a project's rail ledger.
#
# Why this exists: a status page updated by hand drifts from the work it claims to show. One script
# writes the ledger row and prints the same text, so the line pasted to the owner and the recorded
# row can never disagree. The page is built from this file and from nothing else.
#
# BREADCRUMB - why the environment variables are RAIL_*, not RIME_*.
# What broke: the upstream copy of this script (~/.claude/skills/execution-rail/bin/ledger.sh, line 10)
#   defaulted its ledger path to one specific investigation directory. A project that called it without
#   exporting the variable appended its rows to that other project's ledger.
# Why that mattered: the ledger is the sole source the page renders from. A row in the wrong file never
#   appears on the right page, and a foreign row corrupts the other project's record at the same time -
#   two broken records from one missing export, with no error at any point.
# Why this fix: the vendored copy takes RAIL_LEDGER with no default at all and refuses to run without it,
#   so the failure is a message at the first call instead of silent corruption discovered later.
#   Rejected: keeping the default and documenting the export, which is the arrangement that already failed.
# Cost: every caller must set RAIL_LEDGER. report/rail.sh does it, so no human ever types it.
#
# Usage: ledger.sh <step> <started|complete|blocked|issue|question|checkpoint> "<text, 15 words max>" [ref]
#        ledger.sh --show [n]     print the last n rows (default 10)
set -euo pipefail
L="${RAIL_LEDGER:?RAIL_LEDGER must name the ledger file of this project, set by report/rail.sh}"
hdr='at_utc	step	status	text	by	ref'
[ -f "$L" ] || printf '%s\n' "$hdr" > "$L"
if [ "${1:-}" = "--show" ]; then n="${2:-10}"; { head -1 "$L"; tail -n "$n" "$L" | grep -v '^at_utc'; } | column -t -s $'\t'; exit 0; fi
# BREADCRUMB - S-05 L1 (review: ~/.local/state/dotfiles/execution/S-05-review.md).
# What broke: this line was sed -n '21,22p', one off, so a bare call printed the --show line and
#   `set -euo pipefail` instead of the two usage lines above.
# Why it mattered: the usage text is what a seat reads after a wrong call; code teaches it nothing.
# Why this fix: select the usage lines by their shape, so a comment added above them (this one
#   included) cannot shift the range again. Rejected: correcting the numbers, which is the same trap.
# Cost: none.
[ $# -ge 3 ] || { grep -E '^# (Usage: | +)ledger\.sh ' "$0"; exit 2; }
step="$1"; status="$2"; text="$3"; ref="${4:-}"
case "$status" in started|complete|blocked|issue|question|checkpoint) ;; *) echo "status must be started|complete|blocked|issue|question|checkpoint" >&2; exit 2;; esac
[[ "$step" =~ ^[A-Z]-[0-9]{2}[a-z0-9.-]*$ ]] || { echo "step must look like E-01 or F-12" >&2; exit 2; }
words=$(wc -w <<<"$text"); [ "$words" -le 15 ] || { echo "text is $words words, limit 15" >&2; exit 2; }
case "$text$ref" in *$'\t'*|*$'\n'*) echo "no tabs or newlines in text or ref" >&2; exit 2;; esac
at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"; by="${RAIL_SEAT:-unnamed-seat}"
printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$at" "$step" "$status" "$text" "$by" "$ref" >> "$L"
printf '%s %s: %s\n' "$step" "$status" "$text"
