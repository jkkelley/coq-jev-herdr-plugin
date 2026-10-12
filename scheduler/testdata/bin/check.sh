#!/usr/bin/env bash
# check.sh - the check of the golden replay fixtures under scheduler/testdata/replay (SPEC-16.K k-replay, k-coverage).
# Every case is read the way the Go replay reads it: placeholders expanded, records checked against the event schema, the
# context and expected files against scheduler/testdata/replay.schema.json. Then every decision and policy default is
# recomputed from factory/config/routes.json and policies.json the way factory/bin/route.sh and policy.sh decide, so a
# fixture can only say what the bash belt does. Coverage: every routes row, every policies row, every verb of SPEC-16.H
# h-verbs and every verdict is in some case, and every case covers something no other case does, so removing any one
# case fails naming what it alone covered. No line of a fixture may match a forbidden pattern of the scheduler check config.
#
#   check.sh [--repo DIR] [--json]
#
# The fixtures checked are the ones beside this script (../replay), so a copy of scheduler/testdata checks itself. The repo
# (the tables, the event schema, roles, the check config) is --repo, else $REPO_ROOT, else the working directory when it
# holds factory/config/routes.json, else /repo (the lint image's mount).
# Needs bash, python3 with jsonschema (the lint image has both).
# Exit codes: 0 ok, 2 usage, 3 validation (each problem named on stderr), 4 io.
set -euo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd); TESTDATA=$(cd "$HERE/.." && pwd)
REPO=""; JSON=0
die() { local c=$1; shift; printf 'check: %s\n' "$*" >&2; exit "$c"; }
while [ $# -gt 0 ]; do case $1 in
  --repo) REPO=${2:?--repo needs a directory}; shift 2;; --json) JSON=1; shift;;
  -h|--help) sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'; exit 0;;
  *) die 2 "unknown flag $1";; esac; done
if [ -z "$REPO" ]; then
  if [ -n "${REPO_ROOT:-}" ]; then REPO=$REPO_ROOT; elif [ -f "$PWD/factory/config/routes.json" ]; then REPO=$PWD; else REPO=/repo; fi
fi
[ -d "$REPO" ] || die 4 "no such repo $REPO"
command -v python3 >/dev/null || die 4 "python3 is required"
python3 -c 'import jsonschema' 2>/dev/null || die 4 "python3 jsonschema is required (the lint image has it)"
[ -d "$TESTDATA/replay" ] || die 4 "no replay directory at $TESTDATA/replay"

exec python3 - "$REPO" "$TESTDATA" "$JSON" <<'PY'
import json, os, re, sys
import jsonschema

repo, testdata, as_json = sys.argv[1], sys.argv[2], sys.argv[3] == "1"
problems = []
def bad(where, what): problems.append(f"{where}: {what}")
def io(msg): print(f"check: {msg}", file=sys.stderr); sys.exit(4)

def load(path, what):
    try:
        with open(path) as f: return json.load(f)
    except FileNotFoundError: io(f"{what} missing: {path}")
    except ValueError as e: io(f"{what} is not JSON: {path}: {e}")

routes = load(f"{repo}/factory/config/routes.json", "routes table")["routes"]
policies = load(f"{repo}/factory/config/policies.json", "policies table")["policies"]
event_schema = load(f"{repo}/events/schema/event.schema.json", "event schema")
replay_schema = load(f"{testdata}/replay.schema.json", "replay schema")
# A relative $id makes jsonschema 4.10 (the lint image's) resolve "#/$defs/..." against a made-up URL and try to fetch it;
# the documents are self-contained, so their $id is dropped before validating.
event_schema.pop("$id", None); replay_schema.pop("$id", None)
pinned = load(f"{testdata}/forbidden.json", "pinned forbidden list")["forbidden"]

# The forbidden list belongs to specs/scheduler/config/check.json. The pinned copy covers the window before that file is on
# main; when both exist they must agree, so the copy cannot drift.
check_cfg = f"{repo}/specs/scheduler/config/check.json"
if os.path.exists(check_cfg):
    forbidden = load(check_cfg, "scheduler check config")["forbidden"]
    if forbidden != pinned:
        bad("scheduler/testdata/forbidden.json", "differs from specs/scheduler/config/check.json; delete the copy or make it equal")
