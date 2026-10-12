#!/usr/bin/env bash
# SITREP cases (WO-20261012-668a), sourced by inside.sh after its own cases so ok/bad/check, $B, $C and /work are all in scope.
# Covers: the checker against a SITREP that was really sent and against one that breaks the rules, the builder against a synthetic
# repository, bearings.sh sitrep (sends, refuses), the 32000 reply cap, the build stamp, and the page drawing a panel for claude
# and a bubble for the owner or for an unparseable payload.
F=/skill/tests/fixtures
K="node /skill/scripts/sitrep-check.mjs"
BUILD="node /skill/scripts/sitrep-build.mjs"

# S1 the checker, real payload: the last SITREP that was actually sent passes with exit 0.
set +e; out=$($K $F/sitrep-sent-ok.txt 2>&1); rc=$?; set -e
CASE="checker passes the SITREP that was sent (exit 0, 8 items, 70 words)"; check test "$rc" = 0 -a "$out" = "8 items, 70 words of prose, 0 violations"

# S2 the checker, breaking payload: exit 1 and every broken rule is named.
set +e; out=$($K $F/sitrep-bad.json 2>&1); rc=$?; set -e
CASE="checker fails the breaking payload with exit 1"; check test "$rc" = 1
for needle in "words, limit is 15" "semicolon" "3 items, limit is 2" "ticket id in the prose" "carries no full title" "more than one sentence"; do
  CASE="checker names the rule: $needle"; check bash -c 'grep -q -- "$1" <<<"$2"' _ "$needle" "$out"
done
set +e; $K $F/sitrep-bad.json >/dev/null 2>&1; rc=$?; $K >/dev/null 2>&1; rc2=$?; echo '#SITREP/v1#{nope' > /work/unparseable.txt; $K /work/unparseable.txt >/dev/null 2>&1; rc3=$?; set -e
CASE="checker with no file is a usage error (exit 2)"; check test "$rc2" = 2
CASE="checker on JSON that does not parse is a violation (exit 1)"; check test "$rc3" = 1
# one rule broken at a time, so each rule is proved on its own
OK=/work/ok.json; sed 's/^#SITREP\/v1#//' $F/sitrep-sent-ok.txt > $OK
jq -c '.blocks[0].items[0].text = "one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen."' $OK > /work/p-words.json
jq -c '.blocks[0].items[0].text = "Done first; then second."' $OK > /work/p-semi.json
jq -c '.blocks[0].items += [.blocks[0].items[0]]' $OK > /work/p-items.json
jq -c '.blocks[0].items[0].ref_title = ""' $OK > /work/p-title.json
jq -c '.blocks[0].items[0].text = "WO-20261001-aa01 finished today."' $OK > /work/p-ticket.json
jq -c '.blocks |= .[0:4]' $OK > /work/p-blocks.json
for c in words semi items title ticket blocks; do
  set +e; $K /work/p-$c.json >/dev/null 2>&1; rc=$?; set -e
  CASE="checker exits 1 when only the $c rule is broken"; check test "$rc" = 1
done
CASE="checker accepts the bare JSON form of the passing payload"; check $K $OK >/dev/null

