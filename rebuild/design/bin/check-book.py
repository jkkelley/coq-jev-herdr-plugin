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
  C21 md-labels       a pointer into a Markdown file never uses a list label (V04, T02, K07: one letter plus digits) as its anchor,
                      in an attribute or in prose, and a "file.md#anchor" written in prose resolves like any pointer.
                      What broke: the G4 volumes (N-20 to N-26) cited 02-MAPPING list labels as if they were anchors (R-03 review
                      note, 2026-10-14). C06 reads attributes only, so a prose citation was never resolved, and a label in an
                      attribute failed C06 without saying why. Cost: one more pass over every text node.

  C22 examples         bin/check-examples.py: every <example schema="..."> in a volume and every json block of DESIGN.md validates against
                      the one def it names (schema="file.json#/$defs/name"; a root link picks the def named after the kind, never the
                      root oneOf); a JSON example with no schema attribute fails, an example with a schema whose text is not JSON fails,
                      and a missing jsonschema module fails (C10 too)
  C23 edge-fixtures   bin/check-examples.py: <edge-fixture producer="file.json#/$defs/a" consumer="file.json#/$defs/b"/> in any volume
                      makes every example of the producer def validate against the consumer def too (and <example consumers="t1 t2">);
                      a fixture whose producer has no example fails, so a fixture cannot pass by having nothing to test
  C24 transitions     shared/contracts.xml, element id ticket-transitions: rows <transition from="s1 [s2 ...]" to="s" trigger="..."
                      owner="N-xx"/>; every status is in contracts.schema.json#/$defs/ticket_status, every enum status is reachable
                      from cut, every non-terminal status has a way out, the terminal statuses (done, dead, cancelled, refused) have
                      no outgoing row except dead to waiting; no other <transition> row in the book moves between two ticket
                      statuses unless it (or an ancestor) carries machine="..." naming another machine
  C25 operation-keys  every <op-key example="N-xx/op/subject/rN" node="N-xx"/> in the book matches
                      contracts.schema.json#/$defs/operation_key, its node segment equals @node, and no example repeats;
                      shared/contracts.xml holds at least one
  C26 capacity        shared/ci-capacity.xml: <container name pod="suite|canary" cpu mem-request mem-limit [cpu-limit]/> (also
                      spelled cpu-request, memory-request, memory-limit; a <canary> carrying those attributes is the canary
                      pod), optional <pod name .../> equal to the sum of its containers, <capacity runs-in-flight pods-per-run
                      container-cap/> with container-cap = runs x pods, and <quota-row pods requests-cpu requests-memory
                      limits-memory [limits-cpu]/> (or <quota> with those attributes, dotted or hyphenated) equal to
                      container-cap x suite + canary for each resource, pods = container-cap + 1
  C27 retry-budget    shared/retry-budget.xml: <layer id owner max parent retries-on="f1 f2" [chain="ci"]/> rows form one tree
                      through parent (empty, absent or none for a root); a failure is retried by at most one layer; the layers
                      with chain="ci" lie on one parent path and the product of their max is at most
                      <budgets pods-per-unit-per-head="N"/>
  C28 deadlines       every <deadline id value-seconds derived-from="a b"/> in the book: each derived-from id is a <deadline> and
                      value-seconds is at least the sum of theirs
  C29 dispositions    shared/review-dispositions.xml: one <finding id="Fnn" disposition="..."> for each of F01 to F26 (F27 onward
                      allowed), ids unique, disposition one of accepted, accepted-partial, rejected, superseded, new; each has an
                      <evidence> and a <resolution href="file#anchor"/> that resolves; <proof status="not-run|executed"/>, at
                      least one unless the disposition is rejected or superseded
  C30 no-pii          no home directory other than the $HOME forms, no -home-<user>- project slug, no tailnet (ts.net) or
                      .local host name (the in-cluster svc.cluster.local is not a host name of the site), no IPv4 literal other
                      than 127.0.0.1, 0.0.0.0, the documentation ranges (RFC 5737) and a network block of prefix 16 or shorter,
                      in any .xml, .json or .md of the book or any file of bin/
  C31 owner-words     shared/authority.xml: every <permit role="seat" kinds="k1 k2"/> (or <kind> children) names no ruling
                      kind (ruling, *.ruling, ruling.*, owner.*, an owner word); no .xml or .md of the book says "HOLD or USERGO"
                      or "HOLD or GOFACTORY" (a relayed, defaulted or seat-made message is never an owner word), and the lamp is
                      called "the hold lamp" somewhere in the book
  C16-edges           bin/dag-check.py: an edge a node spec declares (<in>/<out> under its edges or dag element, or <edge dir>)
                      is drawn in dag.md or is a section 4 re-entry, unless the element carries drawn="false"; a dag.md edge
                      is declared by one of its two node specs
  C13 and C20 were widened in 1.1.0: a timeout with the word none anywhere needs the class; every <panel> of every node
  volume needs a kind that binds.

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
    ("C22", "check-examples.py", []),
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
        if re.search(r"\bnone\b", timeout, re.I) and wclass not in ("level-triggered", "owner-decision"):
            # 1.1.0: "the policy's deadline, else none" is as unbounded as "none"; the word anywhere needs the class
            fail("C13", path, "wait '%s' has timeout none (in '%s') and no class level-triggered or owner-decision" % (wid, timeout.strip()[:60]))

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
    check_md_pointers(volfile, root, path)


