#!/usr/bin/env python3
"""
rebuild/design/bin/check-book.py: the spec book checker behind rebuild/design/check.sh.

Prints one line per failure: FAIL <check> <file> <detail>
Prints NOTE lines for things it saw but does not fail on (external sources, other-branch citations, planned files).
Exit 0 when every check passes, 1 when any check fails, 2 when the checker itself cannot run (no XSD validator).

Checks (ids match the N-46 spec where one exists):
  C01 well-formed     every .xml under the book parses
  C02 xsd             every volume validates against schema/volume.xsd (xmlschema module, or xmllint)
  C03 line-cap        every volume is 1000 lines or fewer
  C04 contents        <contents> is the first child; every entry ref is an id in the document, in document order
  C05 parent          <pointers> holds a <parent> pointer that resolves
  C06 pointers        every pointer resolves to a file or a declared anchor (see resolve() for the pointer forms)
  C07 many-agents     a many-agents section exists and has content (named element or section id, with or without -at-once)
  C08 no-dashes       no U+2014 em dash or U+2013 en dash in any .xml, .json or .md of the book
  C09 unique-ids      no id attribute value repeats inside one document
  C10 json-schema     every *.schema.json is a valid JSON Schema 2020-12 and every $ref resolves
  C11 index           every nodes/N-xx directory is a <node> in index.xml and the reverse; dag.md names the same set
  C12 envelope        @node equals the directory name; @issued or @written present
  C13 waits           every <wait> element names a timeout and a fallback (attribute or child), the no-cog floor; a wait
                      whose timeout is the word none carries class="level-triggered" (re-evaluated every tick, so nothing
                      holds) or class="owner-decision" (an owner card with its own escalation bound), so a reviewer can
                      tell a deliberate unbounded wait from a missing bound; class, when present, is one of bounded,
                      level-triggered, owner-decision
  C14 registry        bin/registry.py --check: shared/cleanup-registry.json is fresh and every state path has a cleanup
  C15 kinds           bin/make-kinds.py --check: shared/record-kinds.xml is fresh and every status-codes row parses
  C16 dag             bin/dag-check.py: dag.md's Mermaid block, tables, re-entries and section 6 statement agree; acyclic
  C17 index-fresh     bin/make-index.py --check: index.xml is fresh (nodes, volumes, line counts)
  C18 codes           every code a node emits is in shared/status-codes.xml, and every registered kind is named in the
                      emitter rows of every code it carries
  C19 input-output    every node-spec volume has an element with id input and an element with id output
  C20 bindings        every panel kind is a registered record kind, a view of nodes/N-31/spec.xml#views or a static kind
                      of nodes/N-37/spec.xml#static-kinds

Pointer forms resolved by C06 (relative paths are tried against the volume's directory, the book root, then the repository root):
  href="file#anchor"             on any element
  path="file" anchor="anchor"    on any element except <path> (a state path, not a pointer) and <file> that is not a document
  volume="file" anchor="anchor"  on <need>
  schema="file.json#/json/pointer"
  ref="../N-xx/spec.xml#id"      on <in> and <out>; ref="id" on <entry>
  href="#id"                     a local anchor
Anchors: an id attribute in XML, a GitHub heading slug or L<n>[-L<m>] line range in Markdown, a JSON pointer in JSON.
Not resolved, reported as NOTE: paths starting with / ~ $ http STATE/ (outside the repository), elements carrying
branch= (a citation into another branch) or planned= (a file a build ticket creates).
"""
import glob
import json
import os
import re
import subprocess
import sys
import xml.etree.ElementTree as ET

