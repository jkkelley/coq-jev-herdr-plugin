#!/usr/bin/env bash
# aq (WO-20261013-51e8, AC-H1): line/bin/aq.sh, the architect queue, against a scratch state root and a fake clock.
#   order     p0 sorts before p1, older before newer within a priority, whatever order the items were added in
#   dedupe    the same --source and --ref added twice is one item: one id, count 2, the higher priority, the first sighting's age
#   done      moves the item out of open/ into done/ in one rename, with done and done_note set; a second done is exit 6
#   confined  with COQ_STATE set every file the script writes is under it, and the script names no literal home or cache path
#   check     accepts what add wrote and refuses a file whose name disagrees with its content
# A fake date on PATH holds the clock, because the file name carries a one second stamp and the order within a priority is that stamp.
set -uo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
. "$HERE/../lib/assert.sh"
REAL_DATE=$(type -P date); . "$HERE/../lib/world.sh"; world_init
AQ=$REPO/line/bin/aq.sh; Q=$COQ_STATE/queues/architect
export HOME=$W/home AQ_CLOCK=$W/clock; unset AQ_DIR
printf '#!/usr/bin/env bash\nif [ -f "$AQ_CLOCK" ]; then exec %s -d "$(cat "$AQ_CLOCK")" "$@"; fi\nexec %s "$@"\n' "$REAL_DATE" "$REAL_DATE" > "$W/bin/date"; chmod +x "$W/bin/date"
queue() { bash "$AQ" "$@"; }
at() { printf '2026-10-13T%sZ\n' "$1" > "$AQ_CLOCK"; }   # at HH:MM:SS: the clock the next aq call sees
ids() { queue list | cut -f2 | tr '\n' ' ' | sed 's/ $//'; }

echo "-- an empty queue lists nothing, and --json lists []"
assert_eq "list of nothing prints nothing" "$(queue list)" ""
assert_eq "list --json of nothing is []" "$(queue list --json)" "[]"

echo "-- p0 before p1, older before newer within a priority (added out of order)"
at 10:00:01; B=$(queue add --priority p1 --source patrol --ref r-b --text "p1 first seen" )
at 10:00:02; D=$(queue add --priority p3 --source note --ref r-d --text "p3 info")
at 10:00:03; E=$(queue add --priority p0 --source flow --ref r-e --text "p0 late")
at 10:00:04; C=$(queue add --priority p1 --source patrol --ref r-c --text "p1 second seen")
at 10:00:05; A=$(queue add --priority p2 --source patrol --ref r-a --text "p2 stuck seat")
assert_eq "five distinct ids" "$(printf '%s\n' "$A" "$B" "$C" "$D" "$E" | sort -u | wc -l | tr -d ' ')" 5
assert_eq "order is p0, p1 old, p1 new, p2, p3" "$(ids)" "$E $B $C $A $D"
assert_eq "--top 2 is the first two" "$(queue list --top 2 | cut -f2 | tr '\n' ' ' | sed 's/ $//')" "$E $B"
assert_eq "--json is in the same order" "$(queue list --json | jq -r '[.[].id] | join(" ")')" "$E $B $C $A $D"
assert_match "a text row carries priority, id, count, source, ref and text" "$(queue list --top 1)" "^p0	$E	x1	2026-10-13T10:00:03Z	flow	r-e	p0 late$"
assert_file "the p0 file is named pN-<stamp>-<id>.json" "$Q/open/p0-20261013T100003Z-$E.json"

echo "-- the same source and ref twice is one item: higher priority, count 2, first sighting's age, fresh text"
at 10:05:00; B2=$(queue add --priority p0 --source patrol --ref r-b --text "p1 now blocking")
assert_eq "the same id comes back" "$B2" "$B"
assert_eq "still five items" "$(queue list | wc -l | tr -d ' ')" 5
assert_file "the file was renamed to p0 and kept the first stamp" "$Q/open/p0-20261013T100001Z-$B.json"
assert_no_file "no p1 file is left behind" "$Q/open/p1-20261013T100001Z-$B.json"
assert_eq "it now sorts first of the p0s, older than E" "$(ids)" "$B $E $C $A $D"
assert_eq "count is 2, text and seen are fresh, added is the first sighting" \
  "$(jq -r '"\(.count) \(.text) \(.seen) \(.added)"' "$Q/open/p0-20261013T100001Z-$B.json")" "2 p1 now blocking 2026-10-13T10:05:00Z 2026-10-13T10:00:01Z"
