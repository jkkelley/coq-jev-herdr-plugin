#!/usr/bin/env python3
"""
rebuild/design/bin/check-examples.py: C22, every example in the book validates against its schema.

What broke (2026-10-14): shared/state-store.xml#envelope carried a lease.granted example that failed N-02's
record.schema.json (a string token t-000184, a lease: key prefix, no lease fields), and N-01, N-02 and N-07 each
required a different envelope. Nothing compared an example with the schema it claims to follow, so the disagreement
sat in the book until a reader tried it. Cost: one more pass over every volume and DESIGN.md, a second or two.

Examples checked:
  <example schema="path.json#/json/pointer">JSON</example>   any volume; the schema pointer is resolved from the volume's
                                                              directory, then the book root; a JSON text with no schema
                                                              attribute is a FAIL (an example nobody can check)
  DESIGN.md json blocks   a fenced json block takes the next unused record.schema.json link of the nearest prose line
                          above it that has links (one link per block, in order); validated against the schema file root

1.1.0 hardening (verification NF-E6, 2026-10-15): an example is validated against the one def it names, never the root
oneOf (best_match over a oneOf reported whichever branch came closest, so an example could pass as the wrong record); a
schema link with no pointer (DESIGN.md, or schema="file.json") picks the def named after the example's kind (lease.granted
-> #/$defs/lease_granted) and fails when there is none; an <example schema=...> whose text is not JSON fails instead of
being skipped; a missing jsonschema module is a FAIL with exit 2, never a silent pass.

C23 edge fixtures: an example proves its producer's shape, not that the consumer accepts it. In any volume,
  <edge-fixture producer="path.json#/$defs/a" consumer="path.json#/$defs/b"/>   (paths relative to that volume)
makes every example whose schema resolves to the producer def validate against the consumer def too; and
  <example schema="path.json#/$defs/a" consumers="p.json#/$defs/b q.json#/$defs/c">  does the same for one example.
A fixture whose producer has no example in the book fails (a fixture with nothing to test proves nothing), and a
consumer pointer that does not resolve fails. Output lines: FAIL C23 <file> <detail>.

Schemas resolve through their $id (every nodes/N-xx/record.schema.json and shared/*.schema.json is registered under its
own $id, and relative $refs resolve against it), so a cross-node $ref that does not line up with the $ids fails here too.
Output: one line per failure, FAIL C22|C23 <file> <detail>, then a summary line. Exit 0 pass, 1 failures, 2 cannot run.
Nothing is written. Run with python3 -I and the jsonschema module (check.sh arranges that).
"""
import glob
import json
import os
import re
import sys
import xml.etree.ElementTree as ET

