#!/usr/bin/env bash
# 15 - the blueprint server: routes, the live and released modes, one refresh pass (report/blueprint/tests/test_server.py), and the
# tier configs against their schema. The server runs in a thread of the test's own python process, so nothing outlives the case.
. "$(dirname "$0")/../lib/assert.sh"
BP="$REPO_ROOT/report/blueprint"
for tier in dev uat stable; do
  t "the $tier config is valid" python3 -c "import json,jsonschema,sys; jsonschema.validate(json.load(open(sys.argv[1])), json.load(open(sys.argv[2])))" "$BP/config/$tier.json" "$BP/config/tier.schema.json"
done
eq "three tiers, three ports" "3" "$(jq -s '[.[].port] | unique | length' "$BP"/config/{dev,uat,stable}.json)"
eq "three tiers, three out_dirs" "3" "$(jq -s '[.[].out_dir] | unique | length' "$BP"/config/{dev,uat,stable}.json)"
eq "three tiers, three pane labels" "3" "$(jq -s '[.[].pane_label] | unique | length' "$BP"/config/{dev,uat,stable}.json)"
eq "dev out_dir is the view's out_dir" "$(jq -r .out_dir "$REPO_ROOT/report/loop/config/blueprint.json")" "$(jq -r .out_dir "$BP/config/dev.json")"
eq "the chain is dev, then uat, then stable" "null dev uat" "$(jq -rs 'map(.promotes_from) | join(" ")' "$BP"/config/{dev,uat,stable}.json | sed 's/^ /null /')"
for tier in dev uat stable; do
  eq "monitors.json runs the $tier server in a slot named by the tier's pane label" "$(jq -r .pane_label "$BP/config/$tier.json")" "$(jq -r --arg t "$tier" '.tabs[].reserved[] | select(.command == "${repo}/report/blueprint/serve.sh \($t)") | .name' "$REPO_ROOT/herdr/config/monitors.json")"
  eq "and its check is that tier's serve.sh --check" "\${repo}/report/blueprint/serve.sh --check $tier" "$(jq -r --arg t "$tier" '.tabs[].reserved[] | select(.name == "blueprint-\($t)") | .check' "$REPO_ROOT/herdr/config/monitors.json")"
done
t "the server's unit tests pass" env REPO_ROOT="$REPO_ROOT" python3 -I "$BP/tests/test_server.py"
expect_exit 2 "serve.sh with no tier is usage" "$BP/serve.sh"
expect_exit 2 "serve.sh with a bad tier is usage" "$BP/serve.sh" prod
expect_exit 1 "serve.sh --check on a tier nobody serves exits 1" "$BP/serve.sh" --check dev
done_case
