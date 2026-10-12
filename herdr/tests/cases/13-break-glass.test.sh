#!/usr/bin/env bash
# Catches (WO-20261011-4562, DEC-break-glass-one-time): a break glass granted without the owner's answer on the bearings page
# (AC-H2: a 200 record alone, a Refuse, a card that did not show this seat and action, another seat's 200, a command that is
# several commands); a flip that lifts more than the rule covering the action or leaves the action blocked; a second command
# that still runs (the hook must block it); a second use of one answer (AC-H3); a restore that does not verify with --check
# (AC-H1); an expired break glass that is not restored or not called out by --audit; a follow-up 201 that does not restore;
# a dontAsk seat (orchestrator) that is not flipped to bypassPermissions (owner order of 2026-10-12, record 20261012T121854Z-200-uqz6z);
# hook timeouts that are literals in the script instead of break_glass.hook_*_timeout_seconds in herdr.json.
# Real headless herdr and a stub claude; the bearings page is a stub script (BEARINGS) over a directory holding answers.jsonl.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../lib/assert.sh"; . "$HERE/../lib/world.sh"
world_up glass || exit 1
T=WO-20261010-8777; N=worker-wo-20261010-8777; ACTION='gh pr merge 17 --squash'
PAGE="$WORLD/page"; mkdir -p "$PAGE"
cat > "$WORLD/bearings.sh" <<STUB
#!/usr/bin/env bash
[ "\$2" = status ] && printf '{"dir":"%s","alive":true}\n' "$PAGE"
exit 0
STUB
chmod +x "$WORLD/bearings.sh"; export BEARINGS="$WORLD/bearings.sh"
EV="$REPO/events/bin/event.sh"
req() { "$EV" add --kind break.glass --code 300 --seat "$N" --ticket "$T" --action "$1"; }
grant200() { local a=(); [ -n "${2:-}" ] && a=(--answer "$2"); "$EV" add --kind break.glass --code 200 --seat "${3:-$N}" --action "$1" ${a[@]+"${a[@]}"}; }
answer() { jq -nc --arg id "$1" --arg c "$2" --arg d "${4:-Break glass for $N: run exactly $3 - once}" '{id:$id,decide:$d,pick:0,choice:$c,words:"",at:"2026-10-11T19:00:00Z"}' >> "$PAGE/answers.jsonl"; }
glass() { "$SEAT" --break-glass "$N" --record "$1" 2>"$WORLD/err"; }
bg423() { event_count break.glass 423; }

"$SEAT" --ticket "$T" --role worker --worktree "$REPO" >/dev/null; assert_eq "the worker seat is up" "$?" 0
S="$STATE/seats/$N/settings.json"; cp "$S" "$WORLD/settings.role.json"
same_as_role() { cmp -s "$S" "$WORLD/settings.role.json" && echo 1 || echo 0; }

echo "-- AC-H2: refused 423, nothing changed"
r1=$(req "$ACTION")
g=$(grant200 "$ACTION" "$r1"); glass "$g" >/dev/null; rc=$?
assert_eq "a 200 with no answers file on the page" "$rc" 3
assert_match "the refusal says there is no owner answer" "$(cat "$WORLD/err")" "no owner answer"
assert_eq "one 423 record" "$(bg423)" 1
g=$(grant200 "$ACTION"); glass "$g" >/dev/null; rc=$?
assert_eq "a 200 that carries no answer at all" "$rc" 3; assert_match "and says so" "$(cat "$WORLD/err")" "carries no owner answer"
r2=$(req "$ACTION"); answer "$r2" Refuse "$ACTION"; g=$(grant200 "$ACTION" "$r2"); glass "$g" >/dev/null; rc=$?
assert_eq "the owner answered Refuse" "$rc" 3; assert_match "the refusal names the answer" "$(cat "$WORLD/err")" "is 'Refuse', not Grant"
r3=$(req "$ACTION"); answer "$r3" Grant x "Break glass for $N: run exactly gh pr merge 99 - once"; g=$(grant200 "$ACTION" "$r3"); glass "$g" >/dev/null; rc=$?
assert_eq "the owner granted a card that showed another command" "$rc" 3; assert_match "the refusal says the card did not match" "$(cat "$WORLD/err")" "does not name this seat and this action"
r4=$(req 'gh pr merge 17; rm -rf x'); answer "$r4" Grant 'gh pr merge 17; rm -rf x'; g=$(grant200 'gh pr merge 17; rm -rf x' "$r4"); glass "$g" >/dev/null; rc=$?
assert_eq "an action that is two commands" "$rc" 3; assert_match "the refusal says one plain command" "$(cat "$WORLD/err")" "not one plain command"
r5=$(req "$ACTION"); answer "$r5" Grant "$ACTION"; g=$(grant200 "$ACTION" "$r5" some-other-seat); glass "$g" >/dev/null; rc=$?
assert_eq "a 200 that names another seat" "$rc" 3; assert_match "the refusal names the seat" "$(cat "$WORLD/err")" "names seat some-other-seat"
g=$(grant200 'gh pr merge 18 --squash' "$r5"); glass "$g" >/dev/null; rc=$?
assert_eq "a 200 that swaps the command after the owner said yes" "$rc" 3; assert_match "the refusal says it is another command" "$(cat "$WORLD/err")" "another command than the request"
assert_eq "seven refusals, seven 423 records" "$(bg423)" 7
assert_eq "the seat's settings are byte for byte the role's" "$(same_as_role)" 1
assert_eq "no break glass state was written" "$(ls "$STATE/break-glass" 2>/dev/null | wc -l | tr -d ' ')" 0
assert_eq "--check is clean" "$("$SEAT" --check "$N" >/dev/null; echo $?)" 0

