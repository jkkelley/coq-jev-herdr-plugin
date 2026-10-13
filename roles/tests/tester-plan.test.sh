#!/usr/bin/env bash
# roles/tests/tester-plan.test.sh - WO-20261013-b6f3 (cause z). Proves the gate seats run only the plan: the tester's steps run
# exactly what factory/bin/suites.sh plan prints (the list in its brief, or its own plan when the brief has none),
# roles/bin/brief.sh puts that list in a tester's brief verbatim with the head it planned, and the reviewer reads and runs nothing.
#   bash roles/tests/tester-plan.test.sh [repo-root]     default: two levels above this file
# Exit 0 all pass, 1 any fail. Runs with no network and no herdr; python3 with jsonschema, jq and git are the only needs
# (the herdr test image has all four).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
R="${1:-$(cd "$HERE/../.." && pwd)}"
T="$R/roles/tester.json"; V="$R/roles/reviewer.json"; RS="$R/roles/schema/role.schema.json"
pass=0; fail=0
ok() { pass=$((pass + 1)); echo "ok   $1"; }
no() { fail=$((fail + 1)); echo "FAIL $1"; }
check() { local name="$1"; shift; if "$@" >/dev/null 2>&1; then ok "$name"; else no "$name"; fi; }
validate() { python3 -I -c "import json,jsonschema,sys; jsonschema.validate(json.load(open(sys.argv[1])), json.load(open(sys.argv[2])))" "$1" "$2"; }
has() { grep -qF -- "$2" <<<"$1"; }
lacks() { ! grep -qF -- "$2" <<<"$1"; }
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