# S3 the builder against the synthetic repository.
cp /skill/config/sitrep.json /work/sitrep.json
cat > /work/prs-none.json <<'JSON'
[]
JSON
BA=(--tier dev --ticket t1 --config /work/config.json --repo "$F/repo" --prs-json "$F/prs.json" --now 2026-10-12T13:00:00Z)
set +e; $BUILD "${BA[@]}" --out /work/built.txt 2>/work/build.err; rc=$?; set -e
CASE="builder builds a payload from the records (exit 0)"; check test "$rc" = 0
CASE="the built payload passes the checker"; check $K /work/built.txt
sed 's/^#SITREP\/v1#//' /work/built.txt > /work/built.json
CASE="built message starts with the tag and is one JSON object"; check bash -c 'head -c 11 /work/built.txt | grep -q "^#SITREP/v1#$" && jq -e type /work/built.json >/dev/null'
CASE="the five blocks are in the fixed order"; check test "$(jq -r '[.blocks[].name] | join("|")' /work/built.json)" = "EXECUTIVE GROUND TRUTH|DELTA|ACTIVE OPERATIONS|QUEUE MATRIX|TACTICAL NEXT STEPS"
CASE="startable queue counts ready tickets whose dependencies are done (2)"; check test "$(jq -r '.blocks[3].queues[] | select(.name=="STARTABLE") | .count' /work/built.json)" = 2
CASE="waiting queue counts the ready ticket with an open dependency (1)"; check test "$(jq -r '.blocks[3].queues[] | select(.name=="WAITING") | .count' /work/built.json)" = 1
CASE="in progress queue counts 2 and open PRs counts 2"; check test "$(jq -r '[.blocks[3].queues[] | select(.name=="IN PROGRESS" or .name=="OPEN PRS") | .count] | join(",")' /work/built.json)" = "2,2"
# IN FLIGHT (WO-20261012-8f4f): AC-H2 is the first case below, PR 7 names a ticket that is also in progress and it counts once. Open PRs and in-progress or in-review tickets, deduplicated by ticket id, never ticket status on main alone.
inflight() { sed 's/^#SITREP\/v1#//' "$1" | jq -r '.stats[] | select(.label=="IN FLIGHT") | "\(.value)|\(.note)"'; }
export -f inflight; export K
CASE="IN FLIGHT counts PR 7's ticket once though it is also in progress, plus the other in-progress ticket (2)"; check test "$(inflight /work/built.txt)" = "2|1 open PR, 1 without a PR"
CASE="the objective sentence states the same IN FLIGHT figure as the card"; check bash -c 'jq -e "[.blocks[0].items[] | select(.label==\"OBJECTIVE\") | .text] | .[0] | startswith(\"Tickets in flight: 2,\")" /work/built.json >/dev/null'
# AC-H1: three open PRs naming tickets that are ready on main, nothing in progress there: IN FLIGHT is 3. A second PR for the same ticket and a PR with no ticket id add nothing.
cp -r $F/repo /work/repo-ready
sed -i 's/"status": "in-progress"/"status": "ready"/' /work/repo-ready/work-orders/WO-20261001-aa01/WO-20261001-bb0*.md
set +e; $BUILD --tier dev --ticket t1 --config /work/config.json --repo /work/repo-ready --prs-json $F/prs-inflight.json --now 2026-10-12T13:00:00Z --out /work/built-ready.txt 2>/dev/null; rc=$?; set -e
CASE="three open PRs naming ready tickets (one named twice, one with no id) make IN FLIGHT 3, source 3 open PRs"; check bash -c 'test "$1" = 0 && test "$(inflight /work/built-ready.txt)" = "3|3 open PRs"' _ "$rc"
CASE="AC-H3 the IN FLIGHT payload passes the checker with 0 violations"; check bash -c '$K /work/built-ready.txt 2>&1 | grep -q "0 violations"'
# a PR may name a ticket this checkout does not have: main can be behind the branch.
jq '. + [{number: 16, title: "WO-20261001-ee01 - Synthetic ticket this checkout has never seen", url: "https://github.com/example/synthetic/pull/16", headRefName: "feat/ee01"}]' $F/prs-inflight.json > /work/prs-unknown.json
set +e; $BUILD --tier dev --ticket t1 --config /work/config.json --repo /work/repo-ready --prs-json /work/prs-unknown.json --now 2026-10-12T13:00:00Z --out /work/built-unknown.txt 2>/dev/null; rc=$?; set -e
CASE="a PR naming a ticket this checkout has never seen still counts (4 open PRs)"; check bash -c 'test "$1" = 0 && test "$(inflight /work/built-unknown.txt)" = "4|4 open PRs"' _ "$rc"
# in-review counts, and with no PRs at all the source says the tickets have none.
cp -r $F/repo /work/repo-review
sed -i 's/"status": "in-progress"/"status": "in-review"/' /work/repo-review/work-orders/WO-20261001-aa01/WO-20261001-bb02-running-two.md
set +e; $BUILD --tier dev --ticket t1 --config /work/config.json --repo /work/repo-review --prs-json /work/prs-none.json --now 2026-10-12T13:00:00Z --out /work/built-review.txt 2>/dev/null; rc=$?; set -e
CASE="in-progress and in-review tickets with no open PR count (2 without a PR)"; check bash -c 'test "$1" = 0 && test "$(inflight /work/built-review.txt)" = "2|2 without a PR"' _ "$rc"
set +e; $BUILD --tier dev --ticket t1 --config /work/config.json --repo /work/repo-ready --prs-json /work/prs-none.json --now 2026-10-12T13:00:00Z --out /work/built-idle.txt 2>/dev/null; rc=$?; set -e
CASE="nothing in progress and no open PR is IN FLIGHT 0, source nothing in flight"; check bash -c 'test "$1" = 0 && test "$(inflight /work/built-idle.txt)" = "0|nothing in flight"' _ "$rc"
CASE="state is degraded while a failure record is unanswered"; check test "$(jq -r .state /work/built.json)" = degraded
CASE="the answered 409 is not friction: the shown code is the unanswered 423"; check bash -c 'jq -r "[.blocks[0].items[] | select(.label==\"FRICTION\") | .text] | .[0]" /work/built.json | grep -q "code 423, filed 4 hours ago"'
CASE="a ticket reference carries the full title read from the ticket file"; check bash -c '
  want=$(jq -r ".title" <(sed -n "/^---$/,/^---$/p" /skill/tests/fixtures/repo/work-orders/WO-20261001-aa01/WO-20261001-aa01-first-ready.md | sed "1d;\$d"))
  jq -e --arg t "$want" "[.blocks[].items[]? | select(.ref==\"WO-20261001-aa01\") | .ref_title] | all(. == \$t) and length >= 1" /work/built.json >/dev/null'
