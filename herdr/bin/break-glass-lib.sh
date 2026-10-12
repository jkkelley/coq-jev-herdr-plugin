#!/usr/bin/env bash
# break-glass-lib.sh - the break-glass verbs of seat.sh (WO-20261011-4562, DEC-break-glass-one-time). Sourced by seat.sh after
# it defines load_seat and render_settings, which these functions call; it is not run on its own.
#   bg_grant SEAT RECORD       seat.sh --break-glass SEAT --record RECORD
#   bg_restore SEAT REASON     seat.sh --break-glass-restore SEAT      (REASON: done | ttl | manual)
#   bg_sweep                   seat.sh --break-glass-sweep             every active break glass: restore the done and the expired
#   bg_active_state SEAT       the state file of that seat's active break glass, empty when none
#
# The rules, from the owner's order of 2026-10-11 18:42Z: only the owner authorises, one action per authorisation, never a
# session or a day, bypass permissions for that action only, and every one is a record the board shows.
#   Owner answer   a line in the bearings page's answers.jsonl whose id is the 300 request's id, whose choice is Grant, and
#                  whose card text names this seat and this action. Read here from the page, never taken from a 200 record.
#   One use        <state>/break-glass/<request id>.json is created with noclobber and is never deleted, so a second 200
#                  for the same answer finds it and is refused 423 (AC-H3).
#   The flip       the seat's settings.json becomes the role's render with the deny rules that cover the action removed,
#                  Bash(<action>) allowed, the role's own defaultMode kept, and a PreToolUse and a PostToolUse hook on Bash
#                  (break-glass-guard.sh) that allow exactly that command once and deny any other command that holds a lifted
#                  rule's head, so a second command is still denied. Then the seat is prompted with the record id.
#   The restore    the role's render is written back and compared with cmp, the same check --check makes; break.glass 204.
# Records (kind break.glass, the record's seat is the seat the glass is broken for): 300 request, 200 granted, 423 refused,
# 100 in effect, 201 action done, 204 restored.

# BREADCRUMB 2026-10-11 - WO-20261011-4562. What broke: nothing yet; a worker whose role denies the one command a hotfix needs
#   (gh pr merge, git push --force, treehouse destroy) could only be unstuck by the architect running it by hand, outside
#   every record. Why this shape: the verdict lives in seat.sh, where the page and the seat records are, and the route
#   runner only passes it the 200 record's id (factory/bin/route.sh, do break-glass). Three choices that look arbitrary:
#   1. The seat and the action come from the 300 request, never from the 200. A 200 is a record anyone can write; the owner
#      answered the card that showed the request's seat and action, and the answer line carries the card text, which must
#      name both. Rejected: trusting the 200's fields (a forged 200 could swap the command after the owner said yes).
#   2. The action is one plain command: no newline, ; & | ` $( or *. Claude Code reads a * in an allow rule as a wildcard and
#      a compound command as several, so either would let one grant cover more than the owner saw. Cost: a multi-step hotfix
#      is a script, and the script's path is the action.
#   3. Deny rules that cover the action are lifted and a hook keeps the rest of their territory closed. Claude Code evaluates
#      deny before allow, so an allow rule cannot open a hole in a broader deny, and a glob cannot say "everything but this".
#      Rejected: leaving the deny and allowing the action (it never runs) and dropping the whole deny list (a second command
#      would run). Cost: the hook is the fence for the lifted territory; a seat that rewrites its own settings.json defeats
#      it, as it defeats every other rule, and --audit then calls the drift out. Only a Bash command is an action.
#   4. The role's defaultMode is kept, never forced to bypassPermissions (review of 2026-10-12, attempts 1 and 2, on 57dacf2:
#      herdr/bin/break-glass-lib.sh line 122). What broke: the first cut set defaultMode bypassPermissions for every role, but
#      the monitor, orchestrator and interface-agent roles are dontAsk and allow almost nothing, so for up to ttl_seconds any
#      Bash command or tool call their allow list did not name (rm, curl, an Edit outside a deny rule) would have run, not
#      only the one action. Why this fix: the action is opened by the deny lift plus Bash(<action>) in allow, which works
#      under dontAsk and under bypassPermissions alike, so the mode adds nothing for the action and everything for the rest.
#      A bypassPermissions role (the worker, which is where the hotfix need arose) already runs in bypass, so for it the
#      flip is the lift and the hook, as it always was. Rejected: a PreToolUse hook on every tool that refuses all but the
#      action on a dontAsk seat (a second allow list to drift from the role, and a hook that fails open when it errors).
#      Cost: the ticket title says "flips to bypass permissions"; on a dontAsk seat what flips is the one allowed command,
#      and the seat is never in bypass, so --audit has nothing to call out for it. Case 13 proves the dontAsk seat.
#   Not proved here: that a running Claude Code re-reads --settings on change. The suite proves the file, the hook and the
#   records; the live check is the owner's AC-H1 run, and the runbook says how to read the seat's own deny result.

