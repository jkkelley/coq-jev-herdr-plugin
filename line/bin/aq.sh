#!/usr/bin/env bash
# aq.sh - the architect queue: everything that needs the architect, in one list with a priority, fed by code and cleared top down.
# Why: owner order 2026-10-13 (architect addendum 03:15Z): "surface right into a queue with a priority system attached, fed directly
# into an architect queue". Before this, the architect heard of a problem by a prompt (a patrol escalation, a note --to architect),
# each prompt landing mid-thought with no order between them, so a p3 note could arrive ahead of a stalled critical path.
# Contract: the style of queue/bin/queue.sh (a directory of files, add is a write, done is an atomic mv, priority p0..p3, age breaks
# ties), keyed by item id, not by ticket. Dir $COQ_STATE/queues/architect/{open,done}. File name: pN-<UTC stamp>-<id>.json, so
# a plain sort is the order: p0 first, older first within a priority.
# Priority rule (the feeders apply it; aq.sh only stores it):
#   p0  the critical path cannot move: a P0 item of $COQ_STATE/plans/2026/10/20261013025600-priority-list.md is blocked, or the line
#       cannot see or land work.
#   p1  the BOTTLENECK stage named by flow-table.sh.
#   p2  one seat stuck past its deadline (a patrol finding seen 3 times), or any record addressed --to architect.
#   p3  information (a note 100 addressed to the architect).
# Dedupe: the same --source and --ref already open does not add a row; it bumps the priority to the higher of the two, raises count,
# and refreshes text and seen. A bump renames the file, keeping the stamp, so age is the age of the first sighting.
# Rejected: one prompt per finding (the flood of 20:32Z); a model that ranks the list (the patrol lesson: an LLM opinion is not a probe).
# Cost: a feeder that picks the wrong priority misorders the list; the rule above is the only judgement and it is code in the feeders.
# Replaced by: the architect digest and K2 health watch (SPEC-17); roadmap I moves scripts into line/.
#   aq.sh add --priority pN --source S --ref RECORD-or-PR --text '<=200 chars'   prints the item id
#   aq.sh list [--top N] [--json]                                               open items, in order
#   aq.sh done --id ID --note TEXT
#   aq.sh check                                                                 validates every file in open/ and done/
# Exit: 0 ok, 2 usage, 3 validation, 4 io, 6 no such open item.
# BREADCRUMB 2026-10-13 - WO-20261013-51e8 (Roadmap I, ruling ykne9). What broke: this script lived in the owner cache directory coq-watch, outside
#   git, so no review and no test had ever seen it, and its state default was the literal $HOME/.local/state/coq/coq-jev-herdr-plugin
#   (owner 2026-10-12 22:49Z: every script lives in the project, only its artifacts outside). Why this fix: the file moves here with
#   its behaviour unchanged, the state root comes from bin/state-root.sh (COQ_STATE, else the default in config/state.json) found
#   from this file's own location, and line/tests/cases/aq.sh covers add, list and done. Rejected: a symlink from the cache (the
#   copy outside git would stay the thing a caller named) and moving the queue under a tree name of state-root.sh (queues is not one
#   of its trees; adding one is a change to that resolver, which this ticket does not own). Cost: the queue is <state>/queues/
#   architect, a path built here and not read from the config; AQ_DIR still overrides it (the test hook, and a second queue).
#   The cache copy and its .bak files are archived under the state root and deleted after the merge, by the orchestrator lane.
set -euo pipefail
die() { local c=$1; shift; printf 'aq: %s\n' "$*" >&2; exit "$c"; }
command -v jq >/dev/null || die 4 "jq required"
HERE=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd); REPO=$(cd "$HERE/../.." && pwd)
# shellcheck source=../../bin/state-root.sh
. "$REPO/bin/state-root.sh" 2>/dev/null || die 4 "bin/state-root.sh missing beside this line/ tree (roadmap item A1)"
STATE=$(coq_state_root) || die 4 "state root unresolved (bin/state-root.sh said $?)"
Q=${AQ_DIR:-$STATE/queues/architect}; OPEN=$Q/open; DONE=$Q/done
mkdir -p "$OPEN" "$DONE" || die 4 "cannot create $Q"
now() { date -u +%Y-%m-%dT%H:%M:%SZ; }; stamp() { date -u +%Y%m%dT%H%M%SZ; }
sorted() { find "$OPEN" -maxdepth 1 -name 'p[0-3]-*.json' | sort; }
item_of() { find "$OPEN" -maxdepth 1 -name "p[0-3]-*-$1.json" | head -1; }
VERB=${1:-}; shift || true
case $VERB in
  add)
    p=""; src=""; ref=""; text=""
    while [ $# -gt 0 ]; do case $1 in --priority) p=$2; shift 2;; --source) src=$2; shift 2;; --ref) ref=$2; shift 2;; --text) text=$2; shift 2;; *) die 2 "unknown flag $1";; esac; done
    [[ $p =~ ^p[0-3]$ ]] || die 3 "bad priority '$p' (p0..p3)"; [ -n "$src" ] && [ -n "$ref" ] || die 2 "--source and --ref required"
    [ -n "$text" ] || die 2 "--text required"; [ ${#text} -le 200 ] || die 3 "--text is ${#text} chars, 200 at most"
    while IFS= read -r f; do   # dedupe on source + ref
      [ -n "$f" ] || continue
      [ "$(jq -r '.source + "\u0001" + .ref' "$f")" = "$src"$'\001'"$ref" ] || continue
      old=$(jq -r .priority "$f"); new=$old; [[ "$p" < "$old" ]] && new=$p
      b=${f##*/}; nf="$OPEN/$new-${b#*-}"
      jq --arg p "$new" --arg t "$text" --arg at "$(now)" '.priority=$p | .count+=1 | .text=$t | .seen=$at' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
      [ "$nf" = "$f" ] || mv "$f" "$nf"
      jq -r .id "$nf"; exit 0
    done < <(sorted)
    id=$(head -c 6 /dev/urandom | od -An -tx1 | tr -d ' \n' | cut -c1-5); f="$OPEN/$p-$(stamp)-$id.json"
    jq -n --arg id "$id" --arg p "$p" --arg s "$src" --arg r "$ref" --arg t "$text" --arg at "$(now)" \
      '{schema_version:"1.0.0", id:$id, priority:$p, source:$s, ref:$r, text:$t, count:1, added:$at, seen:$at}' > "$f.tmp" && mv "$f.tmp" "$f"
    printf '%s\n' "$id" ;;
  list)
    top=0; json=0
    while [ $# -gt 0 ]; do case $1 in --top) top=$2; shift 2;; --json) json=1; shift;; *) die 2 "unknown flag $1";; esac; done
    [[ $top =~ ^[0-9]+$ ]] || die 2 "--top needs a number"
    files=$(sorted); [ "$top" -gt 0 ] && files=$(head -n "$top" <<<"$files")
    [ -n "$files" ] || { [ "$json" = 1 ] && echo '[]'; exit 0; }
    if [ "$json" = 1 ]; then xargs -r jq -s . <<<"$files"
    else while IFS= read -r f; do jq -r '"\(.priority)\t\(.id)\tx\(.count)\t\(.added)\t\(.source)\t\(.ref)\t\(.text)"' "$f"; done <<<"$files"; fi ;;
  done)
    id=""; note=""
    while [ $# -gt 0 ]; do case $1 in --id) id=$2; shift 2;; --note) note=$2; shift 2;; *) die 2 "unknown flag $1";; esac; done
    [ -n "$id" ] && [ -n "$note" ] || die 2 "--id and --note required"
    f=$(item_of "$id"); [ -n "$f" ] || die 6 "no open item $id"
    jq --arg n "$note" --arg at "$(now)" '.done=$at | .done_note=$n' "$f" > "$f.tmp" && mv "$f.tmp" "$f" && mv "$f" "$DONE/${f##*/}"
    printf 'done %s\n' "$id" ;;
  check)
    bad=0
    for f in "$OPEN"/*.json "$DONE"/*.json; do [ -e "$f" ] || continue
      jq -e '(.id|type=="string") and (.priority|test("^p[0-3]$")) and (.source|length>0) and (.ref|length>0) and (.text|length<=200) and (.count>=1)' "$f" >/dev/null 2>&1 \
        && [[ ${f##*/} == "$(jq -r .priority "$f")"-*-"$(jq -r .id "$f")".json ]] || { echo "bad: $f"; bad=1; }
    done; [ "$bad" = 0 ] && echo "ok" || exit 3 ;;
  *) die 2 "usage: aq.sh add|list|done|check" ;;
esac
