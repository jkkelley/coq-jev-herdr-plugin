#!/usr/bin/env bash
# line/tests/lib/world.sh - the scratch world a board case runs in: a private state root, a copy of the board config the case may edit,
# and a fake herdr on PATH that logs its argv (and fails while $W/herdr.fail exists). The real scripts run unmodified from the
# read-only repo mount; nothing a case does can write back (SPEC-17 s-tests: a fake herdr and a scratch state root, in seconds).
REPO=${REPO_ROOT:-/repo}; BOARD_SH=$REPO/line/bin/board.sh
world_init() {
  W=${COQ_CASE_WORK:?COQ_CASE_WORK is set by line/tests/run.sh}; mkdir -p "$W/bin" "$W/state"; : > "$W/herdr.log"
  printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$*" >> "%s/herdr.log"\n[ ! -e "%s/herdr.fail" ] || exit 1\n' "$W" "$W" > "$W/bin/herdr"; chmod +x "$W/bin/herdr"
  export PATH="$W/bin:$PATH" COQ_STATE="$W/state" COQ_HERDR_SESSION=t-board BOARD_CONFIG="$W/board.json"
  cp "$REPO/line/config/board.json" "$BOARD_CONFIG"
}
board() { bash "$BOARD_SH" "$@"; }
# rid N: a well-formed record id, so ids sort in the order N rises
rid() { printf '20261013T%06dZ-100-a%04d' "$1" "$1"; }
# cfg_set KEY JSON: set one key of this world's board config
cfg_set() { jq --argjson v "$2" --arg k "$1" '.[$k] = $v' "$BOARD_CONFIG" > "$BOARD_CONFIG.tmp" && mv "$BOARD_CONFIG.tmp" "$BOARD_CONFIG"; }
cfg_reset() { cp "$REPO/line/config/board.json" "$BOARD_CONFIG"; }
prompts() { grep -c ' agent prompt ' "$W/herdr.log" || true; }
