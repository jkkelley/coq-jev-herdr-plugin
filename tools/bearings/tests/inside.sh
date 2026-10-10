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
{"schema_version":"1.0.0","project":"t","state_root":"/work/state","listen_host":"127.0.0.1","allowed_hosts":["127.0.0.1","localhost"],"cookie_name":"bearings_key","idle_minutes":5,"settle_ms":300,"stop_tries":3,"stop_try_ms":1000,"max_body_bytes":65536,"max_message_chars":8000,"max_words_chars":4000,"messages_window":50,"pane_split":{"direction":"down","ratio":0.2},
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

echo "bearings tests: $PASS passed, $FAIL failed"
[ "$FAIL" = 0 ] || exit 3