MD_PTR = re.compile(r"([\w./~-]+\.md)#([\w-]+)")
LABEL_ANCHOR = re.compile(r"^[a-km-z]\d{1,3}$", re.I)  # L<n> is a line range, the one letter-plus-digits form that is a pointer


def check_md_pointers(volfile, root, path):
    """C21: list labels are not anchors; a .md#anchor written in prose must resolve."""
    for e in root.iter():
        if "branch" in e.attrib or "planned" in e.attrib:
            continue
        for attr, value in e.attrib.items():
            for target, anchor in MD_PTR.findall(value):
                if LABEL_ANCHOR.match(anchor):
                    fail("C21", path, "<%s %s> anchor '#%s' is a list label, not a heading anchor or L<n>-L<m> range" % (e.tag, attr, anchor))
            if attr == "anchor" and e.attrib.get("path", "").endswith(".md") and LABEL_ANCHOR.match(value.lstrip("#")):
                fail("C21", path, "<%s anchor=\"%s\"> is a list label, not a heading anchor or L<n>-L<m> range" % (e.tag, value))
        for chunk in (e.text or "", e.tail or ""):
            for target, anchor in MD_PTR.findall(chunk):
                if LABEL_ANCHOR.match(anchor):
                    fail("C21", path, "prose pointer %s#%s: '%s' is a list label, not a heading anchor or L<n>-L<m> range" % (target, anchor, anchor))
                    continue
                why = resolve(volfile, target, anchor)
                if why and why != "external":
                    fail("C21", path, "prose pointer %s#%s %s" % (target, anchor, why))


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
        fail("C10", "book", "jsonschema module missing; C10 cannot run (uv run --with jsonschema, or check.sh)")
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
            # a helper may report a sub-check of its own (C16-edges, C23); keep the id it printed
            cid = parts[1] if len(parts) > 1 and re.match(r"^C\d\d(-[\w-]+)?$", parts[1]) else check
            fail(cid, parts[2] if len(parts) > 2 else script, parts[3] if len(parts) > 3 else l)
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
    """C20: every panel of every node volume binds a kind that is a record kind, a view (N-31 #views) or a static kind
    (N-37 #static-kinds). 1.1.0: the scan was N-37 to N-42 under id panels only, so panels in N-49, N-50 and N-51 bound
    nothing and nothing said so; a panel with no kind now fails too."""
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
    for f in sorted(glob.glob(os.path.join(BOOK, "nodes", "N-*", "*.xml"))):
        try:
            root = ET.parse(f).getroot()
        except ET.ParseError:
            continue  # C01 reports it
        for p in root.iter("panel"):
            k = p.attrib.get("kind")
            pid = p.attrib.get("id") or p.attrib.get("screen") or "".join(p.itertext()).strip()[:40]
            if not k:
                fail("C20", rel(f), "panel '%s' has no kind attribute, so it binds nothing" % pid)
            elif k not in known:
                fail("C20", rel(f), "panel %s binds kind %s, which is no record kind, view or static kind" % (pid, k))


