#!/usr/bin/env bash
# serve.sh - serve one tier of the blueprint in the foreground (WO-20261011-ceea). Run it in a labelled herdr pane, never detached.
#   serve.sh TIER               exec server.py for dev, uat or stable; the port, out_dir and pane label come from config/TIER.json
#   serve.sh --check TIER       GET /healthz on the tier's port: prints "ok TIER build N" and exits 0, or says why and exits 1
# Env: BLUEPRINT_ROOT is the repository root the tier's out_dir is relative to; BLUEPRINT_CONFIG_DIR the tier configs.
# Exit: 0 ok, 1 not serving, 2 usage, 4 io.
set -euo pipefail
HERE=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)
ROOT=${BLUEPRINT_ROOT:-$(cd "$HERE/../.." && pwd)}
CONF=${BLUEPRINT_CONFIG_DIR:-$HERE/config}
die() { local c=$1; shift; printf 'serve: %s\n' "$*" >&2; exit "$c"; }
usage() { sed -n '2,6p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' >&2; exit 2; }
command -v python3 >/dev/null || die 4 "python3 is required"
check=0
[ "${1:-}" != --check ] || { check=1; shift; }
tier=${1:-}; [[ $tier =~ ^(dev|uat|stable)$ ]] || usage
[ -f "$CONF/$tier.json" ] || die 4 "no config for the tier $tier at $CONF/$tier.json"
if [ "$check" = 1 ]; then
  exec python3 -I - "$CONF/$tier.json" <<'PY'
import json, sys, urllib.request, urllib.error
cfg = json.load(open(sys.argv[1]))
url = f"http://{cfg.get('host', '127.0.0.1')}:{cfg['port']}/healthz"
try:
    body = json.load(urllib.request.urlopen(url, timeout=3))
    print(f"ok {body['tier']} build {body['build']}")
except urllib.error.HTTPError as e:
    print(f"not serving a page: {url} answered {e.code}", file=sys.stderr); sys.exit(1)
except Exception as e:
    print(f"not serving: {url}: {e}", file=sys.stderr); sys.exit(1)
PY
fi
exec python3 -I "$HERE/server.py" --tier "$tier" --root "$ROOT" --config-dir "$CONF"