echo "-- AC-H1: the owner granted it; the seat is flipped for that one command"
r6=$(req "$ACTION"); answer "$r6" Grant "$ACTION"; g6=$(grant200 "$ACTION" "$r6")
res=$(glass "$g6"); rc=$?
assert_eq "break glass exits 0" "$rc" 0
assert_eq "it names the request" "$(jq -r .break_glass <<<"$res")" "$r6"
assert_eq "default mode is bypassPermissions" "$(jq -r .permissions.defaultMode "$S")" bypassPermissions
assert_eq "the deny rule that covers the action is lifted" "$(jq -r '.permissions.deny | any(. == "Bash(gh pr merge *)")' "$S")" false
assert_eq "the action is allowed, exactly" "$(jq -r --arg a "Bash($ACTION)" '.permissions.allow | index($a) != null' "$S")" true
assert_eq "an unrelated deny rule stays" "$(jq -r '.permissions.deny | index("Bash(treehouse destroy *)") != null' "$S")" true
assert_eq "the Edit denies stay" "$(jq -r --arg r "Edit(/$REPO/roles/**)" '.permissions.deny | index($r) != null' "$S")" true
assert_eq "the guard hook is on Bash, before and after" "$(jq -r '[.hooks.PreToolUse[0].matcher, .hooks.PostToolUse[0].matcher] | join(" ")' "$S")" "Bash Bash"
# WO-20261012-8fb2: `.hooks =` once replaced the whole key; the compact-only SessionStart entry must ride through a break glass.
assert_eq "the compact SessionStart entry survives the flip" "$(jq -r '.hooks.SessionStart[0].matcher' "$S")" compact
assert_eq "a pre-break-glass copy of the settings was kept" "$(cmp -s "$STATE/seats/$N/settings.pre-break-glass.json" "$WORLD/settings.role.json" && echo 1 || echo 0)" 1
assert_eq "the hook timeouts are the configured ones, not literals" "$(jq -r '[.hooks.PreToolUse[0].hooks[0].timeout, .hooks.PostToolUse[0].hooks[0].timeout] | join(" ")' "$S")" \
  "$(jq -r '[.break_glass.hook_pre_timeout_seconds, .break_glass.hook_post_timeout_seconds] | join(" ")' "$REPO/herdr/config/herdr.json")"
assert_eq "a break.glass 100 in effect was recorded" "$(event_count break.glass 100)" 1
sleep 1; assert_match "the seat was prompted with the record id and the command" "$(h agent read "$N" --source recent-unwrapped --lines 200)" "Break glass $r6: the owner authorised exactly one command"
"$SEAT" --check "$N" >"$WORLD/check.out"; rc=$?
assert_eq "--check reports the difference" "$rc" 1; assert_match "and says it is a break glass by design" "$(cat "$WORLD/check.out")" "break glass $r6 active until"

echo "-- the hook: the one command once, nothing else"
SF="$STATE/break-glass/$r6.json"; GUARD="$REPO/herdr/bin/break-glass-guard.sh"
hook() { jq -nc --arg t "$2" --arg c "${3:-}" '{tool_name:$t, tool_input:{command:$c}}' | "$GUARD" "$1" "$SF" 2>"$WORLD/hook.err"; }
hook pre Bash 'ls -la'; assert_eq "a command outside the lifted territory is not its business" "$?" 0
hook pre Read ''; assert_eq "a tool that is not Bash is not its business" "$?" 0
hook pre Bash 'gh pr merge 99 --squash'; assert_eq "another command in the territory is blocked" "$?" 2
hook pre Bash 'echo ok; gh pr merge 99'; assert_eq "a second command smuggled behind a first is blocked" "$?" 2
hook pre Bash "$ACTION"; assert_eq "the authorised command is let through" "$?" 0
assert_eq "it was marked used" "$(jq -r '.used_at != null' "$SF")" true
hook pre Bash "$ACTION"; assert_eq "the same command again is blocked" "$?" 2
assert_match "the block says what is allowed" "$(cat "$WORLD/hook.err")" "allows exactly one command, once: $ACTION"

echo "-- AC-H3: a second action under the same answer is refused"
g=$(grant200 "$ACTION" "$r6"); glass "$g" >/dev/null; rc=$?
assert_eq "the same answer a second time" "$rc" 3; assert_match "the refusal says it was already used" "$(cat "$WORLD/err")" "already used for one action"
g=$(grant200 'gh pr merge 18 --squash' "$r6"); glass "$g" >/dev/null; rc=$?
assert_eq "another command under the same answer" "$rc" 3

echo "-- the follow-up record restores the role settings, verified by --check"
hook post Bash "$ACTION"; assert_eq "post exits 0" "$?" 0
assert_eq "break.glass 201 action done was recorded" "$(event_count break.glass 201)" 1
assert_eq "break.glass 204 restored was recorded" "$(event_count break.glass 204)" 1
assert_eq "the seat's settings are the role's again" "$(same_as_role)" 1
"$SEAT" --check "$N" >/dev/null; assert_eq "--check is clean within the ttl" "$?" 0
assert_eq "the state stays, marked restored, so the answer cannot be used again" "$(jq -r .status "$SF")" restored
g=$(grant200 "$ACTION" "$r6"); glass "$g" >/dev/null; assert_eq "a replay after the restore is still refused" "$?" 3
assert_eq "restored seat: the deny rule is back" "$(jq -r '.permissions.deny | any(. == "Bash(gh pr merge *)")' "$S")" true

echo "-- ttl: an expired break glass is called out by --audit and restored by the sweep"
r7=$(req "$ACTION"); answer "$r7" Grant "$ACTION"; g7=$(grant200 "$ACTION" "$r7"); glass "$g7" >/dev/null; assert_eq "granted again with a new answer" "$?" 0
P="$WORLD/proc"; mkdir -p "$P/10"
printf 'claude\0--model\0claude-sonnet-5-5\0--effort\0high\0--permission-mode\0bypassPermissions\0--settings\0%s\0' "$S" > "$P/10/cmdline"
printf 'COQ_SEAT=%s\0HERDR_PANE_ID=w9:p1\0' "$N" > "$P/10/environ"
rep="$(SEAT_PROC="$P" "$SEAT" --audit)"; rc=$?
assert_match "inside its ttl it is compliant and says why" "$rep" "^COMPLIANT w9:p1 $N pid 10 \(break glass $r7 until"
assert_eq "audit exits 0" "$rc" 0
SF7="$STATE/break-glass/$r7.json"; jq '.expires_at = "2026-10-11T00:00:00Z"' "$SF7" > "$SF7.tmp" && mv "$SF7.tmp" "$SF7"
rep="$(SEAT_PROC="$P" "$SEAT" --audit)"; rc=$?
assert_match "past its ttl it kept bypass" "$rep" "^OUT OF COMPLIANCE w9:p1 $N pid 10: break glass $r7 kept bypass"
assert_eq "audit exits 1" "$rc" 1; assert_eq "a seat.stalled 500 was recorded" "$(event_count seat.stalled 500)" 1
"$SEAT" --check "$N" >"$WORLD/check.out"; assert_match "--check says it is past its ttl" "$(cat "$WORLD/check.out")" "past its ttl"
"$SEAT" --break-glass-sweep >/dev/null; assert_eq "the sweep exits 0" "$?" 0
assert_eq "the sweep restored the role settings" "$(same_as_role)" 1
"$SEAT" --check "$N" >/dev/null; assert_eq "--check is clean after the sweep" "$?" 0
assert_match "the 204 says ttl" "$(jq -r 'select(.kind == "break.glass" and .code == 204) | .note' "$EVENTS"/2*/*/*.json | grep -c "restored (ttl)")" "^1$"

echo "-- the sweep also restores when the follow-up 201 landed but the hook could not"
r8=$(req "$ACTION"); answer "$r8" Grant "$ACTION"; g8=$(grant200 "$ACTION" "$r8"); glass "$g8" >/dev/null
"$EV" add --kind break.glass --code 201 --seat "$N" --ticket "$T" --action "$ACTION" --answer "$r8" >/dev/null
"$SEAT" --break-glass-sweep >/dev/null; assert_eq "restored by the 201" "$(same_as_role)" 1
assert_eq "the sweep left an active break glass alone when nothing was due" "$(r9=$(req "$ACTION"); answer "$r9" Grant "$ACTION"; glass "$(grant200 "$ACTION" "$r9")" >/dev/null; "$SEAT" --break-glass-sweep >/dev/null; jq -r .status "$STATE/break-glass/$r9.json")" active
"$SEAT" --break-glass-restore "$N" --why manual >/dev/null; assert_eq "a manual restore works" "$(same_as_role)" 1

echo "-- a dontAsk seat is flipped to bypassPermissions too (owner order, record 20261012T121854Z-200-uqz6z, overruling review observation 1)"
OACT='git push origin main'
out=$("$SEAT" --role orchestrator --task "route the line" --worktree "$REPO"); assert_eq "the orchestrator seat is up" "$?" 0
O=$(jq -r .name <<<"$out"); OS="$STATE/seats/$O/settings.json"; cp "$OS" "$WORLD/settings.orch.json"
assert_eq "its role is dontAsk" "$(jq -r .permissions.defaultMode "$OS")" dontAsk
ro=$(N=$O; req "$OACT"); answer "$ro" Grant "$OACT" "Break glass for $O: run exactly $OACT - once"
go=$("$EV" add --kind break.glass --code 200 --seat "$O" --action "$OACT" --answer "$ro")
"$SEAT" --break-glass "$O" --record "$go" >/dev/null 2>"$WORLD/err"; assert_eq "break glass on a dontAsk seat exits 0" "$?" 0
assert_eq "it is bypassPermissions for the action" "$(jq -r .permissions.defaultMode "$OS")" bypassPermissions
assert_eq "the only new allow rule is the action" "$(jq -c --slurpfile r "$WORLD/settings.orch.json" '.permissions.allow - $r[0].permissions.allow' "$OS")" "[\"Bash($OACT)\"]"
assert_eq "no allow rule was removed" "$(jq -c --slurpfile r "$WORLD/settings.orch.json" '$r[0].permissions.allow - .permissions.allow' "$OS")" "[]"
assert_eq "the deny rules that cover the action are lifted, and only those" "$(jq -c --slurpfile r "$WORLD/settings.orch.json" '$r[0].permissions.deny - .permissions.deny | sort' "$OS")" '["Bash(git * *)","Bash(git *)"]'
assert_eq "the role's Edit and Write deny rules still hold under bypass" "$(jq -r '[.permissions.deny | index("Edit") != null, index("Write") != null] | join(" ")' "$OS")" "true true"
assert_eq "an unrelated command family is still denied" "$(jq -r '.permissions.deny | any(startswith("Bash(podman"))' "$OS")" true
SFO="$STATE/break-glass/$ro.json"
hookO() { jq -nc --arg t "$1" --arg c "${2:-}" '{tool_name:$t, tool_input:{command:$c}}' | "$GUARD" pre "$SFO" 2>/dev/null; }
hookO Bash 'git reset --hard'; assert_eq "another command in the lifted territory is blocked on the dontAsk seat too" "$?" 2
hookO Bash "$OACT"; assert_eq "the authorised command is let through once" "$?" 0
hookO Bash "$OACT"; assert_eq "and not twice" "$?" 2
"$SEAT" --break-glass-restore "$O" --why manual >/dev/null
assert_eq "the dontAsk seat's settings are the role's again" "$(cmp -s "$OS" "$WORLD/settings.orch.json" && echo 1 || echo 0)" 1
"$SEAT" --check "$O" >/dev/null; assert_eq "--check is clean on the dontAsk seat" "$?" 0

echo "-- a seat that is down cannot be flipped"
"$SEAT" --down "$N" >/dev/null
r10=$(req "$ACTION"); answer "$r10" Grant "$ACTION"; glass "$(grant200 "$ACTION" "$r10")" >/dev/null; rc=$?
assert_eq "refused" "$rc" 3; assert_match "the refusal says the seat is down" "$(cat "$WORLD/err")" "is down since"
case_done
