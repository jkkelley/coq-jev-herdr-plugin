#!/usr/bin/env bash
# report/loop/tests/browser.sh - the board page in a real browser (WO-20261011-616c AC-H3 redraw, AC-H5 pixel parity).
#   bash report/loop/tests/browser.sh               run it in Podman (localhost/coq-bearings-test:1: Node plus Playwright), --network=none
#   bash report/loop/tests/browser.sh --image-only  build the image and stop
# The image is the bearings suite's, reused rather than a second 2.8 GB browser image: it has jq, python3 jsonschema and Playwright.
# Parity: the fixture is the design's own DATA block; rendered through loop.sh it must screenshot byte for byte like the design.
# The design is a fragment with no doctype, and the page it is shown in always has a document around it (the artifact wrapper,
# bearings), so the copy compared here gets the template's own four line header: doctype, html lang, charset, viewport. Without
# the doctype it renders in quirks mode (tables stop inheriting the body font size), so the comparison would test the doctype.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE="localhost/coq-bearings-test:1"

if [ "${LOOP_BROWSER_IN_CONTAINER:-0}" != 1 ]; then
  REPO_ROOT="$(cd "$HERE/../../.." && pwd)"
  command -v podman >/dev/null || { echo "browser.sh: podman is required" >&2; exit 4; }
  if ! podman image exists "$IMAGE" 2>/dev/null; then podman build -q -t "$IMAGE" -f "$REPO_ROOT/tools/bearings/tests/Containerfile" "$REPO_ROOT/tools/bearings/tests" >&2 || exit 4; fi
  [ "${1:-}" != --image-only ] || exit 0
  SCRATCH="$(mktemp -d)"; trap 'rm -rf "$SCRATCH"' EXIT
  podman run --rm --userns=keep-id --network=none \
    -v "$REPO_ROOT:/repo:ro,Z" -v "$SCRATCH:/work:Z" \
    -e LOOP_BROWSER_IN_CONTAINER=1 -e REPO_ROOT=/repo -e HOME=/work -w /work "$IMAGE" bash /repo/report/loop/tests/browser.sh
  rc=$?
  [ "$rc" = 0 ] || { mkdir -p /tmp/loop-browser-shots && cp "$SCRATCH"/shots/*.png /tmp/loop-browser-shots/ 2>/dev/null && echo "browser.sh: screenshots kept in /tmp/loop-browser-shots" >&2; }
  exit "$rc"
fi

# --- inside the container ---
R="${REPO_ROOT:-/repo}/report/loop"
PASS=0; FAIL=0
ok() { PASS=$((PASS + 1)); echo "ok   - $1"; }
bad() { FAIL=$((FAIL + 1)); echo "FAIL - $1" >&2; }
mkdir -p /work/shots /work/rendered /work/live
{ head -n 4 "$R/assets/template.html"; cat "$R/design/loop-design-iteration-5.html"; } > /work/design.html
"$R/loop.sh" render --in "$R/tests/fixtures/design-iteration-5.json" --out /work/rendered >/dev/null || { echo "render failed" >&2; exit 3; }
# The live copy polls every 5 seconds so the redraw case waits seconds, not the configured ten.
jq '.poll_seconds = 5' "$R/tests/fixtures/design-iteration-5.json" > /work/live-in.json
"$R/loop.sh" render --in /work/live-in.json --out /work/live >/dev/null || { echo "render failed" >&2; exit 3; }
node "$R/tests/browser/probe.mjs" /work/design.html /work/rendered /work/live /work/shots > /work/probe.json || { echo "probe failed" >&2; exit 3; }

jq -r '.errors[]?, (.parity_dom_diff // empty | "dom differs at \(.at): design=\(.design | @json) rendered=\(.rendered | @json)"), (.first_box_diff // empty | "first layout difference \(. | @json)"), (.dims[]? | "dims \(. | @json)")' /work/probe.json >&2
chk() { local d=$1 want=$2 got=$3; if [ "$want" = "$got" ]; then ok "$d"; else bad "$d (wanted $want, got $got)"; fi; }
for w in 1100 390; do
  chk "rendered page screenshots like the design at ${w}px" true "$(jq -r --argjson w "$w" '.parity[] | select(.width == $w) | .same' /work/probe.json)"
done
chk "zero page errors" 0 "$(jq '.errors | length' /work/probe.json)"
chk "the served page says it is live" true "$(jq -r .redraw.page_live_pill /work/probe.json)"
chk "the new headline is drawn without a reload" "Redrawn in place" "$(jq -r .redraw.headline /work/probe.json)"
chk "it is drawn within the 30 second promise" true "$(jq '.redraw.seconds <= 30' /work/probe.json)"
chk "the new line appears" true "$(jq -r .redraw.new_line_drawn /work/probe.json)"
chk "the document is the same one (no reload)" true "$(jq -r .redraw.same_document /work/probe.json)"
chk "a folded line stays folded" true "$(jq -r .redraw.line1_still_folded /work/probe.json)"
chk "a line's sideways scroll is kept" 250 "$(jq -r .redraw.line2_scroll /work/probe.json)"
chk "the page scroll is kept" 120 "$(jq -r .redraw.page_scroll /work/probe.json)"
chk "a stopped server shows page offline" true "$(jq -r .redraw.offline_pill /work/probe.json)"
echo "browser: $PASS passed, $FAIL failed"
[ "$FAIL" = 0 ]