# ---------- 1.1.0 semantic checks (C24 to C31) ----------
TICKET_TERMINAL = ("done", "dead", "cancelled", "refused")
TERMINAL_EXITS = {("dead", "waiting")}
DISPOSITIONS = ("accepted", "accepted-partial", "rejected", "superseded", "new")
PROOF_STATUSES = ("not-run", "executed")
FINDINGS_REQUIRED = ["F%02d" % n for n in range(1, 27)]


def shared_root(check, name):
    """Parse shared/<name>; a missing or broken file is a FAIL of the check that needs it."""
    f = os.path.join(BOOK, "shared", name)
    if not os.path.exists(f):
        fail(check, "shared/" + name, "missing shared/%s" % name)
        return None, f
    try:
        return ET.parse(f).getroot(), f
    except ET.ParseError as e:
        fail(check, "shared/" + name, "not well-formed: %s" % e)
        return None, f


def contracts_defs(check):
    f = os.path.join(BOOK, "shared", "contracts.schema.json")
    try:
        with open(f, encoding="utf-8") as fh:
            return json.load(fh).get("$defs", {})
    except (OSError, ValueError) as e:
        fail(check, "shared/contracts.schema.json", "cannot read: %s" % e)
        return None


def parsed_volumes():
    for f in volumes():
        try:
            yield f, ET.parse(f).getroot()
        except ET.ParseError:
            continue  # C01 reports it


def parent_map(root):
    return {c: p for p in root.iter() for c in p}


def by_id(root, i):
    return next((e for e in root.iter() if e.attrib.get("id") == i), None)


