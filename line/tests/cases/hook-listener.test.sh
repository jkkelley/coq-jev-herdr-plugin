#!/usr/bin/env bash
# hook-listener: line/bin/hook-listener.sh serving on a localhost port, against a copy of the scripts it needs, a stub handler and a
# scratch state root (WO-20261013-ca2a, AC-H1 to AC-H3).
#   status      a coq/gate status on a head sha is one record with the sha and the state (201 success, 422 failure, 100 pending)
#   filter      another status context, a created check_run and a closed pull_request make no record and run no handler
#   check_run   a completed check_run is one record with the sha and the pull request number
#   pull_request an opened pull_request is one record with the sha and the number
#   bad         a body that is not JSON and a sha that is not hex are a 400 and no record
#   handlers    each handler hook.json names for the event gets the same payload on stdin; a missing file is skipped with a logged note;
#               a failing one posts a note 500 and the next one still runs
#   retry       a records tree that cannot be written is tried 3 times, then a 500 and a note-500 attempt, never a silent drop
#   page        the page is the blocked 423 to the orchestrator with the unit and the restart count in its note (AC-H2)
#   units       Restart=always, StartLimitBurst equal to restart_limit, OnFailure= the page unit, every ExecStart script present
#   forward     gh webhook forward gets the repo, the events and the listener URL from hook.json; a missing extension is exit 4 with the fix
#   config      a hook.json without a key is exit 3 naming the key
# The kill-and-restart itself is systemd's; the units case checks the settings that make it climb the ladder.
# The world is a copy of the scripts under $W/repo, so handlers resolve ${repo} inside it and the read-only /repo mount is untouched.
set -uo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
. "$HERE/../lib/assert.sh"
SRC=${REPO_ROOT:-/repo}
W=${COQ_CASE_WORK:?COQ_CASE_WORK is set by line/tests/run.sh}; R=$W/repo; STATE=$W/state
mkdir -p "$R/line/bin" "$R/line/config" "$R/line/units" "$R/bin" "$R/config" "$R/events" "$R/ci/bin" "$W/bin" "$W/home" "$STATE"
cp "$SRC/line/bin/hook-listener.sh" "$R/line/bin/"; cp "$SRC"/line/config/hook*.json "$R/line/config/"; cp "$SRC"/line/units/* "$R/line/units/"
cp "$SRC/bin/state-root.sh" "$R/bin/"; cp "$SRC/config/state.json" "$R/config/"; cp -r "$SRC/events/bin" "$SRC/events/schema" "$R/events/"
export HOME="$W/home" COQ_STATE="$STATE" PATH="$W/bin:$PATH" HOOK_CONFIG="$R/line/config/hook.json"
unset COQ_CACHE COQ_REPO XDG_STATE_HOME XDG_CACHE_HOME HOOK_LOG MONITOR_UNIT
SCRIPT=$R/line/bin/hook-listener.sh; PORT=19371; URL=http://127.0.0.1:$PORT/
SHA=0123456789abcdef0123456789abcdef01234567

# the world's config: the test port, and two stub handlers plus one that has no file yet
jq --argjson p "$PORT" '.port = $p | .retry_seconds = 0 | .handlers = [
    {event:"status", context:"coq/gate", run:"${repo}/ci/bin/stub-a.sh"},
    {event:"status", context:"coq/gate", run:"${repo}/ci/bin/missing.sh"},
    {event:"status", context:"coq/gate", run:"${repo}/ci/bin/stub-b.sh"},
    {event:"pull_request", run:"${repo}/ci/bin/stub-a.sh"}]' "$SRC/line/config/hook.json" > "$HOOK_CONFIG"
cat > "$R/ci/bin/stub-a.sh" <<'STUB'
#!/usr/bin/env bash
cat > "$STUB_OUT/a.$HOOK_EVENT.payload"; env | grep '^HOOK_' | sort > "$STUB_OUT/a.$HOOK_EVENT.env"
STUB
cat > "$R/ci/bin/stub-b.sh" <<'STUB'
#!/usr/bin/env bash
cat > "$STUB_OUT/b.$HOOK_EVENT.payload"; [ ! -e "$STUB_FAIL" ] || exit 7
STUB
export STUB_OUT=$W/stub STUB_FAIL=$W/stub-b.fail; mkdir -p "$STUB_OUT"

records() { find "$STATE/records" -name '*.json' 2>/dev/null | sort; }
count() { records | wc -l | tr -d ' '; }
rec() { jq -r "$1" "$(find "$STATE/records" -name '*.json' -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)"; } # one field of the newest record, by write time
# send EVENT JSON: print "<http status> <body>"
send() {
  python3 -I - "$URL" "$1" "$2" <<'PY'
import sys, urllib.request, urllib.error
req = urllib.request.Request(sys.argv[1], data=sys.argv[3].encode(), headers={"X-GitHub-Event": sys.argv[2], "Content-Type": "application/json"})
try:
    r = urllib.request.urlopen(req, timeout=30); print(r.status, r.read().decode().strip())
except urllib.error.HTTPError as e:
    print(e.code, e.read().decode().strip())
PY
}
status_json() { jq -nc --arg c "$1" --arg s "$2" --arg sha "$SHA" '{context:$c, state:$s, sha:$sha, repository:{full_name:"o/r"}}'; }

bash "$SCRIPT" serve > "$W/serve.out" 2>&1 & SERVER=$!
trap 'kill "$SERVER" 2>/dev/null' EXIT
for _ in $(seq 1 50); do (exec 3<>"/dev/tcp/127.0.0.1/$PORT") 2>/dev/null && break; sleep 0.1; done
check "the listener is up" "$([ -d /proc/$SERVER ] && echo 1 || echo 0)"

echo "-- a coq/gate status on a head sha is one record carrying the sha and the state (AC-H1)"
out=$(send status "$(status_json coq/gate success)")
assert_match "answered 200 and says recorded" "$out" '^200 recorded '
assert_eq "one record" "$(count)" 1
assert_eq "its sha" "$(rec .sha)" "$SHA"
assert_eq "its code is 201 for success" "$(rec .code)" 201
assert_match "its note names the state" "$(rec .note)" 'coq/gate success'
assert_eq "its seat" "$(rec .seat)" hook-listener
out=$(send status "$(status_json coq/gate failure)"); assert_match "a failure is answered 200" "$out" '^200 recorded '
assert_eq "failure is code 422" "$(rec .code)" 422
send status "$(status_json coq/gate pending)" > /dev/null
assert_eq "pending is code 100" "$(rec .code)" 100
assert_eq "three deliveries, three records" "$(count)" 3

echo "-- the handlers get the same payload on stdin (AC-H3)"
sent=$(status_json coq/gate success); rm -f "$STUB_OUT"/*; n=$(count); touch "$STUB_FAIL"
send status "$sent" > /dev/null; rm -f "$STUB_FAIL"
assert_eq "stub-a got the payload byte for byte" "$(cat "$STUB_OUT/a.status.payload" 2>/dev/null)" "$sent"
assert_match "stub-a saw the sha and state" "$(cat "$STUB_OUT/a.status.env" 2>/dev/null)" "HOOK_SHA=$SHA"
assert_match "stub-a saw the record path" "$(cat "$STUB_OUT/a.status.env" 2>/dev/null)" "HOOK_RECORD=$STATE/records/"
assert_eq "stub-b, after the missing file, got it too" "$(cat "$STUB_OUT/b.status.payload" 2>/dev/null)" "$sent"
log=$(cat "$STATE"/logs/*/*/*-hook-listener-serve.log)
assert_match "the missing handler was skipped with a note" "$log" 'skipping handler \$\{repo\}/ci/bin/missing.sh: the file does not exist yet'
assert_match "stub-b's failure is logged" "$log" 'stub-b.sh exited 7'
assert_eq "stub-b's failure is a note 500 beside the gate record" "$(( $(count) - n ))" 2
assert_eq "that note is code 500" "$(rec .code)" 500
assert_match "that note names the handler" "$(rec .note)" 'stub-b.sh exited 7'

echo "-- events the line does not want make no record and run no handler"
rm -f "$STUB_OUT"/*; n=$(count)
out=$(send status "$(status_json ci/other success)"); assert_match "other context: 200 skipped" "$out" '^200 skipped context ci/other'
out=$(send check_run "$(jq -nc --arg s "$SHA" '{action:"created", check_run:{name:"x", head_sha:$s}}')"); assert_match "created check_run: skipped" "$out" '^200 skipped action created'
out=$(send pull_request "$(jq -nc --arg s "$SHA" '{action:"closed", number:4, pull_request:{head:{sha:$s}}}')"); assert_match "closed pull_request: skipped" "$out" '^200 skipped action closed'
out=$(send ping '{"zen":"hi"}'); assert_match "ping: skipped" "$out" '^200 skipped event ping'
assert_eq "no record" "$(count)" "$n"
assert_eq "no handler ran" "$(ls "$STUB_OUT" | wc -l | tr -d ' ')" 0

echo "-- check_run and pull_request become records with the number"
out=$(send check_run "$(jq -nc --arg s "$SHA" '{action:"completed", check_run:{name:"coq/gate", head_sha:$s, conclusion:"success", pull_requests:[{number:12}]}}')")
assert_match "completed check_run: recorded" "$out" '^200 recorded '
assert_eq "its sha" "$(rec .sha)" "$SHA"; assert_eq "its pr" "$(rec .pr)" 12; assert_eq "its code" "$(rec .code)" 201
send check_run "$(jq -nc --arg s "$SHA" '{action:"completed", check_run:{name:"coq/gate", head_sha:$s, conclusion:"failure", pull_requests:[]}}')" > /dev/null
assert_eq "a failed check_run is 422" "$(rec .code)" 422; assert_eq "with no pr when the payload names none" "$(rec .pr)" null
out=$(send pull_request "$(jq -nc --arg s "$SHA" '{action:"synchronize", number:12, pull_request:{head:{sha:$s}}}')")
assert_match "synchronize: recorded" "$out" '^200 recorded '
assert_eq "its sha" "$(rec .sha)" "$SHA"; assert_eq "its pr" "$(rec .pr)" 12; assert_eq "its code" "$(rec .code)" 100
assert_eq "the pull_request handler got the payload" "$(jq -r .number "$STUB_OUT/a.pull_request.payload")" 12

echo "-- a bad delivery is a 400 and no record"
n=$(count)
out=$(send status 'not json'); assert_match "not JSON: 400" "$out" '^400 '
out=$(send status "$(jq -nc '{context:"coq/gate", state:"success", sha:"nothex"}')"); assert_match "bad sha: 400" "$out" '^400 '
out=$(send status "$(jq -nc --arg s "$SHA" '{context:"coq/gate", state:"weird", sha:$s}')"); assert_match "unknown state: 400" "$out" '^400 '
assert_eq "no record" "$(count)" "$n"

echo "-- a records tree that cannot be written: 3 tries, a 500, and a report attempt (never silent)"
month=$STATE/records/$(date -u +%Y/%m); chmod 555 "$month"
n=$(count)
out=$(send status "$(status_json coq/gate success)")
chmod 755 "$month"
assert_match "answered 500" "$out" '^500 '
assert_eq "no record written" "$(count)" "$n"
log=$(cat "$STATE"/logs/*/*/*-hook-listener-serve.log)
assert_eq "3 write attempts logged" "$(printf '%s\n' "$log" | grep -c 'record write failed, attempt [123] of 3')" 3
assert_match "the give-up is logged" "$log" 'no record after 3 tries'

echo "-- the page is the blocked 423 to the orchestrator (AC-H2)"
n=$(count); MONITOR_UNIT=coq-hook-listener.service bash "$SCRIPT" page > /dev/null 2>&1; rc=$?
assert_eq "page exits 0" "$rc" 0; assert_eq "one record" "$(( $(count) - n ))" 1
assert_eq "kind blocked" "$(rec .kind)" blocked; assert_eq "code 423" "$(rec .code)" 423
assert_eq "seat hook-listener" "$(rec .seat)" hook-listener; assert_eq "to the orchestrator" "$(rec .to)" orchestrator
assert_eq "the note" "$(rec .note)" "coq-hook-listener.service failed 3 restarts"
bash "$SCRIPT" page coq-hook-forward.service > /dev/null 2>&1; assert_eq "the unit as an argument works too" "$(rec .note)" "coq-hook-forward.service failed 3 restarts"
bash "$SCRIPT" page > /dev/null 2>&1; assert_eq "no unit named is exit 2" "$?" 2

echo "-- the units climb the ladder"
limit=$(jq -r .restart_limit "$SRC/line/config/hook.json")
for u in listener forward; do f=$SRC/line/units/coq-hook-$u.service
  assert_match "$u: Restart=always" "$(cat "$f")" '^Restart=always$'
  assert_eq "$u: StartLimitBurst equals restart_limit" "$(sed -n 's/^StartLimitBurst=//p' "$f")" "$limit"
  assert_match "$u: OnFailure pages" "$(cat "$f")" '^OnFailure=coq-hook-page\.service$'
done
assert_match "page unit is a oneshot" "$(cat "$SRC/line/units/coq-hook-page.service")" '^Type=oneshot$'
for f in "$SRC"/line/units/coq-hook-*.service; do
  exe=$(sed -n 's/^ExecStart=%h\/projects\/coq-jev-herdr-plugin\/\([^ ]*\).*/\1/p' "$f")
  check "$(basename "$f"): ExecStart is a script in this repo ($exe)" "$([ -x "$SRC/$exe" ] && echo 1 || echo 0)"
