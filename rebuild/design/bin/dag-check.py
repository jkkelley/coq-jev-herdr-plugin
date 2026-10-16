#!/usr/bin/env python3
"""
rebuild/design/bin/dag-check.py: check that dag.md agrees with itself and is acyclic.

What broke: dag.md section 6 and N-46 C15 named this script as the generator and checker of the DAG, and it did not
exist (gap review R-03, 2026-10-14), so the Mermaid block, the node table and the cycle statement could drift apart with
nothing to say so; three tickets cut from three of them would disagree about which node feeds which.
Why a checker over dag.md and not a generator from a separate data file: the Mermaid block and the tables are already
the data every reader and make-index.py use; a second data file would be one more copy to keep in step. The rejected
alternative was a JSON node file rendered into dag.md: it is cleaner in theory but doubles the files a DAG ticket
touches. Cost: a person edits the Mermaid block and the table by hand in one ticket, and this check refuses any
disagreement, any cycle and any stale count before the book can merge.

Checks (each failure is one line "FAIL C16 dag.md <detail>"):
  - the Mermaid node declarations, the section 3 table and the section 5 group table name the same node set;
  - every edge names a declared node or the sink RE; no node is isolated;
  - Kahn's algorithm over the drawn edges orders every node (the graph is acyclic);
  - section 6 states the true node, edge (edges into the sink RE are not counted) and re-entry counts, and its topological order is a valid order of all nodes;
  - every re-entry row of section 4 enters at a declared node;
  - C16-edges (1.1.0, verification NF-E6: 35 edges node specs declared were missing from dag.md and nothing compared
    them): every edge a node spec declares is drawn in the Mermaid block or is a section 4 re-entry (source row, any node
    named in its "Enters at" cell), unless the declaring element carries drawn="false"; and every drawn edge A --> B is
    declared by A (an out) or by B (an in). Failures print as "FAIL C16-edges <spec file> <detail>".

Edge declarations read from nodes/N-xx/*.xml, inside an element named edges or dag or carrying id="edges":
  <in from="N-07" .../>  <out to="N-13" .../>              the other node is the first N-xx in from (in) or to (out)
  <in node="N-43" .../>  <out node="N-38" .../>            the other node is @node
  <in ref="../N-05/spec.xml#N-05"/>                         the other node is the N-xx in @ref
  <edge dir="in" from="../N-07/spec.xml#N-07"/>  <edge dir="out" to="../N-15/spec.xml#N-15"/>
A row naming no node (from="any node", ref="../../dag.md#2-the-dag", kind="source" with no node) is not an edge.

Usage: bin/dag-check.py [--check]   (the flag is accepted for symmetry with the other generators; the script only checks)
"""
import glob
import os
import re
import sys
import xml.etree.ElementTree as ET

BOOK = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
DAG = os.path.join(BOOK, "dag.md")


def section(text, number):
    m = re.search(r"^## %d\. .*?$(.*?)(?=^## \d+\. |\Z)" % number, text, re.M | re.S)
    return m.group(1) if m else ""


NID = re.compile(r"N-\d\d")


def spec_edges():
    """{(a, b): [(file, drawn)]} for every edge a node volume declares."""
    out = {}
    for f in sorted(glob.glob(os.path.join(BOOK, "nodes", "N-*", "*.xml"))):
        me = os.path.basename(os.path.dirname(f))
        try:
            root = ET.parse(f).getroot()
        except ET.ParseError:
            continue  # C01 reports it
        for box in root.iter():
            if not (box.tag in ("edges", "dag") or box.attrib.get("id") == "edges"):
                continue
            for e in box:
                d = e.attrib.get("dir") if e.tag == "edge" else e.tag
                if d not in ("in", "out"):
                    continue
                other = None
                for attr in (("from" if d == "in" else "to"), "node", "ref"):
                    v = e.attrib.get(attr)
                    if v:
                        m = NID.search(v)
                        other = m.group(0) if m else None
                        break
                if other is None or other == me:
                    continue
                key = (other, me) if d == "in" else (me, other)
                out.setdefault(key, []).append((os.path.relpath(f, BOOK), e.attrib.get("drawn") != "false", e.attrib.get("record", "")))
    return out