def check_transitions():
    """C24: the ticket transition table is complete, reachable, terminal-safe and the only one in the book."""
    root, f = shared_root("C24", "contracts.xml")
    defs = contracts_defs("C24")
    if defs is None:
        return
    enum = (defs.get("ticket_status") or {}).get("enum")
    if not enum:
        fail("C24", "shared/contracts.schema.json", "no $defs.ticket_status.enum")
        return
    statuses = set(enum)
    table = None
    if root is not None:
        table = by_id(root, "ticket-transitions")
        if table is None:
            fail("C24", "shared/contracts.xml", "no element of id ticket-transitions")
    rows = list(table.iter("transition")) if table is not None else []
    if table is not None and not rows:
        fail("C24", "shared/contracts.xml", "ticket-transitions holds no <transition from to trigger owner/> row")
    out = {s: set() for s in statuses}
    seen = set()
    for t in rows:
        a = t.attrib
        label = "transition %s -> %s" % (a.get("from"), a.get("to"))
        for need in ("from", "to", "trigger", "owner"):
            if not a.get(need, "").strip():
                fail("C24", "shared/contracts.xml", "%s has no %s" % (label, need))
        owners = a.get("owner", "").split()
        if owners and not all(re.match(r"^N-\d\d$", o) for o in owners):
            fail("C24", "shared/contracts.xml", "%s owner '%s' is not a node id (N-xx)" % (label, a.get("owner")))
        to = a.get("to", "").strip()
        if to and to not in statuses:
            fail("C24", "shared/contracts.xml", "%s: '%s' is not in $defs.ticket_status" % (label, to))
        for fr in a.get("from", "").split():
            if fr not in statuses:
                fail("C24", "shared/contracts.xml", "%s: '%s' is not in $defs.ticket_status" % (label, fr))
                continue
            key = (fr, to, a.get("trigger", ""))
            if key in seen:
                fail("C24", "shared/contracts.xml", "transition %s -> %s on %s is declared twice" % key)
            seen.add(key)
            if to in statuses:
                out[fr].add(to)
                if fr in TICKET_TERMINAL and (fr, to) not in TERMINAL_EXITS:
                    fail("C24", "shared/contracts.xml", "terminal status %s has an outgoing row to %s (only dead -> waiting is allowed)" % (fr, to))
    if rows:
        if "cut" not in statuses:
            fail("C24", "shared/contracts.schema.json", "ticket_status has no cut, the status every ticket starts in")
        reached, todo = {"cut"}, ["cut"]
        while todo:
            for n in out.get(todo.pop(), ()):
                if n not in reached:
                    reached.add(n)
                    todo.append(n)
        for s in sorted(statuses - reached):
            fail("C24", "shared/contracts.xml", "status %s is not reachable from cut" % s)
        for s in sorted(statuses - set(TICKET_TERMINAL)):
            if not out[s]:
                fail("C24", "shared/contracts.xml", "non-terminal status %s has no outgoing row (a ticket there is stuck)" % s)
    # the table lives in one place
    for vf, vroot in parsed_volumes():
        pm = parent_map(vroot)
        own = by_id(vroot, "ticket-transitions") if os.path.abspath(vf) == os.path.abspath(f) else None
        skip = set(map(id, own.iter("transition"))) if own is not None else set()
        for t in vroot.iter("transition"):
            if id(t) in skip:
                continue
            fr, to = t.attrib.get("from", "").split(), t.attrib.get("to", "").strip()
            if not fr or to not in statuses or not all(x in statuses for x in fr):
                continue
            e, machine = t, None
            while e is not None and machine is None:
                machine = e.attrib.get("machine")
                e = pm.get(e)
            if machine in (None, "ticket"):
                fail("C24", rel(vf), "<transition from=\"%s\" to=\"%s\"> moves a ticket outside shared/contracts.xml#ticket-transitions (cite that table, or name another machine with machine=)" % (" ".join(fr), to))


def check_operation_keys():
    """C25: operation key examples match the pattern, name their node and never repeat."""
    root, f = shared_root("C25", "contracts.xml")
    defs = contracts_defs("C25")
    if defs is None:
        return
    pattern = (defs.get("operation_key") or {}).get("pattern")
    if not pattern:
        fail("C25", "shared/contracts.schema.json", "no $defs.operation_key.pattern")
        return
    rx = re.compile(pattern)
    seen = {}
    in_contracts = 0
    for vf, vroot in parsed_volumes():
        for k in vroot.iter("op-key"):
            ex, node = k.attrib.get("example", ""), k.attrib.get("node", "")
            if os.path.abspath(vf) == os.path.abspath(f):
                in_contracts += 1
            if not ex:
                fail("C25", rel(vf), "<op-key> without example=")
                continue
            if not rx.search(ex):
                fail("C25", rel(vf), "op-key '%s' does not match $defs.operation_key" % ex)
            if ex.split("/")[0] != node:
                fail("C25", rel(vf), "op-key '%s' node segment is not @node '%s'" % (ex, node))
            if ex in seen:
                fail("C25", rel(vf), "op-key '%s' repeats (first in %s)" % (ex, seen[ex]))
            seen.setdefault(ex, rel(vf))
    if root is not None and not in_contracts:
        fail("C25", "shared/contracts.xml", "no <op-key example node/> row (operation-keys)")


def cpu_milli(v):
    v = v.strip()
    return int(round(float(v[:-1]))) if v.endswith("m") else int(round(float(v) * 1000))


MEM = {"Ki": 1.0 / 1024, "Mi": 1, "Gi": 1024, "Ti": 1024 * 1024}