done

echo "-- forward feeds the listener from hook.json"
printf '#!/usr/bin/env bash\n[ "$1 $2" != "webhook --help" ] || exit 0\nprintf "%%s\\n" "$*" > "%s/gh.argv"\n' "$W" > "$W/bin/gh"; chmod +x "$W/bin/gh"
bash "$SCRIPT" forward > /dev/null 2>&1
assert_eq "gh got the repo, the events and the URL" "$(cat "$W/gh.argv")" "webhook forward --repo $(jq -r .repo "$HOOK_CONFIG") --events status,check_run,pull_request --url $URL"
printf '#!/usr/bin/env bash\nexit 1\n' > "$W/bin/gh"
out=$(bash "$SCRIPT" forward 2>&1); rc=$?
assert_eq "a missing extension is exit 4" "$rc" 4; assert_match "and names the fix" "$out" 'gh extension install cli/gh-webhook'

echo "-- the config"
bash "$SCRIPT" check > /dev/null 2>&1; assert_eq "check passes" "$?" 0
jq 'del(.port)' "$HOOK_CONFIG" > "$W/bad.json"; out=$(HOOK_CONFIG=$W/bad.json bash "$SCRIPT" check 2>&1); rc=$?
assert_eq "a missing key is exit 3" "$rc" 3; assert_match "naming the key" "$out" 'lacks: port'
python3 -I -c "import json,jsonschema,sys; jsonschema.validate(json.load(open(sys.argv[1])), json.load(open(sys.argv[2])))" "$SRC/line/config/hook.json" "$SRC/line/config/hook.schema.json" 2>/dev/null
assert_eq "the shipped hook.json passes its schema" "$?" 0

echo "-- files"
assert_eq "HOME is still empty" "$(ls -A "$HOME" | wc -l | tr -d ' ')" 0
case_done
