#!/usr/bin/env bash
# Runs inside the test container. /skill is the tool (read-only), /work is scratch.
set -euo pipefail
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "ok   - $*"; }
bad() { FAIL=$((FAIL+1)); echo "FAIL - $*" >&2; }
check() { if "$@"; then ok "${CASE:-$*}"; else bad "${CASE:-$*}"; fi; }
B=/skill/scripts/bearings.sh

# T0 config lint against the JSON schema (the contract) with python jsonschema.
CASE="config/bearings.json validates against bearings.schema.json"
check python3 -c 'import json,jsonschema,sys; jsonschema.validate(json.load(open("/skill/config/bearings.json")), json.load(open("/skill/config/bearings.schema.json")))'
[ "${MODE:-all}" = --lint-only ] && { echo "lint: $PASS passed, $FAIL failed"; exit $((FAIL>0?3:0)); }

# A test config: state under /work, dev tier on a small port range.
cat > /work/config.json <<JSON
{"schema_version":"1.0.0","project":"t","state_root":"/work/state","listen_host":"127.0.0.1","allowed_hosts":["127.0.0.1","localhost"],"cookie_name":"bearings_key","idle_minutes":5,"settle_ms":300,"stop_tries":3,"stop_try_ms":1000,"max_body_bytes":65536,"max_message_chars":8000,"max_reply_chars":32000,"max_words_chars":4000,"messages_window":50,"open_label_prefix":"OPEN - any tool","pane_split":{"direction":"down","ratio":0.2},
 "tiers":{"stable":{"page":"\${project}-stable","port":45900,"pane_label":"b-stable","wait_pane_label":"b-stable-wait","checkout":"main"},
          "dev":{"page":"\${project}-dev-\${ticket}","port_range":[45920,45922],"pane_label":"b-dev-\${ticket}","wait_pane_label":"b-dev-\${ticket}-wait","checkout":"slot"}}}
JSON
C=(--config /work/config.json --no-herdr)

# T1 a missing key fails with exit 3 naming the key, nothing starts.
jq 'del(.tiers.dev.page)' /work/config.json > /work/bad.json
set +e; out=$($B dev status --ticket x --config /work/bad.json 2>&1); rc=$?; set -e
CASE="missing config key -> exit 3 naming tiers.dev.page"; check test "$rc" = 3 -a "${out#*tiers.dev.page}" != "$out"

# T2 serve dev with a ticket, page name and state dir derive from config.
cat > /work/q.json <<'JSON'
{"title":"probe","items":[{"id":"P1","about":"probe","decide":"Pick one?","options":[{"label":"A","then":"a"},{"label":"B","then":"b"}],"rec":0}]}
JSON
$B dev ask --ticket t1 "${C[@]}" /work/q.json
URL=$($B dev serve --ticket t1 "${C[@]}")
CASE="dev serve prints a url on a port in the configured range"; check bash -c '[[ "$1" =~ ^http://localhost:4592[0-2]/\?key=[a-f0-9]{32}$ ]]' _ "$URL"
CASE="state dir is <state_root>/<project>-dev-<ticket>"; check test -f /work/state/t-dev-t1/server.json
CASE="/state serves the asked card"; check bash -c 'curl -sf "$1" >/dev/null 2>&1 || node -e "fetch(process.argv[1].replace(\"/?key=\",\"/state?key=\")).then(r=>r.json()).then(s=>process.exit(s.questions.items[0].id===\"P1\"?0:1))" "$1"' _ "$URL"

# T3 a second start of the same tier is refused with exit 3 and the live url.
set +e; out=$($B dev serve --ticket t1 "${C[@]}" 2>&1); rc=$?; set -e
CASE="second serve of the same tier -> exit 3 with the url"; check test "$rc" = 3 -a "${out#*$URL}" != "$out"

