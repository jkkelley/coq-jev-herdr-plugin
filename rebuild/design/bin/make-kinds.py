#!/usr/bin/env python3
"""
rebuild/design/bin/make-kinds.py: generate rebuild/design/shared/record-kinds.xml, the record kinds registry, from the
status-codes section of every node volume.

What broke: shared/state-store.xml#record-kinds-registry was a hand-written list by group; it omitted most kinds the node
volumes emit (every store.* kind, dispatch.refused, seat.bundle.refused, every deploy.* and art.* kind, push.failed and
dozens more), while N-01 refuses an unregistered kind with 400 and N-43 refuses a kind not listed under its code. A
factory built from that list would refuse its own records on the first put (gap review R-03, 2026-10-14).
Why generated: the node volume that emits a kind is the only author that knows it; a second hand list drifts the day a
volume gains a kind. The rejected alternative was a check that compares the hand list with the volumes: it finds the
drift but still asks a person to type the fix. Cost: the registry changes whenever a status-codes section changes, so
the ticket that edits a status-codes section regenerates this file in the same pull request (check.sh C15 refuses drift).

Sources read: every nodes/N-xx/*.xml element whose id is status-codes or codes; children emits (code, kind) and
code (value, kind or name; when both kind and name are present, name is a status name carried by the record kind
in kind, as on the G6 screens where map.rendered is a frame.report state). A kind attribute may hold two kinds joined by "or" or a comma and a parenthetical note;
both are normalised; a code attribute may list several codes with notes in parentheses. Class: line-op from the one list in state-store.xml#record-kinds-registry, owner-surface for G5,
plan for N-33, screen for G6, record otherwise.

Usage: bin/make-kinds.py [--check]   (--check exits 1 and prints FAIL lines when the committed file differs)
"""
import glob
import os
import re
import sys
import xml.etree.ElementTree as ET

BOOK = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
TARGET = os.path.join(BOOK, "shared", "record-kinds.xml")
ISSUED = "2026-10-14T06:30:00Z"
KIND_RE = re.compile(r"^[a-z][a-z0-9_-]*(\.[a-z0-9_-]+)*$")
# The line-op class (kinds a seat may never put, 403) is read from the one list in
# shared/state-store.xml#record-kinds-registry, the statement that starts "Line-op class".


def line_ops():
    root = ET.parse(os.path.join(BOOK, "shared", "state-store.xml")).getroot()
    for rule in root.iter("store-rule"):
        if rule.attrib.get("id") != "record-kinds-registry":
            continue
        for st in rule.iter("statement"):
            text = "".join(st.itertext())
            if text.startswith("Line-op class"):
                body = text.split(":", 1)[1].split(". ")[0]
                return {t.strip() for t in body.split(",") if KIND_RE.match(t.strip())}
    return set()
GROUP_CLASS = {"G5": "owner-surface", "G6": "screen"}


def esc(s):
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace('"', "&quot;")


def split_kinds(raw):
    raw = re.sub(r"\([^)]*\)", " ", raw)
    out = []
    for part in re.split(r"\s+or\s+|,|\|", raw):
        part = part.strip()
        if KIND_RE.match(part):
            out.append(part)
    return out


def collect():
    """Return {kind: {"codes", "writers", "groups", "names": set}} and a list of (file, problem) lines."""
    kinds = {}
    problems = []
    for f in sorted(glob.glob(os.path.join(BOOK, "nodes", "N-*", "*.xml"))):
        try:
            root = ET.parse(f).getroot()
        except ET.ParseError:
            continue
        node = root.attrib.get("node") or os.path.basename(os.path.dirname(f))
        group = root.attrib.get("group", "")
        for sec in root.iter():
            if sec.attrib.get("id") not in ("status-codes", "codes"):
                continue
            for e in sec:
                if e.tag not in ("emits", "code"):
                    continue
                code = e.attrib.get("code") or e.attrib.get("value") or ""
                raw = e.attrib.get("kind") or e.attrib.get("name") or ""
                names = split_kinds(raw)
                # G6 rows carry a status name (map.rendered) and the record kind that carries it (frame.report)
                status_name = e.attrib.get("name") if e.attrib.get("kind") and e.attrib.get("name") else None
                codes = [int(c) for c in re.findall(r"\b[1-5][0-9][0-9]\b", re.sub(r"\([^)]*\)", " ", code))]
                if not codes or not names:
                    problems.append((os.path.relpath(f, BOOK), "unparsable %s row: code=%r kind=%r" % (e.tag, code, raw)))
                    continue
                for k in names:
                    d = kinds.setdefault(k, {"codes": set(), "writers": set(), "groups": set(), "names": set()})
                    d["codes"].update(codes)
                    if status_name and status_name != k:
                        d["names"].add(status_name)
                    d["writers"].add(node)
                    d["groups"].add(group)
    return kinds, problems


