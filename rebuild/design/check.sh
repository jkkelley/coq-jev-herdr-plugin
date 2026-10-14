#!/usr/bin/env bash
# rebuild/design/check.sh: validate the spec book. One line per failure. Exit 0 pass, 1 failures, 2 cannot run.
#
# Fails on: any volume over 1000 lines; any XSD failure against schema/volume.xsd; any pointer that does not
# resolve to a file or a declared anchor; any volume without a contents element, a parent pointer or a
# many-agents section; and the companion checks listed at the top of bin/check-book.py (dashes, unique ids,
# JSON schemas, index completeness and line counts, waits with timeout and fallback, the generated cleanup registry
# and record kinds, the DAG, index freshness, codes, input and output, panel bindings, examples against their schemas: C01 to C22, the same ids as
# nodes/N-46/spec.xml#checks). bin/test-checks.py proves every check fires on a mutated copy of the book.
#
# The XSD validator: the python module xmlschema when importable, else `uv run --with xmlschema` (uv is on the
# host, xmlschema is pure Python and cached after the first run), else xmllint. The checker image of
# ci/config/images.json carries xmllint and xmlschema, so in a pod the first branch is taken.
# Artifacts: none written to the repository; set COQ_CHECK_NOTES=1 to print the NOTE lines (external sources).
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECK="$HERE/bin/check-book.py"

if python3 -c 'import xmlschema' 2>/dev/null; then
  python3 -I "$CHECK" "$@"
elif command -v uv >/dev/null 2>&1; then
  uv run --quiet --with xmlschema --with jsonschema python3 -I "$CHECK" "$@"
elif command -v xmllint >/dev/null 2>&1; then
  python3 -I "$CHECK" "$@"
else
  echo "FAIL C02 book no XSD validator: install python xmlschema, uv, or xmllint"
  exit 2
fi