# T4 the browser: Live, card rendered, no page errors, answer round-trips.
node /skill/tests/probe.mjs "$URL" /work/shot.png > /work/probe.json
CASE="page reports Live"; check test "$(jq -r .live /work/probe.json)" = Live
CASE="first card rendered"; check test "$(jq -r .card_head /work/probe.json | grep -c 'Pick one')" = 1
[ "$(jq '.errors | length' /work/probe.json)" = 0 ] || jq -r '.errors[]' /work/probe.json >&2
CASE="zero page errors"; check test "$(jq '.errors | length' /work/probe.json)" = 0
if ! { test -s /work/state/t-dev-t1/answers.jsonl && grep -q "probe words" /work/state/t-dev-t1/answers.jsonl; }; then
  { echo "--- debug: state dir"; ls -la /work/state/t-dev-t1 || true; echo "--- answers.jsonl"; cat /work/state/t-dev-t1/answers.jsonl || true; echo "--- probe.json"; cat /work/probe.json || true; echo; } >&2 || true
fi
CASE="queued answer reached answers.jsonl with the words"; check bash -c 'test -s /work/state/t-dev-t1/answers.jsonl && grep -q "probe words" /work/state/t-dev-t1/answers.jsonl'
CASE="wait.mjs delivers the ANSWER line"; check bash -c 'timeout 15 $0 dev wait --ticket t1 "$@" | grep -q "^ANSWER P1 - Pick one? -> A | words: probe words"' "$B" "${C[@]}"

# T4b attachments: upload the probe screenshot as a PNG, send a message carrying it,
# read it back inline, and the wait line names the stored path (owner ask m-20261010192521524-wfo6h).
node -e '
const url = process.argv[1]; const fs = require("fs");
const at = (route) => url.replace("/?key=", `/${route}?key=`);
(async () => {
  const buf = fs.readFileSync("/work/shot.png");
  const up = await (await fetch(at("file"), { method: "POST", headers: { "content-type": "image/png", "x-file-name": "shot.png" }, body: buf })).json();
  if (!up.id) throw new Error(`upload: ${JSON.stringify(up)}`);
  const msg = await (await fetch(at("message"), { method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify({ id: "m-probe-file-1", text: "here is a shot", files: [{ id: up.id }] }) })).json();
  if (!msg.files) throw new Error(`message: ${JSON.stringify(msg)}`);
  const got = await fetch(at(`file/${up.id}`));
  const len = (await got.arrayBuffer()).byteLength;
  fs.writeFileSync("/work/file.json", JSON.stringify({ upload: up, message: msg, get_status: got.status, get_type: got.headers.get("content-type"), get_len: len, buf_len: buf.length }));
})().catch((e) => fs.writeFileSync("/work/file.json", JSON.stringify({ error: String(e) })));
' "$URL"
[ "$(jq -r '.error // empty' /work/file.json)" = "" ] || jq -r .error /work/file.json >&2
CASE="PNG upload is stored as image/png with an f- id"; check bash -c 'test "$(jq -r .upload.mime /work/file.json)" = image/png && [[ "$(jq -r .upload.id /work/file.json)" == f-* ]]'
CASE="GET /file/:id serves the same bytes back as image/png"; check bash -c 'test "$(jq -r .get_type /work/file.json)" = image/png -a "$(jq .get_len /work/file.json)" = "$(jq .buf_len /work/file.json)"'
CASE="wait.mjs prints the stored path on the MESSAGE line"; check bash -c 'timeout 15 $0 dev wait --ticket t1 "$@" | grep -qE "^MESSAGE m-probe-file-1 - here is a shot \| files: /work/state/t-dev-t1/files/f-[A-Za-z0-9-]+\.png$"' "$B" "${C[@]}"

# T4c rotate-key: a new key, the old link refused, the page still up on the same port.
OLD_URL=$URL
URL=$($B dev rotate-key --ticket t1 "${C[@]}")
CASE="rotate-key prints a url with a different key"; check bash -c '[[ "$2" =~ ^http://localhost:4592[0-2]/\?key=[a-f0-9]{32}$ ]] && [ "$1" != "$2" ] && [ "${1%%\?*}" = "${2%%\?*}" ]' _ "$OLD_URL" "$URL"
CASE="the old key is refused with 403"; check bash -c 'test "$(node -e "fetch(process.argv[1]).then(r=>console.log(r.status))" "$1")" = 403' _ "$OLD_URL"
CASE="the new key serves the page with 200"; check bash -c 'test "$(node -e "fetch(process.argv[1]).then(r=>console.log(r.status))" "$1")" = 200' _ "$URL"