at 10:06:00; queue add --priority p3 --source patrol --ref r-b --text "calm again" >/dev/null
assert_file "a lower priority never demotes" "$Q/open/p0-20261013T100001Z-$B.json"
assert_eq "same source, other ref is a new item" "$(queue add --priority p2 --source patrol --ref r-other --text x >/dev/null; queue list | wc -l | tr -d ' ')" 6
assert_eq "same ref, other source is a new item" "$(queue add --priority p2 --source other --ref r-b --text x >/dev/null; queue list | wc -l | tr -d ' ')" 7

echo "-- done moves the file out of open/ into done/, atomically, and says why"
at 10:10:00; out=$(queue "done" --id "$E" --note "landed in PR 9"); assert_eq "done exits 0" "$?" 0
assert_eq "done prints done <id>" "$out" "done $E"
assert_no_file "the item left open/" "$Q/open/p0-20261013T100003Z-$E.json"
assert_file "the item is in done/ under the same name" "$Q/done/p0-20261013T100003Z-$E.json"
assert_eq "done and done_note are set" "$(jq -r '"\(.done) \(.done_note)"' "$Q/done/p0-20261013T100003Z-$E.json")" "2026-10-13T10:10:00Z landed in PR 9"
assert_eq "no temporary file is left in either directory" "$(find "$Q" -name '*.tmp' | wc -l | tr -d ' ')" 0
assert_no_match "list no longer shows it" "$(ids)" "$E"
queue "done" --id "$E" --note again >/dev/null 2>&1; assert_eq "a second done is exit 6" "$?" 6
queue "done" --id nosuch --note x >/dev/null 2>&1; assert_eq "an unknown id is exit 6" "$?" 6
at 10:11:00; queue add --priority p1 --source flow --ref r-e --text "back again" >/dev/null
assert_eq "a done item does not dedupe: the same source and ref opens a new item" "$(queue list | grep -c "	flow	r-e	")" 1

echo "-- usage and validation errors"
queue add --priority p4 --source s --ref r --text t >/dev/null 2>&1; assert_eq "p4 is exit 3" "$?" 3
queue add --priority p1 --source s --ref r >/dev/null 2>&1; assert_eq "no --text is exit 2" "$?" 2
queue add --priority p1 --source s --text t >/dev/null 2>&1; assert_eq "no --ref is exit 2" "$?" 2
queue add --priority p1 --source s --ref r --text "$(printf 'x%.0s' $(seq 201))" >/dev/null 2>&1; assert_eq "201 characters of text is exit 3" "$?" 3
queue add --priority p1 --source s --ref r --text t --bogus 1 >/dev/null 2>&1; assert_eq "an unknown flag is exit 2" "$?" 2
queue list --top x >/dev/null 2>&1; assert_eq "--top x is exit 2" "$?" 2
queue "done" --id "$A" >/dev/null 2>&1; assert_eq "done without --note is exit 2" "$?" 2
queue frobnicate >/dev/null 2>&1; assert_eq "an unknown verb is exit 2" "$?" 2

echo "-- check accepts what add wrote and refuses a name that disagrees with its content"
out=$(queue check); assert_eq "check exits 0 on a clean queue" "$?" 0; assert_eq "check says ok" "$out" ok
f=$(ls "$Q"/open/p2-*-"$A".json); mv "$f" "${f/\/p2-/\/p1-}"
out=$(queue check 2>&1); assert_eq "a renamed item is exit 3" "$?" 3; assert_match "check names the file" "$out" "bad: .*p1-.*$A.json"
mv "${f/\/p2-/\/p1-}" "$f"; queue check >/dev/null 2>&1; assert_eq "put back: exit 0" "$?" 0

echo "-- every file lands under the state root; the script names no literal home or cache path"
assert_eq "the queue is <state>/queues/architect" "$([ -d "$Q/open" ] && [ -d "$Q/done" ] && echo yes)" yes
stray=$(find "$W" -type f ! -path "$COQ_STATE/*" ! -path "$W/bin/*" ! -name herdr.log ! -name board.json ! -name clock | wc -l | tr -d ' ')
assert_eq "no file outside the state root, the fakes and the clock" "$stray" 0
assert_no_file "the script never touched HOME" "$HOME"
assert_eq "no /home/luna and no .cache/coq-watch in the script" "$(grep -c -E '/home/luna|\.cache/coq-watch' "$AQ" || true)" 0
want=$(env -u COQ_STATE -u XDG_STATE_HOME HOME="$W/home2" bash "$REPO/bin/state-root.sh" state)
env -u COQ_STATE -u XDG_STATE_HOME HOME="$W/home2" bash "$AQ" add --priority p1 --source s --ref r --text t >/dev/null
assert_eq "without COQ_STATE the queue is under what state-root.sh says" "$(find "$W/home2" -name 'p1-*.json' -path "$want/queues/architect/open/*" | wc -l | tr -d ' ')" 1
case_done
