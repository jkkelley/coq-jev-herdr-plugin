#!/usr/bin/env bash
# sitrep.sh - the one way a SITREP page is built for the owner (WO-20261011-3d78).
#   sitrep.sh render <entry.json> [--out FILE]     validate the entry against schema/sitrep.schema.json, fill assets/template.html
#   sitrep.sh new <NNN>                            print an empty entry skeleton for SITREP NNN on stdout (fill it, save it under entries/)
# Entries live under entries/YYYY/MM/YYYYMMDD-sitrep-NNN.json (dated entry files, UTC). The rendered file is handed to the
# Artifact tool or to bearings by the seat that reports; this script never publishes.
# Exit: 0 ok, 2 usage, 3 refused (schema, or a ticket id with no legend title), 4 render failure.
#
# BREADCRUMB 2026-10-11 - WO-20261011-3d78. What broke: SITREP 003 was a hand-written HTML artifact, iterated twice in chat
#   until the owner said "lock this aspect in"; the next SITREP written by hand would drift from that shape, and
#   DEC-templates-over-handwriting says records are generated from templates. Why this fix: the shape lives once in
#   assets/template.html, the content once in a JSON entry the schema constrains (cell lengths included, so density cannot
#   creep back), and this script joins them; python3 does the validation and the render because report/rail already made
#   python3 the only dependency of a page builder here and jq is absent on Windows (see report/rail/bin/rail-build.sh).
#   Rejected: extending report/rail (the rail is a ledger of steps, the SITREP is a board of state; one template cannot be
#   both) and a node renderer (tools/bearings is node, but the report tree is bash plus python3 and stays one toolchain).
#   Cost: a new entry file per SITREP; that is the record the owner asked for.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
usage() { sed -n '2,4p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2; }
die() { local code=$1; shift; printf 'sitrep: %s\n' "$*" >&2; exit "$code"; }
command -v python3 >/dev/null 2>&1 || die 4 "python3 is required"
cmd=${1:-}; shift || true
case "$cmd" in
  new)
    n=${1:-}; [[ "$n" =~ ^[0-9]{3}$ ]] || usage
    python3 - "$n" <<'PY'
