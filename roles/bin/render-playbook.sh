#!/usr/bin/env bash
# render-playbook.sh - playbooks/<role>.md from roles/<role>.json. Pure render:
# same input, same output; a diff in CI means someone edited a playbook by hand.
#   render-playbook.sh <roles-dir> <out-dir> [--check]
# Exit 0 ok, 2 usage, 3 schema or drift, 4 io.
set -euo pipefail
R=${1:-}; O=${2:-}; CHECK=${3:-}; [ -d "$R" ] && [ -n "$O" ] || { echo "usage: render-playbook.sh <roles-dir> <out-dir> [--check]" >&2; exit 2; }
command -v jq >/dev/null || { echo "jq required" >&2; exit 4; }
render() { jq -r '
  def li: map("- " + .) | join("\n");
  def num: to_entries | map("\(.key+1). \(.value)") | join("\n");
  "# Playbook: \(.name)\n\n## Contents\n\n- Who you are\n- Runtime and model\n- Permissions\n- Steps\n- Records you emit\n- What wakes you\n- Forbidden\n\n## Who you are\n\n\(.title). \(.purpose)\nEvery line below is a command or a record. Nothing else is yours to decide. Read-only: \(.read_only). Owner channel: \(.owner_channel).\n\n## Runtime and model\n\nRuntime \(.runtime.default) (allowed: \(.runtime.allowed | join(", "))). Model \(.model.claude)\(if .model.codex then " / codex " + .model.codex else "" end)\(if .model["system-one"] then " / system-one " + .model["system-one"] else "" end), effort \(.effort)\(if .model.architect_may_override then "; the architect may override the model per ticket" else "" end). Compaction at \(.context_threshold_percent) percent and task complete. Seat label `\(.label)`, layout `\(.pane_layout)`, at most \(.max_seats) seats.\n\n## Permissions\n\nMode `\(.permission_mode)`.\nAllowed tools: \(.allow.tools | join(", ")). Allowed paths: \(.allow.paths | join(", ")). Allowed commands: \(.allow.commands | join(", ")).\nDenied tools: \(.deny.tools | join(", ")). Denied paths: \(.deny.paths | join(", ")). Denied commands: \(.deny.commands | join(", ")).\nInputs: \(.inputs | join(", ")). Outputs: \(.outputs | join(", ")).\n\n## Steps\n\n\(.must | num)\n\n## Records you emit\n\n\(.records | to_entries | map("- `\(.key)` -> \(.value)") | join("\n"))\n\n## What wakes you\n\n\(.wakes_on | li)\n\n## Forbidden\n\n\(.forbidden | li)\n"' "$1"; }
bad=0
for f in "$R"/*.json; do
  n=$(jq -r .name "$f"); out="$O/$n.md"
  if [ "$CHECK" = --check ]; then [ -f "$out" ] && diff -q <(render "$f") "$out" >/dev/null || { echo "playbook drift: $out" >&2; bad=1; }
  else mkdir -p "$O"; render "$f" > "$out.tmp" && mv "$out.tmp" "$out"; echo "$out"; fi
done
[ "$bad" = 0 ] || exit 3
