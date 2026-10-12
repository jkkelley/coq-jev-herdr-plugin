#!/usr/bin/env bash
# check.sh - the scheduler specs, checked rather than trusted (specs/scheduler/config/check.json). Every specs/scheduler/*.xml
# must validate against specs/scheduler/schema/scheduler-spec.xsd, stay under max_lines, keep every element's own words under
# under_chars, cite a source that resolves for every element that carries words, match no forbidden pattern, declare only graph
# nodes that exist with the same title, and together own every row of the routes table and every status code exactly once.
#
#   check.sh check [--config FILE] [--repo DIR] [FILE...]   default FILE: every file the config's specs glob names
#   check.sh lines [--config FILE] [--repo DIR]             the line count of every spec, biggest first
# Runs in the lint image (xmllint, python3): make lint calls it once the lint ticket lands; until then
#   podman run --rm --network=none -v "$PWD:/repo:ro,Z" localhost/coq-lint:1 bash /repo/specs/scheduler/bin/check.sh check --repo /repo
# Prints `ok FILE` per file, or one line per violation naming the element, never the matched text.
# Exit codes: 0 ok, 2 usage, 3 validation, 4 io.
set -euo pipefail
HERE=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd); REPO=$(cd "$HERE/../../.." && pwd)
CONFIG=""; VERB=${1:-}; shift || true
die() { local c=$1; shift; printf 'check: %s\n' "$*" >&2; exit "$c"; }
files=()
while [ $# -gt 0 ]; do case $1 in
  --config) CONFIG=${2:?--config needs a file}; shift 2;;
  --repo) REPO=$(cd "${2:?--repo needs a directory}" && pwd) || die 4 "no such --repo"; shift 2;;
  -*) die 2 "unknown flag $1";;
  *) files+=("$1"); shift;; esac; done
case $VERB in check|lines) ;; *) sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2;; esac
[ -n "$CONFIG" ] || CONFIG=$REPO/specs/scheduler/config/check.json
[ -f "$CONFIG" ] || die 4 "config $CONFIG missing"
command -v python3 >/dev/null || die 4 "python3 is required"
[ "$VERB" = lines ] || command -v xmllint >/dev/null || die 4 "xmllint is required (the lint image has it)"
exec python3 - "$VERB" "$CONFIG" "$REPO" "${files[@]}" <<'PY'
import glob, json, os, re, subprocess, sys, xml.etree.ElementTree as ET
verb, config, repo, files = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4:]
cfg = json.load(open(config, encoding="utf-8"))
for key in ("specs", "schema", "specs_dir", "graph_nodes", "routes", "max_lines", "under_chars", "codes", "forbidden"):
    if key not in cfg:
        print(f"check: config key {key} missing"); sys.exit(3)
if not files:
    files = sorted(glob.glob(os.path.join(repo, cfg["specs"])))
if not files:
    print("check: no spec files"); sys.exit(4)
rel = lambda p: os.path.relpath(p, repo)
if verb == "lines":
    for p in sorted(files, key=lambda p: -sum(1 for _ in open(p, encoding="utf-8"))):
        print(f"{sum(1 for _ in open(p, encoding='utf-8')):5d} {rel(p)}")
    sys.exit(0)

limit, max_lines = cfg["under_chars"], cfg["max_lines"]
forbidden = [(f["name"], re.compile(f["regex"])) for f in cfg["forbidden"]]
schema = os.path.join(repo, cfg["schema"]); nodes_dir = os.path.join(repo, cfg["graph_nodes"])
bad = []
WORDS = {"text", "purpose", "mermaid", "key", "field", "verb", "state", "case", "owns-route", "owns-code", "example"}

# every spec id and its section ids, from the SPEC-NN tree and this tree, so spec: sources and refs resolve across both
spec_sections = {}
for p in glob.glob(os.path.join(repo, cfg["specs_dir"], "SPEC-*.xml")) + files:
    try:
        t = ET.parse(p).getroot()
    except ET.ParseError as e:
        bad.append(f"{rel(p)}: does not parse: {e}"); continue
    spec_sections[t.get("id")] = {e.get("id") for e in t.iter() if e.get("id")}
graph_nodes = {os.path.basename(f)[:-5]: json.load(open(f, encoding="utf-8")) for f in glob.glob(os.path.join(nodes_dir, "*.json"))}

def own_text(el):
    return ((el.text or "") + "".join(c.tail or "" for c in el)).strip()

def where(el, parents):
    for e in [el] + parents[::-1]:
        for a in ("id", "name", "match", "value", "kind"):
            if e.get(a):
                return f"<{el.tag} {a}={e.get(a)}>" if e is el else f"<{el.tag}> in <{e.tag} {a}={e.get(a)}>"
    return f"<{el.tag}>"

def walk(el, parents, out):
    out.append((el, parents))
    for c in el:
        walk(c, parents + [el], out)

def source_ok(src):
    # one or more sources joined by ';': a repo path with an optional #locator, spec:ID#anchor, node:ID, owner:channel:UTC
    for s in [x.strip() for x in src.split(";")]:
        if s.startswith("owner:"):
            continue
        if s.startswith("spec:"):
            sid, _, anchor = s[5:].partition("#")
            if sid not in spec_sections: return f"spec {sid} unknown"
            if anchor and anchor not in spec_sections[sid]: return f"anchor {sid}#{anchor} unknown"
            continue
        if s.startswith("node:"):
            if s[5:] not in graph_nodes: return f"node {s[5:]} missing from graph"
            continue
        path = s.split("#", 1)[0]
        if not os.path.exists(os.path.join(repo, path)): return f"source path {path} missing"
    return ""