def mem_mi(v):
    v = v.strip()
    for suf, mult in MEM.items():
        if v.endswith(suf):
            return float(v[:-2]) * mult
    return float(v) / (1024 * 1024)  # plain bytes


# (quota key, container attribute spellings, parser, unit); the quota key may also be spelled with a hyphen (requests-cpu)
RESOURCES = (("requests.cpu", ("cpu-request", "cpu"), cpu_milli, "m"), ("limits.cpu", ("cpu-limit",), cpu_milli, "m"),
             ("requests.memory", ("memory-request", "mem-request"), mem_mi, "Mi"),
             ("limits.memory", ("memory-limit", "mem-limit"), mem_mi, "Mi"))


def res_attr(e, names):
    """The first of the attribute spellings e carries, or None."""
    return next((e.attrib[n] for n in names if n in e.attrib), None)


def quota_attr(e, q):
    return e.attrib.get(q, e.attrib.get(q.replace(".", "-")))


def check_capacity():
    """C26: the namespace quota is recomputed from the containers, the capacity row and the canary."""
    root, f = shared_root("C26", "ci-capacity.xml")
    if root is None:
        return
    P = "shared/ci-capacity.xml"
    pods = {}
    try:
        for c in root.iter("container"):
            pods.setdefault(c.attrib.get("pod", "suite"), []).append(c)
        for c in root.iter("canary"):  # a <canary> carrying resource attributes is the canary pod's one container
            if any(res_attr(c, names) for _, names, _, _ in RESOURCES):
                pods.setdefault("canary", []).append(c)
        totals = {}
        for pod, cs in pods.items():
            t = {}
            for q, names, conv, _ in RESOURCES:
                vals = [res_attr(c, names) for c in cs]
                if any(vals):
                    t[q] = sum(conv(v) for v in vals if v)
            totals[pod] = t
        for pe in root.iter("pod"):
            name = pe.attrib.get("name")
            for q, names, conv, unit in RESOURCES:
                v = res_attr(pe, names)
                if v and name in totals and abs(conv(v) - totals[name].get(q, 0)) > 0.001:
                    fail("C26", P, "pod %s states %s %s but its containers sum to %g%s" % (name, q, v, totals[name].get(q, 0), unit))
        if "suite" not in totals:
            fail("C26", P, "no <container pod=\"suite\"> rows")
            return
        if "canary" not in totals:
            fail("C26", P, "no canary row (<container pod=\"canary\"> or <canary> with resource attributes)")
            return
        cap = root.find(".//capacity")
        if cap is None:
            fail("C26", P, "no <capacity runs-in-flight pods-per-run container-cap/>")
            return
        ccap = int(cap.attrib["container-cap"])
        if "runs-in-flight" in cap.attrib and "pods-per-run" in cap.attrib:
            want = int(cap.attrib["runs-in-flight"]) * int(cap.attrib["pods-per-run"])
            if want != ccap:
                fail("C26", P, "container-cap %d is not runs-in-flight x pods-per-run = %d" % (ccap, want))
                ccap = want
        quota = root.find(".//quota-row")
        if quota is None:
            quota = root.find(".//quota")
        if quota is None or quota_attr(quota, "pods") is None:
            fail("C26", P, "no <quota-row pods requests-cpu requests-memory limits-memory/> (or <quota> with those attributes)")
            return
        if int(quota_attr(quota, "pods")) != ccap + 1:
            fail("C26", P, "quota pods %s is not container-cap + 1 = %d" % (quota_attr(quota, "pods"), ccap + 1))
        for q, _, conv, unit in RESOURCES:
            if q not in totals["suite"]:
                continue
            want = ccap * totals["suite"][q] + totals["canary"].get(q, 0)
            v = quota_attr(quota, q)
            if v is None:
                fail("C26", P, "quota has no %s (want %g%s)" % (q, want, unit))
            elif abs(conv(v) - want) > 0.001:
                fail("C26", P, "quota %s %s is not container-cap x suite + canary = %g%s" % (q, v, want, unit))
    except (KeyError, ValueError) as e:
        fail("C26", P, "a capacity row is missing or has an unreadable value: %s" % e)