else:
    forbidden = pinned
forbidden = [(f["name"], re.compile(f["regex"])) for f in forbidden]

# The verb set is the schema's enum, which copies SPEC-16.H h-verbs; when the spec is on disk the two must agree.
verbs = replay_schema["$defs"]["job"]["properties"]["verb"]["enum"]
spec_h = [p for p in (os.listdir(f"{repo}/specs/scheduler") if os.path.isdir(f"{repo}/specs/scheduler") else []) if p.startswith("SPEC-16.H-")]
if spec_h:
    with open(f"{repo}/specs/scheduler/{spec_h[0]}") as f:
        spec_verbs = re.findall(r'<verb name="([a-z_]+)"', f.read())
    if sorted(spec_verbs) != sorted(verbs):
        bad("scheduler/testdata/replay.schema.json", f"verb enum {sorted(verbs)} differs from SPEC-16.H h-verbs {sorted(spec_verbs)}")

roles = {}
for name in os.listdir(f"{repo}/roles"):
    if name.endswith(".json"):
        roles[name[:-5]] = load(f"{repo}/roles/{name}", "role").get("label")

VERDICTS = ["routed", "ignored", "unrouted", "own"]

# Placeholders keep real ids out of the fixture files: the copy rule forbids anything shaped like a ticket or record id.
TOKEN = re.compile(r"<<([a-z]+):([^>]*)>>")
def expand(text, where):
    def one(m):
        kind, arg = m.group(1), m.group(2)
        if kind == "ticket" and re.fullmatch(r"[a-f]", arg): return f"WO-20000101-000{arg}"
        if kind == "tkt" and re.fullmatch(r"[a-f]", arg): return f"wo-20000101-000{arg}"
        mm = re.fullmatch(r"([0-5][0-9]):([1-5][0-9]{2})", arg)
        if kind == "id" and mm: return f"20000101T0000{mm.group(1)}Z-{mm.group(2)}-syn{mm.group(1)}"
        bad(where, f"unknown placeholder {m.group(0)}")
        return m.group(0)
    return TOKEN.sub(one, text)

def seat_of(role, ticket):
    label = roles.get(role)
    if not label: return None
    label = label.replace("${ticket}", (ticket or "").lower())
    return None if "${" in label or not label else label.lower()

def role_of_seat(seat, ticket):
    for role in sorted(roles):
        if seat_of(role, ticket) == seat: return role
    return None

def match_row(rec, esc):
    a = rec.get("attempt", 1)
    for i, row in enumerate(routes):
        m = row["match"]
        if all([m.get("kind") in (None, rec["kind"]), m.get("code") in (None, rec["code"]),
                m.get("code_gte") is None or rec["code"] >= m["code_gte"],
                m.get("attempt") is None or a == m["attempt"], m.get("attempt_lt") is None or a < m["attempt_lt"],
                m.get("escalations") is None or esc == m["escalations"],
                m.get("escalations_lt") is None or esc < m["escalations_lt"]]):
            return i, row
    return None, None

def job(key, verb, args, after): return {"key": key, "verb": verb, "args": args, "after": after}

