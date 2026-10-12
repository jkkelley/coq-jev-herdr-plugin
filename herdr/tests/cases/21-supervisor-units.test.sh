#!/usr/bin/env bash
# Catches (WO-20261012-b800): the systemd units that start the supervisor at boot and between ticks being typed by hand or pointing
# into a treehouse slot, a unit with no PATH for the commands a tick calls, a timer that does not start at boot or does not repeat
# within the 60 seconds AC-H1 allows, and install changing the host from a seat. systemctl has no verb but `--user start` in the
# suite, so install itself is not run here; render is, and install's only other step is two systemctl calls.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/assert.sh"; . "$HERE/../lib/world.sh"
world_up units || exit 1
UN="$REPO/herdr/bin/supervisor-units.sh"; OUT="$WORLD/units"

echo "-- render with an explicit main checkout writes both units"
"$UN" render --dir "$OUT" --repo /srv/main-checkout > "$WORLD/out" 2>&1; assert_eq "exits 0" "$?" 0
assert_file "the service" "$OUT/coq-supervisor.service"; assert_file "the timer" "$OUT/coq-supervisor.timer"
svc="$(cat "$OUT/coq-supervisor.service")"; tmr="$(cat "$OUT/coq-supervisor.timer")"
assert_match "ExecStart runs supervisor.sh in the named checkout" "$svc" "^ExecStart=/srv/main-checkout/herdr/bin/supervisor\\.sh$"
assert_match "it is a oneshot with a backstop timeout" "$svc" "^Type=oneshot"
assert_match "TimeoutStartSec is set" "$svc" "^TimeoutStartSec=[0-9]+"
assert_match "PATH carries the directory of jq and herdr" "$svc" "^Environment=PATH=.*$(dirname "$(command -v jq)").*"
assert_eq "no placeholder is left" "$(grep -c '@REPO@\|@PATH@' <<<"$svc$tmr")" 0
assert_match "the timer starts after boot" "$tmr" "^OnBootSec=[0-9]+s$"
iv="$(sed -nE 's/^OnUnitInactiveSec=([0-9]+)s$/\1/p' <<<"$tmr")"
check "and repeats within 60 seconds (every ${iv}s after a tick ends)" "$([ -n "$iv" ] && [ "$iv" -le 45 ] && echo 1 || echo 0)"
assert_match "it is wanted by timers.target" "$tmr" "^WantedBy=timers\\.target$"

echo "-- a linked worktree is refused unless --repo is given"
git init -q "$WORLD/main" && git -C "$WORLD/main" commit -q --allow-empty -m x && git -C "$WORLD/main" worktree add -q "$WORLD/slot" -b slot >/dev/null 2>&1
mkdir -p "$WORLD/slot/herdr/bin" "$WORLD/slot/herdr/config" "$WORLD/slot/herdr/systemd"
cp -a "$REPO/herdr/bin/." "$WORLD/slot/herdr/bin/"; cp -a "$REPO/herdr/config/." "$WORLD/slot/herdr/config/"; cp -a "$REPO/herdr/systemd/." "$WORLD/slot/herdr/systemd/"
"$WORLD/slot/herdr/bin/supervisor-units.sh" render --dir "$WORLD/units2" > "$WORLD/out" 2>&1; rc=$?
assert_eq "refused, exit 3" "$rc" 3
assert_match "it says why" "$(cat "$WORLD/out")" "is a linked worktree"
assert_eq "nothing was written" "$([ -e "$WORLD/units2" ] && echo 1 || echo 0)" 0
"$WORLD/slot/herdr/bin/supervisor-units.sh" render --dir "$WORLD/units3" --repo "$WORLD/main" >/dev/null 2>&1; assert_eq "with --repo it renders" "$?" 0
case_done
