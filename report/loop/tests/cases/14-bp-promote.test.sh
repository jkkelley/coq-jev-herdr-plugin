#!/usr/bin/env bash
# 14 - promotion: dev to uat to stable moves a tagged build forward, never by hand. The stable page shows the promoted build number.
. "$(dirname "$0")/../lib/assert.sh"
BP="$REPO_ROOT/report/blueprint"; P="$BP/bin/promote.sh"
export BLUEPRINT_ROOT="$W/root" BLUEPRINT_CONFIG_DIR="$BP/config"
OUT="$W/root/$(jq -r .out_dir "$BP/config/dev.json")"; UAT="$W/root/$(jq -r .out_dir "$BP/config/uat.json")"; STB="$W/root/$(jq -r .out_dir "$BP/config/stable.json")"
mkdir -p "$W/root" "$W/live"; cp -r "$FIX/blueprint/." "$W/live/"
dev() { LOOP_ROOT="$W/live" "$LOOP" --view blueprint watch --iterations 1 --out "$OUT" 2>/dev/null; }
expect_exit 3 "uat has nothing to take while dev has no page" "$P" uat
dev
t "promote uat takes dev's build" "$P" uat
eq "uat serves build 1" "releases/1" "$(readlink "$UAT/current")"
eq "the promoted page keeps the build number" "1" "$(jq -r .number "$UAT/current/data.json")"
eq "the promoted page says which tier it is" "uat" "$(jq -r .state "$UAT/current/data.json")"
has "the promoted page is a rendered page" "$UAT/current/index.html" 'CMP-alpha'
eq "the release records where it came from" "1 dev uat" "$(jq -r '"\(.build) \(.from) \(.tier)"' "$UAT/current/build.json")"
m1=$(stat -c %Y "$UAT/releases/1/index.html"); sleep 1
"$P" uat | grep -q 'already serves build 1' && pass "promoting the build uat already has changes nothing and says so" || flunk "promoting twice should say already"
eq "and leaves the release alone" "$m1" "$(stat -c %Y "$UAT/releases/1/index.html")"
jq '.title = "Alpha, changed"' "$FIX/blueprint/graph/nodes/CMP-alpha.json" > "$W/live/graph/nodes/CMP-alpha.json"; dev
eq "dev moved to build 2" "2" "$(jq -r .number "$OUT/data.json")"
eq "uat still serves build 1 until promoted" "releases/1" "$(readlink "$UAT/current")"
t "promote uat again" "$P" uat
eq "uat serves build 2" "releases/2" "$(readlink "$UAT/current")"
t "the older release stays" test -f "$UAT/releases/1/index.html"
t "promote stable takes uat's build" "$P" stable
eq "stable serves the promoted build number" "2" "$(jq -r .number "$STB/current/data.json")"
eq "stable says it is stable" "stable" "$(jq -r .state "$STB/current/data.json")"
eq "stable took the build from uat" "uat" "$(jq -r .from "$STB/current/build.json")"
expect_exit 2 "dev takes no promotion" "$P" dev
expect_exit 2 "an unknown tier is usage" "$P" prod
expect_exit 2 "no tier is usage" "$P"
printf '{"not":"an entry"}' > "$OUT/data.json"
expect_exit 3 "a dev page that does not validate is not promoted" "$P" uat
eq "and uat still serves build 2" "releases/2" "$(readlink "$UAT/current")"
done_case