# plan RECORD ROW CTX: the jobs factory/bin/route.sh performs for a routed record, as job specs (perform, act_primary, act_down,
# route_file's receipt), in order: primary, down, receipt.
def plan(rec, row, ctx, gate):
    rid, t, to, act = rec["id"], rec.get("ticket"), row.get("to"), row["do"]
    pb = ctx["playbooks_dir"]; jobs = []
    if act in ("wake", "notify_owner", "seat"):
        seat = seat_of(to, t)
        if act == "notify_owner":
            line = f"record {rid} line {row['line']} playbook {pb}/{to}.md"
        else:
            extra = ""
            if row.get("with") in ("pr", "merge-main"):
                if "pr" in rec: extra += f" pr {rec['pr']}"
                if "sha" in rec: extra += f" sha {rec['sha']}"
                if row["with"] == "merge-main":
                    extra += " merge main (git fetch origin, git merge origin/main, fix the conflicts, push, post pr.opened with the new sha)"
                if row.get("supersede") and gate.get("supersedes"):
                    extra += f" supersedes {gate['supersedes']} (drop that run and post nothing for it)"
            line = f"record {rid}{extra} playbook {pb}/{to}.md"
        if act == "seat":
            jobs.append(job(f"{rid}:seat_up:{seat}", "seat_up", [t, to], []))
        jobs.append(job(f"{rid}:prompt:{seat}", "prompt", [seat, line], [j["key"] for j in jobs]))
    elif act == "enqueue":
        prio = rec.get("priority", "")
        if re.fullmatch(r"p[0-3]", str(prio)): jobs.append(job(f"{rid}:enqueue_priority:{t}", "enqueue_priority", [t, rid, prio], []))
        else: jobs.append(job(f"{rid}:enqueue:{t}", "enqueue", [t, rid], []))
    elif act == "escalate":
        args = ["--code", str(row["code"]), "--kind", "escalated", "--to", to, "--note", f"escalated record {rid}"]
        if t: args += ["--ticket", t]
        jobs.append(job(f"{rid}:record:escalated", "record", args, []))
    elif act == "break-glass":
        jobs.append(job(f"{rid}:break_glass:{rec['seat']}", "break_glass", [rec["seat"], rid], []))
    primary = [j["key"] for j in jobs]
    down = row.get("down")
    if down:
        ds = seat_of(down, t)
        jobs.append(job(f"{rid}:seat_down:{ds}", "seat_down", [ds], [k + "?" for k in primary]))
    note = f"routed {rec['kind']} {rec['code']} ({rid}): {act} {to}" + (f", down {down}" if down else "")
    args = ["--code", "300", "--kind", "record.routed", "--to", to, "--note", note, "--evidence", f"{ctx['evidence_dir']}/{rid}.json"]
    if t: args += ["--ticket", t]
    jobs.append(job(f"{rid}:record:record.routed", "record", args, [j["key"] for j in jobs]))
    return jobs

