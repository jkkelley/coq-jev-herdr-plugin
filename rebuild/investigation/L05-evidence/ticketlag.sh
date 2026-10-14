#!/usr/bin/env bash
# ticketlag.sh - does a ticket's status on main lag the merge of its implementing commit? Read-only.
# Usage: ticketlag.sh [CLONE]   (a clone at origin/main)
# For every ticket file under work-orders/ (archive included) it prints: id, status, location (live|archive), count of commits on main whose
# subject starts with the id, and of those how many are "implementing" = touch at least one path outside work-orders/ and changelog/.
# Lag = status is ready, draft or in-progress while implementing >= 1. Output TSV on stdout, then a summary on stderr.
CLONE=${1:-/home/luna/.local/state/coq/coq-jev-herdr-plugin/rebuild/2026/10/investigation/clones/coq}; export TZ=UTC
cd "$CLONE" || exit 4
TL=$(mktemp); git log --format='%H %s' origin/main > "$TL" 2>/dev/null || exit 4
python3 -I - "$CLONE" "$TL" <<'PY'
import sys, re, json, glob, subprocess, collections
clone, logf = sys.argv[1], sys.argv[2]
commits = [l.rstrip("\n").split(" ", 1) for l in open(logf)]
byid = collections.defaultdict(list)
for h, s in commits:
    for i in set(re.findall(r"WO-\d{8}-[0-9a-f]{4}", s.split(" - ")[0] if " - " in s else s)):
        byid[i].append(h)
def impl(h):
    out = subprocess.run(["git", "-C", clone, "show", "--name-only", "--format=", h], capture_output=True, text=True).stdout.split()
    return any(not re.match(r"^(work-orders|changelog)/", p) for p in out)
rows = []
for f in sorted(glob.glob(clone + "/work-orders/**/WO-*.md", recursive=True)):
    t = open(f).read(); m = re.match(r"---\n(.*?)\n---", t, re.S)
    if not m: continue
    try: d = json.loads(m.group(1))
    except Exception: continue
    i = d["id"]; loc = "archive" if "/archive/" in f else "live"
    hs = byid.get(i, []); n_impl = sum(1 for h in hs if impl(h))
    rows.append((i, d["status"], loc, len(hs), n_impl, d.get("parent") or "-", d["title"][:80]))
for r in rows: print("\t".join(map(str, r)))
c = collections.Counter()
for r in rows:
    c[("status", r[1])] += 1
    if r[1] in ("ready", "draft", "in-progress") and r[4] >= 1: c["LAG: not-done status with an implementing commit"] += 1
    if r[1] == "done" and r[2] == "live": c["done but not archived"] += 1
    if r[1] in ("ready", "draft", "in-progress") and r[4] == 0 and r[3] >= 1: c["not-done, only cut/housekeeping commits"] += 1
    if r[1] in ("ready", "draft", "in-progress") and r[3] == 0: c["not-done, no commit names it"] += 1
for k, v in sorted(c.items(), key=str): print(k, v, file=sys.stderr)
print("tickets parsed:", len(rows), file=sys.stderr)
PY
rm -f "$TL"
