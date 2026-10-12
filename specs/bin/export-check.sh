#!/usr/bin/env bash
# export-check.sh - the copy rule of a spec export, checked rather than trusted. A file under specs/exports/ leaves this
# repository for another host (the factory spec another agent ports from), so it must parse, stay bounded and stay generic.
#
#   export-check.sh check    [--config FILE] [--repo DIR] [FILE...]   default FILE: every file the config's exports glob names
#       xmllint parses it; the root carries a semver version; sections are S1..Sn with no gap; ids are unique and every ref
#       names one; every element's own text and every attribute value is shorter than under_chars; an element with text
#       cites a repo-relative source (or a ref into the file); status is draft or absent; no line matches a forbidden pattern.
#   export-check.sh coverage [--config FILE] [--repo DIR] FILE...
#       every cited source exists under the repo, and every file the config's cover globs name is cited at least once.
# Config: specs/config/export.json, validated by the schema beside it in make lint. make lint runs `check`; `coverage` is run
# when an export is rebuilt, because a rule that cites a file another ticket renames or adds must not fail that ticket's lint.
# Prints `ok FILE ...` per file, or one line per violation naming the element or the line, never the matched text.
# Exit codes: 0 ok, 2 usage, 3 validation, 4 io.
set -euo pipefail
HERE=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd); REPO=$(cd "$HERE/../.." && pwd)
CONFIG=""; VERB=${1:-}; shift || true
die() { local c=$1; shift; printf 'export-check: %s\n' "$*" >&2; exit "$c"; }
files=()
while [ $# -gt 0 ]; do case $1 in
  --config) CONFIG=${2:?--config needs a file}; shift 2;;
  --repo) REPO=$(cd "${2:?--repo needs a directory}" && pwd) || die 4 "no such --repo"; shift 2;;
  -*) die 2 "unknown flag $1";;
  *) files+=("$1"); shift;; esac; done
case $VERB in check|coverage) ;; *) sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2;; esac
[ -n "$CONFIG" ] || CONFIG=$REPO/specs/config/export.json
[ -f "$CONFIG" ] || die 4 "config $CONFIG missing"
command -v python3 >/dev/null || die 4 "python3 is required"
[ "$VERB" = check ] || [ "${#files[@]}" -gt 0 ] || die 2 "coverage needs the export to read"
[ "$VERB" = coverage ] || command -v xmllint >/dev/null || die 4 "xmllint is required (the lint image has it)"
exec python3 - "$VERB" "$CONFIG" "$REPO" "${files[@]}" <<'PY'
import json, os, re, subprocess, sys, xml.etree.ElementTree as ET
verb, config, repo, files = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4:]
cfg = json.load(open(config, encoding="utf-8"))
for key in ("exports", "under_chars", "forbidden", "cover"):
    if key not in cfg:
        print(f"export-check: config key {key} missing"); sys.exit(3)
limit = cfg["under_chars"]
forbidden = [(f["name"], re.compile(f["regex"])) for f in cfg["forbidden"]]
SOURCE = re.compile(r"^[A-Za-z0-9_.$][A-Za-z0-9_./${}-]*$")
bad = []

def rel(p):
    return os.path.relpath(p, repo)

def own_text(el):
    # The element's own words: its text and the tails of its children, never its children's text.
    return ((el.text or "") + "".join(c.tail or "" for c in el)).strip()

def where(el, parents):
    for e in [el] + parents[::-1]:
        for a in ("id", "name", "n", "rule", "value", "kind"):
            if e.get(a):
                return f"<{el.tag}> in <{e.tag} {a}={e.get(a)}>" if e is not el else f"<{el.tag} {a}={e.get(a)}>"
    return f"<{el.tag}>"

def walk(el, parents, out):
    out.append((el, parents))
    for c in el:
        walk(c, parents + [el], out)