def check_retry_budget():
    """C27: retry layers form one tree, each failure has one retrying layer, the CI chain fits the pod budget."""
    root, f = shared_root("C27", "retry-budget.xml")
    if root is None:
        return
    P = "shared/retry-budget.xml"
    layers = {}
    for l in root.iter("layer"):
        i = l.attrib.get("id")
        if not i:
            fail("C27", P, "<layer> without id")
            continue
        if i in layers:
            fail("C27", P, "layer %s declared twice" % i)
        layers[i] = l
    if not layers:
        fail("C27", P, "no <layer id owner max parent retries-on/> rows")
        return
    parent, maxes = {}, {}
    for i, l in layers.items():
        p = l.attrib.get("parent", "").strip()
        parent[i] = None if p in ("", "none", "null") else p
        if parent[i] is not None and parent[i] not in layers:
            fail("C27", P, "layer %s parent '%s' is no layer" % (i, p))
            parent[i] = None
        try:
            maxes[i] = int(l.attrib["max"])
            if maxes[i] < 1:
                raise ValueError
        except (KeyError, ValueError):
            fail("C27", P, "layer %s max '%s' is not a positive integer" % (i, l.attrib.get("max")))
            maxes[i] = 1
        if not re.match(r"^N-\d\d$", l.attrib.get("owner", "")):
            fail("C27", P, "layer %s owner '%s' is not a node id" % (i, l.attrib.get("owner", "")))
    for i in layers:  # cycles
        seen, cur = set(), i
        while cur is not None and cur not in seen:
            seen.add(cur)
            cur = parent[cur]
        if cur is not None:
            fail("C27", P, "layer %s is on a parent cycle" % i)
            return
    owner_of = {}
    for i, l in layers.items():
        for fk in l.attrib.get("retries-on", "").split():
            if fk in owner_of:
                fail("C27", P, "failure %s is retried by two layers, %s and %s (only the innermost retries)" % (fk, owner_of[fk], i))
            owner_of.setdefault(fk, i)
    budgets = root.find(".//budgets")
    if budgets is None or "pods-per-unit-per-head" not in budgets.attrib:
        fail("C27", P, "no <budgets pods-per-unit-per-head=\"N\"/>")
        return
    budget = int(budgets.attrib["pods-per-unit-per-head"])
    ci = [i for i, l in layers.items() if l.attrib.get("chain") == "ci"]
    if not ci:
        fail("C27", P, "no layer carries chain=\"ci\" (the pod ladder and the plan attempts)")
        return

    def path(i):
        out = []
        while i is not None:
            out.append(i)
            i = parent[i]
        return out
    deepest = max(ci, key=lambda i: len(path(i)))
    line = path(deepest)
    off = [i for i in ci if i not in line]
    if off:
        fail("C27", P, "chain=ci layers %s are not on the parent path of %s" % (" ".join(off), deepest))
    product = 1
    for i in ci:
        product *= maxes[i]
    if product > budget:
        fail("C27", P, "CI chain %s multiplies to %d pods per unit per head, over the budget %d" % (" x ".join("%s %d" % (i, maxes[i]) for i in ci), product, budget))


