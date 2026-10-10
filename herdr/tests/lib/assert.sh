#!/usr/bin/env bash
# herdr/tests/lib/assert.sh - the assertion vocabulary every case sources. Every check states what it expected inline
# so a failing line is diagnosable from the log alone, and sets CASE_FAILED rather than exiting, so one failure does
# not hide the rest of the case. Ported from ~/tools/bearings-v2/tests/lib/assert.sh, 2026-10-10.
CASE_FAILED=0
check() { if [ "$2" = 1 ]; then echo "  ok   - $1"; else echo "  FAIL - $1"; CASE_FAILED=1; fi; }
assert_eq() { if [ "$2" = "$3" ]; then echo "  ok   - $1 (got '$2')"; else echo "  FAIL - $1 (got '$2', want '$3')"; CASE_FAILED=1; fi; }
assert_match() {
  if printf '%s' "$2" | grep -qE "$3"; then echo "  ok   - $1"
  else echo "  FAIL - $1 (no match for /$3/; got: $(printf '%s' "$2" | head -c 240 | tr '\n' ' '))"; CASE_FAILED=1; fi
}
assert_file() { if [ -f "$2" ]; then echo "  ok   - $1 ($2)"; else echo "  FAIL - $1 (no file $2)"; CASE_FAILED=1; fi; }
case_done() { [ "$CASE_FAILED" = 0 ]; }