# T5 stable tier isolation: fixed port, its own dir, untouched by dev.
URL2=$($B stable serve "${C[@]}")
CASE="stable serves on its fixed port"; check bash -c '[[ "$1" == http://localhost:45900/* ]]' _ "$URL2"
CASE="stable state dir has no dev answers"; check test ! -e /work/state/t-stable/answers.jsonl

# T6 migrate dev -> a fresh page dir, byte-identical answers; refuses into a running tier.
set +e; out=$($B stable migrate "${C[@]}" /work/state/t-dev-t1 2>&1); rc=$?; set -e
CASE="migrate into a running tier is refused (exit 3)"; check test "$rc" = 3
$B stable stop "${C[@]}" >/dev/null; sleep 2
$B stable migrate "${C[@]}" /work/state/t-dev-t1 2>/dev/null
CASE="migrate copies answers.jsonl byte for byte"; check cmp -s /work/state/t-dev-t1/answers.jsonl /work/state/t-stable/answers.jsonl

# T7 stop writes stopped.json and the wait reports STOPPED.
$B dev stop --ticket t1 "${C[@]}" >/dev/null; sleep 2
CASE="stop leaves stopped.json"; check test -f /work/state/t-dev-t1/stopped.json
CASE="wait reports STOPPED after stop"; check bash -c 'timeout 15 $0 dev wait --ticket t1 "$@" | grep -q "^STOPPED"' "$B" "${C[@]}"

# T8 placement in the tool grid (WO-20261010-2d04). A stub herdr on PATH keeps a pane table in /work/stub/panes.json and logs
# every call to calls.log; `pane run` really starts a server so wait_for_server has something to find, and does nothing for
# any other command. No real herdr runs here, so what is proved is which pane bearings.sh asks herdr to split, rename and close.
mkdir -p /work/stubbin /work/stub
cat > /work/stubbin/herdr <<'STUB'
#!/usr/bin/env bash
S=/work/stub; P=$S/panes.json; echo "$*" >> $S/calls.log
case "$1 $2" in
  "pane list") jq -c '{result:{panes:.}}' $P ;;
  "pane rename") jq --arg p "$3" --arg l "$4" 'map(if .pane_id == $p then .label = $l else . end)' $P > $P.t && mv $P.t $P ;;
  "pane split") n="n$(( $(jq length $P) + 1 ))"; t=$(jq -r --arg p "$3" '.[] | select(.pane_id == $p) | .tab_id' $P)
    jq --arg n "$n" --arg t "$t" '. + [{pane_id:$n, tab_id:$t, label:""}]' $P > $P.t && mv $P.t $P; jq -cn --arg n "$n" '{result:{pane:{pane_id:$n}}}' ;;
  "pane run") case "$4" in *server.mjs*) nohup bash -c "$4" >/dev/null 2>&1 & ;; esac ;;
  "pane process-info") exit 1 ;;
  *) exit 0 ;;
esac
STUB
chmod +x /work/stubbin/herdr
cat > /work/stub/panes.json <<'JSON'
[{"pane_id":"s1","tab_id":"tA","label":"claude-fable - high - WO-x architect"},
 {"pane_id":"g1","tab_id":"tA","label":"OPEN - any tool 1"},
 {"pane_id":"g2","tab_id":"tA","label":"OPEN - any tool 2"},
 {"pane_id":"g3","tab_id":"tA","label":"OPEN - any tool 3"},
 {"pane_id":"o1","tab_id":"tB","label":"OPEN - any tool 9"},
 {"pane_id":"s2","tab_id":"tC","label":"claude - worker"}]
JSON
label_of() { jq -r --arg p "$1" '.[] | select(.pane_id == $p) | .label' /work/stub/panes.json; }
calls() { grep -c "^pane $1" /work/stub/calls.log || true; }
H=(env "PATH=/work/stubbin:$PATH" HERDR_ENV=1 HERDR_PANE_ID=s1 HERDR_TAB_ID=tA COQ_SEAT=architect)
D=(--ticket t2 --config /work/config.json)

