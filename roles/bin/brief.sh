#!/usr/bin/env bash
# brief.sh - the one-line brief a seat receives (SPEC-03: a brief names the ticket,
# its title and the playbook; nothing else). Pure: role + ticket file in, one line out.
#   brief.sh --role <role> --ticket <WO-ID> [--project DIR]
set -euo pipefail
ROLE=""; ID=""; PROJ=.
while [ $# -gt 0 ]; do case $1 in --role) ROLE=$2; shift 2;; --ticket) ID=$2; shift 2;; --project) PROJ=$2; shift 2;; *) echo "usage: brief.sh --role R --ticket WO-ID [--project DIR]" >&2; exit 2;; esac; done
[ -n "$ROLE" ] && [ -n "$ID" ] || { echo "usage: brief.sh --role R --ticket WO-ID [--project DIR]" >&2; exit 2; }
[ -f "$PROJ/roles/$ROLE.json" ] || { echo "no role $ROLE" >&2; exit 6; }
F=$(find "$PROJ/work-orders" -name "$ID-*.md" -not -path '*/archive/*' | head -1); [ -n "$F" ] || { echo "no ticket $ID" >&2; exit 6; }
TITLE=$(awk '/^---$/{c++; next} c==1' "$F" | jq -r .title 2>/dev/null || sed -n 's/^# [^ ]* - //p' "$F" | head -1)
printf '%s - %s. Playbook playbooks/%s.md. Post your first record before anything else.\n' "$ID" "$TITLE" "$ROLE"