CASE="every ref in the built payload has a non-empty full title"; check bash -c 'jq -e "[.blocks[].items[]? | select(.ref) | .ref_title | length > 0] | all" /work/built.json >/dev/null'
CASE="queues send both next_items and next, at most 5"; check bash -c 'jq -e "[.blocks[3].queues[] | (.next_items|length) == (.next|length) and (.next|length) <= 5] | all" /work/built.json >/dev/null'
CASE="the open PR badge links are minified-able https urls"; check bash -c 'jq -e "[.blocks[].items[]? | .links[]? | .href | startswith(\"https://\")] | length >= 1" /work/built.json >/dev/null'
CASE="no sentence of prose carries a ticket id"; check bash -c '! jq -r ".blocks[].items[]? | .text" /work/built.json | grep -qE "WO-[0-9]{8}"'
CASE="a build without --save changes nothing on disk"; check test ! -e /work/state/t-dev-t1/sitrep-counts.json
CASE="first briefing shows delta new on every queue"; check test "$(jq -r '[.blocks[3].queues[].delta] | unique | join(",")' /work/built.json)" = new
$BUILD "${BA[@]}" --save --out /work/built2.txt 2>/dev/null
CASE="--save keeps the queue counts for the next briefing"; check test "$(jq -r .counts.STARTABLE /work/state/t-dev-t1/sitrep-counts.json)" = 2
# a ticket moves from ready to done between briefings: the next delta shows it
cp -r $F/repo /work/repo2
sed -i 's/"status": "ready"/"status": "done"/; s/"closed": null/"closed": "2026-10-12"/' /work/repo2/work-orders/WO-20261001-aa01/WO-20261001-aa03-second-ready.md
set +e; $BUILD --tier dev --ticket t1 --config /work/config.json --repo /work/repo2 --prs-json $F/prs.json --now 2026-10-12T14:00:00Z --out /work/built3.txt 2>/dev/null; rc=$?; set -e
CASE="second briefing shows the startable delta -1"; check bash -c 'test "$1" = 0 && sed "s/^#SITREP\/v1#//" /work/built3.txt | jq -e "[.blocks[3].queues[] | select(.name==\"STARTABLE\") | .delta] == [\"-1\"]" >/dev/null' _ "$rc"