def klass(kind, d, ops):
    if kind in ops:
        return "line-op"
    if d["writers"] == {"N-33"}:
        return "plan"
    for g in sorted(d["groups"]):
        if g in GROUP_CLASS:
            return GROUP_CLASS[g]
    return "record"


def render(kinds):
    ops = line_ops()
    L = []
    a = L.append
    a('<?xml version="1.0" encoding="UTF-8"?>')
    a("<!-- GENERATED by rebuild/design/bin/make-kinds.py from the status-codes section of every node volume; edit the")
    a("     node volume that emits the kind, then regenerate. The record kinds registry N-43 loads with the code table and")
    a("     N-01 validates every put against. Validated by rebuild/design/check.sh (C02 xsd, C15 freshness, C18 codes). -->")
    a('<volume id="record-kinds" kind="shared" version="1.0.0" issued="%s" timezone="UTC" title="Record kinds registry (generated)">' % ISSUED)
    a("")
    a('  <contents id="contents">')
    a('    <entry ref="pointers">Pointers: parent, siblings, the generator</entry>')
    a('    <entry ref="purpose">Purpose and how a kind is added</entry>')
    a('    <entry ref="kinds">Every record kind: codes, writer nodes, class, schema</entry>')
    a('    <entry ref="many-agents">Many agents at once</entry>')
    a("  </contents>")
    a("")
    a('  <pointers id="pointers">')
    a('    <parent href="../index.xml#shared"/>')
    a('    <sibling href="state-store.xml#record-kinds-registry" kind="shared">The store rule this registry implements</sibling>')
    a('    <sibling href="status-codes.xml#codes" kind="shared">The code map whose emitter rows name the same kinds</sibling>')
    a('    <shared href="../bin/make-kinds.py" role="generator">The generator; --check is check.sh C15</shared>')
    a('    <shared href="../nodes/N-43/spec.xml#N-43" role="loader">N-43 loads this registry with the code table</shared>')
    a("  </pointers>")
    a("")
    a('  <purpose id="purpose">')
    a("    <s>One row per record kind any node volume emits: the codes it may carry, the nodes that write it, its class and the schema of its first writer; N-01 refuses a put of a kind not here (400) and N-43 refuses a kind under a code not listed for it.</s>")
    a("    <s>Class line-op is refused 403 from a seat (seat-contract.xml#line-ops); owner-surface, plan and screen set the retention class N-45 applies (state-store.xml#retention); record is everything else.</s>")
    a("    <s>A kind is added by the ticket that adds it to its node volume's status-codes section and regenerates this file in the same pull request; nobody edits this file by hand.</s>")
    a("    <s>Panel bindings may also name a view (nodes/N-31/spec.xml#views) or a static kind (nodes/N-37/spec.xml#mechanism); those are not records and are not listed here.</s>")
    a("  </purpose>")
    a("")
    a('  <kinds id="kinds" count="%d">' % len(kinds))
    for k in sorted(kinds):
        d = kinds[k]
        writers = sorted(d["writers"])
        names = (' status-names="%s"' % " ".join(sorted(d["names"]))) if d["names"] else ""
        a('    <record-kind name="%s" codes="%s" writers="%s" class="%s"%s schema="nodes/%s/record.schema.json"/>' % (
            esc(k), " ".join(str(c) for c in sorted(d["codes"])), " ".join(writers), klass(k, d, ops), names, writers[0]))
    a("  </kinds>")
    a("")
    a('  <many-agents id="many-agents">')
    a("    <readers>N-01, N-43, N-37 and every author read this file by kind name; it is stateless and generated, so any number read it at once.</readers>")
    a("    <writers>Only the generator writes it; two tickets adding kinds in two node volumes each regenerate it, and the second to merge re-runs the generator on rebase (the same rule as index.xml), so no merge conflict is resolved by hand.</writers>")
    a("    <collision>A kind emitted by two nodes is one row with both writers; a kind emitted under two codes is one row with both codes; a node that emits a kind under a code the code map does not name for it fails check.sh C18 before N-43 ever loads it.</collision>")
    a("  </many-agents>")
    a("</volume>")
    return "\n".join(L) + "\n"


def main():
    kinds, problems = collect()
    text = render(kinds)
    rc = 0
    for f, p in problems:
        print("FAIL C15 %s %s" % (f, p))
        rc = 1
    if "--check" in sys.argv:
        current = open(TARGET, encoding="utf-8").read() if os.path.exists(TARGET) else ""
        if current != text:
            print("FAIL C15 shared/record-kinds.xml is stale; run rebuild/design/bin/make-kinds.py")
            rc = 1
        return rc
    with open(TARGET, "w", encoding="utf-8") as fh:
        fh.write(text)
    print("wrote %s (%d kinds)" % (os.path.relpath(TARGET, BOOK), len(kinds)))
    return rc


if __name__ == "__main__":
    sys.exit(main())
