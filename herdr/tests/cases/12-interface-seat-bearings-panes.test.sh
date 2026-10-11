#!/usr/bin/env bash
# Catches (WO-20261011-e618, AC-H1): the interface agent's seat coming up without the bearings serve and wait panes in its own tab,
# a layout pre_start line run outside the seat's tab (bearings claims panes by the HERDR_TAB_ID of its caller, so the page would
# stay in the architect's tab), the wait loop aimed at any pane but the agent, serve started over a page that is already
# up (it refuses), pre_start repeated on a repair of a live seat, or a line that never finishes not refusing the up.
# bearings.sh is a stub that logs its tab, pane and arguments; the real one needs node and would touch the live page.
# roles/ belongs to the architect, so the world's copy of the role is pointed at the layout here; the real role file follows.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/assert.sh"; . "$HERE/../lib/world.sh"
world_up interface || exit 1
N=interface
jq '.pane_layout = "interface-2x2"' "$REPO/roles/interface-agent.json" > "$WORLD/role.tmp" && mv "$WORLD/role.tmp" "$REPO/roles/interface-agent.json"
LOG="$WORLD/bearings.log"; : > "$LOG"
cat > "$REPO/tools/bearings/scripts/bearings.sh" <<STUB
#!/usr/bin/env bash
printf 'tab=%s pane=%s %s\n' "\${HERDR_TAB_ID:-}" "\${HERDR_PANE_ID:-}" "\$*" >> "$LOG"
if [ "\$2" = status ]; then if [ -f "$WORLD/alive" ]; then echo '{"alive":true}'; else echo '{"alive":false}'; fi; fi
exit 0
STUB
chmod +x "$REPO/tools/bearings/scripts/bearings.sh"

echo "-- the seat comes up with the layout's four panes and runs its pre_start lines in its own tab"
out="$("$SEAT" --role interface-agent --task "owner channel" --worktree "$REPO")"; rc=$?
assert_eq "up exits 0" "$rc" 0
ws="$(jq -r .workspace <<<"$out")"; tab="$(jq -r .tab <<<"$out")"; agent="$(jq -r .agent <<<"$out")"
assert_eq "the seat is named from the role label" "$(jq -r .name <<<"$out")" "$N"
assert_eq "interface-2x2 builds the agent, monitor and both bearings panes" "$(pane_labels "$ws" "$tab")" \
  "MONITOR - $N|bearings-stable|bearings-stable-wait|claude-sonnet-5-5 - high - interface-agent"
assert_eq "the agent started" "$(h agent get "$N" | jq -r .result.agent.agent_status)" idle
assert_eq "bearings was called three times: status, serve, wait" "$(wc -l < "$LOG" | tr -d ' ')" 3
assert_match "status came first" "$(sed -n 1p "$LOG")" "stable status --json$"
assert_match "serve joined the page" "$(sed -n 2p "$LOG")" "stable serve --join$"
assert_match "wait is aimed at the agent pane" "$(sed -n 3p "$LOG")" "stable wait --to $agent$"
assert_eq "every call came from the agent pane" "$(grep -c "pane=$agent " "$LOG")" 3
assert_eq "every call carried the seat's tab id, so bearings claims panes in this tab" "$(grep -c "tab=$tab " "$LOG")" 3

echo "-- a repair of a live seat does not run pre_start again"
out2="$("$SEAT" --role interface-agent --task "owner channel" --worktree "$REPO")"; rc=$?
assert_eq "rerun exits 0" "$rc" 0
assert_eq "rerun did not start a second agent" "$(jq -r .started <<<"$out2")" false
assert_eq "the log is unchanged" "$(wc -l < "$LOG" | tr -d ' ')" 3

echo "-- serve is skipped when the page is already up"
"$SEAT" --down "$N" >/dev/null; assert_eq "--down exits 0" "$?" 0
: > "$LOG"; : > "$WORLD/alive"
"$SEAT" --role interface-agent --task "owner channel" --worktree "$REPO" >/dev/null; rc=$?
assert_eq "a fresh up exits 0" "$rc" 0
assert_eq "status then wait, no serve" "$(sed -e 's/^tab=[^ ]* pane=[^ ]* //' -e 's/--to .*/--to P/' "$LOG" | tr '\n' ';')" "stable status --json;stable wait --to P;"
"$SEAT" --down "$N" >/dev/null

echo "-- a pre_start line that never finishes refuses the up"
jq '.prompt_timeout_ms = 3000' "$COQ_HERDR_CONFIG" > "$WORLD/cfg.tmp" && mv "$WORLD/cfg.tmp" "$COQ_HERDR_CONFIG"
jq '.pre_start = ["sleep 30"]' "$REPO/herdr/layouts/interface-2x2.json" > "$WORLD/l.tmp" && mv "$WORLD/l.tmp" "$REPO/herdr/layouts/interface-2x2.json"
"$SEAT" --role interface-agent --task "owner channel" --worktree "$REPO" >/dev/null 2>"$WORLD/err"; rc=$?
assert_eq "refused with exit 4" "$rc" 4
assert_match "the refusal names the line and the layout" "$(cat "$WORLD/err")" "pre_start line 1 of layout interface-2x2 did not finish"
case_done