"${H[@]}" $B dev serve "${D[@]}" >/work/serve2.url 2>/work/serve2.err || cat /work/serve2.err >&2
CASE="serve from a seat takes the first OPEN slot of its tab (g1) and relabels it"; check test "$(label_of g1)" = "b-dev-t2"
CASE="serve from a seat never splits"; check test "$(calls split)" = 0
CASE="serve leaves the seat pane's label alone"; check test "$(label_of s1)" = "claude-fable - high - WO-x architect"
CASE="serve leaves another tab's OPEN pane alone"; check test "$(label_of o1)" = "OPEN - any tool 9"
"${H[@]}" $B dev wait "${D[@]}" >/dev/null 2>&1
CASE="wait takes the next OPEN slot (g2) and relabels it"; check test "$(label_of g2)" = "b-dev-t2-wait"
CASE="wait from a seat never splits"; check test "$(calls split)" = 0
CASE="server.json remembers the labels the slots had"; check bash -c 'test "$(jq -c .open_slots /work/state/t-dev-t2/server.json)" = "{\"server\":\"OPEN - any tool 1\",\"wait\":\"OPEN - any tool 2\"}"'
"${H[@]}" $B dev stop "${D[@]}" >/dev/null 2>&1; sleep 2
CASE="stop gives the server slot its old OPEN label back"; check test "$(label_of g1)" = "OPEN - any tool 1"
CASE="stop gives the wait slot its old OPEN label back"; check test "$(label_of g2)" = "OPEN - any tool 2"
CASE="stop closes no pane"; check test "$(calls close)" = 0
CASE="stop forgets open_slots"; check bash -c 'test "$(jq -r ".open_slots // \"none\"" /work/state/t-dev-t2/server.json)" = none'
"${H[@]}" $B dev serve "${D[@]}" >/dev/null 2>&1
CASE="serve after stop takes the same slot (g1) again, still no split"; check test "$(label_of g1)" = "b-dev-t2" -a "$(calls split)" = 0
"${H[@]}" $B dev stop "${D[@]}" >/dev/null 2>&1; sleep 2

# A seat in a tab with no OPEN slot is refused, naming the tab, and nothing is split.
set +e; out=$(env PATH=/work/stubbin:$PATH HERDR_ENV=1 HERDR_PANE_ID=s2 HERDR_TAB_ID=tC COQ_SEAT=worker $B dev serve "${D[@]}" 2>&1); rc=$?; set -e
CASE="a seat with no OPEN slot in its tab -> exit 3 naming the tab"; check test "$rc" = 3 -a "${out#*tab tC}" != "$out"
CASE="that refusal split nothing"; check test "$(calls split)" = 0
# No seat and no OPEN slot: the calling pane is split, as before.
env PATH=/work/stubbin:$PATH HERDR_ENV=1 HERDR_PANE_ID=s2 HERDR_TAB_ID=tC $B dev serve "${D[@]}" >/dev/null 2>&1 || true
CASE="outside a seat layout the calling pane is split once and the new pane takes the label"; check test "$(calls split)" = 1 -a "$(jq -r '[.[] | select(.label == "b-dev-t2")] | length' /work/stub/panes.json)" = 1
env PATH=/work/stubbin:$PATH HERDR_ENV=1 HERDR_PANE_ID=s2 HERDR_TAB_ID=tC $B dev stop "${D[@]}" >/dev/null 2>&1; sleep 2

