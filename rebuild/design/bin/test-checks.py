#!/usr/bin/env python3
"""
rebuild/design/bin/test-checks.py: prove that every check of check.sh fires, by running it on mutated copies of the book.

What broke: N-46's checklist asked for one failing fixture per check under rebuild/design/tests/fixtures, and none
existed (gap review R-03, 2026-10-14), so a check that silently stopped firing would pass every book forever.
Why mutations and not committed fixtures: a committed broken volume goes stale the day the XSD or a neighbour changes,
and it would sit in the tree check.sh walks; a mutation is applied to a fresh temporary copy at run time, so it always
tests today's book. Rejected: one fixture directory per check (fifty broken files to keep in step by hand). Cost: one
copy of the book per check in a temporary directory (a few megabytes each), removed at exit; nothing is written under
the repository or the state root.

How: for each check id, copy rebuild/design into a temporary tree whose other top-level entries are symlinks to the real
repository (so repository pointers still resolve), apply the mutation, optionally regenerate the generated files so only
the targeted check fires, run the copy's check.sh, and assert the check id is among the FAIL lines. A first run on an
unmutated copy must pass with zero failures.

Usage: bin/test-checks.py [CHECK_ID ...]   exit 0 when every check fired, 1 otherwise, 2 when the baseline fails
"""
import os
import re
import shutil
import subprocess
import sys
import tempfile

BOOK = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
REPO = os.path.abspath(os.path.join(BOOK, "..", ".."))


def sub(path, old, new, count=1):
    with open(path, encoding="utf-8") as fh:
        s = fh.read()
    if old not in s:
        raise SystemExit("mutation anchor not found in %s: %r" % (path, old[:60]))
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(s.replace(old, new, count))


def resub(path, pattern, new):
    with open(path, encoding="utf-8") as fh:
        s = fh.read()
    s2, n = re.subn(pattern, new, s, count=1, flags=re.S)
    if n != 1:
        raise SystemExit("mutation pattern not found in %s: %r" % (path, pattern[:60]))
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(s2)


def append(path, text):
    with open(path, "a", encoding="utf-8") as fh:
        fh.write(text)


EM = chr(0x2014)
# (check id, mutation(book), regenerate generated files after the mutation)
MUTATIONS = [
    ("C01", lambda b: append(os.path.join(b, "nodes/N-01/spec.xml"), "<broken\n"), False),
    ("C02", lambda b: sub(os.path.join(b, "shared/command-center.xml"), 'timezone="UTC"', 'timezone="CET"'), False),
    ("C03", lambda b: append(os.path.join(b, "nodes/N-02/spec.xml"), "<!-- padding -->\n" * 1000), False),
    ("C04", lambda b: sub(os.path.join(b, "shared/command-center.xml"), '<entry ref="purpose">', '<entry ref="no-such-id">'), False),
    ("C05", lambda b: sub(os.path.join(b, "shared/command-center.xml"), '<parent href="../index.xml#shared"/>', '<note-to-self/>'), False),
    ("C06", lambda b: sub(os.path.join(b, "shared/command-center.xml"), 'href="status-codes.xml#lamp"', 'href="status-codes.xml#no-such-anchor"'), False),
    ("C07", lambda b: resub(os.path.join(b, "shared/command-center.xml"), r'<many-agents id="many-agents">.*?</many-agents>', '<many-agents id="many-agents"></many-agents>'), False),
    ("C08", lambda b: sub(os.path.join(b, "dag.md"), "# Factory rebuild design - the DAG", "# Factory rebuild design %s the DAG" % EM), False),
    ("C09", lambda b: sub(os.path.join(b, "shared/command-center.xml"), '<screens id="screens">', '<screens id="purpose">'), False),
    ("C10", lambda b: sub(os.path.join(b, "shared/cleanup-registry.schema.json"), "2020-12", "2019-09"), False),
    ("C11", lambda b: resub(os.path.join(b, "index.xml"), r'(nodes/N-01/spec.xml#N-01" kind="node-spec" lines=")(\d+)', r'\g<1>1'), False),
    ("C12", lambda b: sub(os.path.join(b, "nodes/N-01/spec.xml"), 'node="N-01" group="G1"', 'node="N-02" group="G1"'), False),
    ("C13", lambda b: sub(os.path.join(b, "nodes/N-01/spec.xml"), ' fallback="503 store.busy to the caller; the caller retries per retries; no row is written"', ""), False),
    ("C14", lambda b: sub(os.path.join(b, "nodes/N-45/spec.xml"), 'cleanup="line/bin/cleanup.sh --entry N-45.log"', 'cleanup=""'), False),
    ("C15", lambda b: sub(os.path.join(b, "nodes/N-01/spec.xml"), '<emits code="100" kind="store.opened"', '<emits code="100" kind="store.mutated"/>\n    <emits code="100" kind="store.opened"'), False),
    ("C16", lambda b: sub(os.path.join(b, "dag.md"), "Nodes: 52.", "Nodes: 51."), False),
    ("C17", lambda b: sub(os.path.join(b, "index.xml"), "Read one volume at a time", "Read every volume at once"), False),
    ("C18", lambda b: sub(os.path.join(b, "nodes/N-01/spec.xml"), '<emits code="100" kind="store.opened"', '<emits code="100" kind="store.mutated"/>\n    <emits code="100" kind="store.opened"'), True),
    ("C19", lambda b: sub(os.path.join(b, "nodes/N-01/spec.xml"), '<output id="output">', '<output id="outputs">'), False),
    ("C20", lambda b: sub(os.path.join(b, "nodes/N-38/spec.xml"), '<panel id="map.canvas" kind="map.state"', '<panel id="map.canvas" kind="no.such.kind"'), False),
    ("C21", lambda b: sub(os.path.join(b, "nodes/N-24/spec.xml"), 'rebuild/investigation/02-MAPPING.md#2-validated-keep">V04 pod', 'rebuild/investigation/02-MAPPING.md#v04">V04 pod'), False),
    ("C22", lambda b: sub(os.path.join(b, "shared/state-store.xml"), '"token":184', '"token":"t-000184"'), False),
    ("C21-prose", lambda b: sub(os.path.join(b, "nodes/N-19/spec.xml"), '02-MAPPING.md#2-validated-keep V15', '02-MAPPING.md#no-such-heading V15'), False),
]


