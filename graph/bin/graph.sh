#!/usr/bin/env bash
# graph.sh - the knowledge graph. One JSON file per node under graph/nodes/, so N
# agents add nodes at once with no lock and no merge conflict. Specs point at
# nodes by id; the Architect queries here before cutting a ticket.
#
#   graph.sh add  --id DEC-xxx --type Decision --title T [--status locked] [--text T] [--source kind:id[:utc]]... [--edge kind:NODE]...
#   graph.sh edge --from NODE --kind depends_on --to NODE
#   graph.sh get  <id> [--json]
#   graph.sh find --type T | --text substring | --edge-to NODE
#   graph.sh check                         every edge resolves, ids valid, no dupes; exit 3 names each offender
#   graph.sh index                         writes graph/INDEX.md (table) and graph/GRAPH.mmd (mermaid)
#   graph.sh sync-specs <specs-dir>        every <node> in the XML specs exists here with the same title; exit 3 on drift
#
# Node types and prefixes: Decision DEC, Requirement REQ, Component CMP, Interface IFC,
# Schema SCH, Workflow WFL, Node NOD (a DAG node), Role ROL, Spike SPK, Risk RSK,
# StatusCode STC, Runbook RUN.
# Exit codes: 0 ok, 2 usage, 3 validation, 4 io, 6 not found.
set -euo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd); ROOT=$(cd "$HERE/.." && pwd); NODES=$ROOT/nodes
die() { local c=$1; shift; printf 'graph: %s\n' "$*" >&2; exit "$c"; }
need() { command -v "$1" >/dev/null || die 4 "$1 is required"; }; need jq
ID_RE='^(DEC|REQ|CMP|IFC|SCH|WFL|NOD|ROL|SPK|RSK|STC|RUN)-[a-z0-9][a-z0-9-]{1,47}$'
EDGE_RE='^(depends_on|implements|decided_by|verified_by|risks|owned_by|defined_in|supersedes)$'
TYPES='{"DEC":"Decision","REQ":"Requirement","CMP":"Component","IFC":"Interface","SCH":"Schema","WFL":"Workflow","NOD":"Node","ROL":"Role","SPK":"Spike","RSK":"Risk","STC":"StatusCode","RUN":"Runbook"}'
now() { date -u +%Y-%m-%dT%H:%MZ; }
vid() { [[ $1 =~ $ID_RE ]] || die 3 "bad node id $1 (prefix-slug, e.g. DEC-game-host-wsl)"; }
f() { printf '%s/%s.json\n' "$NODES" "$1"; }
VERB=${1:-}; shift || true
case $VERB in
  add)
    id=""; type=""; title=""; status=draft; text=""; sources=(); edges=()
    while [ $# -gt 0 ]; do case $1 in
      --id) id=$2; shift 2;; --type) type=$2; shift 2;; --title) title=$2; shift 2;; --status) status=$2; shift 2;; --text) text=$2; shift 2;;
      --source) sources+=("$2"); shift 2;; --edge) edges+=("$2"); shift 2;; *) die 2 "unknown flag $1";; esac; done
    [ -n "$id" ] && [ -n "$title" ] || die 2 "add needs --id and --title"; vid "$id"
    pre=${id%%-*}; want=$(jq -r --arg p "$pre" '.[$p]' <<<"$TYPES"); [ -z "$type" ] && type=$want
    [ "$type" = "$want" ] || die 3 "id prefix $pre means type $want, not $type"
    [[ $status =~ ^(draft|proposed|locked|superseded)$ ]] || die 3 "bad status $status"
    [ -e "$(f "$id")" ] && die 3 "$id exists; edit through edge or a new superseding node"
    mkdir -p "$NODES"
    # grep exits 1 on an empty list, which pipefail would turn into a failed add; the `|| true` keeps the empty array.
    src=$(printf '%s\n' "${sources[@]:-}" | { grep -v '^$' || true; } | jq -R 'split(":") | {kind:.[0], id:.[1], at:(.[2] // null)}' | jq -s .)
    edg=$(printf '%s\n' "${edges[@]:-}" | { grep -v '^$' || true; } | jq -R 'split(":") | {kind:.[0], to:.[1]}' | jq -s .)
    for e in "${edges[@]:-}"; do [ -z "$e" ] && continue; [[ ${e%%:*} =~ $EDGE_RE ]] || die 3 "bad edge kind ${e%%:*}"; vid "${e#*:}"; done
    jq -n --arg id "$id" --arg type "$type" --arg title "$title" --arg status "$status" --arg text "$text" --arg at "$(now)" --argjson sources "$src" --argjson edges "$edg" \
      '{id:$id, type:$type, title:$title, status:$status, text:$text, sources:$sources, edges:$edges, created:$at, updated:$at}' > "$(f "$id").tmp" && mv "$(f "$id").tmp" "$(f "$id")"
    printf '%s\n' "$id" ;;
  edge)
    from=""; kind=""; to=""
    while [ $# -gt 0 ]; do case $1 in --from) from=$2; shift 2;; --kind) kind=$2; shift 2;; --to) to=$2; shift 2;; *) die 2 "unknown flag $1";; esac; done
    vid "$from"; vid "$to"; [[ $kind =~ $EDGE_RE ]] || die 3 "bad edge kind $kind"
    [ -e "$(f "$from")" ] || die 6 "no node $from"; [ -e "$(f "$to")" ] || die 6 "no node $to"
    jq --arg k "$kind" --arg t "$to" --arg at "$(now)" '.edges |= (. + [{kind:$k,to:$t}] | unique) | .updated=$at' "$(f "$from")" > "$(f "$from").tmp" && mv "$(f "$from").tmp" "$(f "$from")" ;;
  get) [ -e "$(f "${1:-}")" ] || die 6 "no node ${1:-}"; if [ "${2:-}" = --json ]; then cat "$(f "$1")"; else jq -r '"\(.id)\t\(.type)\t\(.status)\t\(.title)"' "$(f "$1")"; fi ;;
  find)
    type=""; text=""; eto=""
    while [ $# -gt 0 ]; do case $1 in --type) type=$2; shift 2;; --text) text=$2; shift 2;; --edge-to) eto=$2; shift 2;; *) die 2 "unknown flag $1";; esac; done
    jq -r --arg type "$type" --arg text "$text" --arg eto "$eto" 'select(($type=="" or .type==$type) and ($text=="" or ((.title+" "+.text) | ascii_downcase | contains($text|ascii_downcase))) and ($eto=="" or any(.edges[]; .to==$eto))) | "\(.id)\t\(.type)\t\(.status)\t\(.title)"' "$NODES"/*.json 2>/dev/null || true ;;
  check)
    bad=0; ids=$(jq -r .id "$NODES"/*.json 2>/dev/null | sort)
    for fpath in "$NODES"/*.json; do [ -e "$fpath" ] || break
      id=$(jq -r .id "$fpath"); [ "$(basename "$fpath" .json)" = "$id" ] || { echo "filename/id mismatch: $fpath" >&2; bad=1; }
      [[ $id =~ $ID_RE ]] || { echo "bad id: $id" >&2; bad=1; }
      for to in $(jq -r '.edges[].to' "$fpath"); do grep -qx "$to" <<<"$ids" || { echo "$id -> $to: no such node" >&2; bad=1; }; done
    done
    [ "$(printf '%s\n' "$ids" | uniq -d | wc -l)" = 0 ] || { echo "duplicate ids" >&2; bad=1; }
    [ "$bad" = 0 ] && echo "graph ok: $(printf '%s\n' "$ids" | grep -c . ) nodes" || exit 3 ;;
  index)
    { echo "# Knowledge graph"; echo; echo "Generated by graph/bin/graph.sh index at $(now). Do not edit."; echo
      echo "| id | type | status | title | edges |"; echo "| --- | --- | --- | --- | --- |"
      jq -r '"| \(.id) | \(.type) | \(.status) | \(.title) | \([.edges[] | "\(.kind) \(.to)"] | join("<br>")) |"' "$NODES"/*.json 2>/dev/null | sort
    } > "$ROOT/INDEX.md"
    { echo "flowchart LR"
      jq -r '"  \(.id)[\"\(.id)<br/>\(.title | gsub("[\"\\[\\]]"; "") | .[0:40])\"]"' "$NODES"/*.json 2>/dev/null
      jq -r '.id as $i | .edges[] | "  \($i) -- \(.kind) --> \(.to)"' "$NODES"/*.json 2>/dev/null
    } > "$ROOT/GRAPH.mmd"
    echo "wrote $ROOT/INDEX.md and $ROOT/GRAPH.mmd" ;;
  sync-specs)
    dir=${1:-}; [ -d "$dir" ] || die 2 "sync-specs needs the specs dir"; need python3; bad=0
    while IFS=$'\t' read -r id title; do
      [ -e "$(f "$id")" ] || { echo "spec node $id missing from graph" >&2; bad=1; continue; }
      [ "$(jq -r .title "$(f "$id")")" = "$title" ] || { echo "title drift for $id" >&2; bad=1; }
    done < <(python3 - "$dir" <<'PY'
import sys,glob,xml.etree.ElementTree as ET
for p in sorted(glob.glob(sys.argv[1]+"/SPEC-*.xml")):
    for n in ET.parse(p).getroot().iter("node"): print(n.get("id")+"\t"+n.findtext("title").strip())
PY
)
    [ "$bad" = 0 ] && echo "specs and graph agree" || exit 3 ;;
  *) sed -n '2,22p' "$0" >&2; exit 2 ;;
esac
