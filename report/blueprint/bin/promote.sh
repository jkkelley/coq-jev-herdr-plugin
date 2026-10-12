#!/usr/bin/env bash
# promote.sh - move a tagged build of the blueprint one tier forward (WO-20261011-ceea, DEC-blueprint-server-tiers).
#   promote.sh TIER             uat takes dev's page, stable takes uat's; the source is the tier's `promotes_from` in config/TIER.json
# The build is the source page's own build number (data.json `number`). It is rendered again into TIER's out_dir/releases/<build>
# with its state set to the tier name, so the promoted page says which tier it is and keeps the number it was built as, then the
# `current` link is switched to it atomically. An older release stays on disk. Promoting the build a tier already serves says so
# and changes nothing. Never copy a page by hand: the number on stable is a promise that uat held that build.
# Env: BLUEPRINT_ROOT, BLUEPRINT_CONFIG_DIR as serve.sh.
# Exit: 0 ok (or already there), 2 usage, 3 the source has no valid page, 4 io.
set -euo pipefail
HERE=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)
BP=$(cd "$HERE/.." && pwd)
ROOT=${BLUEPRINT_ROOT:-$(cd "$BP/../.." && pwd)}
CONF=${BLUEPRINT_CONFIG_DIR:-$BP/config}
LOOP=$ROOT/report/loop/loop.sh
[ -x "$LOOP" ] || LOOP=$BP/../loop/loop.sh
die() { local c=$1; shift; printf 'promote: %s\n' "$*" >&2; exit "$c"; }
usage() { sed -n '2,3p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' >&2; exit 2; }
command -v jq >/dev/null || die 4 "jq is required"
to=${1:-}; [[ $to =~ ^(uat|stable)$ ]] || usage
from=$(jq -r '.promotes_from // empty' "$CONF/$to.json") || die 4 "cannot read $CONF/$to.json"
[ -n "$from" ] || die 2 "$to does not take promotions"
mode_from=$(jq -r .mode "$CONF/$from.json")
src=$ROOT/$(jq -r .out_dir "$CONF/$from.json"); [ "$mode_from" != released ] || src=$src/current
dst=$ROOT/$(jq -r .out_dir "$CONF/$to.json")
[ -f "$src/data.json" ] || die 3 "$from has no page to promote (no $src/data.json); start its server or run make render"
export LOOP_ROOT=$ROOT
"$LOOP" --view blueprint validate "$src/data.json" || die 3 "$from's page does not validate"
build=$(jq -r .number "$src/data.json")
if [ "$(readlink "$dst/current" 2>/dev/null || true)" = "releases/$build" ]; then printf 'promote: %s already serves build %s\n' "$to" "$build"; exit 0; fi
mkdir -p "$dst/releases" || die 4 "cannot create $dst/releases"
tmp=$(mktemp -d "$dst/releases/.promote.XXXXXX") || die 4 "cannot write in $dst"
trap 'rm -rf "$tmp"' EXIT
jq --arg s "$to" '.state = $s' "$src/data.json" > "$tmp/in.json"
"$LOOP" --view blueprint render --in "$tmp/in.json" --out "$tmp/page" >/dev/null || die 3 "the promoted page did not render"
jq -n --argjson build "$build" --arg from "$from" --arg tier "$to" --arg at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '{build: $build, tier: $tier, from: $from, promoted_at: $at}' > "$tmp/page/build.json"
rm -rf "$dst/releases/$build"
mv "$tmp/page" "$dst/releases/$build" || die 4 "cannot place release $build"
ln -sfn "releases/$build" "$dst/current.new" && mv -T "$dst/current.new" "$dst/current" || die 4 "cannot switch current to build $build"
printf 'promote: %s now serves build %s from %s\n' "$to" "$build" "$from"
