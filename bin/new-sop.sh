#!/usr/bin/env bash
# new-sop.sh - write a SOP with a minted number (WO-20261012-0677, AC-H4): the same arguments and output as `docs.sh sop`, but the id comes
# from bin/mint-id.sh, so two PRs cannot both take SOP-0003.
#
#   new-sop.sh --project DIR --title T --purpose P --when W --steps S     prints the id; the file is docs/sops/<id>-<slug>.md
# Env: DOCS_SH=PATH the docs.sh to call (default the living-docs skill's copy). Exit: docs.sh's, or 4 when the id it wrote is not the minted one.
#
# BREADCRUMB 2026-10-12 - WO-20261012-0677. What broke: docs.sh sop has no --id, and it numbers from the highest file in the directory it is
#   given (see bin/mint-id.sh). Why this fix: docs.sh owns the SOP format, so it still writes the file; it is run on a scratch project whose
#   docs/sops holds one placeholder numbered one below the minted id, so the number it picks is the minted one, and the file is then moved
#   into the real project. Rejected: copying the format here (two writers to keep in step) and renaming the file after docs.sh ran (the
#   title line inside it would still carry the old id). Cost: if docs.sh ever numbers differently, this refuses with exit 4 and leaves the
#   minted number unused rather than write a SOP under the wrong id.
set -uo pipefail
HERE=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd); REPO=$(cd "$HERE/.." && pwd)
DOCS=${DOCS_SH:-$REPO/.claude/skills/living-docs/scripts/docs.sh}
die() { local c=$1; shift; printf 'new-sop: %s\n' "$*" >&2; exit "$c"; }
[ -f "$DOCS" ] || die 4 "no docs.sh at $DOCS"
project=""; args=()
while [ $# -gt 0 ]; do case $1 in --project) project=${2:-}; shift 2;; *) args+=("$1"); shift;; esac; done
[ -d "$project" ] || die 2 "--project DIR is required and must exist"
id=$(bash "$HERE/mint-id.sh" sop --repo "$project") || die 4 "mint-id failed"
n=$((10#${id#SOP-})); scratch=$(mktemp -d) || die 4 "no scratch dir"; trap 'rm -rf "$scratch"' EXIT
mkdir -p "$scratch/docs/sops"; [ "$n" -le 1 ] || : > "$scratch/docs/sops/$(printf 'SOP-%04d' $((n - 1)))-placeholder.md"
got=$(bash "$DOCS" sop --project "$scratch" "${args[@]}") || die 4 "docs.sh sop failed"
[ "$got" = "$id" ] || die 4 "docs.sh wrote $got, not the minted $id"
mkdir -p "$project/docs/sops"; mv "$scratch"/docs/sops/"$id"-*.md "$project/docs/sops/" || die 4 "cannot move the SOP into $project/docs/sops"
printf '%s\n' "$id"
