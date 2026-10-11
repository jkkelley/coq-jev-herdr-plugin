#!/usr/bin/env bash
# 03 - the template keeps the owner-locked design: its markup and CSS are the design's, byte for byte. Only the script block
# is ours. (Pixel parity of the rendered page against the design runs in a browser: make -C report/loop test-browser.)
. "$(dirname "$0")/../lib/assert.sh"
D="$REPO_ROOT/report/loop/design/loop-design-iteration-5.html"
T="$REPO_ROOT/report/loop/assets/template.html"

# The design is a fragment that starts at <title>; the template adds a four line header (doctype, html, charset, viewport) ahead of it.
head_of() { awk '/^<script/ { exit } { print }' | sed '${/^$/d}'; }
eq "the template's first four lines are the document header" \
  $'<!doctype html>\n<html lang="en">\n<meta charset="utf-8">\n<meta name="viewport" content="width=device-width, initial-scale=1">' \
  "$(head -n 4 "$T")"
t "the template's markup and CSS equal the design's" diff <(head_of < "$D") <(tail -n +5 "$T" | head_of)
eq "the data placeholder appears once" "1" "$(grep -c '@@DATA@@' "$T")"
eq "no copy of the design's DATA block is left in the template" "0" "$(grep -c 'const DATA = {' "$T")"
eq "no copy of the design's STATIONS constant is left in the template" "0" "$(grep -c 'const STATIONS' "$T")"
has "the page polls data.json" "$T" 'data\.json'
has "the page keeps fold state across a redraw" "$T" 'function snapshot'
done_case
