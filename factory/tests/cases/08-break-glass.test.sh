#!/usr/bin/env bash
# Catches (WO-20261011-4562): a break.glass 300 request not reaching the interface agent as a decision card, a break.glass 200
# not running seat.sh --break-glass with the 200 record's own id (the runner must pass the id and nothing it read from the
# record), a refusal by seat.sh (exit 3, which wrote its own 423) turning into a second 500, a seat.sh crash vanishing instead of
# becoming a 500, the lifecycle records 100, 201 and 204 turning into "no route" 500s, and a refused 423 not waking the monitor.
# seat.sh is a stub that logs its argv and exits with the code in $W/seat.rc; the real one is proved by herdr case 13.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "${REPO_ROOT:-/repo}/herdr/tests/lib/assert.sh"; . "$HERE/../lib/world.sh"
world_up breakglass
mkdir -p "$R/herdr/bin"; SLOG="$W/seat.log"; : > "$SLOG"
printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$*" >> "%s"\nexit "$(cat "%s/seat.rc" 2>/dev/null || echo 0)"\n' "$SLOG" "$W" > "$R/herdr/bin/seat.sh"; chmod +x "$R/herdr/bin/seat.sh"
# bg: evo, so each record lands a second after the last and never sorts before it. The runner routes by id order, and a host clock that
# steps back a second (06-belt breadcrumb) put a record in the same second as the previous receipt (backlog disva, 2026-10-12: the
# receipt for the 300 request was read as the receipt for the 200 grant).
bg() { evo --kind break.glass --seat worker-wo-20261011-aaaa --action 'gh pr merge 17 --squash' "$@"; }
n500() { files_code 500 | wc -l | tr -d ' '; }

echo "-- a 300 request becomes a decision card for the interface agent"
req=$(bg --code 300); run_once; assert_eq "exit 0" "$?" 0
assert_match "agent prompt to the interface seat names the record, the decision line and the playbook" "$(cat "$HLOG")" \
  "^--session stable agent prompt interface record $req line decision playbook $R/playbooks/interface-agent.md$"
assert_eq "seat.sh was not run for a request" "$(wc -l < "$SLOG" | tr -d ' ')" 0

echo "-- a 200 runs seat.sh --break-glass for the record's seat with the 200's own id"
grant=$(bg --code 200 --answer "$req"); run_once
assert_eq "seat.sh was run once, with the seat and the record id only" "$(cat "$SLOG")" "--break-glass worker-wo-20261011-aaaa --record $grant"
assert_eq "herdr was not asked for anything else" "$(hcalls)" 1
assert_match "the receipt names the action" "$(rec_files | xargs -r cat | jq -r 'select(.kind == "record.routed") | .note' | grep -F "routed break.glass 200 ($grant)")" "routed break.glass 200 \($grant\): break-glass orchestrator"
assert_eq "no 500" "$(n500)" 0

echo "-- a refusal by seat.sh (exit 3, its own 423 written) is handled: a receipt, no second 500"
echo 3 > "$W/seat.rc"; refused=$(bg --code 200); run_once
assert_match "seat.sh was run for it" "$(tail -1 "$SLOG")" " --record $refused$"
assert_match "receipted as routed" "$(rec_files | xargs -r grep -l "routed break.glass 200 ($refused)" 2>/dev/null | head -1)" "json$"
assert_eq "still no 500" "$(n500)" 0

echo "-- a seat.sh failure that is not a refusal becomes a 500 to the monitor"
echo 4 > "$W/seat.rc"; broke=$(bg --code 200 --answer "$req"); run_once
assert_eq "one 500" "$(n500)" 1
r=$(cat "$(files_code 500 | head -1)")
assert_eq "a note to the monitor" "$(jq -r '[.kind, .to, .seat] | join(" ")' <<<"$r")" "note monitor route-runner"
assert_match "it names the record and the exit" "$(jq -r .note <<<"$r")" "route failed for break.glass 200, record $broke: seat.sh --break-glass exited 4"
echo 0 > "$W/seat.rc"

echo "-- the lifecycle records 100, 201 and 204 are receipted, not 500s, and run nothing"
before=$(wc -l < "$SLOG" | tr -d ' '); h=$(hcalls)
for c in 100 201 204; do bg --code "$c" --answer "$req" >/dev/null; done; run_once
assert_eq "still one 500, the seat.sh crash above" "$(n500)" 1
assert_eq "seat.sh not run" "$(wc -l < "$SLOG" | tr -d ' ')" "$before"
assert_eq "herdr not asked" "$(hcalls)" "$h"
assert_eq "three receipts for the three records" "$(rec_files | xargs -r grep -l 'routed break.glass \(100\|201\|204\)' | wc -l | tr -d ' ')" 3

echo "-- a refused 423 wakes the monitor with the record"
id=$(bg --code 423 --answer "$req"); run_once
assert_match "agent prompt to the monitor" "$(tail -1 "$HLOG")" "^--session stable agent prompt monitor record $id playbook $R/playbooks/monitor.md$"
case_done