import json, sys, datetime
n = int(sys.argv[1])
now = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%MZ")
print(json.dumps({
  "schema_version": "1.0.0", "number": n, "at": now, "actor": "<role pane>", "state": "RUNNING",
  "headline": "<one line, 80 chars>",
  "strip": [{"kind": "go", "text": "<n closed>"}],
  "phase": {"now": "P0", "phases": [{"id": "P0", "label": "here"}, {"id": "P1", "label": "sitrep site"}],
            "gate": {"columns": ["P0 gate", "Need", "Have"], "rows": [["<item>", "<need>", "<have>"]]}},
  "tickets": [{"id": "0000", "what": "<verb phrase, 48 chars>", "state": "<state>", "kind": "go", "pr": None}],
  "blocks": [{"title": "Held", "kind": "hold", "rows": [["<key>", "<value>"]]}],
  "question": {"title": "Q1 · <topic>", "options": [{"key": "A", "text": "<option>", "rec": True}, {"key": "B", "text": "<option>"}], "queued": ""},
  "legend": {"0000": "WO-YYYYMMDD-0000 - <full title>"},
  "sources": "<where the facts came from> · built " + now
}, indent=2, ensure_ascii=False))
PY
    ;;
  render)
    entry=${1:-}; shift || true; out=""
    while [ $# -gt 0 ]; do case $1 in --out) out=${2:-}; shift 2 ;; *) usage ;; esac; done
    [ -n "$entry" ] && [ -f "$entry" ] || usage
    python3 - "$HERE" "$entry" "$out" <<'PY'
import json, sys, re, html, os
here, entry_path, out = sys.argv[1], sys.argv[2], sys.argv[3]
schema = json.load(open(os.path.join(here, "schema", "sitrep.schema.json")))
try:
    entry = json.load(open(entry_path))
except Exception as e:
    print(f"sitrep: {entry_path} is not JSON: {e}", file=sys.stderr); sys.exit(3)
try:
    import jsonschema
    jsonschema.validate(entry, schema)
except ImportError:
    print("sitrep: python3 jsonschema is required", file=sys.stderr); sys.exit(4)
except jsonschema.ValidationError as e:
    loc = "/".join(str(p) for p in e.absolute_path) or "<root>"
    print(f"sitrep: {entry_path} fails the schema at {loc}: {e.message}", file=sys.stderr); sys.exit(3)
missing = [t["id"] for t in entry["tickets"] if t["id"] not in entry["legend"]]
if missing:
    print(f"sitrep: ticket id {' '.join(missing)} has no legend title; every id on the board needs its WO id and full title in legend", file=sys.stderr); sys.exit(3)

# cell text: [[kind:text]] renders a pill, `code` renders code, everything else is escaped. One pass, no re-scan.
TOK = re.compile(r"\[\[(go|hold|ask|risk|plain):([^\]]{1,24})\]\]|`([^`]{1,60})`")
def cell(s):
    o, i = [], 0
    for m in TOK.finditer(s):
        o.append(html.escape(s[i:m.start()]))
        if m.group(1):
            k = "" if m.group(1) == "plain" else " " + m.group(1)
            o.append(f'<span class="pill{k}">{html.escape(m.group(2))}</span>')
        else:
            o.append(f"<code>{html.escape(m.group(3))}</code>")
        i = m.end()
    o.append(html.escape(s[i:]))
    return "".join(o)
def esc(s): return html.escape(s)
def pill(p):
    k = "" if p["kind"] == "plain" else " " + p["kind"]
    return f'<span class="pill{k}">{esc(p["text"])}</span>'
def table(columns, rows, first_mono=False):
    h = "<table>"
    if columns:
        h += "<tr>" + "".join(f"<th>{esc(c)}</th>" for c in columns) + "</tr>"
    for r in rows:
        tds = []
        for j, v in enumerate(r):
            cls = ' class="id"' if (first_mono and j == 0) else ""
            tds.append(f"<td{cls}>{cell(v)}</td>")
        h += "<tr>" + "".join(tds) + "</tr>"
    return h + "</table>"

ph = entry["phase"]
phases = "".join(
    f'<div class="ph{" now" if p["id"] == ph["now"] else (" done" if p.get("done") else "")}">{esc(p["id"])}<small>{esc(p["label"])}</small></div>'
    for p in ph["phases"])
gate = table(ph["gate"]["columns"], ph["gate"]["rows"])
tickets = "<table><tr><th>id</th><th>what</th><th>state</th><th>pr</th></tr>" + "".join(
    f'<tr><td class="id">{esc(t["id"])}</td><td>{cell(t["what"])}</td>'
    f'<td>{pill({"kind": t["kind"], "text": t["state"]})}</td>'
    f'<td class="mono">{esc(str(t["pr"])) if t.get("pr") is not None else "-"}</td></tr>'
    for t in entry["tickets"]) + "</table>"
blocks = "\n".join(
    f'  <section class="blk" data-s="{b["kind"]}">\n    <h2>{esc(b["title"])}</h2>\n    <div class="tbl">{table([], b["rows"])}</div>\n  </section>'
    for b in entry["blocks"])
q = entry["question"]
REC = ' <span class="pill go">rec</span>'  # outside the f-string: the lint image's python predates backslashes in f-string expressions
qopts = "".join(
    f'<div class="opt"><b>{esc(o["key"])}</b><span>{cell(o["text"])}{REC if o.get("rec") else ""}</span></div>'
    for o in q["options"])
qqueued = f'<div class="eyebrow" style="margin-top:8px">{esc(q["queued"])}</div>' if q.get("queued") else ""
legend = table([], [[k, v] for k, v in sorted(entry["legend"].items())], first_mono=True)
at = entry["at"].replace("T", " ").replace("Z", " UTC")
eyebrow = f'SITREP {entry["number"]:03d} · {at} · {entry["actor"]} · {entry["state"]}'
fill = {
    "__TITLE__": esc(f'Qud Factory SITREP {entry["number"]:03d}'),
    "__EYEBROW__": esc(eyebrow),
    "__HEADLINE__": esc(entry["headline"]),
    "__STRIP__": "".join(pill(p) for p in entry["strip"]),
    "__PHASE_COUNT__": str(len(ph["phases"])),
    "__PHASES__": phases, "__GATE__": gate, "__TICKETS__": tickets, "__BLOCKS__": blocks,
    "__Q_TITLE__": esc(q["title"]), "__Q_OPTIONS__": qopts, "__Q_QUEUED__": qqueued,
    "__LEGEND__": legend, "__SOURCES__": esc(entry["sources"]),
}
tpl = open(os.path.join(here, "assets", "template.html"), encoding="utf-8").read()
page = re.sub("|".join(map(re.escape, fill)), lambda m: fill[m.group(0)], tpl)
if out:
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    open(out, "w", encoding="utf-8").write(page)
    print(f"sitrep: wrote {out}", file=sys.stderr)
else:
    sys.stdout.write(page)
PY
    ;;
  *) usage ;;
esac
