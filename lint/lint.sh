#!/usr/bin/env bash
# lint.sh - every static check the repo has, in one container, fast. Runs inside
# the lint image with the repo mounted read-only at /repo. Each check is a pure
# function of the tree: no network, no state. CI runs all of it on every PR;
# locally `make lint` runs the same thing (DEC-local-fast-ci-full).
set -euo pipefail
R=${1:-/repo}; FAIL=0
step() { printf '%-40s' "$1"; }
step "specs: well-formed + schema"; if xmllint --noout --schema "$R/specs/schema/spec.xsd" "$R"/specs/SPEC-*.xml 2>/tmp/x; then echo ok; else echo FAIL; cat /tmp/x >&2; FAIL=1; fi
step "specs: under 1000 lines"; big=$(wc -l "$R"/specs/SPEC-*.xml | awk '$1>=1000 && $2!="total"{print $2}'); if [ -z "$big" ]; then echo ok; else echo "FAIL $big"; FAIL=1; fi
step "specs: no em dash"; if grep -l $'\xe2\x80\x94' "$R"/specs/SPEC-*.xml "$R"/*.md "$R"/tools/*/AGENTS.md 2>/dev/null; then echo FAIL; FAIL=1; else echo ok; fi
step "specs: pointers resolve"; if python3 - "$R" <<'PY'
import sys,glob,os,xml.etree.ElementTree as ET
root=sys.argv[1]; specs={}; bad=0
for p in glob.glob(root+"/specs/SPEC-*.xml"):
    t=ET.parse(p).getroot(); specs[t.get("id")]={s.get("id") for s in t.iter("section")}
nodes={os.path.basename(f)[:-5] for f in glob.glob(root+"/graph/nodes/*.json")}
for p in glob.glob(root+"/specs/SPEC-*.xml"):
    for r in ET.parse(p).getroot().iter("ref"):
        sp,an,nd=r.get("spec"),r.get("anchor"),r.get("node")
        if sp and sp not in specs: print(f"{p}: ref to missing spec {sp}"); bad=1
        elif sp and an and an not in specs[sp]: print(f"{p}: ref to missing anchor {sp}#{an}"); bad=1
        if nd and nd not in nodes: print(f"{p}: ref to missing node {nd}"); bad=1
sys.exit(bad)
PY
then echo ok; else echo FAIL; FAIL=1; fi
step "graph: check + specs agree"; if (cd "$R/graph" && bin/graph.sh check >/dev/null && bin/graph.sh sync-specs "$R/specs" >/dev/null); then echo ok; else echo FAIL; FAIL=1; fi
step "configs: schema"; ok=1
while IFS= read -r c; do s="${c%.json}.schema.json"; [ -f "$s" ] || continue; python3 -c "import json,jsonschema,sys; jsonschema.validate(json.load(open(sys.argv[1])), json.load(open(sys.argv[2])))" "$c" "$s" || ok=0; done < <(find "$R" -path '*/config/*.json' -not -name '*.schema.json' 2>/dev/null)
if [ "$ok" = 1 ]; then echo ok; else echo FAIL; FAIL=1; fi
step "herdr: layouts against layout.schema.json"; ok=1
for l in "$R"/herdr/layouts/*.json; do case $l in *.schema.json) continue;; esac; python3 -c "import json,jsonschema,sys; jsonschema.validate(json.load(open(sys.argv[1])), json.load(open(sys.argv[2])))" "$l" "$R/herdr/layouts/layout.schema.json" 2>/dev/null || { echo "invalid layout $l" >&2; ok=0; }; done
if [ "$ok" = 1 ]; then echo ok; else echo FAIL; FAIL=1; fi
step "roles: schema + playbooks in sync"; ok=1
for f in "$R"/roles/*.json; do python3 -c "import json,jsonschema,sys; jsonschema.validate(json.load(open(sys.argv[1])), json.load(open(sys.argv[2])))" "$f" "$R/roles/schema/role.schema.json" 2>/dev/null || { echo "invalid role $f" >&2; ok=0; }; done
bash "$R/roles/bin/render-playbook.sh" "$R/roles" "$R/playbooks" --check || ok=0
if [ "$ok" = 1 ]; then echo ok; else echo FAIL; FAIL=1; fi
step "changelog: entries + CHANGELOG.md rendered"; if bash "$R/bin/changelog.sh" check >/dev/null 2>&1; then echo ok; else bash "$R/bin/changelog.sh" check >&2 || true; echo FAIL; FAIL=1; fi
step "events: every file valid"; if (cd "$R/events" && bin/event.sh check >/dev/null); then echo ok; else echo FAIL; FAIL=1; fi
step "shell: shellcheck"; mapfile -t SH < <(find "$R" -name '*.sh' -not -path '*/node_modules/*' -not -path '*/.claude/*' -not -path '*/report/*')
if shellcheck -S warning "${SH[@]}" 2>/tmp/sc; then echo ok; else echo FAIL; head -40 /tmp/sc >&2; FAIL=1; fi
step "markdown: contents list in sync"; ok=1; for m in "$R"/AGENTS.md "$R"/tools/*/AGENTS.md; do [ -f "$m" ] || continue; bash "$R/bin/md-contents.sh" --check "$m" || ok=0; done; if [ "$ok" = 1 ]; then echo ok; else echo FAIL; FAIL=1; fi
[ "$FAIL" = 0 ] && echo "lint: all ok" || { echo "lint: failures" >&2; exit 3; }