# Both roles validate, and both playbooks are the render of their role.
check "tester role validates against role.schema.json" validate "$T" "$RS"
check "reviewer role validates against role.schema.json" validate "$V" "$RS"
mkdir -p "$tmp/pb"; cp "$R"/playbooks/*.md "$tmp/pb/"
check "playbooks in sync with the roles (render --check)" bash "$R/roles/bin/render-playbook.sh" "$R/roles" "$tmp/pb" --check

# AC-H1, AC-H3: the tester runs the brief's plan, else its own suites.sh plan, and nothing else. STEP is the predicate the
# rest hangs on; the mutation below proves it fails when the step is removed, so it can never pass by accident.
STEP='any(.must[]; test("Test plan for head") and test("verbatim") and test("factory/bin/suites.sh plan"))'
check "a tester step runs the list after 'Test plan for head', else suites.sh plan" jq -e "$STEP" "$T"
jq 'del(.must[] | select(test("Test plan for head")))' "$T" > "$tmp/tester-without-step.json"
if jq -e "$STEP" "$tmp/tester-without-step.json" >/dev/null 2>&1; then no "the step check fails on a tester role without the step"
else ok "the step check fails on a tester role without the step"; fi
check "the rendered tester playbook carries the step" grep -Eq '^[0-9]+\. .*Test plan for head.*factory/bin/suites\.sh plan' "$R/playbooks/tester.md"
check "no tester step runs the ticket's test plan" jq -e 'all(.must[]; test("its test plan|plan case") | not)' "$T"
check "a failed plan is 423 and stop, never a substitute" jq -e 'any(.must[]; test("exits non-zero, post 423"))' "$T"
check "every planned command runs through testpane.sh, one at a time" jq -e 'any(.must[]; test("one at a time") and test("herdr/bin/testpane.sh"))' "$T"
check "the tester may run suites.sh plan and testpane.sh, never make test" \
  jq -e '(.allow.commands | index("factory/bin/suites.sh plan") != null) and (.allow.commands | index("herdr/bin/testpane.sh *") != null) and (.allow.commands | index("make test") == null)' "$T"
check "forbidden: a command suites.sh plan did not print" jq -e 'any(.forbidden[]; test("suites.sh plan did not print"))' "$T"

# The architect ruling of 22:28Z: the reviewer reads the diff and the ticket and runs nothing, and the fence holds it to that.
check "the reviewer's first step reads the diff and runs no test" jq -e '.must[0] | test("gh pr diff") and test("run no test")' "$V"
check "the reviewer may run no make, podman or testpane.sh" jq -e '[.allow.commands[] | select(test("^(make|podman|herdr/bin/testpane)"))] | length == 0' "$V"
check "the fence denies make, podman and testpane.sh to the reviewer" \
  jq -e '.deny.commands as $d | all("make *", "podman *", "herdr/bin/testpane.sh *"; . as $c | $d | index($c) != null)' "$V"
check "the rendered reviewer playbook says it runs nothing" grep -qF 'run no test, suite, case, lint or make target' "$R/playbooks/reviewer.md"

# brief.sh in a world of its own: a project with the real brief.sh, roles, suites.sh and suites.json, and a pull request
# worktree whose diff touches work-orders/, docs/ and factory/bin/ (its own suites.sh, which only prints a marker).
P="$tmp/proj"; W="$tmp/wt"; ID=WO-20991231-0001; TITLE="Fixture ticket for the tester plan"
mkdir -p "$P/roles/bin" "$P/factory/bin" "$P/factory/config" "$P/work-orders/WO-20991231-0000"
cp "$R/roles/bin/brief.sh" "$P/roles/bin/"; cp "$T" "$R/roles/worker.json" "$P/roles/"
cp "$R/factory/bin/suites.sh" "$P/factory/bin/"; cp "$R/factory/config/suites.json" "$P/factory/config/"
printf -- '---\n{"id": "%s", "title": "%s"}\n---\n\n# %s - %s\n' "$ID" "$TITLE" "$ID" "$TITLE" > "$P/work-orders/WO-20991231-0000/$ID-fixture.md"
g() { git -C "$1" -c user.name=tester-plan -c user.email=tester-plan@example.invalid "${@:2}"; }
git -c init.defaultBranch=main init -q "$W"; echo base > "$W/README.md"; g "$W" add -A; g "$W" commit -qm base; g "$W" update-ref refs/remotes/origin/main HEAD
g "$W" checkout -qb feat/fixture
mkdir -p "$W/work-orders/WO-20991231-0000" "$W/docs" "$W/factory/bin"
echo ticket > "$W/work-orders/WO-20991231-0000/$ID-fixture.md"; echo doc > "$W/docs/fixture.md"
printf '#!/usr/bin/env bash\necho WORKTREE-COPY-RAN\n' > "$W/factory/bin/suites.sh"; chmod +x "$W/factory/bin/suites.sh"
g "$W" add -A; g "$W" commit -qm change
head="$(git -C "$W" rev-parse HEAD)"
plan="$("$P/factory/bin/suites.sh" plan --repo "$W" 2>/dev/null)"
want=""; n=0
while IFS= read -r c; do [ -n "$c" ] || continue; n=$((n + 1)); want+=" $n) \`$c\`"; done <<<"$plan"
check "the fixture plan is not empty and includes make lint" has "$want" '`make lint`'

b="$(bash "$P/roles/bin/brief.sh" --role tester --ticket "$ID" --project "$P" --test-pane wD9:p9 --worktree "$W" 2>"$tmp/err")"; rc=$?
check "a tester brief with --worktree exits 0" test "$rc" = 0
check "it names the ticket, the playbook and the test pane as before" has "$b" "$ID - $TITLE. Playbook playbooks/tester.md. Your test pane is wD9:p9; run commands only there, through herdr/bin/testpane.sh."
check "it names the head it planned" has "$b" " Test plan for head $head, printed by factory/bin/suites.sh plan; run exactly these $n commands in order and nothing else:"
check "it lists every command suites.sh plan printed, verbatim and in order" has "$b" "nothing else:$want. Post your first record before anything else."
check "the brief is one line" test "$(printf '%s\n' "$b" | wc -l)" = 1
check "the project's suites.sh planned it, never the pull request's" lacks "$b" WORKTREE-COPY-RAN

b0="$(bash "$P/roles/bin/brief.sh" --role tester --ticket "$ID" --project "$P" --test-pane wD9:p9 2>/dev/null)"
check "a tester brief without --worktree is the brief it always was" test "$b0" = "$ID - $TITLE. Playbook playbooks/tester.md. Your test pane is wD9:p9; run commands only there, through herdr/bin/testpane.sh. Post your first record before anything else."
bw="$(bash "$P/roles/bin/brief.sh" --role worker --ticket "$ID" --project "$P" --worktree "$W" 2>/dev/null)"
check "a worker brief carries no plan" lacks "$bw" "Test plan"

# A plan that cannot be made leaves the brief as it was and says why on stderr: a worktree with no origin/main, and no git at all.
W2="$tmp/wt-no-origin"; git -c init.defaultBranch=main init -q "$W2"; echo x > "$W2/x"; g "$W2" add -A; g "$W2" commit -qm only
b2="$(bash "$P/roles/bin/brief.sh" --role tester --ticket "$ID" --project "$P" --worktree "$W2" 2>"$tmp/err2")"; rc=$?
check "a plan that fails still prints the brief, exit 0" test "$rc" = 0
check "and the brief carries no plan" lacks "$b2" "Test plan"
check "and stderr says why" grep -qF "brief: no plan for $ID: suites.sh plan failed" "$tmp/err2"
mkdir -p "$tmp/not-git"
b3="$(bash "$P/roles/bin/brief.sh" --role tester --ticket "$ID" --project "$P" --worktree "$tmp/not-git" 2>"$tmp/err3")"; rc=$?
check "a worktree that is not a checkout still prints the brief, exit 0" test "$rc" = 0
check "and the brief names the ticket but carries no plan" has "$b3" "$ID - $TITLE. Playbook playbooks/tester.md."
check "and no plan line" lacks "$b3" "Test plan"
check "and stderr names the missing HEAD" grep -qF "brief: no plan for $ID: no HEAD" "$tmp/err3"

echo "tester plan: $pass passed, $fail failed"
[ "$fail" = 0 ]
