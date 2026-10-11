#!/usr/bin/env bash
# assert.sh - the few helpers every case sources. A case is a script that exits 0 when every assertion held.
#   LOOP     the real loop.sh        FIX    tests/fixtures        W    this case's scratch directory
#   t DESC CMD...          CMD exits 0           expect_exit N DESC CMD...   CMD exits N
#   eq DESC WANT GOT       equal strings         has DESC FILE PATTERN       FILE matches the extended regex
set -uo pipefail
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${REPO_ROOT:-$(cd "$LIB_DIR/../../../.." && pwd)}"
export LOOP="$REPO_ROOT/report/loop/loop.sh" FIX="$REPO_ROOT/report/loop/tests/fixtures"
export W="${CASE_WORK:-$(mktemp -d)}"; mkdir -p "$W"
FAILS=0
pass() { echo "ok   - $1"; }
flunk() { echo "FAIL - $1" >&2; FAILS=$((FAILS + 1)); }
t() { local d=$1; shift; if "$@" >"$W/.out" 2>&1; then pass "$d"; else flunk "$d"; sed 's/^/       /' "$W/.out" >&2; fi; }
expect_exit() { local want=$1 d=$2 got; shift 2; "$@" >"$W/.out" 2>&1; got=$?; if [ "$got" = "$want" ]; then pass "$d"; else flunk "$d (exit $got, wanted $want)"; sed 's/^/       /' "$W/.out" >&2; fi; }
eq() { if [ "$2" = "$3" ]; then pass "$1"; else flunk "$1"; printf '       wanted: %s\n       got:    %s\n' "$2" "$3" >&2; fi; }
has() { if grep -Eq -- "$3" "$2"; then pass "$1"; else flunk "$1 ($2 lacks /$3/)"; fi; }
done_case() { [ "$FAILS" = 0 ]; }