# defaults RECORDS CTX: the policy defaults factory/bin/policy.sh applies (open_escalations, apply) over the replayed records,
# with history counted for answers and limits but never judged itself.
def defaults(records, ctx):
    from datetime import datetime, timezone
    def ts(s): return datetime.strptime(s, "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=timezone.utc).timestamp()
    now, every, out = ts(ctx["clock"]), ctx["history"] + records, []
    given = {}
    for r in records:
        for p in policies:
            m = p["match"]
            if r["kind"] != m["kind"] or r["code"] != m["code"] or ("attempt" in m and r.get("attempt", 1) != m["attempt"]): continue
            if not r.get("ticket"): continue
            if any(o.get("ticket") == r["ticket"] and o["id"] > r["id"] and o["kind"] in p["answered_by"] for o in every): continue
            if any(o["kind"] == "policy.applied" and o.get("answer") == r["id"] for o in every): continue
            have = sum(1 for o in every if o["kind"] == "policy.applied" and o.get("ticket") == r["ticket"] and o.get("policy") == p["id"])
            if have + given.get((r["ticket"], p["id"]), 0) >= p["limit_per_ticket"]: continue
            if ts(r["at"]) + p["deadline_seconds"] > now: continue
            given[(r["ticket"], p["id"])] = given.get((r["ticket"], p["id"]), 0) + 1
            to = p["default"]["to"]
            role, target = (role_of_seat(r["seat"], r["ticket"]), r["seat"]) if to == "source" else (to, seat_of(to, r["ticket"]))
            args = ["--code", "200", "--kind", "policy.applied", "--ticket", r["ticket"], "--policy", p["id"], "--answer", r["id"],
                    "--note", f"default {p['id']}: {p['default']['answer']}"[:240]]
            if role: args += ["--to", role]
            rk = f"{r['id']}:record:policy.applied"
            jobs = [job(rk, "record", args, [])]
            if role and target:
                jobs.append(job(f"{r['id']}:prompt:{target}", "prompt", [target, f"record {{out:{rk}}} playbook {ctx['playbooks_dir']}/{role}.md"], [rk]))
            out.append({"policy": p["id"], "escalation": r["id"], "jobs": jobs})
    return out

# first_diff GOT WANT: the first entry where the fixture and the bash belt part, both sides, so a long plan names its one difference.
def first_diff(got, want):
    for i in range(max(len(got), len(want))):
        g = got[i] if i < len(got) else None; w = want[i] if i < len(want) else None
        if g != w: return f"entry {i}\n      fixture: {json.dumps(g)}\n      bash:    {json.dumps(w)}"
    return "no difference"

def strip(jobs): return [{k: j[k] for k in ("key", "verb", "args", "after")} for j in jobs]

replay = f"{testdata}/replay"
cases = sorted(d for d in os.listdir(replay) if os.path.isdir(f"{replay}/{d}"))
if not cases: bad("scheduler/testdata/replay", "no cases")
cover = {}  # case -> set of covered items
for case in cases:
    d, where = f"{replay}/{case}", f"replay/{case}"
    texts = {}
    for name in ("records.jsonl", "context.json", "expected.json"):
        try:
            with open(f"{d}/{name}") as f: texts[name] = f.read()
        except FileNotFoundError:
            bad(where, f"{name} missing")
    for name in sorted(os.listdir(d)):
        with open(f"{d}/{name}") as f:
            for n, line in enumerate(f, 1):
                for fname, rx in forbidden:
                    if rx.search(line): bad(f"{where}/{name}:{n}", f"matches the forbidden pattern {fname}")
    if len(texts) < 3: continue
    try:
        records = [json.loads(l) for l in expand(texts["records.jsonl"], f"{where}/records.jsonl").splitlines() if l.strip()]
        ctx = json.loads(expand(texts["context.json"], f"{where}/context.json"))
        exp = json.loads(expand(texts["expected.json"], f"{where}/expected.json"))
    except ValueError as e:
        bad(where, f"not JSON after expansion: {e}"); continue
    ok = True
    for label, doc in (("context.json", ctx), ("expected.json", exp)):
        try: jsonschema.validate(doc, replay_schema)
        except jsonschema.ValidationError as e: bad(f"{where}/{label}", f"schema: {e.message} at {'/'.join(map(str, e.absolute_path))}"); ok = False
    for i, r in enumerate(ctx.get("history", []) + records):
        try: jsonschema.validate(r, event_schema)
        except jsonschema.ValidationError as e: bad(f"{where} record {r.get('id', i)}", f"event schema: {e.message}"); ok = False
    if not ok: continue
    if exp["case"] != case: bad(f"{where}/expected.json", f"case is {exp['case']}, the directory is {case}")
    last = max([h["id"] for h in ctx["history"]], default="")
    for r in records:
        if r["id"] <= last: bad(where, f"record {r['id']} does not sort after the one before it or after the history")
        last = r["id"]
    for r in ctx["history"] + records:
        stamp = r["id"][:16]
        if f"{stamp[0:4]}-{stamp[4:6]}-{stamp[6:8]}T{stamp[9:11]}:{stamp[11:13]}:{stamp[13:15]}Z" != r["at"]: bad(where, f"record {r['id']} has at {r['at']}, its id says otherwise")
        if int(r["id"][17:20]) != r["code"]: bad(where, f"record {r['id']} has code {r['code']}, its id says otherwise")
    gates = {g["record"]: g for g in ctx["gates"]}
    covered = set()
    if len(exp["decisions"]) != len(records):
        bad(f"{where}/expected.json", f"{len(exp['decisions'])} decisions for {len(records)} records"); continue
    every = ctx["history"] + records
    for r, dec in zip(records, exp["decisions"]):
        at = f"{where} record {r['id']}"
        if dec["record"] != r["id"]: bad(at, f"decision is for {dec['record']}; decisions follow records.jsonl in order"); continue
        if r["seat"] in ctx["runner_seats"]:
            verdict, idx, want = "own", None, []
        else:
            esc = sum(1 for o in every if o["kind"] == "escalated" and o["seat"] in ctx["runner_seats"]
                      and o.get("ticket") == r.get("ticket") and o["id"] < r["id"])
            idx, row = match_row(r, esc)
            if row is None:
                verdict = "unrouted"
                args = ["--code", "500", "--kind", "note", "--to", "monitor", "--note", f"no route for {r['kind']} {r['code']}, record {r['id']}"]
                if r.get("ticket"): args += ["--ticket", r["ticket"]]
                want = [job(f"{r['id']}:record:note", "record", args, [])]
            elif row["do"] == "ignore":
                verdict, want = "ignored", []
            else:
                verdict, g = "routed", gates.get(r["id"], {})
                if row.get("when") and (g.get("when") != row["when"] or g.get("result") != "proceed"):
                    bad(at, f"row {idx} names when {row['when']}: the context's gates must say it proceeds (a held record is not a SPEC-16 verdict)")
                if row.get("supersede") and "supersedes" not in g:
                    bad(at, f"row {idx} supersedes: the context's gates must say what gate.sh supersedes answers")
                want = plan(r, row, ctx, g)
        if dec["verdict"] != verdict: bad(at, f"verdict {dec['verdict']}, the table says {verdict}")
        if dec["row"] != idx: bad(at, f"row {dec['row']}, the first matching row is {idx}")
        if strip(dec["jobs"]) != want:
            bad(at, "jobs differ from what route.sh performs: " + first_diff(strip(dec["jobs"]), want))
        covered.add(f"verdict {verdict}")
        if idx is not None: covered.add(f"routes row {idx}")
    want_defaults = defaults(records, ctx)
    got_defaults = [{"policy": x["policy"], "escalation": x["escalation"], "jobs": strip(x["jobs"])} for x in exp["defaults"]]
    if got_defaults != want_defaults:
        bad(f"{where}/expected.json", "defaults differ from what policy.sh applies: " + first_diff(got_defaults, want_defaults))
    for x in exp["defaults"]: covered.add(f"policies row {x['policy']}")
    for j in [j for x in exp["decisions"] + exp["defaults"] + exp["engine"] for j in x["jobs"]]:
        covered.add(f"verb {j['verb']}")
        for a in j["args"]:
            for ref in re.findall(r"\{out:([^}]*)\}", a):
                if ref not in j["after"]: bad(f"{where} job {j['key']}", f"{{out:{ref}}} names a job not in after")
    cover[case] = covered

need = [f"routes row {i}" for i in range(len(routes))] + [f"policies row {p['id']}" for p in policies] + \
       [f"verb {v}" for v in verbs] + [f"verdict {v}" for v in VERDICTS]
have = set().union(*cover.values()) if cover else set()
def describe(item):
    if item.startswith("routes row "):
        i = int(item.split()[-1]); return f"{item} {json.dumps(routes[i]['match'], separators=(',', ':'))} do {routes[i]['do']}"
    return item
for item in need:
    if item not in have: bad("coverage", f"uncovered {describe(item)}")
for case, items in cover.items():
    alone = items - set().union(*[v for k, v in cover.items() if k != case])
    if not alone: bad(f"replay/{case}", "covers nothing no other case covers; a redundant case hides a gap when another is removed")

if as_json:
    print(json.dumps({"ok": not problems, "cases": {k: sorted(v) for k, v in cover.items()}, "problems": problems}))
else:
    for case in cases:
        if case in cover:
            alone = cover[case] - set().union(*[v for k, v in cover.items() if k != case])
            print(f"case {case}: alone covers {', '.join(sorted(alone)) or 'nothing'}")
    rows_in = [i for i in range(len(routes)) if "routes row %d" % i in have]
    pols_in = [p["id"] for p in policies if "policies row " + p["id"] in have]
    verbs_in = [v for v in verbs if "verb " + v in have]
    print("routes rows covered: %d of %d" % (len(rows_in), len(routes)))
    print("policies rows covered: %s (%d of %d)" % (", ".join(pols_in) or "none", len(pols_in), len(policies)))
    print("verbs covered: %s (%d of %d)" % (", ".join(verbs_in), len(verbs_in), len(verbs)))
    print("verdicts covered: " + ", ".join(v for v in VERDICTS if "verdict " + v in have))
for p in problems: print(f"check: {p}", file=sys.stderr)
sys.exit(3 if problems else 0)
PY