BOOK = os.path.abspath(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
failures = []
checked = 0
edge_checked = 0


def fail(path, detail, check="C22"):
    failures.append((check, path, detail))


def rel(p):
    return os.path.relpath(p, BOOK)


try:
    import jsonschema
    from jsonschema import Draft202012Validator
    from referencing import Registry, Resource
    from referencing.jsonschema import DRAFT202012
except ImportError:
    print("FAIL C22 bin jsonschema with referencing is not importable; C22 and C23 cannot run (uv run --with jsonschema)")
    sys.exit(2)


def build_registry():
    reg = Registry()
    docs = {}
    for f in sorted(glob.glob(os.path.join(BOOK, "nodes", "N-*", "*.schema.json")) + glob.glob(os.path.join(BOOK, "shared", "*.schema.json"))):
        try:
            with open(f, encoding="utf-8") as fh:
                doc = json.load(fh)
        except ValueError as e:
            fail(rel(f), "schema is not JSON: %s" % e)
            continue
        docs[os.path.abspath(f)] = doc
        if "$id" not in doc:
            fail(rel(f), "schema has no $id, so relative $refs into it cannot resolve")
            continue
        reg = reg.with_resource(doc["$id"], Resource.from_contents(doc, default_specification=DRAFT202012))
    return reg, docs


def find_schema(base_dir, target):
    """target is path.json or path.json#/pointer; returns (file, pointer) or None."""
    path, _, ptr = target.partition("#")
    for root in (base_dir, BOOK, os.path.dirname(os.path.dirname(BOOK))):
        f = os.path.abspath(os.path.join(root, path))
        if os.path.isfile(f):
            return f, ptr
    return None


def pointer_node(doc, ptr):
    node = doc
    for part in [p.replace("~1", "/").replace("~0", "~") for p in ptr.split("/") if p]:
        node = node.get(part) if isinstance(node, dict) else None
        if node is None:
            return None
    return node


def pins_kind(body, kind):
    """True when a def fixes kind to this value (properties.kind const or a one-value enum, also inside allOf)."""
    if not isinstance(body, dict):
        return False
    k = body.get("properties", {}).get("kind", {})
    if isinstance(k, dict) and (k.get("const") == kind or k.get("enum") == [kind]):
        return True
    return any(pins_kind(b, kind) for b in body.get("allOf", []))


def resolve_target(docs, base_dir, target, instance, label, check="C22"):
    """(file, pointer) of the one def a target names, or None after a FAIL. A root link picks the def named after the kind."""
    hit = find_schema(base_dir, target)
    if hit is None or hit[0] not in docs:
        fail(label, "schema '%s' is not a book schema" % target, check)
        return None
    f, ptr = hit
    doc = docs[f]
    if ptr:
        if pointer_node(doc, ptr) is None:
            fail(label, "schema pointer '%s' does not resolve" % target, check)
            return None
        return f, ptr
    if any(k in doc for k in ("oneOf", "anyOf")):
        kind = instance.get("kind") if isinstance(instance, dict) else None
        name = re.sub(r"[.\-]", "_", kind) if isinstance(kind, str) else None
        if name and name in doc.get("$defs", {}):
            return f, "/$defs/" + name
        pinned = [d for d, body in doc.get("$defs", {}).items() if isinstance(kind, str) and pins_kind(body, kind)]
        if len(pinned) == 1:
            return f, "/$defs/" + pinned[0]
        fail(label, "schema '%s' is a oneOf root and no $defs entry is named after kind %r; name the def (schema=\"file.json#/$defs/name\")" % (target, kind), check)
        return None
    return f, ""


def validate_against(reg, docs, label, instance, f, ptr, check="C22", what="does not validate against"):
    doc = docs[f]
    wrapper = {"$ref": doc["$id"] + ("#" + ptr if ptr else "")}
    errors = list(Draft202012Validator(wrapper, registry=reg).iter_errors(instance))
    if errors:
        best = jsonschema.exceptions.best_match(errors)
        fail(label, "%s %s#%s: %s (at /%s)" % (what, rel(f), ptr, best.message[:200], "/".join(str(p) for p in best.absolute_path)), check)
        return False
    return True


def parse_example(label, text):
    try:
        return json.loads(text), True
    except ValueError as e:
        fail(label, "example is not JSON: %s" % e)
        return None, False


def xml_files():
    return sorted(glob.glob(os.path.join(BOOK, "*.xml")) + glob.glob(os.path.join(BOOK, "shared", "*.xml")) + glob.glob(os.path.join(BOOK, "nodes", "N-*", "*.xml")))


def collect_fixtures(docs):
    """{(producer file, pointer): [(consumer file, pointer, declared in)]} from every <edge-fixture>."""
    fixtures = {}
    for f in xml_files():
        try:
            root = ET.parse(f).getroot()
        except ET.ParseError:
            continue
        for n, e in enumerate(root.iter("edge-fixture"), 1):
            label = "%s edge-fixture %d" % (rel(f), n)
            prod, cons = e.attrib.get("producer", ""), e.attrib.get("consumer", "")
            if "#" not in prod or "#" not in cons:
                fail(label, "needs producer=\"file.json#/$defs/a\" and consumer=\"file.json#/$defs/b\"", "C23")
                continue
            ends = []
            for t in (prod, cons):
                hit = find_schema(os.path.dirname(f), t)
                if hit is None or hit[0] not in docs or pointer_node(docs[hit[0]], hit[1]) is None:
                    fail(label, "'%s' does not resolve to a def of a book schema" % t, "C23")
                    break
                ends.append(hit)
            if len(ends) == 2:
                fixtures.setdefault(ends[0], []).append((ends[1][0], ends[1][1], label))
    return fixtures


def check_xml_examples(reg, docs, fixtures):
    global checked, edge_checked
    used = set()
    for f in xml_files():
        try:
            root = ET.parse(f).getroot()
        except ET.ParseError:
            continue  # C01 reports it
        for n, e in enumerate(root.iter("example"), 1):
            text = "".join(e.itertext()).strip()
            target = e.attrib.get("schema")
            label = "%s example %d" % (rel(f), n)
            json_shaped = text.startswith(("{", "["))
            if not target:
                if json_shaped:
                    fail(label, "JSON example has no schema attribute (schema=\"path.json#/$defs/name\")")
                continue  # a prose example names no schema and is not checked
            if not json_shaped:
                fail(label, "example names schema '%s' but its text is not JSON (starts %r)" % (target, text[:30]))
                continue
            instance, ok = parse_example(label, text)
            if not ok:
                continue
            hit = resolve_target(docs, os.path.dirname(f), target, instance, label)
            if hit is None:
                continue
            checked += 1
            validate_against(reg, docs, label, instance, hit[0], hit[1])
            consumers = list(fixtures.get(hit, []))
            if hit in fixtures:
                used.add(hit)
            for t in e.attrib.get("consumers", "").split():
                c = find_schema(os.path.dirname(f), t)
                if c is None or c[0] not in docs or pointer_node(docs[c[0]], c[1]) is None:
                    fail(label, "consumer '%s' does not resolve to a def of a book schema" % t, "C23")
                    continue
                consumers.append((c[0], c[1], "consumers attribute"))
            for cf, cp, why in consumers:
                edge_checked += 1
                validate_against(reg, docs, label, instance, cf, cp, "C23",
                                 "producer example (%s#%s) is refused by consumer" % (rel(hit[0]), hit[1]) + " (" + why + ")")
    for prod, rows in sorted(fixtures.items()):
        if prod not in used:
            for _, _, label in rows:
                fail(label, "producer %s#%s has no <example> in the book, so the fixture tests nothing" % (rel(prod[0]), prod[1]), "C23")


def check_design_md(reg, docs):
    global checked
    f = os.path.join(BOOK, "DESIGN.md")
    if not os.path.exists(f):
        return
    pending = []
    block = None
    start = 0
    with open(f, encoding="utf-8") as fh:
        for ln, line in enumerate(fh, 1):
            if block is None:
                m = re.match(r"^```json\s*$", line)
                if m:
                    block, start = [], ln
                    continue
                links = re.findall(r"\]\(((?:nodes/N-[0-9]+|shared)/[\w.-]+\.schema\.json(?:#[^)]*)?)\)", line)
                if links:
                    pending = links
            elif line.startswith("```"):
                label = "DESIGN.md line %d" % start
                if not pending:
                    fail(label, "json block has no schema link above it")
                else:
                    target = pending.pop(0)
                    instance, ok = parse_example(label, "".join(block))
                    if ok:
                        hit = resolve_target(docs, BOOK, target, instance, label)
                        if hit is not None:
                            checked += 1
                            validate_against(reg, docs, label, instance, hit[0], hit[1])
                block = None
            else:
                block.append(line)


def main():
    reg, docs = build_registry()
    fixtures = collect_fixtures(docs)
    check_xml_examples(reg, docs, fixtures)
    check_design_md(reg, docs)
    for check, path, detail in failures:
        print("FAIL %s %s %s" % (check, path, detail))
    print("%d examples checked, %d edge validations, %d failures" % (checked, edge_checked, len(failures)))
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