def make_copy(tmp):
    """A tree whose rebuild/design is a real copy and whose every other entry is a symlink into the repository."""
    root = os.path.join(tmp, "repo")
    os.makedirs(os.path.join(root, "rebuild"))
    for name in os.listdir(REPO):
        if name != "rebuild":
            os.symlink(os.path.join(REPO, name), os.path.join(root, name))
    for name in os.listdir(os.path.join(REPO, "rebuild")):
        if name != "design":
            os.symlink(os.path.join(REPO, "rebuild", name), os.path.join(root, "rebuild", name))
    book = os.path.join(root, "rebuild", "design")
    shutil.copytree(BOOK, book, ignore=shutil.ignore_patterns("__pycache__"))
    return book


def run(book, regen):
    if regen:
        for script in ("make-kinds.py", "registry.py", "make-index.py"):
            subprocess.run([sys.executable, "-I", os.path.join(book, "bin", script)], capture_output=True)
    r = subprocess.run([os.path.join(book, "check.sh")], capture_output=True, text=True)
    return {l.split()[1] for l in r.stdout.splitlines() if l.startswith("FAIL ")}, r


def main():
    wanted = set(sys.argv[1:])
    with tempfile.TemporaryDirectory(prefix="spec-book-checks-") as tmp:
        base = os.path.join(tmp, "base")
        os.makedirs(base)
        fired, r = run(make_copy(base), False)
        if fired:
            print("BASELINE FAIL: the unmutated book fails %s" % " ".join(sorted(fired)))
            print(r.stdout[-2000:])
            return 2
        missed = []
        for cid, mutate, regen in MUTATIONS:
            if wanted and cid.split("-")[0] not in wanted:
                continue
            d = os.path.join(tmp, cid)
            os.makedirs(d)
            book = make_copy(d)
            mutate(book)
            fired, _ = run(book, regen)
            if cid.split("-")[0] in fired:
                print("PASS %s fired (with %s)" % (cid, " ".join(sorted(fired - {cid})) or "nothing else"))
            else:
                print("MISS %s did not fire (fired: %s)" % (cid, " ".join(sorted(fired)) or "nothing"))
                missed.append(cid)
            shutil.rmtree(d)
    print("%d checks proven, %d missed" % (len([m for m in MUTATIONS if not wanted or m[0].split("-")[0] in wanted]) - len(missed), len(missed)))
    return 1 if missed else 0


if __name__ == "__main__":
    sys.exit(main())
