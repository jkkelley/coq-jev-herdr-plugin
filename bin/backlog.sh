#!/usr/bin/env bash
# backlog.sh - the backlog is GitHub issues (ROADMAP item H, owner card C14). One issue per item, a `backlog` label, one `priority: ...`
# label, and nothing written into git. The runbook is docs/runbooks/backlog.md.
#
#   backlog.sh add     --title T --why T --done-when T [--priority critical|now|next|later] [--json]   file an issue, default priority later
#   backlog.sh list    [--priority P] [--state open|closed|all] [--json]                             default: open issues, every priority
#   backlog.sh move    --id N|SUFFIX --to critical|now|next|later [--json]                           swap the priority label of an open issue
#   backlog.sh done    --id N|SUFFIX [--json]                                                        close the issue as completed
#   backlog.sh labels  [--json]                                                                      create the backlog and priority labels that are missing
#   backlog.sh migrate [--from-dir DIR]... [--from-ref REF]... [--dry-run] [--json]                  file every item of an old backlog/ tree, once
#   backlog.sh selftest                                                                              the suite, against a stub gh in a scratch directory
# --id takes an issue number (12 or #12) or the five-character suffix an item had in the old backlog/ tree (piwqm).
# Env: COQ_BACKLOG_REPO=OWNER/NAME the repository (default: the one gh resolves from the current checkout)   COQ_GH=PATH the gh binary (default gh)
#      COQ_BACKLOG_GIT=DIR the git checkout --from-ref reads (default: the checkout this script is in)
# Exit: 0 ok, 2 usage, 3 validation (a bad item, a closed issue, a refused state), 4 io (gh or git failed), 6 id not found.
#
# BREADCRUMB 2026-10-12 - WO-20261012-6c76. What broke: a backlog item was a file under backlog/, so adding one needed a branch and a pull
#   request, and 29 of 34 items (the ones cut after 2026-10-10) existed only on the architect's local records branch and in its working
#   tree, never on main (owner card C14; AC-H2). Why this fix: an issue is created in one call and touches no file, so there is nothing
#   for two pull requests to share. The old five-character suffix stays in the body as `<!-- backlog-id: SUFFIX -->` because comments in
#   herdr/bin and factory/bin cite items by it ("backlog disva"), and `migrate` uses the same marker to skip an item it already filed, so
#   a run that died halfway is simply run again. Rejected: a label per suffix (34 labels that mean nothing), and keeping backlog/ as a
#   cache of the issues (two sources of truth, the thing this removes).
#   Choices that look arbitrary:
#   1. Priority is the label, four values: now, next and later are the old buckets, and `critical` is read from the word in an item's
#      why line (only 1arbf, the Raspberry Pi DNS item, says it) because the old tree had no field for it and the owner called that item
#      critical on 2026-10-11. Cost: a future item that says "critical" in passing is filed critical; `move` corrects it.
#   2. A done item is filed closed with no priority label: it has none left to keep. Cost: the one closed item is not found by `list --priority`.
#   3. The sources are read in the order given and the first copy of an id wins, so the architect's records branch and the live checkout
#      (which share most of their items) file each once.
#   4. Every item is read and checked before the first issue is created, so a malformed file stops the run with nothing filed.
#   Cost: a run that is killed between two creates leaves some issues filed; run it again, it skips them.
set -uo pipefail
export LC_ALL=C
SELF=$(readlink -f "${BASH_SOURCE[0]}"); HERE=$(dirname "$SELF"); REPO=$(cd "$HERE/.." && pwd); GITDIR=${COQ_BACKLOG_GIT:-$REPO}
GH=${COQ_GH:-gh}; PRIOS=(critical now next later); LABEL=backlog
die() { local c=$1; shift; printf 'backlog: %s\n' "$*" >&2; exit "$c"; }
for t in jq "$GH"; do command -v "$t" >/dev/null 2>&1 || die 4 "$t is required"; done
GHR=(); [ -z "${COQ_BACKLOG_REPO:-}" ] || GHR=(-R "$COQ_BACKLOG_REPO")
# BREADCRUMB 2026-10-12 - WO-20261012-6c76. What broke: this wrapper was named gh, so with the default GH=gh the line below called the
#   wrapper itself, recursed until bash gave up, and every verb died with "gh issue list failed" against the real gh. The selftest never
#   saw it because its stub is a path, not a name on PATH. Why this fix: a name that no binary has (ghr); the selftest now also runs the
#   default, a stub named gh found on PATH. Rejected: `command gh` (it would skip a COQ_GH override). Cost: none.
ghr() { "$GH" "$@" ${GHR[@]+"${GHR[@]}"}; }