# S4 the builder refuses a payload that breaks the standard, and a template that names a fact that does not exist.
jq '.blocks[0].items[0].text = "Tickets in flight: {{in_progress.count}}; ready to start: {{startable.count}}."' /skill/config/sitrep.template.json > /work/tpl-bad.json
jq '.build.template = "/work/tpl-bad.json"' /work/sitrep.json > /work/sitrep-bad-tpl.json
rm -f /work/refused.txt
set +e; $BUILD "${BA[@]}" --sitrep-config /work/sitrep-bad-tpl.json --out /work/refused.txt 2>/work/refused.err; rc=$?; set -e
CASE="builder exits 3 on a semicolon in a template sentence and writes nothing"; check test "$rc" = 3 -a ! -e /work/refused.txt
CASE="the refusal names the violation"; check grep -q "semicolon" /work/refused.err
jq '.blocks[0].items[0].text = "Value {{no.such.fact}}."' /skill/config/sitrep.template.json > /work/tpl-fact.json
jq '.build.template = "/work/tpl-fact.json"' /work/sitrep.json > /work/sitrep-fact-tpl.json
set +e; $BUILD "${BA[@]}" --sitrep-config /work/sitrep-fact-tpl.json 2>/work/fact.err >/dev/null; rc=$?; set -e
CASE="a template naming an unknown fact fails (exit 3) naming it"; check bash -c 'test "$1" = 3 && grep -q "no.such.fact" /work/fact.err' _ "$rc"
set +e; $BUILD --tier dev --ticket t1 --config /work/config.json --repo /work/nowhere --prs-json $F/prs.json >/dev/null 2>&1; rc=$?; set -e
CASE="a repo with no tickets is exit 4, not an empty briefing"; check test "$rc" = 4

