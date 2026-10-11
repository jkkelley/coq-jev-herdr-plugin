#!/usr/bin/env bash
# md-contents.sh - the Contents block of a markdown file, generated from its own
# H2 headings so it can never drift (REQ-agents-md-portable).
#   md-contents.sh --fix   <file.md>   insert or refresh the block after the H1
#   md-contents.sh --check <file.md>   exit 3 if missing or stale, naming the file
# Pure: reads the file, computes the block, writes only under --fix. Exit 0 ok, 2 usage, 3 stale, 4 io.
set -euo pipefail
MODE=${1:-}; F=${2:-}; [ -n "$F" ] && [ -f "$F" ] || { echo "usage: md-contents.sh --fix|--check <file.md>" >&2; exit 2; }
# the block: every H2 except Contents itself, as a bullet list, in order
want=$(awk '/^## /{t=substr($0,4); if (t!="Contents") print "- " t}' "$F")
have=$(awk '/^## Contents/{f=1; next} f&&/^## /{exit} f&&/^- /{print}' "$F")
if [ "$MODE" = --check ]; then
  grep -q '^## Contents' "$F" || { echo "$F: no '## Contents' block" >&2; exit 3; }
  [ "$want" = "$have" ] || { echo "$F: Contents block is stale (run md-contents.sh --fix)" >&2; exit 3; }
  exit 0
fi
[ "$MODE" = --fix ] || { echo "usage: md-contents.sh --fix|--check <file.md>" >&2; exit 2; }
tmp=$(mktemp)
if grep -q '^## Contents' "$F"; then
  # Replace only the bullet list under "## Contents", not everything up to the next H2.
  # Broke 2026-10-11 on docs/sops/SOP-0001: the old `skip&&/^## /` form dropped the
  # prose between the list and "## Purpose" ("Diataxis mode", "Last reviewed"), so a
  # --fix run silently deleted living-docs metadata. Skipping ends at the first line
  # that is neither a bullet nor blank; a second H2-bounded pass was rejected because
  # it cannot tell generated bullets from an author's own list. No cost: a stale list
  # is still fully replaced. Record: WO-20261011-23df step "SOP-0001 updated".
  awk -v block="$want" 'BEGIN{skip=0} /^## Contents/{print; print ""; print block; print ""; skip=1; next} skip&&(/^- /||/^$/){next} {skip=0; print}' "$F" > "$tmp"
else
  awk -v block="$want" 'NR==1&&/^# /{print; print ""; print "## Contents"; print ""; print block; next} {print}' "$F" > "$tmp"
fi
mv "$tmp" "$F"; echo "$F: Contents block written"