owned_routes, owned_codes, line_total = {}, {}, {}
for path in files:
    name = rel(path)
    r = subprocess.run(["xmllint", "--noout", "--schema", schema, path], capture_output=True, text=True)
    if r.returncode != 0:
        bad.append(f"{name}: schema: " + (r.stderr.strip().splitlines() or ["invalid"])[-1]); continue
    lines = open(path, encoding="utf-8").read().splitlines()
    if len(lines) >= max_lines:
        bad.append(f"{name}: {len(lines)} lines, the limit is under {max_lines}")
    for n, line in enumerate(lines, 1):
        for fname, rx in forbidden:
            if rx.search(line):
                bad.append(f"{name}:{n}: forbidden ({fname})")
    root = ET.parse(path).getroot()
    sid = root.get("id")
    nodes = []; walk(root, [], nodes)
    for el, parents in nodes:
        text = own_text(el)
        if len(text) >= limit and el.tag != "mermaid":  # a diagram is one element by nature
            bad.append(f"{name}: {where(el, parents)} has {len(text)} chars of its own, the limit is under {limit}")
        for a, v in el.attrib.items():
            if len(v) >= limit and a not in ("command", "argv", "expected"):
                bad.append(f"{name}: {where(el, parents)} attribute {a} is {len(v)} chars, the limit is under {limit}")
        inherited = parents and parents[-1].tag in ("example", "node")
        if el.tag in WORDS and not inherited:
            src = el.get("source")
            if src is None:
                bad.append(f"{name}: {where(el, parents)} carries words and no source")
            elif src is not None:
                why = source_ok(src)
                if why: bad.append(f"{name}: {where(el, parents)}: {why}")
        if el.tag == "ref":
            sp, an, nd = el.get("spec"), el.get("anchor"), el.get("node")
            if sp and sp not in spec_sections: bad.append(f"{name}: ref to missing spec {sp}")
            elif sp and an and an not in spec_sections[sp]: bad.append(f"{name}: ref to missing anchor {sp}#{an}")
            if nd and nd not in graph_nodes: bad.append(f"{name}: ref to missing node {nd}")
        if el.tag == "node":
            nid, title = el.get("id"), (el.findtext("title") or "").strip()
            if nid not in graph_nodes: bad.append(f"{name}: node {nid} missing from graph")
            elif graph_nodes[nid]["title"] != title: bad.append(f"{name}: title drift for {nid}")
            for s in el.iter("source"):
                if s.get("kind") in ("spec",) and s.get("id") not in spec_sections: bad.append(f"{name}: node {nid} cites unknown spec {s.get('id')}")
        if el.tag == "owns-route":
            m = el.get("match")
            try:
                canon = json.dumps(json.loads(m), sort_keys=True, separators=(",", ":"))
            except ValueError:
                bad.append(f"{name}: owns-route match is not JSON: {m}"); continue
            if canon != m: bad.append(f"{name}: owns-route match is not canonical JSON (sorted keys, no spaces): {m}")
            owned_routes.setdefault(canon, []).append(sid)
        if el.tag == "owns-code":
            owned_codes.setdefault(int(el.get("value")), []).append((sid, el.get("name")))
    print(f"ok {name} ({len(lines)} lines)")

# ownership: every routes row and every code in the universe is owned by exactly one spec
routes = json.load(open(os.path.join(repo, cfg["routes"]), encoding="utf-8"))["routes"]
rows = [json.dumps(r["match"], sort_keys=True, separators=(",", ":")) for r in routes]
for i, row in enumerate(rows):
    owners = owned_routes.get(row, [])
    if len(owners) != 1:
        bad.append(f"routes row {i} {row}: owned by {len(owners)} specs ({', '.join(owners) or 'none'}), must be exactly one")
for row, owners in owned_routes.items():
    if row not in rows: bad.append(f"owns-route {row} ({', '.join(owners)}): no such row in the routes table")
universe = {c["value"]: c["name"] for c in cfg["codes"]}
for r in routes:
    for k in ("code", "code_gte"):
        v = r["match"].get(k)
        if v is not None and v not in universe: bad.append(f"routes row code {v} is not in check.json codes")
    if r.get("code") is not None and r["code"] not in universe: bad.append(f"routes row emits code {r['code']} which is not in check.json codes")
for value, cname in universe.items():
    owners = owned_codes.get(value, [])
    if len(owners) != 1:
        bad.append(f"status code {value} {cname}: owned by {len(owners)} specs ({', '.join(o[0] for o in owners) or 'none'}), must be exactly one")
    elif owners[0][1] != cname:
        bad.append(f"status code {value}: {owners[0][0]} names it {owners[0][1]}, check.json names it {cname}")
for value, owners in owned_codes.items():
    if value not in universe: bad.append(f"owns-code {value} ({owners[0][0]}): not in check.json codes")
if bad:
    print("\n".join(bad)); sys.exit(3)
print(f"ownership ok: {len(rows)} routes rows and {len(universe)} status codes each owned once")
PY