def check_deadlines():
    """C28: a derived deadline is at least the sum of the deadlines it is derived from."""
    root, f = shared_root("C28", "retry-budget.xml")
    found = {}
    for vf, vroot in parsed_volumes():
        for d in vroot.iter("deadline"):
            if d.attrib.get("id"):
                found[d.attrib["id"]] = (vf, d)
    if root is not None and not any(os.path.abspath(v) == os.path.abspath(f) for v, _ in found.values()):
        fail("C28", "shared/retry-budget.xml", "no <deadline id value-seconds/> row (deadlines)")
    for i, (vf, d) in sorted(found.items()):
        try:
            v = int(d.attrib["value-seconds"])
        except (KeyError, ValueError):
            fail("C28", rel(vf), "deadline %s value-seconds '%s' is not an integer" % (i, d.attrib.get("value-seconds")))
            continue
        refs = d.attrib.get("derived-from", "").split()
        total, ok = 0, True
        for r in refs:
            if r not in found:
                fail("C28", rel(vf), "deadline %s derived-from '%s' is no <deadline id>" % (i, r))
                ok = False
                continue
            try:
                total += int(found[r][1].attrib["value-seconds"])
            except (KeyError, ValueError):
                ok = False
        if refs and ok and v < total:
            fail("C28", rel(vf), "deadline %s is %d s but the deadlines it nests (%s) sum to %d s" % (i, v, " + ".join(refs), total))


def check_dispositions():
    """C29: every review finding has one disposition with evidence, a resolving resolution and an honest proof status."""
    root, f = shared_root("C29", "review-dispositions.xml")
    if root is None:
        return
    P = "shared/review-dispositions.xml"
    ids = {}
    for fe in root.iter("finding"):
        i = fe.attrib.get("id", "")
        if not re.match(r"^F\d{2,}$", i):
            fail("C29", P, "finding id '%s' is not Fnn" % i)
            continue
        if i in ids:
            fail("C29", P, "finding %s appears twice" % i)
        ids[i] = fe
        disp = fe.attrib.get("disposition")
        if disp not in DISPOSITIONS:
            fail("C29", P, "finding %s disposition '%s' is not one of %s" % (i, disp, ", ".join(DISPOSITIONS)))
        if not any("".join(e.itertext()).strip() or e.attrib for e in fe.iter("evidence")):
            fail("C29", P, "finding %s has no <evidence>" % i)
        res = [r for r in fe.iter("resolution") if r.attrib.get("href")]
        if not res:
            fail("C29", P, "finding %s has no <resolution href=\"file#anchor\"/>" % i)
        for r in res:
            href = r.attrib["href"]
            if href.startswith("#"):
                if href[1:] not in {e.attrib.get("id") for e in root.iter()}:
                    fail("C29", P, "finding %s resolution %s: local anchor not declared" % (i, href))
                continue
            if "planned" in r.attrib or "branch" in r.attrib:
                continue
            why = resolve(f, *split_target(href))
            if why and why != "external":
                fail("C29", P, "finding %s resolution %s %s" % (i, href, why))
        proofs = list(fe.iter("proof"))
        for pr in proofs:
            if pr.attrib.get("status") not in PROOF_STATUSES:
                fail("C29", P, "finding %s proof status '%s' is not not-run or executed" % (i, pr.attrib.get("status")))
        if not proofs and disp not in ("rejected", "superseded"):
            fail("C29", P, "finding %s (%s) has no <proof status=\"not-run|executed\"/>" % (i, disp))
    for i in FINDINGS_REQUIRED:
        if i not in ids:
            fail("C29", P, "no <finding id=\"%s\">" % i)


PII = (
    ("a home directory", re.compile(r"/home/(?![<$])[A-Za-z0-9._-]+/?")),
    ("a project slug", re.compile(r"(?<![\w-])-home-[a-z][a-z0-9_.]*-")),
    ("a tailnet host", re.compile(r"\b(?:[A-Za-z0-9-]+\.)+ts\.net\b")),
    ("a .local host", re.compile(r"\b(?:[A-Za-z0-9-]+\.)+local\b(?![\w.-])")),
)
IPV4 = re.compile(r"(?<![\w.])(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})(?![\w]|\.\d)(/\d{1,2})?")
DOC_NETS = ((192, 0, 2), (198, 51, 100), (203, 0, 113))