VERB=${1:-}; [ $# -eq 0 ] || shift
TITLE=""; WHY=""; DONEWHEN=""; PRIO=""; STATE=open; ID=""; TO=""; JSON=0; DRY=0; FROM_DIRS=(); FROM_REFS=()
while [ $# -gt 0 ]; do case $1 in
  --title) TITLE=${2-}; shift 2;; --why) WHY=${2-}; shift 2;; --done-when) DONEWHEN=${2-}; shift 2;; --priority) PRIO=${2-}; shift 2;;
  --state) STATE=${2-}; shift 2;; --id) ID=${2-}; shift 2;; --to) TO=${2-}; shift 2;; --json) JSON=1; shift;; --dry-run) DRY=1; shift;;
  --from-dir) FROM_DIRS+=("${2-}"); shift 2;; --from-ref) FROM_REFS+=("${2-}"); shift 2;;
  *) die 2 "unknown argument $1 (sed -n '2,12p' $0)";; esac; done

is_prio() { local p; for p in "${PRIOS[@]}"; do [ "$p" = "$1" ] && return 0; done; return 1; }
one_line() { printf '%s' "$1" | tr '\r\n\t' '   ' | sed 's/  */ /g; s/^ //; s/ $//'; }
# issues_json: every backlog issue, open and closed, with the priority and the old suffix pulled out of the labels and the body.
issues_json() {
  ghr issue list --label "$LABEL" --state all --limit 1000 --json number,title,state,labels,body,url | jq -c '
    map({number, title, state: (.state | ascii_downcase), url,
         priority: ([.labels[].name | select(startswith("priority: ")) | .[10:]] | first // null),
         legacy_id: (((.body // "") | capture("<!-- backlog-id: (?<i>[a-z0-9]{5}) -->") | .i) // null)})' || die 4 "gh issue list failed"
}
# ensure_labels: create the backlog label and the four priority labels that are missing (one list call, then one create per gap).
ensure_labels() {
  local have p n; have=$(ghr label list --json name --limit 200 | jq -r '.[].name') || die 4 "gh label list failed"
  declare -A color=([critical]=B60205 [now]=D93F0B [next]=FBCA04 [later]=0E8A16)
  printf '%s\n' "$have" | grep -qxF "$LABEL" || ghr label create "$LABEL" --color 5319E7 --description "a backlog item (bin/backlog.sh)" >/dev/null || die 4 "cannot create label $LABEL"
  for p in "${PRIOS[@]}"; do n="priority: $p"
    printf '%s\n' "$have" | grep -qxF "$n" || ghr label create "$n" --color "${color[$p]}" --description "backlog priority $p" >/dev/null || die 4 "cannot create label $n"
  done
}
# resolve_id VALUE: the issue's JSON object on stdout, or exit 6.
resolve_id() {
  local v=${1#\#} all hit; [ -n "$v" ] || die 2 "--id is required"
  all=$(issues_json) || exit 4
  if [[ $v =~ ^[0-9]+$ ]]; then hit=$(printf '%s' "$all" | jq -c --argjson n "$v" 'map(select(.number == $n)) | first // empty')
  elif [[ $v =~ ^[a-z0-9]{5}$ ]]; then hit=$(printf '%s' "$all" | jq -c --arg s "$v" 'map(select(.legacy_id == $s)) | first // empty')
  else die 2 "--id takes an issue number or a five-character suffix (got: $1)"; fi
  [ -n "$hit" ] || die 6 "$1 is not a backlog issue"
  printf '%s' "$hit"
}
body_of() { # WHY DONEWHEN [SUFFIX ADDED SOURCE]
  [ -z "${3:-}" ] || printf '<!-- backlog-id: %s -->\n' "$3"
  printf '**Why:** %s\n\n**Done when:** %s\n' "$1" "$2"
  [ -z "${5:-}" ] || printf '\n_Filed from %s, added %s._\n' "$5" "${4:-unknown}"
}
# file_issue TITLE BODY PRIORITY(or empty): creates the issue, prints its number.
file_issue() {
  local url labels=(--label "$LABEL"); [ -z "$3" ] || labels+=(--label "priority: $3")
  url=$(printf '%s' "$2" | ghr issue create --title "$1" --body-file - "${labels[@]}") || die 4 "gh issue create failed for: $1"
  printf '%s' "${url##*/}"
}
out_issue() { # JSON-with-number: print one issue as text or JSON
  if [ "$JSON" = 1 ]; then printf '%s\n' "$1"; else printf '%s' "$1" | jq -r '"#\(.number) \(.priority // "-") \(.state) \(.title)"'; fi
}

cmd_add() {
  [ -n "$TITLE" ] && [ -n "$WHY" ] && [ -n "$DONEWHEN" ] || die 2 "add needs --title, --why and --done-when"
  PRIO=${PRIO:-later}; is_prio "$PRIO" || die 2 "--priority is one of: ${PRIOS[*]}"
  local t w d n; t=$(one_line "$TITLE"); w=$(one_line "$WHY"); d=$(one_line "$DONEWHEN")
  ensure_labels; n=$(file_issue "$t" "$(body_of "$w" "$d")" "$PRIO")
  [[ $n =~ ^[0-9]+$ ]] || die 4 "gh issue create printed no issue number"
  if [ "$JSON" = 1 ]; then jq -nc --argjson n "$n" --arg p "$PRIO" --arg t "$t" '{ok: true, number: $n, priority: $p, title: $t}'; else printf '#%s\n' "$n"; fi
}
cmd_list() {
  case $STATE in open|closed|all) ;; *) die 2 "--state is open, closed or all";; esac
  [ -z "$PRIO" ] || is_prio "$PRIO" || die 2 "--priority is one of: ${PRIOS[*]}"
  local rows; rows=$(issues_json | jq -c --arg s "$STATE" --arg p "$PRIO" 'map(select(($s == "all" or .state == $s) and ($p == "" or .priority == $p))) | sort_by(.number)') || exit 4
  if [ "$JSON" = 1 ]; then printf '%s\n' "$rows"; else printf '%s' "$rows" | jq -r '.[] | "#\(.number) \(.priority // "-") \(.state) \(.legacy_id // "-") \(.title)"'; fi
}
cmd_move() {
  [ -n "$TO" ] && is_prio "$TO" || die 2 "move needs --to: ${PRIOS[*]}"
  local it n cur; it=$(resolve_id "$ID") || exit $?; n=$(printf '%s' "$it" | jq -r .number); cur=$(printf '%s' "$it" | jq -r '.priority // ""')
  [ "$(printf '%s' "$it" | jq -r .state)" = open ] || die 3 "#$n is closed; a closed item has no priority to move"
  if [ "$cur" = "$TO" ]; then
    if [ "$JSON" = 1 ]; then jq -nc --argjson n "$n" --arg p "$TO" '{ok: true, number: $n, priority: $p, moved: false}'; else printf '#%s is already %s - nothing to do\n' "$n" "$TO"; fi; return 0
  fi
  ensure_labels
  if [ -n "$cur" ]; then ghr issue edit "$n" --add-label "priority: $TO" --remove-label "priority: $cur" >/dev/null || die 4 "gh issue edit failed for #$n"
  else ghr issue edit "$n" --add-label "priority: $TO" >/dev/null || die 4 "gh issue edit failed for #$n"; fi
  if [ "$JSON" = 1 ]; then jq -nc --argjson n "$n" --arg f "$cur" --arg p "$TO" '{ok: true, number: $n, from: $f, priority: $p, moved: true}'; else printf '#%s\n' "$n"; fi
}
cmd_done() {
  local it n; it=$(resolve_id "$ID") || exit $?; n=$(printf '%s' "$it" | jq -r .number)
  if [ "$(printf '%s' "$it" | jq -r .state)" = closed ]; then
    if [ "$JSON" = 1 ]; then jq -nc --argjson n "$n" '{ok: true, number: $n, state: "closed", closed: false}'; else printf '#%s is already closed - nothing to do\n' "$n"; fi; return 0
  fi
  ghr issue close "$n" --reason completed >/dev/null || die 4 "gh issue close failed for #$n"
  if [ "$JSON" = 1 ]; then jq -nc --argjson n "$n" '{ok: true, number: $n, state: "closed", closed: true}'; else printf '#%s\n' "$n"; fi
}
cmd_labels() { ensure_labels; if [ "$JSON" = 1 ]; then jq -nc '{ok: true}'; else echo "labels ok"; fi; }

# parse_item BUCKET SOURCE: one old item on stdin -> one JSON line, or a message on stderr and exit 1.
parse_item() {
  local c title id added why dw; c=$(cat)
  title=$(printf '%s\n' "$c" | sed -n '1s/^# //p'); id=$(printf '%s\n' "$c" | sed -n 's/^id: //p' | head -n1)
  added=$(printf '%s\n' "$c" | sed -n 's/^added: //p' | head -n1)
  why=$(printf '%s\n' "$c" | sed -n 's/^- why: //p' | head -n1); dw=$(printf '%s\n' "$c" | sed -n 's/^- done-when: //p' | head -n1)
  if [ -z "$title" ] || ! [[ $id =~ ^[a-z0-9]{5}$ ]] || [ -z "$why" ] || [ -z "$dw" ]; then
    printf 'backlog: %s: not a backlog item (a title, an id of five characters, a why and a done-when are needed)\n' "$2" >&2; return 1
  fi
  jq -nc --arg id "$id" --arg b "$1" --arg t "$title" --arg w "$why" --arg d "$dw" --arg a "$added" --arg s "$2" \
    '{id: $id, bucket: $b, title: $t, why: $w, done_when: $d, added: $a, source: $s}'
}
# collect_items: every item of every source as JSON lines on stdout; exit 1 when one was bad (all bad ones are named), 4 on an unreadable source.
collect_items() {
  local bad=0 d ref f rel b
  for d in ${FROM_DIRS[@]+"${FROM_DIRS[@]}"}; do
    [ -d "$d" ] || die 4 "--from-dir $d is not a directory"
    while IFS= read -r f; do rel=${f#"$d"/}; b=${rel%%/*}; parse_item "$b" "backlog/$rel" <"$f" || bad=1
    done < <(find "$d" -type f -name '*.md' \( -path "$d/now/*" -o -path "$d/next/*" -o -path "$d/later/*" -o -path "$d/done/*" \) | sort)
  done
  for ref in ${FROM_REFS[@]+"${FROM_REFS[@]}"}; do
    git -C "$GITDIR" rev-parse --verify --quiet "$ref^{commit}" >/dev/null || die 4 "--from-ref $ref is not a commit in $GITDIR"
    while IFS= read -r f; do rel=${f#backlog/}; b=${rel%%/*}; git -C "$GITDIR" show "$ref:$f" | parse_item "$b" "$f" || bad=1
    done < <(git -C "$GITDIR" ls-tree -r --name-only "$ref" -- backlog | grep -E '^backlog/(now|next|later|done)/.*\.md$' | sort)
  done
  return "$bad"
}
cmd_migrate() {
  [ $((${#FROM_DIRS[@]} + ${#FROM_REFS[@]})) -gt 0 ] || die 2 "migrate needs --from-dir DIR (holding now/ next/ later/ done/) or --from-ref REF, one or more"
  local items rc total uniq existing row id bucket prio title why dw added src hit num state res="" filed=0 skipped=0 verb
  items=$(collect_items); rc=$?
  [ "$rc" = 0 ] || die $((rc == 1 ? 3 : rc)) "nothing filed: fix the items named above and run again"
  total=$(printf '%s\n' "$items" | grep -c .)
  uniq=$(printf '%s\n' "$items" | jq -sc 'unique_by(.id) | sort_by(.added, .id)') || die 4 "jq failed"
  [ "$DRY" = 1 ] || ensure_labels
  existing=$(issues_json) || exit 4
  while IFS= read -r row; do
    id=$(jq -r .id <<<"$row"); bucket=$(jq -r .bucket <<<"$row"); title=$(jq -r .title <<<"$row"); why=$(jq -r .why <<<"$row")
    dw=$(jq -r .done_when <<<"$row"); added=$(jq -r .added <<<"$row"); src=$(jq -r .source <<<"$row")
    prio=$bucket; [ "$bucket" != "done" ] || prio=""
    if [ -n "$prio" ] && printf '%s\n' "$why" | grep -qiw critical; then prio=critical; fi
    hit=$(jq -c --arg i "$id" 'map(select(.legacy_id == $i)) | first // empty' <<<"$existing"); num=""; state=""
    if [ -n "$hit" ]; then
      num=$(jq -r .number <<<"$hit"); state=skipped; skipped=$((skipped + 1))
      if [ "$bucket" = "done" ] && [ "$(jq -r .state <<<"$hit")" = open ] && [ "$DRY" = 0 ]; then
        ghr issue close "$num" --reason completed >/dev/null || die 4 "gh issue close failed for #$num"; state=closed-now
      fi
    elif [ "$DRY" = 1 ]; then state=would-file; filed=$((filed + 1))
    else
      num=$(file_issue "$title" "$(body_of "$why" "$dw" "$id" "$added" "$src")" "$prio"); [[ $num =~ ^[0-9]+$ ]] || die 4 "gh issue create printed no issue number for $id"
      [ "$bucket" != "done" ] || ghr issue close "$num" --reason completed >/dev/null || die 4 "filed #$num for $id but gh issue close failed; run again to close it"
      state=filed; filed=$((filed + 1))
    fi
    res+=$(jq -nc --arg id "$id" --arg s "$state" --arg n "$num" --arg p "$prio" --arg t "$title" '{legacy_id: $id, result: $s, number: ($n | tonumber? // null), priority: (if $p == "" then null else $p end), title: $t}')$'\n'
    [ "$JSON" = 1 ] || printf '%s %s %s %s %s\n' "$id" "$state" "${num:+#$num}" "${prio:--}" "$title"
  done < <(printf '%s' "$uniq" | jq -c '.[]')
  verb=filed; [ "$DRY" = 0 ] || verb="would file"
  if [ "$JSON" = 1 ]; then
    printf '%s' "$res" | jq -sc --argjson t "$total" --argjson f "$filed" --argjson s "$skipped" --argjson dr "$DRY" \
      '{ok: true, dry_run: ($dr == 1), read: $t, filed: $f, skipped: $s, items: .}'
  else printf 'migrate: %s read, %s distinct, %s %s, %s already filed\n' "$total" "$(jq length <<<"$uniq")" "$filed" "$verb" "$skipped"; fi
}
# write_stub DIR: a gh that keeps issues in DIR/issues.json and labels in DIR/labels.json and logs every call to DIR/calls.log.
# STUB_FAIL_CREATE_AFTER=N makes `issue create` fail once N issues exist (the half-finished migrate case).
write_stub() {
  cat >"$1/gh" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
D=$(dirname "$0"); I=$D/issues.json; L=$D/labels.json; printf '%s\n' "$*" >>"$D/calls.log"
args=(); while [ $# -gt 0 ]; do case $1 in -R) shift 2;; *) args+=("$1"); shift;; esac; done
set -- "${args[@]}"; group=$1; verb=$2; shift 2
save() { mv "$1.t" "$1"; }
case "$group $verb" in
  "label list") cat "$L";;
  "label create") jq -c --arg n "$1" '. + [{name: $n}]' "$L" >"$L.t"; save "$L";;
  "issue list") cat "$I";;
  "issue create") title=""; labels=()
    while [ $# -gt 0 ]; do case $1 in --title) title=$2; shift 2;; --label) labels+=("$2"); shift 2;; *) shift;; esac; done
    body=$(cat); n=$(jq 'length + 1' "$I")
    if [ -n "${STUB_FAIL_CREATE_AFTER:-}" ] && [ "$n" -gt "$STUB_FAIL_CREATE_AFTER" ]; then echo "stub: create refused" >&2; exit 1; fi
    lj=$(printf '%s\n' "${labels[@]}" | jq -R . | jq -sc 'map({name: .})')
    jq -c --argjson n "$n" --arg t "$title" --arg b "$body" --argjson l "$lj" \
      '. + [{number: $n, title: $t, state: "OPEN", body: $b, url: "https://example.test/o/r/issues/\($n)", labels: $l}]' "$I" >"$I.t"; save "$I"
    echo "https://example.test/o/r/issues/$n";;
  "issue edit") n=$1; shift; add=""; rm=""
    while [ $# -gt 0 ]; do case $1 in --add-label) add=$2; shift 2;; --remove-label) rm=$2; shift 2;; *) shift;; esac; done
    jq -c --argjson n "$n" --arg a "$add" --arg r "$rm" 'map(if .number == $n then .labels = ((.labels | map(select(.name != $r))) + (if $a == "" then [] else [{name: $a}] end)) else . end)' "$I" >"$I.t"; save "$I";;
  "issue close") jq -c --argjson n "$1" 'map(if .number == $n then .state = "CLOSED" else . end)' "$I" >"$I.t"; save "$I";;
  *) echo "stub: unsupported: $group $verb" >&2; exit 1;;
esac
STUB
  chmod +x "$1/gh"; printf '[]' >"$1/issues.json"; printf '[]' >"$1/labels.json"
}
# mk_item FILE ID TITLE WHY DONE_WHEN ADDED: an old-format item; an empty DONE_WHEN leaves the line out (a bad item).
mk_item() {
  mkdir -p "$(dirname "$1")"
  { printf '# %s\n\n<!-- item\nid: %s\nadded: %s\n-->\n\n- why: %s\n' "$3" "$2" "$6" "$4"; [ -z "$5" ] || printf -- '- done-when: %s\n' "$5"; } >"$1"
}
T=""; PASS=0; FAILS=0
check() { if [ "$2" = 0 ]; then PASS=$((PASS + 1)); printf 'ok    %s\n' "$1"; else FAILS=$((FAILS + 1)); printf 'FAIL  %s\n' "$1"; fi; }
# bb ARGS: this script, against the stub, from inside the scratch git checkout (so a file it wrote into git would show in `git status`).
bb() { (cd "$T/repo" && COQ_GH="$T/stub/gh" COQ_BACKLOG_GIT="$T/repo" bash "$SELF" "$@"); }
nissues() { jq length "$T/stub/issues.json"; }
issue() { jq -c --argjson n "$1" '.[] | select(.number == $n)' "$T/stub/issues.json"; }
cmd_selftest() {
  local o rc before
  T=$(mktemp -d) || die 4 "mktemp failed"; mkdir -p "$T/stub" "$T/repo"; write_stub "$T/stub"
  git -C "$T/repo" init -q && git -C "$T/repo" -c user.name=t -c user.email=t@example.test commit -q --allow-empty -m init || die 4 "git init failed"
  o=$(bb add --title "First  item" --why "because" --done-when "it is filed"); rc=$?
  check "add prints the issue number" "$([ "$rc" = 0 ] && [ "$o" = '#1' ]; echo $?)"
  check "add: default priority is later, labels backlog and priority: later" "$(issue 1 | jq -e '(.labels | map(.name) | sort) == ["backlog", "priority: later"]' >/dev/null; echo $?)"
  check "add: title is one line, body has why and done-when" "$(issue 1 | jq -e '.title == "First item" and (.body | contains("**Why:** because") and contains("**Done when:** it is filed"))' >/dev/null; echo $?)"
  check "add: all five labels exist" "$(jq -e 'map(.name) | sort == ["backlog", "priority: critical", "priority: later", "priority: next", "priority: now"]' "$T/stub/labels.json" >/dev/null; echo $?)"
  check "add: changes no file in git (AC-H2)" "$([ -z "$(git -C "$T/repo" status --porcelain)" ]; echo $?)"
  bb add --title "Pi DNS" --why "critical, owner said so" --done-when "names resolve" --priority critical >/dev/null
  check "add --priority critical" "$(issue 2 | jq -e '.labels | map(.name) | index("priority: critical") != null' >/dev/null; echo $?)"
  bb add --title "x" --why "y" --done-when "z" --priority urgent >/dev/null 2>&1; rc=$?; check "add: an unknown priority is exit 2" "$([ "$rc" = 2 ]; echo $?)"
  bb add --title "x" --why "y" >/dev/null 2>&1; rc=$?; check "add: a missing --done-when is exit 2" "$([ "$rc" = 2 ]; echo $?)"
  check "add: refused calls filed nothing" "$([ "$(nissues)" = 2 ]; echo $?)"
  check "list: default is the open issues" "$([ "$(bb list | wc -l)" = 2 ]; echo $?)"
  check "list --priority critical --json" "$(bb list --priority critical --json | jq -e 'length == 1 and .[0].number == 2 and .[0].priority == "critical"' >/dev/null; echo $?)"
  bb move --id 1 --to now >/dev/null; check "move swaps the priority label" "$(issue 1 | jq -e '(.labels | map(.name) | sort) == ["backlog", "priority: now"]' >/dev/null; echo $?)"
  o=$(bb move --id '#1' --to now --json); check "move to the same priority is a reported no-op" "$(printf '%s' "$o" | jq -e '.moved == false' >/dev/null; echo $?)"
  bb move --id 1 --to soon >/dev/null 2>&1; rc=$?; check "move: an unknown priority is exit 2" "$([ "$rc" = 2 ]; echo $?)"
  bb move --id 99 --to now >/dev/null 2>&1; rc=$?; check "move: an unknown issue is exit 6" "$([ "$rc" = 6 ]; echo $?)"
  bb move --id zzzzz --to now >/dev/null 2>&1; rc=$?; check "move: an unknown old suffix is exit 6" "$([ "$rc" = 6 ]; echo $?)"
  bb "done" --id 2 >/dev/null; check "done closes the issue" "$(issue 2 | jq -e '.state == "CLOSED"' >/dev/null; echo $?)"
  o=$(bb "done" --id 2 --json); check "done on a closed issue is a reported no-op" "$(printf '%s' "$o" | jq -e '.closed == false' >/dev/null; echo $?)"
  bb move --id 2 --to now >/dev/null 2>&1; rc=$?; check "move: a closed issue is exit 3" "$([ "$rc" = 3 ]; echo $?)"
  check "list: default hides the closed one, --state all shows both" "$([ "$(bb list | wc -l)" = 1 ] && [ "$(bb list --state all | wc -l)" = 2 ]; echo $?)"
  # the default gh is a name on PATH, which is what a seat has; COQ_GH set to a path would not have caught the wrapper calling itself
  o=$(cd "$T/repo" && env -u COQ_GH PATH="$T/stub:$PATH" COQ_BACKLOG_GIT="$T/repo" bash "$SELF" list --state all); rc=$?
  check "list works with gh found on PATH (the default)" "$([ "$rc" = 0 ] && [ "$(printf '%s\n' "$o" | wc -l)" = 2 ]; echo $?)"

  # migrate
  local O="$T/old" before2
  mk_item "$O/now/20261010T000001Z-aaaaa.md" aaaaa "A now item" "reason a" "check a" 2026-10-10T00:00:01Z
  mk_item "$O/next/20261010T000002Z-bbbbb.md" bbbbb "A next item" "reason b" "check b" 2026-10-10T00:00:02Z
  mk_item "$O/later/20261010T000003Z-ccccc.md" ccccc "A later item" "reason c" "check c" 2026-10-10T00:00:03Z
  mk_item "$O/done/2026/10/20261010T000004Z-ddddd.md" ddddd "A done item" "reason d" "check d" 2026-10-10T00:00:04Z
  mk_item "$O/now/20261010T000005Z-eeeee.md" eeeee "The critical item" "Owner said critical, today" "check e" 2026-10-10T00:00:05Z
  : >"$O/now/.gitkeep"
  before=$(nissues); o=$(bb migrate --from-dir "$O" --dry-run); rc=$?
  check "migrate --dry-run files nothing" "$([ "$rc" = 0 ] && [ "$(nissues)" = "$before" ] && printf '%s' "$o" | grep -q 'would file'; echo $?)"
  o=$(bb migrate --from-dir "$O" --json); rc=$?
  check "migrate files every item once" "$([ "$rc" = 0 ] && [ "$(nissues)" = $((before + 5)) ] && printf '%s' "$o" | jq -e '.filed == 5 and .skipped == 0' >/dev/null; echo $?)"
  check "migrate: each priority comes from its bucket, critical from the word" "$(bb list --state all --json | jq -e '
      (map(select(.legacy_id == "aaaaa"))[0].priority == "now") and (map(select(.legacy_id == "bbbbb"))[0].priority == "next")
      and (map(select(.legacy_id == "ccccc"))[0].priority == "later") and (map(select(.legacy_id == "eeeee"))[0].priority == "critical")' >/dev/null; echo $?)"
  check "migrate: a done item is filed closed with no priority" "$(bb list --state closed --json | jq -e 'map(select(.legacy_id == "ddddd")) | length == 1 and .[0].priority == null' >/dev/null; echo $?)"
  check "migrate: the body keeps the old id, why and done-when" "$(issue "$((before + 1))" | jq -e '.body | contains("<!-- backlog-id: aaaaa -->") and contains("**Why:** reason a") and contains("**Done when:** check a")' >/dev/null; echo $?)"
  check "migrate: oldest item is the lowest issue number" "$(issue "$((before + 1))" | jq -e '.title == "A now item"' >/dev/null; echo $?)"
  before=$(nissues); o=$(bb migrate --from-dir "$O" --json)
  check "migrate twice files nothing the second time" "$([ "$(nissues)" = "$before" ] && printf '%s' "$o" | jq -e '.filed == 0 and .skipped == 5' >/dev/null; echo $?)"
  check "move and done find a migrated item by its old suffix" "$(bb move --id aaaaa --to next >/dev/null && bb "done" --id ccccc >/dev/null && issue "$((before - 4))" | jq -e '.labels | map(.name) | index("priority: next") != null' >/dev/null; echo $?)"
  check "migrate changes no file in git" "$([ -z "$(git -C "$T/repo" status --porcelain)" ]; echo $?)"

  # a second source: the same item twice files it once, a new one is filed
  local O2="$T/old2"; mk_item "$O2/now/20261010T000001Z-aaaaa.md" aaaaa "A now item" "reason a" "check a" 2026-10-10T00:00:01Z
  mk_item "$O2/next/20261010T000006Z-fffff.md" fffff "Only in the second source" "reason f" "check f" 2026-10-10T00:00:06Z
  before=$(nissues); o=$(bb migrate --from-dir "$O" --from-dir "$O2" --json)
  check "migrate: two sources, one copy of an id, new items filed" "$([ "$(nissues)" = $((before + 1)) ] && printf '%s' "$o" | jq -e '.read == 7 and .filed == 1 and .skipped == 5' >/dev/null; echo $?)"

  # a git ref
  mkdir -p "$T/repo/backlog/now"; mk_item "$T/repo/backlog/now/20261010T000007Z-ggggg.md" ggggg "Only on a branch" "reason g" "check g" 2026-10-10T00:00:07Z
  git -C "$T/repo" add -A && git -C "$T/repo" -c user.name=t -c user.email=t@example.test commit -q -m "an item"
  before=$(nissues); o=$(bb migrate --from-ref HEAD --json); rc=$?
  check "migrate --from-ref reads the items a commit holds" "$([ "$rc" = 0 ] && [ "$(nissues)" = $((before + 1)) ] && printf '%s' "$o" | jq -e '.filed == 1' >/dev/null; echo $?)"
  bb migrate --from-ref no-such-ref >/dev/null 2>&1; rc=$?; check "migrate: an unknown ref is exit 4" "$([ "$rc" = 4 ]; echo $?)"
  bb migrate >/dev/null 2>&1; rc=$?; check "migrate: no source is exit 2" "$([ "$rc" = 2 ]; echo $?)"

  # a bad item stops the run with nothing filed
  local O3="$T/old3"; mk_item "$O3/now/20261010T000008Z-hhhhh.md" hhhhh "Good" "r" "c" 2026-10-10T00:00:08Z
  mk_item "$O3/now/20261010T000009Z-iiiii.md" iiiii "Missing its done-when" "r" "" 2026-10-10T00:00:09Z
  before=$(nissues); bb migrate --from-dir "$O3" >/dev/null 2>"$T/err"; rc=$?
  check "migrate: a bad item is exit 3, names the file and files nothing" "$([ "$rc" = 3 ] && [ "$(nissues)" = "$before" ] && grep -q 'iiiii.md' "$T/err"; echo $?)"

  # a run that dies halfway is finished by running it again
  local O4="$T/old4"; mk_item "$O4/now/20261010T000010Z-jjjjj.md" jjjjj "J" "r" "c" 2026-10-10T00:00:10Z
  mk_item "$O4/now/20261010T000011Z-kkkkk.md" kkkkk "K" "r" "c" 2026-10-10T00:00:11Z
  mk_item "$O4/now/20261010T000012Z-lllll.md" lllll "L" "r" "c" 2026-10-10T00:00:12Z
  before2=$(nissues); STUB_FAIL_CREATE_AFTER=$((before2 + 1)) bb migrate --from-dir "$O4" >/dev/null 2>&1; rc=$?
  check "migrate: a failing create is exit 4 after the first was filed" "$([ "$rc" = 4 ] && [ "$(nissues)" = $((before2 + 1)) ]; echo $?)"
  o=$(bb migrate --from-dir "$O4" --json)
  check "migrate: running again files only the rest, none twice" "$([ "$(nissues)" = $((before2 + 3)) ] && printf '%s' "$o" | jq -e '.filed == 2 and .skipped == 1' >/dev/null; echo $?)"

  rm -rf "$T"
  printf 'backlog selftest: %s passed, %s failed\n' "$PASS" "$FAILS"
  [ "$FAILS" = 0 ] || exit 3
}

case $VERB in
  add) cmd_add;; list) cmd_list;; move) cmd_move;; done) cmd_done;; labels) cmd_labels;;
  migrate) cmd_migrate;; selftest) cmd_selftest;;
  *) sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2;;
esac