BOOK = os.path.abspath(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
REPO = os.path.abspath(os.path.join(BOOK, "..", ".."))
XSD = os.path.join(BOOK, "schema", "volume.xsd")
LINE_CAP = 1000
MANY_AGENTS_IDS = ("many-agents", "many-agents-at-once")
WAIT_CLASSES = ("bounded", "level-triggered", "owner-decision")
HELPERS = (  # (check id, script, args): generators and checkers run as subprocesses; their FAIL lines are folded in
    ("C14", "registry.py", ["--check"]),
    ("C15", "make-kinds.py", ["--check"]),
    ("C16", "dag-check.py", []),
    ("C17", "make-index.py", ["--check"]),
)

failures = []
notes = []


def fail(check, path, detail):
    failures.append((check, path, detail))


def note(path, detail):
    notes.append((path, detail))


def rel(p):
    return os.path.relpath(p, BOOK)


def volumes():
    files = sorted(glob.glob(os.path.join(BOOK, "*.xml")))
    files += sorted(glob.glob(os.path.join(BOOK, "shared", "*.xml")))
    files += sorted(glob.glob(os.path.join(BOOK, "nodes", "N-*", "*.xml")))
    return files


# ---------- anchor helpers ----------
_slug_cache = {}


def md_slugs(path):
    if path in _slug_cache:
        return _slug_cache[path]
    out = set()
    fence = False
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            if line.startswith("```"):
                fence = not fence
                continue
            if fence:
                continue
            m = re.match(r"^(#{1,6})\s+(.*?)\s*#*\s*$", line)
            if m:
                t = m.group(2).strip().lower()
                t = re.sub(r"`", "", t)
                t = re.sub(r"[^\w\- ]", "", t).replace(" ", "-")
                out.add(t)
    _slug_cache[path] = out
    return out


_ids_cache = {}


def xml_ids(path):
    if path in _ids_cache:
        return _ids_cache[path]
    try:
        root = ET.parse(path).getroot()
    except ET.ParseError:
        _ids_cache[path] = None
        return None
    ids = {e.attrib["id"] for e in root.iter() if "id" in e.attrib}
    _ids_cache[path] = ids
    return ids


def json_pointer_ok(path, ptr):
    try:
        with open(path, encoding="utf-8") as fh:
            doc = json.load(fh)
    except (OSError, ValueError):
        return False
    if ptr == "":
        return True
    if not ptr.startswith("/"):
        return False
    cur = doc
    for part in ptr[1:].split("/"):
        part = part.replace("~1", "/").replace("~0", "~")
        if isinstance(cur, dict) and part in cur:
            cur = cur[part]
        elif isinstance(cur, list) and part.isdigit() and int(part) < len(cur):
            cur = cur[int(part)]
        else:
            return False
    return True


def anchor_ok(path, anchor):
    if os.path.isdir(path) or anchor == "":
        return True
    if path.endswith(".md"):
        m = re.match(r"^L(\d+)(?:-L(\d+))?$", anchor)
        if m:
            with open(path, encoding="utf-8") as fh:
                n = sum(1 for _ in fh)
            return int(m.group(2) or m.group(1)) <= n
        return anchor in md_slugs(path)
    if path.endswith(".xml") or path.endswith(".xsd"):
        ids = xml_ids(path)
        return ids is not None and anchor in ids
    if path.endswith(".json"):
        return json_pointer_ok(path, anchor)
    return True


EXTERNAL_PREFIXES = ("/", "~", "$", "http://", "https://", "STATE/", "<")


def resolve(volfile, target, anchor):
    """Return None when resolved, else a reason string. 'external' is a NOTE, not a failure."""
    if target.startswith(EXTERNAL_PREFIXES):
        return "external"
    voldir = os.path.dirname(volfile)
    candidates = [
        os.path.normpath(os.path.join(voldir, target)),
        os.path.normpath(os.path.join(BOOK, target)),
        os.path.normpath(os.path.join(REPO, target)),
    ]
    found = next((c for c in candidates if os.path.exists(c)), None)
    if found is None:
        return "no such file (tried the volume directory, the book root and the repository root)"
    if not anchor_ok(found, anchor):
        return "no anchor '%s' in %s" % (anchor, os.path.relpath(found, BOOK))
    return None


def split_target(value):
    target, _, anchor = value.partition("#")
    return target, anchor


# ---------- per-volume checks ----------
def check_volume(volfile, validator):
    path = rel(volfile)
    with open(volfile, encoding="utf-8") as fh:
        text = fh.read()
    lines = text.count("\n") + (0 if text.endswith("\n") else 1)
    if lines > LINE_CAP:
        fail("C03", path, "%d lines, cap is %d" % (lines, LINE_CAP))
    try:
        root = ET.parse(volfile).getroot()
    except ET.ParseError as e:
        fail("C01", path, "not well-formed: %s" % e)
        return
    if root.tag != "volume":
        fail("C02", path, "root element is <%s>, expected <volume>" % root.tag)
        return
    err = validator(volfile)
    if err:
        fail("C02", path, err)

    # C09 unique ids
    seen = {}
    for e in root.iter():
        i = e.attrib.get("id")
        if i is None:
            continue
        if i in seen:
            fail("C09", path, "id '%s' declared twice (<%s> and <%s>)" % (i, seen[i], e.tag))
        seen[i] = e.tag
    ids = set(seen)

    # C12 envelope
    kind = root.attrib.get("kind", "")
    if kind.startswith("node-"):
        dirname = os.path.basename(os.path.dirname(volfile))
        if root.attrib.get("node") != dirname:
            fail("C12", path, "@node is '%s' but the directory is %s" % (root.attrib.get("node"), dirname))
    if "issued" not in root.attrib and "written" not in root.attrib:
        fail("C12", path, "neither @issued nor @written is present")

    # C04 contents first, refs resolve in order
    children = list(root)
    if not children or children[0].tag != "contents":
        fail("C04", path, "first child is <%s>, expected <contents>" % (children[0].tag if children else "nothing"))
    else:
        order = [e.attrib.get("id") for e in root.iter() if "id" in e.attrib]
        pos = {i: n for n, i in enumerate(order)}
        last = -1
        for entry in children[0]:
            ref = entry.attrib.get("ref", "").lstrip("#")
            if ref not in ids:
                fail("C04", path, "contents entry ref '%s' is not an id in this volume" % ref)
                continue
            if pos[ref] < last:
                fail("C04", path, "contents entry '%s' is out of document order" % ref)
            last = max(last, pos[ref])

    # C05 parent pointer
    pointers = root.find("pointers")
    if pointers is None:
        fail("C05", path, "no <pointers> element")
    else:
        parent = pointers.find("parent")
        if parent is None:
            fail("C05", path, "no <parent> pointer under <pointers>")
        elif not (parent.attrib.get("href") or (parent.attrib.get("path") and parent.attrib.get("anchor"))):
            fail("C05", path, "<parent> needs href or path plus anchor")
        if pointers.find("sibling") is None and kind != "index":
            note(path, "no <sibling> pointer")

    # C07 many agents
    ma = None
    for e in root.iter():
        if e.tag in MANY_AGENTS_IDS or e.attrib.get("id") in MANY_AGENTS_IDS:
            ma = e
            break
    if ma is None:
        fail("C07", path, "no many-agents section (element many-agents or many-agents-at-once, or a section with that id)")
    elif not "".join(ma.itertext()).strip():
        fail("C07", path, "many-agents section is empty")

    # C13 waits
    for w in root.iter("wait"):
        has_timeout = "timeout" in w.attrib or w.find("timeout") is not None
        has_fallback = "fallback" in w.attrib or w.find("fallback") is not None
        wid = w.attrib.get("id") or w.attrib.get("name") or w.attrib.get("what") or "".join(w.itertext()).strip()[:60]
        if not (has_timeout and has_fallback):
            fail("C13", path, "wait '%s' lacks %s" % (wid, "a timeout" if not has_timeout else "a fallback"))
            continue
        timeout = w.attrib.get("timeout")
        if timeout is None:
            timeout = "".join(w.find("timeout").itertext())
        wclass = w.attrib.get("class")
        if wclass is not None and wclass not in WAIT_CLASSES:
            fail("C13", path, "wait '%s' class '%s' is not one of %s" % (wid, wclass, ", ".join(WAIT_CLASSES)))
        if timeout.strip().lower().startswith("none") and wclass not in ("level-triggered", "owner-decision"):
            fail("C13", path, "wait '%s' has timeout none and no class level-triggered or owner-decision" % wid)

    # C19 input and output
    if kind == "node-spec" and not ({"input", "output"} <= ids):
        fail("C19", path, "node-spec without an element of id %s" % " and ".join(sorted({"input", "output"} - ids)))

    # C06 pointers
    for e in root.iter():
        a = e.attrib
        skip_disk = "branch" in a or "planned" in a
        targets = []
        if e.tag == "entry":
            continue
        if "href" in a:
            targets.append(("href", a["href"]))
        if "ref" in a and e.tag in ("in", "out", "cite", "uses"):
            targets.append(("ref", a["ref"]))
        if "schema" in a and re.search(r"\.(json|xml)(#|$)", a["schema"]):
            targets.append(("schema", a["schema"]))
        if "path" in a and e.tag != "path":
            v = a["path"]
            if e.tag == "file" and not re.search(r"\.(xml|json|md|xsd)$", v):
                pass
            else:
                targets.append(("path", v if "#" in v or not a.get("anchor") else v + "#" + a["anchor"].lstrip("#")))
        if "volume" in a and e.tag == "need":
            v = a["volume"]
            targets.append(("volume", v if "#" in v or not a.get("anchor") else v + "#" + a["anchor"].lstrip("#")))
        for attr, value in targets:
            if value.startswith("#"):
                if value[1:] not in ids:
                    fail("C06", path, "<%s %s=\"%s\"> local anchor not declared" % (e.tag, attr, value))
                continue
            target, anchor = split_target(value)
            if skip_disk:
                note(path, "<%s> cites %s on %s; not resolved on disk" % (e.tag, value, a.get("branch") or "a planned file"))
                continue
            why = resolve(volfile, target, anchor)
            if why == "external":
                note(path, "<%s %s=\"%s\"> is outside the repository; not resolved" % (e.tag, attr, value))
            elif why:
                fail("C06", path, "<%s %s=\"%s\"> %s" % (e.tag, attr, value, why))


# ---------- XSD validator selection ----------
def make_validator():
    try:
        import xmlschema  # noqa: F401
    except ImportError:
        xmlschema = None
    if xmlschema is not None:
        schema = xmlschema.XMLSchema10(XSD)

        def v(volfile):
            try:
                schema.validate(volfile)
            except xmlschema.XMLSchemaException as e:
                msg = str(e).strip().splitlines()
                reason = next((l.strip() for l in msg if l.strip().startswith("Reason:")), msg[0] if msg else "invalid")
                pathline = next((l.strip() for l in msg if l.strip().startswith("Path:")), "")
                return "xsd: %s %s" % (reason, pathline)
            return None
        return v, "python xmlschema"
    try:
        subprocess.run(["xmllint", "--version"], capture_output=True, check=True)
    except (OSError, subprocess.CalledProcessError):
        return None, None

    def v(volfile):
        r = subprocess.run(["xmllint", "--noout", "--schema", XSD, volfile], capture_output=True, text=True)
        if r.returncode != 0:
            lines = [l for l in r.stderr.splitlines() if "validates" not in l]
            return "xsd: " + (lines[0] if lines else r.stderr.strip())
        return None
    return v, "xmllint"


# ---------- cross-file checks ----------
def check_dashes():
    for pattern in ("*.xml", "*.md", "*.json", "*.sh", "shared/*", "schema/*", "bin/*", "nodes/*/*"):
        for f in glob.glob(os.path.join(BOOK, pattern)):
            if os.path.isdir(f):
                continue
            with open(f, encoding="utf-8", errors="replace") as fh:
                for n, line in enumerate(fh, 1):
                    if chr(0x2014) in line or chr(0x2013) in line:
                        fail("C08", rel(f), "line %d has an em dash or en dash" % n)


def check_json_schemas():
    try:
        import jsonschema
        from jsonschema import Draft202012Validator
    except ImportError:
        note("book", "jsonschema module missing; C10 skipped")
        return
    for f in sorted(glob.glob(os.path.join(BOOK, "nodes", "N-*", "*.schema.json")) + glob.glob(os.path.join(BOOK, "shared", "*.schema.json"))):
        path = rel(f)
        try:
            with open(f, encoding="utf-8") as fh:
                doc = json.load(fh)
        except ValueError as e:
            fail("C10", path, "not JSON: %s" % e)
            continue
        if "2020-12" not in str(doc.get("$schema", "")):
            fail("C10", path, "$schema is not JSON Schema 2020-12")
        try:
            Draft202012Validator.check_schema(doc)
        except jsonschema.SchemaError as e:
            fail("C10", path, "invalid schema: %s" % e.message)

        def walk(node):
            if isinstance(node, dict):
                r = node.get("$ref")
                if isinstance(r, str):
                    target, anchor = split_target(r)
                    if target == "":
                        if not json_pointer_ok(f, anchor):
                            fail("C10", path, "$ref '%s' does not resolve" % r)
                    elif not target.startswith(EXTERNAL_PREFIXES):
                        why = resolve(f, target, anchor)
                        if why:
                            fail("C10", path, "$ref '%s' %s" % (r, why))
                for v in node.values():
                    walk(v)
            elif isinstance(node, list):
                for v in node:
                    walk(v)
        walk(doc)


def check_index():
    index = os.path.join(BOOK, "index.xml")
    dirs = {os.path.basename(d) for d in glob.glob(os.path.join(BOOK, "nodes", "N-*")) if os.path.isdir(d)}
    if not os.path.exists(index):
        fail("C11", "index.xml", "missing")
        return
    try:
        root = ET.parse(index).getroot()
    except ET.ParseError:
        return
    listed = {}
    for n in root.iter("node"):
        listed[n.attrib.get("id")] = n
    for d in sorted(dirs - set(listed)):
        fail("C11", "index.xml", "node directory nodes/%s has no <node> entry" % d)
    for d in sorted(set(listed) - dirs):
        if listed[d].attrib.get("status") != "pending":
            fail("C11", "index.xml", "<node id=\"%s\"> has no directory and is not pending" % d)
    for nid, n in listed.items():
        if nid in dirs and n.attrib.get("status") == "pending":
            fail("C11", "index.xml", "<node id=\"%s\"> is pending but nodes/%s exists" % (nid, nid))
        for vr in n.iter("volume-ref"):
            href = vr.attrib.get("href", "")
            target, anchor = split_target(href)
            why = resolve(index, target, anchor)
            if why and why != "external":
                fail("C11", "index.xml", "volume-ref '%s' %s" % (href, why))
            elif "lines" in vr.attrib and not why:
                f = os.path.normpath(os.path.join(BOOK, target))
                with open(f, encoding="utf-8") as fh:
                    actual = sum(1 for _ in fh)
                if int(vr.attrib["lines"]) != actual:
                    fail("C11", "index.xml", "volume-ref '%s' says %s lines, file has %d" % (href, vr.attrib["lines"], actual))
    dag = os.path.join(BOOK, "dag.md")
    if os.path.exists(dag):
        with open(dag, encoding="utf-8") as fh:
            dag_nodes = set(re.findall(r"^\| (N-\d\d) \|", fh.read(), re.M))
        for d in sorted(dag_nodes ^ set(listed)):
            fail("C11", "index.xml", "node %s is in %s only" % (d, "dag.md" if d in dag_nodes else "index.xml"))


def run_helpers():
    for check, script, args in HELPERS:
        f = os.path.join(BOOK, "bin", script)
        if not os.path.exists(f):
            fail(check, "bin/" + script, "missing")
            continue
        r = subprocess.run([sys.executable, "-I", f] + args, capture_output=True, text=True)
        lines = [l for l in r.stdout.splitlines() if l.startswith("FAIL ")]
        for l in lines:
            parts = l.split(" ", 3)
            fail(check, parts[2] if len(parts) > 2 else script, parts[3] if len(parts) > 3 else l)
        if r.returncode != 0 and not lines:
            fail(check, "bin/" + script, "exit %d: %s" % (r.returncode, (r.stderr or r.stdout).strip()[:200]))


def check_codes():
    """C18: every emitted code exists in the map; every registered kind is named in its codes' emitter rows."""
    try:
        sc = ET.parse(os.path.join(BOOK, "shared", "status-codes.xml")).getroot()
        reg = ET.parse(os.path.join(BOOK, "shared", "record-kinds.xml")).getroot()
    except (ET.ParseError, OSError) as e:
        fail("C18", "shared", "cannot read the code map or the kinds registry: %s" % e)
        return
    emit = {}
    for e in sc.iter("status-code"):
        emit[int(e.attrib["value"])] = " ".join(" ".join(x.itertext()) for x in e.findall("emitter"))
    for k in reg.iter("record-kind"):
        names = [k.attrib["name"]] + k.attrib.get("status-names", "").split()
        for c in (int(x) for x in k.attrib["codes"].split()):
            if c not in emit:
                fail("C18", "shared/record-kinds.xml", "kind %s carries code %d, which shared/status-codes.xml does not define" % (k.attrib["name"], c))
                continue
            if not any(re.search(r"(?<![\w.-])" + re.escape(n) + r"(?![\w-])", emit[c]) for n in names):
                fail("C18", "shared/status-codes.xml", "code %d has no emitter row naming %s (written by %s)" % (c, k.attrib["name"], k.attrib["writers"]))


def check_bindings():
    """C20: every panel kind is a record kind, a view (N-31 #views) or a static kind (N-37 #static-kinds)."""
    known = set()
    try:
        reg = ET.parse(os.path.join(BOOK, "shared", "record-kinds.xml")).getroot()
        known |= {k.attrib["name"] for k in reg.iter("record-kind")}
        n31 = ET.parse(os.path.join(BOOK, "nodes", "N-31", "spec.xml")).getroot()
        views = {v.attrib["name"] for e in n31.iter() if e.attrib.get("id") == "views" for v in e.iter("view")}
        n37 = ET.parse(os.path.join(BOOK, "nodes", "N-37", "spec.xml")).getroot()
        static = {v.attrib["name"] for e in n37.iter() if e.attrib.get("id") == "static-kinds" for v in e.iter("static-kind")}
    except (ET.ParseError, OSError, KeyError) as e:
        fail("C20", "nodes", "cannot read the registry, N-31 views or N-37 static kinds: %s" % e)
        return
    if not views:
        fail("C20", "nodes/N-31/spec.xml", "no <view name=...> under the element of id views")
    if not static:
        fail("C20", "nodes/N-37/spec.xml", "no <static-kind name=...> under the element of id static-kinds")
    known |= views | static
    for f in sorted(glob.glob(os.path.join(BOOK, "nodes", "N-3[7-9]", "spec.xml")) + glob.glob(os.path.join(BOOK, "nodes", "N-4[0-2]", "spec.xml"))):
        root = ET.parse(f).getroot()
        for sec in root.iter():
            if sec.attrib.get("id") != "panels":
                continue
            for p in sec.iter("panel"):
                k = p.attrib.get("kind")
                if k and k not in known:
                    fail("C20", rel(f), "panel %s binds kind %s, which is no record kind, view or static kind" % (p.attrib.get("id"), k))


def main():
    validator, name = make_validator()
    if validator is None:
        print("FAIL C02 book no XSD validator: install python xmlschema (uv run --with xmlschema) or xmllint")
        return 2
    vols = volumes()
    for v in vols:
        check_volume(v, validator)
    check_dashes()
    check_json_schemas()
    check_index()
    run_helpers()
    check_codes()
    check_bindings()
    for check, path, detail in failures:
        print("FAIL %s %s %s" % (check, path, detail))
    if os.environ.get("COQ_CHECK_NOTES") == "1":
        for path, detail in notes:
            print("NOTE %s %s" % (path, detail))
    print("checked %d volumes with %s: %d failures, %d notes (COQ_CHECK_NOTES=1 prints them)" % (len(vols), name, len(failures), len(notes)))
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