def ipv4_ok(m):
    o = [int(x) for x in m.groups()[:4]]
    if any(x > 255 for x in o):
        return True  # not an address
    if o in ([127, 0, 0, 1], [0, 0, 0, 0]) or tuple(o[:3]) in DOC_NETS:
        return True
    if m.group(5):  # a network block: generic when the prefix is 16 or shorter and the host bits are zero
        bits = int(m.group(5)[1:])
        n = (o[0] << 24) | (o[1] << 16) | (o[2] << 8) | o[3]
        return bits <= 16 and n & ((1 << (32 - bits)) - 1) == 0
    return False


def check_pii():
    """C30: no personal data (home paths, project slugs, private host names or addresses) in the book or bin/."""
    files = set()
    for pattern in ("**/*.xml", "**/*.json", "**/*.md"):
        files |= set(glob.glob(os.path.join(BOOK, pattern), recursive=True))
    files |= {f for f in glob.glob(os.path.join(BOOK, "bin", "*")) if os.path.isfile(f)}
    for f in sorted(files):
        if "__pycache__" in f:
            continue
        with open(f, encoding="utf-8", errors="replace") as fh:
            for n, line in enumerate(fh, 1):
                for what, rx in PII:
                    for m in rx.finditer(line):
                        if what == "a .local host" and m.group(0).endswith("svc.cluster.local"):
                            continue
                        fail("C30", rel(f), "line %d has %s '%s' (use $HOME, ${HOME_SLUG} or a ${SITE_...} placeholder)" % (n, what, m.group(0)))
                for m in IPV4.finditer(line):
                    if not ipv4_ok(m):
                        fail("C30", rel(f), "line %d has an IPv4 literal '%s' (use a ${SITE_...} placeholder)" % (n, m.group(0)))


RULING_KIND = re.compile(r"^(ruling(\..*)?|.*\.ruling|owner\..*|.*(gofactory|usergo|userhalt).*)$", re.I)
OWNER_WORD_PHRASES = ("HOLD or USERGO", "HOLD or GOFACTORY")


def check_owner_words():
    """C31: a seat can never write a ruling; no text says the lamp offers an owner word; the lamp has one name."""
    root, f = shared_root("C31", "authority.xml")
    if root is not None:
        permits = list(root.iter("permit"))
        if not permits:
            fail("C31", "shared/authority.xml", "no <permit role kinds/> rows")
        for p in permits:
            if p.attrib.get("role") != "seat":
                continue
            kinds = p.attrib.get("kinds", "").split()
            kinds += [k.attrib.get("name") or "".join(k.itertext()).strip() for k in p.iter("kind")]
            for k in kinds:
                if RULING_KIND.match(k):
                    fail("C31", "shared/authority.xml", "<permit role=\"seat\"> grants ruling kind %s; a seat-produced message is never an owner word" % k)
    lamp = False
    files = volumes() + sorted(glob.glob(os.path.join(BOOK, "*.md")))
    for vf in files:
        with open(vf, encoding="utf-8") as fh:
            text = fh.read()
        lamp = lamp or re.search(r"\b[Tt]he hold lamp\b", text) is not None
        if rel(vf) == "shared/review-dispositions.xml":
            continue  # it quotes the old wording as evidence of finding it disposes
        for n, line in enumerate(text.splitlines(), 1):
            for ph in OWNER_WORD_PHRASES:
                if ph in line:
                    fail("C31", rel(vf), "line %d says '%s'; the lamp is the hold lamp and names the owner word it waits on" % (n, ph))
    if not lamp:
        fail("C31", "book", "no volume calls the lamp 'the hold lamp'")


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
    check_transitions()
    check_operation_keys()
    check_capacity()
    check_retry_budget()
    check_deadlines()
    check_dispositions()
    check_pii()
    check_owner_words()
    for check, path, detail in failures:
        print("FAIL %s %s %s" % (check, path, detail))
    if os.environ.get("COQ_CHECK_NOTES") == "1":
        for path, detail in notes:
            print("NOTE %s %s" % (path, detail))
    print("checked %d volumes with %s: %d failures, %d notes (COQ_CHECK_NOTES=1 prints them)" % (len(vols), name, len(failures), len(notes)))
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
