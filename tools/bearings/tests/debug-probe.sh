#!/usr/bin/env bash
# Debug helper: start a dev page in the test container and print the probe's
# JSON (errors included). Not part of the suite. Usage: tests/debug-probe.sh
set -euo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd); TOOL=$(cd "$HERE/.." && pwd)
SCRATCH=$(mktemp -d); trap 'rm -rf "$SCRATCH"' EXIT
podman run --rm --network=none --userns=keep-id -e HOME=/work -v "$TOOL:/skill:ro,Z" -v "$SCRATCH:/work:Z" -w /work localhost/coq-bearings-test:1 bash -c '
set -e
sed "s#/work/state#/work/state#" /skill/tests/inside.sh >/dev/null
cat > /work/config.json <<JSON
{"schema_version":"1.0.0","project":"t","state_root":"/work/state","listen_host":"127.0.0.1","allowed_hosts":["127.0.0.1","localhost"],"cookie_name":"bearings_key","idle_minutes":5,"settle_ms":300,"stop_tries":3,"stop_try_ms":1000,"max_body_bytes":65536,"max_message_chars":8000,"max_words_chars":4000,"messages_window":50,"pane_split":{"direction":"down","ratio":0.2},"tiers":{"dev":{"page":"\${project}-dev-\${ticket}","port_range":[45920,45922],"pane_label":"x","wait_pane_label":"y","checkout":"slot"}}}
JSON
echo "{\"title\":\"probe\",\"items\":[{\"id\":\"P1\",\"about\":\"probe\",\"decide\":\"Pick one?\",\"options\":[{\"label\":\"A\",\"then\":\"a\"},{\"label\":\"B\",\"then\":\"b\"}],\"rec\":0}]}" > /work/q.json
B=/skill/scripts/bearings.sh; $B dev ask --ticket t1 --config /work/config.json --no-herdr /work/q.json
URL=$($B dev serve --ticket t1 --config /work/config.json --no-herdr)
node /skill/tests/probe.mjs "$URL" /work/shot.png | jq .
echo "--- answers:"; cat /work/state/t-dev-t1/answers.jsonl 2>/dev/null || echo none
echo "--- server.log:"; tail -5 /work/state/t-dev-t1/server.log
'
