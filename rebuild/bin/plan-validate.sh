#!/usr/bin/env bash
# Validate rebuild/factory-rebuild-plan.xml against rebuild/schema/factory-rebuild-plan.xsd, then run the checks XSD 1.0 cannot express.
# Why this exists: the owner ordered "Specs are XML", and the rail reads only this file, so a malformed plan must stop the build before it reaches the page.
# Which validator: xmllint when installed; on 2026-10-14 this machine has no xmllint, no lxml and no xmlschema, so the fallback is the python
# package xmlschema in a venv under the state directory (outside the repo, rebuilt on demand, 3 install attempts). The README records which one ran.
# Rejected: skipping the XSD and checking in python alone, because the XSD is the contract other tools will read.
# Usage: plan-validate.sh [plan.xml]      exit 0 clean, exit 1 any error, exit 2 the validator could not be set up.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
xml="${1:-$here/../factory-rebuild-plan.xml}"
xsd="$here/../schema/factory-rebuild-plan.xsd"
venv="${COQ_REBUILD_VENV:-$HOME/.local/state/coq/coq-jev-herdr-plugin/rebuild/venv}"
[ -f "$xml" ] || { echo "plan-validate: no such file $xml" >&2; exit 2; }

if command -v xmllint >/dev/null 2>&1; then
  validator="xmllint"
  xmllint --noout --schema "$xsd" "$xml" || { echo "plan-validate: XSD validation failed" >&2; exit 1; }
else
  validator="python xmlschema ($venv)"
  if ! "$venv/bin/python" -c 'import xmlschema' >/dev/null 2>&1; then
    ok=0
    for attempt in 1 2 3; do
      python3 -m venv "$venv" && "$venv/bin/pip" install -q xmlschema && ok=1 && break
      echo "plan-validate: validator install attempt $attempt failed" >&2
    done
    [ "$ok" = 1 ] || { echo "plan-validate: could not set up xmlschema after 3 attempts" >&2; exit 2; }
  fi
  "$venv/bin/python" - "$xsd" "$xml" <<'PY' || { echo "plan-validate: XSD validation failed" >&2; exit 1; }
import sys, xmlschema
schema = xmlschema.XMLSchema(sys.argv[1])
errors = list(schema.iter_errors(sys.argv[2]))
for e in errors:
    print(f"{sys.argv[2]}:{getattr(e, 'sourceline', '?')}: {e.reason}", file=sys.stderr)
sys.exit(1 if errors else 0)
PY
fi

python3 - "$xml" <<'PY' || { echo "plan-validate: semantic checks failed" >&2; exit 1; }
import re, sys
import xml.etree.ElementTree as ET
path = sys.argv[1]
raw = open(path, encoding="utf-8").read()
errs = []
if "—" in raw:
    errs.append("the em dash character appears in the file")
lines = raw.count("\n") + (0 if raw.endswith("\n") else 1)
if lines > 1000:
    errs.append(f"{lines} lines, limit 1000")
root = ET.fromstring(raw)
tops = [c for c in root]
top_ids = [c.get("id") for c in tops]
contents = [e.get("ref") for e in root.find("contents").findall("entry")]
if contents != top_ids[1:]:
    errs.append(f"contents refs {contents} do not match the top-level sections after contents {top_ids[1:]}")
if top_ids != [c.get("id") for c in tops] or tops[0].tag != "contents":
    errs.append("contents must be the first section")
steps = root.find("steps").findall("step")
ids = [s.get("id") for s in steps]
want = [f"R-{i:02d}" for i in range(1, len(ids) + 1)]
if ids != want:
    errs.append(f"step ids {ids} are not consecutive from R-01")
case_ids = {c.get("id") for c in root.find("failure-cases").findall("case")}
for i, s in enumerate(steps):
    for on in s.find("depends-on").findall("on"):
        if on.get("ref") not in ids[:i]:
            errs.append(f"{s.get('id')} depends on {on.get('ref')}, which is not an earlier step")
    for c in s.find("failure").findall("case"):
        if c.get("ref") not in case_ids:
            errs.append(f"{s.get('id')} failure case ref {c.get('ref')} is not a failure-cases id")
    st = s.find("status")
    has_reason = st.find("reason") is not None
    if st.get("value") == "blocked" and not has_reason:
        errs.append(f"{s.get('id')} is blocked with no reason")
    if st.get("value") != "blocked" and has_reason:
        errs.append(f"{s.get('id')} has a reason but is not blocked")
for e in errs:
    print("plan-validate: " + e, file=sys.stderr)
sys.exit(1 if errs else 0)
PY
echo "plan-validate: OK ($validator) $xml"