# T9 the factory board routes (WO-20261011-616c): /board and /board/data.json serve report/loop's built page behind the page key.
# board_dir is absolute here because the tool is mounted alone at /skill, with no repository around it.
jq '.board_dir = "/work/board"' /work/config.json > /work/config-board.json
BC=(--ticket t3 --config /work/config-board.json --no-herdr)
BURL=$($B dev serve "${BC[@]}")
BASE=${BURL%%/\?key=*}; BKEY=${BURL##*key=}
get() { node -e '
const [url, cookie] = process.argv.slice(1);
fetch(url, { headers: cookie ? { cookie } : {} }).then(async (r) => {
  const body = await r.text();
  console.log(JSON.stringify({ status: r.status, type: r.headers.get("content-type"), cache: r.headers.get("cache-control"), cookie: r.headers.get("set-cookie"), body }));
});' "$@"; }
CASE="/board before the page is built is 503 saying so"; check bash -c 'r=$(cat); test "$(jq -r .status <<<"$r")" = 503 && jq -r .body <<<"$r" | jq -e ".error == \"board not built\"" >/dev/null' < <(get "$BASE/board?key=$BKEY")
CASE="/board/data.json before the page is built is 503 too"; check bash -c 'test "$(jq -r .status < <(cat))" = 503' < <(get "$BASE/board/data.json?key=$BKEY")
CASE="a 503 does not leak the server's own directory"; check bash -c '! grep -q /work/board < <(cat)' < <(get "$BASE/board?key=$BKEY")
mkdir -p /work/board
printf '<!doctype html><title>board</title><p id="x">first &lt;draw&gt;</p>\n' > /work/board/index.html
printf '{"number":1,"headline":"first"}\n' > /work/board/data.json
get "$BASE/board?key=$BKEY" > /work/board-page.json
CASE="/board serves the built page as html"; check bash -c 'test "$(jq -r .status /work/board-page.json)" = 200 && jq -r .type /work/board-page.json | grep -q "^text/html" && test "$(jq -r .body /work/board-page.json)" = "$(cat /work/board/index.html)"'
CASE="/board is never cached"; check test "$(jq -r .cache /work/board-page.json)" = no-store
CASE="/board sets the page cookie so the page's own poll is allowed"; check bash -c 'jq -r .cookie /work/board-page.json | grep -q "^bearings_key=$0; HttpOnly; SameSite=Strict; Path=/"' "$BKEY"
get "$BASE/board/data.json" "bearings_key=$BKEY" > /work/board-data.json
CASE="/board/data.json with only the cookie serves the data as json"; check bash -c 'test "$(jq -r .status /work/board-data.json)" = 200 && jq -r .type /work/board-data.json | grep -q "^application/json" && test "$(jq -c ".body | fromjson" /work/board-data.json)" = "{\"number\":1,\"headline\":\"first\"}"'
CASE="/board/ with a trailing slash is the page too"; check test "$(get "$BASE/board/?key=$BKEY" | jq -r .status)" = 200
printf '{"number":2,"headline":"second"}\n' > /work/board/data.json
CASE="a rewritten data.json is served at once"; check test "$(get "$BASE/board/data.json?key=$BKEY" | jq -r '.body | fromjson | .number')" = 2
CASE="/board without the key is refused with 403"; check test "$(get "$BASE/board" | jq -r .status)" = 403
CASE="/board/data.json with a wrong key is refused with 403"; check test "$(get "$BASE/board/data.json?key=0000" | jq -r .status)" = 403
CASE="/board is read only (POST is not a route)"; check test "$(node -e 'fetch(process.argv[1],{method:"POST",body:"{}"}).then(r=>console.log(r.status))' "$BASE/board?key=$BKEY")" != 200
$B dev stop "${BC[@]}" >/dev/null; sleep 2
# Without board_dir in the config the routes answer 404 and say why.
$B dev serve --ticket t4 "${C[@]}" >/work/t4.url
T4=$(cat /work/t4.url)
CASE="no board_dir in the config -> /board is 404 naming the key"; check bash -c 'r=$(cat); test "$(jq -r .status <<<"$r")" = 404 && jq -r .body <<<"$r" | grep -q board_dir' < <(get "${T4%%/\?key=*}/board?key=${T4##*key=}")
$B dev stop --ticket t4 "${C[@]}" >/dev/null; sleep 2
jq '.board_dir = ""' /work/config.json > /work/config-empty.json
set +e; out=$(node /skill/scripts/server.mjs --tier dev --ticket t5 --config /work/config-empty.json 2>&1); rc=$?; set -e
CASE="an empty board_dir fails at start (exit 3) naming the key"; check test "$rc" = 3 -a "${out#*board_dir}" != "$out"

. /skill/tests/sitrep.sh
. /skill/tests/owner.sh

echo "bearings tests: $PASS passed, $FAIL failed"
[ "$FAIL" = 0 ] || exit 3