# S5 bearings.sh sitrep on a running page: sends a passing payload as a reply, refuses a failing one.
URL6=$($B dev serve --ticket t6 "${C[@]}")
BASE6=${URL6%%/\?key=*}; KEY6=${URL6##*key=}
node -e '
fetch(process.argv[1]+"/message?key="+process.argv[2], { method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify({ id: "m-owner-ask-1", text: "status please" }) }).then(r => r.json()).then(j => console.log(JSON.stringify(j)));
' "$BASE6" "$KEY6" > /work/owner-msg.json
MSGS=/work/state/t-dev-t6/messages.jsonl
CASE="the owner's message landed (setup)"; check grep -q m-owner-ask-1 $MSGS
set +e; out=$($B dev sitrep --ticket t6 "${C[@]}" --payload /work/built.txt 2>&1); rc=$?; set -e
CASE="bearings.sh sitrep sends a passing payload (exit 0)"; check test "$rc" = 0
CASE="the SITREP is a claude reply to the owner's newest message"; check bash -c 'jq -e "select(.from==\"claude\") | .reply_to == \"m-owner-ask-1\" and (.text | startswith(\"#SITREP/v1#{\"))" '"$MSGS"' >/dev/null'
CASE="the sent text is the checked payload, uncut"; check bash -c 'test "$(jq -r "select(.from==\"claude\") | .text" '"$MSGS"' | head -c 100000)" = "$(cat /work/built.txt)"'
before=$(wc -l < $MSGS)
set +e; out=$($B dev sitrep --ticket t6 "${C[@]}" --payload $F/sitrep-bad.json 2>&1); rc=$?; set -e
CASE="bearings.sh sitrep refuses a breaking payload (exit 3) and names the rule"; check test "$rc" = 3 -a "${out#*semicolon}" != "$out"
CASE="a refused SITREP wrote nothing to messages.jsonl"; check test "$(wc -l < $MSGS)" = "$before"
set +e; $B dev sitrep --ticket t6 "${C[@]}" >/dev/null 2>&1; rc=$?; set -e
CASE="bearings.sh sitrep without --payload is a usage error (exit 2)"; check test "$rc" = 2
set +e; $B dev sitrep --ticket t6 "${C[@]}" --payload /work/built.txt --to m-nope >/dev/null 2>&1; rc=$?; set -e
CASE="bearings.sh sitrep to an unknown message id is exit 6"; check test "$rc" = 6

# S6 the reply cap: 32000 for a reply, the owner's own messages stay at max_message_chars.
head -c 20000 /dev/zero | tr '\0' 'a' > /work/long20k.txt
head -c 40000 /dev/zero | tr '\0' 'b' > /work/long40k.txt
$B dev reply --ticket t6 "${C[@]}" --to m-owner-ask-1 "$(cat /work/long20k.txt)" >/dev/null
$B dev reply --ticket t6 "${C[@]}" --to m-owner-ask-1 "$(cat /work/long40k.txt)" >/dev/null
CASE="a 20000 character reply is kept whole"; check test "$(jq -r 'select(.from=="claude") | .text | select(startswith("aaaa")) | length' $MSGS)" = 20000
CASE="a 40000 character reply is cut at max_reply_chars (32000)"; check test "$(jq -r 'select(.from=="claude") | .text | select(startswith("bbbb")) | length' $MSGS)" = 32000

# S7 the build stamp: the server reports a stamp on /state and injects the same one into the page.
node -e '
const [b, k] = process.argv.slice(1);
(async () => {
  const s = await (await fetch(`${b}/state?key=${k}`)).json();
  const h = await (await fetch(`${b}/?key=${k}`)).text();
  console.log(JSON.stringify({ state_build: s.build, page_build: (h.match(/PAGE_BUILD = "([^"]*)"/) || [])[1], placeholder_left: h.includes("@@BUILD@@") }));
})();
' "$BASE6" "$KEY6" > /work/build.json
CASE="/state reports a 12 hex build stamp"; check bash -c '[[ "$(jq -r .state_build /work/build.json)" =~ ^[a-f0-9]{12}$ ]]'
CASE="the page carries the same stamp and no @@BUILD@@ is left"; check bash -c 'test "$(jq -r .state_build /work/build.json)" = "$(jq -r .page_build /work/build.json)" && test "$(jq -r .placeholder_left /work/build.json)" = false'

# S8 the page: a panel for claude, a bubble for the owner typing the same text, a bubble for an unparseable payload.
$B dev stop --ticket t6 "${C[@]}" >/dev/null; sleep 2
rm -f $MSGS
SR=$(cat /work/built.txt)
jq -cn --arg t "$SR" '{id:"m-s1",from:"claude",reply_to:null,text:$t,at:"2026-10-12T13:00:00.000Z"}' >> $MSGS
jq -cn --arg t "$SR" '{id:"m-s2",from:"you",text:$t,at:"2026-10-12T13:01:00.000Z"}' >> $MSGS
jq -cn '{id:"m-s3",from:"claude",reply_to:null,text:"#SITREP/v1#{this is not json",at:"2026-10-12T13:02:00.000Z"}' >> $MSGS
URL6=$($B dev serve --ticket t6 "${C[@]}")
node /skill/tests/sitrep-probe.mjs "$URL6" /work/sitrep-shot.png /work/sitrep-panel.png > /work/sitrep-probe.json
[ ! -d /shots ] || cp /work/sitrep-shot.png /work/sitrep-panel.png /shots/
CASE="the page drew exactly one panel (claude's)"; check test "$(jq -r .panels /work/sitrep-probe.json)" = 1
CASE="thread order is panel, owner bubble, fallback bubble"; check test "$(jq -r '[.kinds[] | select(startswith("panel") or startswith("bubble"))] | map(split(":")[0]) | join(",")' /work/sitrep-probe.json)" = "panel,bubble,bubble"
CASE="the owner's identical text is a bubble, not a panel"; check bash -c 'jq -r ".kinds[]" /work/sitrep-probe.json | grep -c "^bubble:#SITREP" | grep -q "^2$"'
CASE="the panel has five blocks, four stat cards and four queue cards"; check test "$(jq -r '[.blocks,.stats,.queues] | join(",")' /work/sitrep-probe.json)" = "5,4,4"
CASE="the panel shows every ref line with the full title"; check bash -c 'jq -e ".refs | length >= 4 and all(.[]; length > 40)" /work/sitrep-probe.json >/dev/null'
CASE="the PR link renders as a badge with an https href"; check bash -c 'jq -e ".badges | length >= 1 and all(.[]; startswith(\"https://\"))" /work/sitrep-probe.json >/dev/null'
CASE="the status pill reads DEGRADED"; check test "$(jq -r .pill /work/sitrep-probe.json)" = DEGRADED
CASE="no [object Object] and no raw JSON on the page"; check test "$(jq -r '[.object_object, .raw_json_visible] | join(",")' /work/sitrep-probe.json)" = "false,false"
CASE="the screen reader announces the label, not the braces"; check bash -c '! jq -r .announcer /work/sitrep-probe.json | grep -q "scope"'
# shellcheck disable=SC2034 # CASE is read by check(), defined in inside.sh
CASE="the SITREP page had zero page errors"; check test "$(jq '.errors | length' /work/sitrep-probe.json)" = 0
$B dev stop --ticket t6 "${C[@]}" >/dev/null; sleep 2