def edge_fails(edges, re_rows, nodes):
    """C16-edges: dag.md and the node specs declare the same edges."""
    drawn = {(a, b) for a, b in edges if a != "RE" and b != "RE"}
    reentry = {(src, t) for src, enters in re_rows for t in NID.findall(enters)}
    declared = spec_edges()
    lines = []
    for (a, b), rows in sorted(declared.items()):
        if (a, b) in drawn or (a, b) in reentry:
            continue
        for f, is_drawn, record in rows:
            if is_drawn:
                lines.append((f, "declares edge %s --> %s%s that dag.md does not draw and section 4 does not list; draw it or mark the element drawn=\"false\"" % (a, b, " (" + record + ")" if record else "")))
    for a, b in sorted(drawn):
        if (a, b) not in declared and a in nodes and b in nodes:
            lines.append(("dag.md", "edge %s --> %s is declared by neither nodes/%s (an out) nor nodes/%s (an in)" % (a, b, a, b)))
    return lines


def main():
    text = open(DAG, encoding="utf-8").read()
    fails = []
    mer = re.search(r"```mermaid\n(.*?)```", text, re.S)
    if not mer:
        print("FAIL C16 dag.md no mermaid block")
        return 1
    body = mer.group(1)
    declared = set(re.findall(r"^\s*(N-\d\d)\[", body, re.M))
    edges = re.findall(r"^\s*(N-\d\d|RE) --> (N-\d\d|RE)\s*$", body, re.M)
    table = set(re.findall(r"^\| (N-\d\d) \|", section(text, 3), re.M))
    groups = set(re.findall(r"N-\d\d", section(text, 5)))
    for name, s in (("section 3 table", table), ("section 5 groups", groups)):
        for n in sorted(declared - s):
            fails.append("%s is in the Mermaid block but not in the %s" % (n, name))
        for n in sorted(s - declared):
            fails.append("%s is in the %s but not in the Mermaid block" % (n, name))
    nodes = declared
    touched = set()
    for a, b in edges:
        for x in (a, b):
            if x != "RE" and x not in nodes:
                fails.append("edge %s --> %s names an undeclared node %s" % (a, b, x))
        touched.update((a, b))
    for n in sorted(nodes - touched):
        fails.append("%s is isolated (no edge in or out)" % n)
    # Kahn
    real = [(a, b) for a, b in edges if a != "RE" and b != "RE"]
    indeg = {n: 0 for n in nodes}
    out = {n: [] for n in nodes}
    for a, b in real:
        if a in nodes and b in nodes:
            indeg[b] += 1
            out[a].append(b)
    queue = sorted(n for n in nodes if indeg[n] == 0)
    order = []
    while queue:
        n = queue.pop(0)
        order.append(n)
        for m in out[n]:
            indeg[m] -= 1
            if indeg[m] == 0:
                queue.append(m)
    if len(order) != len(nodes):
        fails.append("cycle: nodes not ordered by Kahn's algorithm: %s" % " ".join(sorted(set(nodes) - set(order))))
    # section 4 re-entries
    re_rows = re.findall(r"^\| (N-\d\d) \| [^|]+\| ([^|]+)\|", section(text, 4), re.M)
    for src, enters in re_rows:
        targets = re.findall(r"N-\d\d", enters)
        if not targets:
            fails.append("re-entry row from %s names no entry node" % src)
        for t in targets:
            if t not in nodes:
                fails.append("re-entry row from %s enters at undeclared %s" % (src, t))
    # section 6 statement
    s6 = section(text, 6)
    m = re.search(r"Nodes: (\d+)\. Drawn edges: (\d+)\. Re-entries \(not edges\): (\d+)\.", s6)
    if not m:
        fails.append("section 6 has no 'Nodes: N. Drawn edges: E. Re-entries (not edges): R.' line")
    else:
        want = (len(nodes), len(real), len(re_rows))
        got = tuple(int(x) for x in m.groups())
        if got != want:
            fails.append("section 6 states nodes, edges, re-entries %s but the DAG has %s" % (got, want))
    t = re.search(r"Topological order: ([N0-9\- ]+)\.", s6)
    if not t:
        fails.append("section 6 has no topological order line")
    else:
        stated = t.group(1).split()
        if sorted(stated) != sorted(nodes):
            fails.append("section 6 topological order does not list every node exactly once")
        else:
            pos = {n: i for i, n in enumerate(stated)}
            for a, b in real:
                if a in pos and b in pos and pos[a] > pos[b]:
                    fails.append("section 6 topological order puts %s after %s, against edge %s --> %s" % (a, b, a, b))
    efails = edge_fails(edges, re_rows, nodes)
    for f in fails:
        print("FAIL C16 dag.md %s" % f)
    for f, detail in efails:
        print("FAIL C16-edges %s %s" % (f, detail))
    return 1 if fails or efails else 0


if __name__ == "__main__":
    sys.exit(main())