# shellcheck disable=SC2154  # settings, sd, id, ended_at and the rest are set by seat.sh load_seat, which sources this file
BG_DIR="$STATE/break-glass"
BG_ID_RE='^[0-9]{8}T[0-9]{6}Z-[0-9]{3}-[a-z0-9]{5}$'

# bg_refuse SEAT ACTION ANSWER REASON: a 423 record that carries the reason, then exit 3. Runs before anything is changed.
bg_refuse() {
  local seat=$1 action=${2:-} answer=${3:-} why=$4 a=()
  [[ $answer =~ $BG_ID_RE ]] && a=(--answer "$answer")
  sl_record break.glass 423 "$seat" --action "${action:-(unknown)}" ${a[@]+"${a[@]}"} --note "refused: ${why:0:200}"
  SL_EXIT=3 sl_die "break glass refused: $why"
}
# bg_covers INNER ACTION: does the deny rule Bash(INNER) cover this command? Prefix form (cmd:*) or a glob.
bg_covers() {
  local inner=$1 action=$2 p
  # shellcheck disable=SC2053  # the rule's own glob is the pattern
  case $inner in
    *:'*') p=${inner%:\*}; [[ $action == "$p" || $action == "$p "* ]] ;;
    *) [[ $action == $inner ]] ;;
  esac
}
bg_events() { "$SL_REPO/events/bin/event.sh" list --json | jq -s '.'; }
# bg_page_dir: the bearings page's state directory. BEARINGS overrides the script, as interface.sh does, so tests stub it.
bg_page_dir() {
  local b=${BEARINGS:-$SL_REPO/tools/bearings/scripts/bearings.sh}
  "$b" "$(sl_cfg .break_glass.bearings_tier)" status --json 2>/dev/null | jq -r '.dir // empty'
}
bg_active_state() {
  local f; for f in "$BG_DIR"/*.json; do [ -f "$f" ] || continue
    jq -e --arg s "$1" '.status == "active" and .seat == $s' "$f" >/dev/null 2>&1 && { printf '%s' "$f"; return 0; }
  done; return 0
}
bg_copy_of() { printf '%s/settings.break-glass.json' "$(dirname "$(jq -r .settings "$1")")"; }

bg_grant() {
  local seat=$1 recid=$2 all rec code req_id req action rseat dir line choice decide sf ttl tpre tpost exp now base lifted=() heads=() d inner h hs ls
  [[ $recid =~ $BG_ID_RE ]] || bg_refuse "$seat" "" "" "--record must be a record id"
  all=$(bg_events) || bg_refuse "$seat" "" "" "the event log could not be read"
  rec=$(jq -c --arg id "$recid" 'map(select(.id == $id and .kind == "break.glass")) | first // empty' <<<"$all")
  [ -n "$rec" ] || bg_refuse "$seat" "" "" "no break.glass record $recid in the event log"
  code=$(jq -r .code <<<"$rec")
  case $code in
    200) req_id=$(jq -r '.answer // empty' <<<"$rec")
         [ -n "$req_id" ] || bg_refuse "$seat" "$(jq -r .action <<<"$rec")" "" "the 200 record $recid carries no owner answer" ;;
    300) req_id=$recid ;;
    *) bg_refuse "$seat" "$(jq -r .action <<<"$rec")" "" "record $recid is code $code; a break glass starts from its 200 or its 300" ;;
  esac
  req=$(jq -c --arg id "$req_id" 'map(select(.id == $id and .kind == "break.glass" and .code == 300)) | first // empty' <<<"$all")
  [ -n "$req" ] || bg_refuse "$seat" "$(jq -r .action <<<"$rec")" "" "no break.glass 300 request $req_id for the answer the 200 names"
  action=$(jq -r .action <<<"$req"); rseat=$(jq -r .seat <<<"$req")
  [ "$rseat" = "$seat" ] || bg_refuse "$seat" "$action" "$req_id" "the request $req_id is for seat $rseat, not $seat"
  [ "$(jq -r .seat <<<"$rec")" = "$seat" ] || bg_refuse "$seat" "$action" "$req_id" "record $recid names seat $(jq -r .seat <<<"$rec"), not $seat"
  [ "$(jq -r .action <<<"$rec")" = "$action" ] || bg_refuse "$seat" "$action" "$req_id" "record $recid names another command than the request the owner answered"
  case $action in *$'\n'*|*';'*|*'&'*|*'|'*|*'`'*|*'$('*|*'*'*) bg_refuse "$seat" "$action" "$req_id" "the action is not one plain command (no newline, ; & | backtick \$( or *); put a multi-step fix in a script and name the script" ;; esac

  dir=$(bg_page_dir); [ -n "$dir" ] && [ -f "$dir/answers.jsonl" ] || bg_refuse "$seat" "$action" "$req_id" "no owner answer: the bearings page has no answers file"
  line=$(jq -sc --arg id "$req_id" 'map(select(.id == $id)) | last // empty' "$dir/answers.jsonl" 2>/dev/null)
  [ -n "$line" ] || bg_refuse "$seat" "$action" "$req_id" "no owner answer on the bearings page for $req_id"
  choice=$(jq -r '.choice // empty' <<<"$line")
  [ "$choice" = Grant ] || bg_refuse "$seat" "$action" "$req_id" "the owner's answer to $req_id is '${choice:-none}', not Grant"
  decide=$(jq -r '.decide // empty' <<<"$line")
  [[ $decide == *"$seat"* && $decide == *"$action"* ]] || bg_refuse "$seat" "$action" "$req_id" "the card the owner answered does not name this seat and this action"

  [ -f "$(sl_seat_record "$seat")" ] || bg_refuse "$seat" "$action" "$req_id" "no seat named $seat under $STATE/seats"
  load_seat "$seat"
  [ -z "$ended_at" ] || bg_refuse "$seat" "$action" "$req_id" "seat $seat is down since $ended_at"
  mkdir -p "$BG_DIR"; sf="$BG_DIR/$req_id.json"
  if [ "$DRY" != 1 ]; then ( set -C; : > "$sf" ) 2>/dev/null || bg_refuse "$seat" "$action" "$req_id" "the answer $req_id was already used for one action ($sf); a second action needs a second answer"; fi

  base=$(render_settings)
  while IFS= read -r d; do
    inner=${d#Bash(}; inner=${inner%)}
    bg_covers "$inner" "$action" || continue
    lifted+=("$d"); h=${inner%%\**}; h=${h%:}; h=${h%% }
    case " ${heads[*]-} " in *" $h "*) ;; *) heads+=("$h") ;; esac
  done < <(jq -r '.permissions.deny[] | select(startswith("Bash("))' <<<"$base")
  ttl=$(sl_cfg .break_glass.ttl_seconds); now=$(sl_now); exp=$(date -u -d "+$ttl seconds" +%Y-%m-%dT%H:%M:%SZ)
  ls=$(printf '%s\n' ${lifted[@]+"${lifted[@]}"} | jq -R . | jq -s 'map(select(. != ""))')
  hs=$(printf '%s\n' ${heads[@]+"${heads[@]}"} | jq -R . | jq -s .)
  if [ "$DRY" = 1 ]; then sl_log "DRY: break glass $req_id for $seat: lift $ls, heads $hs, until $exp"; return 0; fi
  cp "$settings" "$sd/settings.pre-break-glass.json"
  tpre=$(sl_cfg .break_glass.hook_pre_timeout_seconds); tpost=$(sl_cfg .break_glass.hook_post_timeout_seconds)
  jq --arg a "$action" --argjson lifted "$ls" --argjson tpre "$tpre" --argjson tpost "$tpost" --arg pre "$(printf '%q pre %q' "$SL_HERE/break-glass-guard.sh" "$sf")" --arg post "$(printf '%q post %q' "$SL_HERE/break-glass-guard.sh" "$sf")" '
      .permissions.deny -= $lifted
      | .permissions.allow += ["Bash(\($a))"]
      | .hooks = {PreToolUse: [{matcher: "Bash", hooks: [{type: "command", command: $pre, timeout: $tpre}]}],
                  PostToolUse: [{matcher: "Bash", hooks: [{type: "command", command: $post, timeout: $tpost}]}]}' <<<"$base" > "$sd/settings.break-glass.json"
  jq -n --arg req "$req_id" --arg seat "$seat" --arg a "$action" --arg grant "$recid" --argjson lifted "$ls" --argjson heads "$hs" --arg now "$now" --arg exp "$exp" \
    --arg settings "$settings" --arg eb "$SL_REPO/events/bin/event.sh" --arg er "${COQ_EVENTS_ROOT:-$SL_REPO/events}" --arg t "$id" \
    '{request: $req, seat: $seat, ticket: $t, action: $a, grant_record: $grant, lifted: $lifted, heads: $heads, started_at: $now, expires_at: $exp,
      used_at: null, done_at: null, status: "active", settings: $settings, events_bin: $eb, events_root: $er}' > "$sf.tmp" && mv -f "$sf.tmp" "$sf"
  cp "$sd/settings.break-glass.json" "$settings.tmp" && mv "$settings.tmp" "$settings"
  sl_record break.glass 100 "$seat" ${id:+--ticket "$id"} --action "$action" --answer "$req_id" --note "in effect until $exp"
  sl_mut agent prompt "$seat" "Break glass $req_id: the owner authorised exactly one command, once, for you: $action . Run it, nothing else; its record closes the break glass and your role settings return. It expires at $exp." >/dev/null \
    || sl_log "seat $seat: the break glass prompt could not be sent; the monitor will re-prompt"
  jq -nc --arg seat "$seat" --arg req "$req_id" --arg exp "$exp" --argjson lifted "$ls" '{seat: $seat, break_glass: $req, expires_at: $exp, lifted: $lifted}'
}

# bg_restore SEAT REASON: the role's settings back, compared with cmp, then break.glass 204. Returns 1 when the compare fails.
bg_restore() {
  local seat=$1 why=${2:-manual} sf req action now
  sf=$(bg_active_state "$seat"); [ -n "$sf" ] || { echo "$seat: no active break glass"; return 0; }
  req=$(jq -r .request "$sf"); action=$(jq -r .action "$sf"); now=$(sl_now)
  load_seat "$seat"
  if [ "$DRY" = 1 ]; then sl_log "DRY: restore $seat from break glass $req ($why)"; return 0; fi
  render_settings > "$settings.tmp" && mv "$settings.tmp" "$settings"
  if ! render_settings | cmp -s - "$settings"; then
    sl_record seat.stalled 500 "$seat" ${id:+--ticket "$id"} --note "break glass $req: the role settings did not verify after the restore"
    SL_EXIT=4 sl_die "seat $seat: settings did not verify after the restore of break glass $req"
  fi
  jq --arg now "$now" --arg why "$why" '.status = "restored" | .restored_at = $now | .restore_reason = $why' "$sf" > "$sf.tmp" && mv -f "$sf.tmp" "$sf"
  sl_record break.glass 204 "$seat" ${id:+--ticket "$id"} --action "$action" --answer "$req" --note "restored ($why): role settings back and verified"
  echo "$seat: break glass $req restored ($why)"
}
# bg_sweep: restore every active break glass whose follow-up 201 has landed or whose ttl has passed.
bg_sweep() {
  local f seat req exp now all done_n
  [ -d "$BG_DIR" ] || return 0
  now=$(sl_now); all=$(bg_events) || return 0
  for f in "$BG_DIR"/*.json; do [ -f "$f" ] || continue
    jq -e '.status == "active"' "$f" >/dev/null 2>&1 || continue
    seat=$(jq -r .seat "$f"); req=$(jq -r .request "$f"); exp=$(jq -r .expires_at "$f")
    done_n=$(jq --arg r "$req" '[.[] | select(.kind == "break.glass" and .code == 201 and .answer == $r)] | length' <<<"$all")
    if [ "$done_n" -gt 0 ]; then bg_restore "$seat" "done"
    elif [[ $now > $exp || $now == "$exp" ]]; then bg_restore "$seat" ttl
    fi
  done
}
