#!/usr/bin/env bash
# 02 - render writes the page and the data from one validated entry, refuses a bad one without writing, and cannot be
# talked out of its script element by what the data says.
. "$(dirname "$0")/../lib/assert.sh"
F="$FIX/design-iteration-5.json"
OUT="$W/out"

# embedded FILE: the entry inside the page's loop-data element, sorted, so two JSON texts compare as data.
embedded() { sed -n 's/.*id="loop-data">\(.*\)<\/script>.*/\1/p' "$1" | jq -S .; }

t "render writes data.json and index.html" "$LOOP" render --in "$F" --out "$OUT"
eq "data.json holds the entry" "$(jq -S . "$F")" "$(jq -S . "$OUT/data.json")"
eq "index.html embeds the same entry" "$(jq -S . "$F")" "$(embedded "$OUT/index.html")"
eq "the placeholder is gone from the page" "0" "$(grep -c '@@DATA@@' "$OUT/index.html")"
eq "no render temp directory is left behind" "0" "$(find "$OUT" -name '.render.*' | wc -l | tr -d ' ')"

sum() { sha256sum "$OUT/index.html" "$OUT/data.json" | cut -d' ' -f1 | tr '\n' ' '; }
first="$(sum)"
"$LOOP" render --in "$F" --out "$OUT" >/dev/null
eq "rendering twice gives the same bytes" "$first" "$(sum)"

# A name that tries to close the script element, plus the characters a substitution tool treats as special.
jq '.lines[0].name = "</script><b>x</b> & \\1 / \\ end"' "$F" > "$W/evil.json"
t "an entry full of special characters renders" "$LOOP" render --in "$W/evil.json" --out "$W/evil-out"
eq "a closing script tag in the data does not reach the page raw" "0" "$(grep -c '<b>x</b>' "$W/evil-out/index.html")"
eq "the special characters round-trip through the page" "$(jq -S . "$W/evil.json")" "$(embedded "$W/evil-out/index.html")"
eq "the page still has exactly two script elements" "2" "$(grep -o '<script' "$W/evil-out/index.html" | wc -l | tr -d ' ')"

# A refused entry leaves nothing: not the directory, not a half-written page.
jq 'del(.headline)' "$F" > "$W/bad.json"
expect_exit 3 "an invalid entry is refused" "$LOOP" render --in "$W/bad.json" --out "$W/bad-out"
eq "a refused entry writes nothing" "no" "$([ -e "$W/bad-out" ] && echo yes || echo no)"

# Replacing a good page with a bad entry keeps the good page.
before="$(sum)"
expect_exit 3 "a bad entry over a good page is refused" "$LOOP" render --in "$W/bad.json" --out "$OUT"
eq "the good page is untouched" "$before" "$(sum)"

# --in defaults to the out directory's own data.json, the file watch writes and render redraws.
"$LOOP" render --out "$OUT" >/dev/null
eq "render with no --in redraws from the out directory" "$before" "$(sum)"

# The config rule a schema cannot say: poll_seconds + watch_seconds is 30 or less.
jq '.poll_seconds = 25 | .watch_seconds = 10' "$REPO_ROOT/report/loop/config/board.json" > "$W/board.json"
cp "$REPO_ROOT/report/loop/config/board.schema.json" "$W/board.schema.json"
expect_exit 3 "a config whose poll and watch pass 30 is refused" env LOOP_CONFIG="$W/board.json" "$LOOP" render --in "$F" --out "$W/cfg-out"
done_case