def check(path):
    raw = open(path, encoding="utf-8").read()
    root = ET.parse(path).getroot()
    name = rel(path)
    if not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", root.get("version") or ""):
        bad.append(f"{name}: the root carries no semver version")
    secs = [s.get("id") for s in root.iter("section")]
    if secs != [f"S{i}" for i in range(1, len(secs) + 1)]:
        bad.append(f"{name}: sections are {' '.join(map(str, secs))}, expected S1..S{len(secs)} with no gap")
    nodes = []; walk(root, [], nodes)
    ids = {}
    for el, _ in nodes:
        i = el.get("id")
        if i is not None:
            if i in ids: bad.append(f"{name}: id {i} is used twice")
            ids[i] = el
    longest = 0
    for el, parents in nodes:
        text = own_text(el); longest = max(longest, len(text))
        if len(text) >= limit:
            bad.append(f"{name}: {where(el, parents)} has {len(text)} chars of text, the limit is under {limit}")
        for a, v in el.attrib.items():
            if len(v) >= limit: bad.append(f"{name}: {where(el, parents)} attribute {a} has {len(v)} chars")
        src, ref = el.get("source"), el.get("ref")
        if text and not src and not ref:
            bad.append(f"{name}: {where(el, parents)} has text but no source and no ref")
        if src is not None and (not SOURCE.match(src) or "/../" in f"/{src}/" or src.startswith("/")):
            bad.append(f"{name}: {where(el, parents)} source is not a repo-relative path")
        if ref is not None and ref not in ids:
            bad.append(f"{name}: {where(el, parents)} ref {ref} names no id in the file")
        if el.get("status") not in (None, "draft"):
            bad.append(f"{name}: {where(el, parents)} status is not draft")
    for n, line in enumerate(raw.splitlines(), 1):
        for label, rx in forbidden:
            if rx.search(line):
                bad.append(f"{name}:{n}: forbidden {label}")
    return f"ok {name} version {root.get('version')} sections {secs[0] if secs else '-'}..{secs[-1] if secs else '-'} elements {len(nodes)} longest {longest}"

def repo_files():
    try:
        out = subprocess.run(["git", "-C", repo, "ls-files", "-z"], capture_output=True, check=True).stdout.decode()
        return [p for p in out.split("\0") if p]
    except (OSError, subprocess.CalledProcessError):
        found = []
        for d, dirs, fs in os.walk(repo):
            dirs[:] = [x for x in dirs if not x.startswith(".") and x != "node_modules"]
            found += [rel(os.path.join(d, f)) for f in fs]
        return found

def glob_rx(g):
    # * stays inside one directory, **/ spans any depth (none included).
    out = ""; i = 0
    while i < len(g):
        if g.startswith("**/", i): out += "(?:.*/)?"; i += 3
        elif g[i] == "*": out += "[^/]*"; i += 1
        else: out += re.escape(g[i]); i += 1
    return re.compile(out + r"\Z")

def coverage(path):
    root = ET.parse(path).getroot(); name = rel(path)
    cited = {e.get("source") for e in root.iter() if e.get("source")}
    for s in sorted(cited):
        if not os.path.isfile(os.path.join(repo, s)): bad.append(f"{name}: cites {s}, which does not exist")
    want = sorted({p for p in repo_files() for g in cfg["cover"] if glob_rx(g).match(p)})
    for p in want:
        if p not in cited: bad.append(f"{name}: {p} is cited by no element")
    return f"ok {name} cites {len(cited)} sources, covers {len(want)} of {len(want)} required files"

if not files:
    import glob
    files = sorted(glob.glob(os.path.join(repo, cfg["exports"])))
    if not files:
        print(f"export-check: no export matches {cfg['exports']}"); sys.exit(0)
lines = []
for f in files:
    if verb == "check":
        try:
            r = subprocess.run(["xmllint", "--noout", f], capture_output=True, text=True)
        except OSError as e:
            print(f"export-check: xmllint did not run: {e}", file=sys.stderr); sys.exit(4)
        if r.returncode != 0:
            bad.append(f"{rel(f)}: xmllint could not parse it: {r.stderr.strip().splitlines()[0] if r.stderr.strip() else r.returncode}")
            continue
    try:
        lines.append(check(f) if verb == "check" else coverage(f))
    except ET.ParseError as e:
        bad.append(f"{rel(f)}: does not parse: {e}")
    except OSError as e:
        print(f"export-check: cannot read {f}: {e}", file=sys.stderr); sys.exit(4)
if bad:
    print("\n".join(bad)); sys.exit(3)
print("\n".join(lines))
PY
