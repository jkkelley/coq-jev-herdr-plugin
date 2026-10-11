#!/usr/bin/env bash
# bearings-stub.sh - stands in for tools/bearings/scripts/bearings.sh in interface/tests/run.sh: `<tier> status --json` names
# $STUB_DIR, `<tier> reply --to ID text` appends a claude message to $STUB_DIR/messages.jsonl the way reply.mjs does, `<tier> ask FILE` replaces
# $STUB_DIR/questions.json the way bearings.sh does.
set -euo pipefail
tier=$1; verb=$2; shift 2
case $verb in
  status) jq -nc --arg d "$STUB_DIR" '{dir:$d}' ;;
  reply) to=""; text=""
    while [ $# -gt 0 ]; do case $1 in --to) to=$2; shift 2;; --*) shift 2;; *) text=$1; shift;; esac; done
    jq -nc --arg to "$to" --arg text "$text" '{id:"m-c0",from:"claude",reply_to:$to,text:$text,at:"2026-10-11T00:00:00Z"}' >> "$STUB_DIR/messages.jsonl"
    echo "replied to $to on $tier" ;;
  ask) cp "$1" "$STUB_DIR/questions.json"; echo "asked on $tier" ;;
  *) exit 2 ;;
esac
