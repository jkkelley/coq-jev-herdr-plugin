#!/usr/bin/env bash
# execution-rail: build the tracker page from a plan and a ledger. See SKILL.md for the contract.
# Usage: rail-build.sh --plan plan.json --ledger ledger.tsv --out page.html [--title T] [--eyebrow E] [--source S]
#        [--side side.html] [--signal GOTEAM] [--approved] [--not-approved]
set -euo pipefail
D="$(cd "$(dirname "$0")/.." && pwd)"; T="$D/assets/template.html"
plan= ledger= out= title="Execution Rail" eyebrow="execution rail" source="" side= signal="GOTEAM" approved=
while (( $# )); do case $1 in
  --plan) plan=$2; shift 2;; --ledger) ledger=$2; shift 2;; --out) out=$2; shift 2;; --title) title=$2; shift 2;;
  --eyebrow) eyebrow=$2; shift 2;; --source) source=$2; shift 2;; --side) side=$2; shift 2;; --signal) signal=$2; shift 2;;
  --approved) approved=true; shift;; --not-approved) approved=false; shift;; *) echo "unknown flag $1" >&2; exit 2;; esac; done
[ -n "$plan" ] && [ -n "$ledger" ] && [ -n "$out" ] || { sed -n 3,4p "$0"; exit 2; }
[ -f "$ledger" ] || printf 'at_utc\tstep\tstatus\ttext\tby\tref\n' > "$ledger"
marker="$(dirname "$out")/.approved"
if [ -z "$approved" ]; then approved=false; [ -f "$marker" ] && approved=true; else [ "$approved" = true ] && : > "$marker" || rm -f "$marker"; fi
sidehtml=""; [ -n "$side" ] && sidehtml="$(cat "$side")"
# BREADCRUMB - why plan validation and ledger parsing moved out of jq and into the python block below.
# What broke: the upstream copy (~/.claude/skills/execution-rail/bin/rail-build.sh, lines 11 and 15-16) called jq
#   three times, then python3 for the render. jq is absent from Git Bash on Windows and from the pinned python image
#   this skill's suite runs in, so the vendored copy could not be tested under Rule 14 without a third image.
# Why it mattered: a template every scaffolded project inherits must run wherever that project runs (Rule 17), and a
#   script that cannot be tested in the suite's own image ships unproven.
# Why this fix: python3 is already a hard dependency of this script for the render, so doing the parse there removes a
#   dependency instead of adding one. Rejected: a jq-carrying test image, which proves the script only on machines that
#   happen to have jq and leaves the Windows failure in place.
# Cost: none at runtime; the parse is the same five-field split jq did.
# BREADCRUMB - S-05 L2 (review: ~/.local/state/dotfiles/execution/S-05-review.md).
# What broke: the render below filled placeholders with plain str.replace and no escaping. A ledger row
#   carrying </script> ended the <script type="application/json"> block (assets/template.html:561-562) and
#   the page stopped parsing there; a title or directory name carrying < or & went raw into <title> and <h1>
#   (template.html:1,522); and a value naming a later placeholder, such as __TITLE__, was substituted again.
# Why it mattered: the page is the owner's only view of the plan. A row that breaks it hides every row after it.
# Why this fix: escape per context and substitute once. JSON goes in with <, > and & as \u escapes, which JSON
#   decodes to the same text and HTML never reads as markup. Text goes in html.escape'd, with backslashes as
#   an entity too, because __SIGNAL__ sits inside a JS string literal. One regex pass means a replacement is
#   never scanned again. Rejected: escaping in ledger.sh, which would corrupt the TSV record for every other
#   reader to protect one renderer.
# Cost: __SIDE_HTML__ is still inserted raw, on purpose - it is the project's own committed HTML fragment,
#   and escaping it would render its markup as text.
built="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
python3 - "$T" "$out" "$plan" "$ledger" "$built" "$approved" "$title" "$eyebrow" "$source" "$sidehtml" "$signal" <<'PY'
import html,json,re,sys
t,o,planf,ledgerf,built,approved,title,eyebrow,source,side,signal=sys.argv[1:12]
try:
    p=json.load(open(planf,encoding="utf-8"))
except (OSError,ValueError) as e:
    sys.exit(f"plan.json does not parse: {e}")
if not isinstance(p,list) or not all(isinstance(x,dict) and {"id","t","who"} <= x.keys() for x in p):
    sys.exit("plan.json must be an array of {id,t,who,gate,owner}")
def js(v):
    return json.dumps(v,separators=(",",":")).replace("<","\\u003c").replace(">","\\u003e").replace("&","\\u0026")
def text(v):
    return html.escape(v,quote=True).replace("\\","&#92;").replace("\n"," ")
plan=js(p)
keys=("at_utc","step","status","text","by","ref")
lines=open(ledgerf,encoding="utf-8").read().split("\n")[1:]
rows=js([dict(zip(keys,(l.split("\t")+[""]*6)[:6])) for l in lines if l])
if approved not in ("true","false"):
    sys.exit(f"approved must be true or false, got {approved!r}")
vals={"__PLAN_JSON__":plan,"__LEDGER_JSON__":rows,"__BUILT_AT__":text(built),"__APPROVED__":approved,
      "__TITLE__":text(title),"__EYEBROW__":text(eyebrow),"__SOURCE__":text(source),"__SIDE_HTML__":side,
      "__SIGNAL__":text(signal)}
s=open(t,encoding="utf-8").read()
s=re.sub("|".join(map(re.escape,vals)),lambda m:vals[m.group(0)],s)
open(o,"w",encoding="utf-8").write(s)
PY
echo "$out"
