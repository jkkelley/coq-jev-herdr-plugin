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

Schemas resolve through their $id (every nodes/N-xx/record.schema.json and shared/*.schema.json is registered under its
own $id, and relative $refs resolve against it), so a cross-node $ref that does not line up with the $ids fails here too.
Output: one line per failure, FAIL C22 <file> <detail>, then a summary line. Exit 0 pass, 1 failures, 2 cannot run.
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


def fail(path, detail):
    failures.append((path, detail))


def rel(p):
    return os.path.relpath(p, BOOK)


try:
    import jsonschema
    from jsonschema import Draft202012Validator
    from referencing import Registry, Resource
    from referencing.jsonschema import DRAFT202012
except ImportError:
    print("FAIL C22 bin jsonschema with referencing is not importable")
    sys.exit(2)


def build_registry():
    reg = Registry()
    docs = {}
    for f in sorted(glob.glob(os.path.join(BOOK, "nodes", "N-*", "*.schema.json")) + glob.glob(os.path.join(BOOK, "shared", "*.schema.json"))):
        with open(f, encoding="utf-8") as fh:
            doc = json.load(fh)
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


def validate(reg, docs, label, text, base_dir, target):
    global checked
    try:
        instance = json.loads(text)
    except ValueError as e:
        fail(label, "example is not JSON: %s" % e)
        return
    hit = find_schema(base_dir, target)
    if hit is None or hit[0] not in docs:
        fail(label, "schema '%s' is not a book schema" % target)
        return
    f, ptr = hit
    doc = docs[f]
    node = doc
    for part in [p.replace("~1", "/").replace("~0", "~") for p in ptr.split("/") if p]:
        node = node.get(part) if isinstance(node, dict) else None
        if node is None:
            fail(label, "schema pointer '%s' does not resolve" % target)
            return
    wrapper = {"$ref": doc["$id"] + ("#" + ptr if ptr else "")}
    best = jsonschema.exceptions.best_match(Draft202012Validator(wrapper, registry=reg).iter_errors(instance))
    checked += 1
    if best is not None:
        # a oneOf root reports every branch; best_match picks the branch the instance came closest to
        fail(label, "does not validate against %s: %s (at /%s)" % (target, best.message[:200], "/".join(str(p) for p in best.absolute_path)))


def check_xml_examples(reg, docs):
    for f in sorted(glob.glob(os.path.join(BOOK, "shared", "*.xml")) + glob.glob(os.path.join(BOOK, "nodes", "N-*", "*.xml"))):
        try:
            root = ET.parse(f).getroot()
        except ET.ParseError:
            continue  # C01 reports it
        for n, e in enumerate(root.iter("example"), 1):
            text = "".join(e.itertext()).strip()
            if not text.startswith(("{", "[")):
                continue
            label = "%s example %d" % (rel(f), n)
            target = e.attrib.get("schema")
            if not target:
                fail(label, "JSON example has no schema attribute (schema=\"path.json#/$defs/name\")")
                continue
            validate(reg, docs, label, text, os.path.dirname(f), target)


def check_design_md(reg, docs):
    f = os.path.join(BOOK, "DESIGN.md")
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
                links = re.findall(r"\]\((nodes/N-[0-9]+/record\.schema\.json)\)", line)
                if links:
                    pending = links
            elif line.startswith("```"):
                label = "DESIGN.md line %d" % start
                if not pending:
                    fail(label, "json block has no record.schema.json link above it")
                else:
                    validate(reg, docs, label, "".join(block), BOOK, pending.pop(0))
                block = None
            else:
                block.append(line)


def main():
    reg, docs = build_registry()
    check_xml_examples(reg, docs)
    check_design_md(reg, docs)
    for path, detail in failures:
        print("FAIL C22 %s %s" % (path, detail))
    print("%d examples checked, %d failures" % (checked, len(failures)))
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
