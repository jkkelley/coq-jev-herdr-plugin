#!/usr/bin/env bash
# hook-listener.sh - turns GitHub status, check_run and pull_request events into records, and hands each to the handlers hook.json names.
# WO-20261013-ca2a (CI gate 6), design plans/2026/10/20261013194800-ci-gate-design.md, Amendment 2026-10-13T20:20Z.
#
#   hook-listener.sh serve            listen on host:port from hook.json; each POST is one delivery, handed to ingest
#   hook-listener.sh ingest EVENT     one delivery: payload JSON on stdin, EVENT the X-GitHub-Event header; prints "recorded PATH" or "skipped WHY"
#   hook-listener.sh forward          exec `gh webhook forward` for hook.json's repo and events, aimed at the listener (the outbound feed)
#   hook-listener.sh page [UNIT]      post the blocked 423 that pages the orchestrator; UNIT defaults to $MONITOR_UNIT (systemd sets it for OnFailure=)
#   hook-listener.sh check            validate hook.json against its required keys
# Exit codes: 0 ok, 2 usage, 3 validation (bad config, bad payload), 4 io (no jq, no python3, record not written, gh webhook missing).
#
# What an event becomes: one kind `note` record, with --sha (and --pr when the payload names one), by the first rule that fits:
#   status       context equal to gate_context        state success 201, failure or error 422, pending 100
#   check_run    action in check_run_actions          conclusion success, neutral or skipped 201, none 100, anything else 422
#   pull_request action in pull_request_actions       100 (opened or synchronize)
# Anything else is skipped with a logged reason and answered 200, so the forward never retries what the line does not want.
# After the record is written, every handler in hook.json whose event (and context, when it names one) matches runs once with the raw
# payload on stdin and HOOK_EVENT, HOOK_SHA, HOOK_STATE, HOOK_CONTEXT, HOOK_PR and HOOK_RECORD in its environment. A handler file that
# does not exist yet is skipped with a logged note (the handler tickets land after this one). A handler that fails posts a note 500,
# which routes to the monitor, and the next handler still runs.
#
# Where it writes (nothing else, anywhere): the records tree through events/bin/event.sh, and one log per start,
#   <logs tree>/YYYY/MM/YYYYMMDDHHMMSS-hook-listener-serve.log (ingest run by hand writes ...-hook-listener-ingest-PID.log).
# The logs are safe to delete at any time. The units that supervise this are line/units/coq-hook-*.service; install them once, by hand,
# as the owner or orchestrator, with: systemctl --user link <checkout>/line/units/coq-hook-{listener,forward,page}.service &&
#   systemctl --user daemon-reload && systemctl --user enable --now coq-hook-listener.service coq-hook-forward.service
# `forward` needs the extension once: gh extension install cli/gh-webhook (it needs admin on the repo).
#
# BREADCRUMB 2026-10-14 - WO-20261013-ca2a. What broke: nothing yet; this host has no public ingress, so a GitHub status for coq/gate
#   reached the line only by merge-watch polling once a minute. Why this fix: `gh webhook forward` opens the connection outbound and
#   posts each event to localhost, and this listener is the other end. Records are kind `note`: `gate` has no row in
#   factory/config/routes.json and an unmatched record is a "no route" 500 to the monitor (factory/bin/route.sh), while `note` is ignored
#   by the router and pr.opened would seat a second tester for a pull request the worker already announced. The consumers (WO-20261013-3217,
#   WO-20261013-aff2) take the raw payload from their handler hook, not the record. The socket is python3's stdlib http.server because bash
#   cannot listen and this host has neither socat nor a netcat that can exec; all logic stays in bash and python only moves bytes.
#   Rejected: smee.io or any public relay and a port opened on the host (the design); a Go service (a second toolchain for forty lines).
#   Cost: no payload signature check - the socket binds 127.0.0.1 only, so only a local process can post, and a local process can write
#   a record directly anyway. Handlers run inside the request, so a slow handler holds one delivery for up to handler_timeout_seconds.
set -uo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd); REPO=$(cd "$HERE/../.." && pwd)
SCHEMA=$REPO/line/config/hook.schema.json; CONFIG=${HOOK_CONFIG:-$REPO/line/config/hook.json}
EVENT_SH=$REPO/events/bin/event.sh
die() { local c=$1; shift; printf 'hook-listener: %s\n' "$*" >&2; exit "$c"; }
command -v jq >/dev/null || die 4 "jq is required"
# shellcheck source=../../bin/state-root.sh
. "$REPO/bin/state-root.sh" || die 4 "bin/state-root.sh is missing or unusable"
LOGS=$(coq_tree logs) || exit 4

load_config() {
  local missing
  [ -f "$CONFIG" ] && jq -e . "$CONFIG" >/dev/null 2>&1 || die 3 "$CONFIG is missing or not JSON"
  missing=$(jq -r --slurpfile s "$SCHEMA" '. as $c | $s[0].required[] | select($c[.] == null)' "$CONFIG") || die 4 "cannot read $SCHEMA"
  [ -z "$missing" ] || die 3 "$CONFIG lacks: $(printf '%s' "$missing" | tr '\n' ' ')"
  SLUG=$(jq -r .repo "$CONFIG"); HOST=$(jq -r .host "$CONFIG"); PORT=$(jq -r .port "$CONFIG")
  GATE=$(jq -r .gate_context "$CONFIG"); SEAT=$(jq -r .seat "$CONFIG"); PAGE_TO=$(jq -r .page_to "$CONFIG")
  RETRIES=$(jq -r .retries "$CONFIG"); RETRY_SECONDS=$(jq -r .retry_seconds "$CONFIG"); LIMIT=$(jq -r .restart_limit "$CONFIG")
  MAX_BODY=$(jq -r .max_body_bytes "$CONFIG"); HANDLER_SECONDS=$(jq -r .handler_timeout_seconds "$CONFIG")
}
open_log() { # open_log NAME: one dated log per start, unless the parent (serve) already chose one
  [ -z "${HOOK_LOG:-}" ] || return 0
  local s; s=$(date -u +%Y%m%d%H%M%S); HOOK_LOG=$LOGS/${s:0:4}/${s:4:2}/$s-hook-listener-$1.log; export HOOK_LOG
  mkdir -p "$(dirname "$HOOK_LOG")" || die 4 "cannot create the log directory under $LOGS"
}
log() { printf '%s %s\n' "$(date -u +%FT%TZ)" "$*" | tee -a "$HOOK_LOG" >&2; }
in_list() { jq -e --arg v "$2" 'index($v) != null' <<<"$1" >/dev/null; } # in_list JSON-ARRAY VALUE

post() { # post EVENT.SH-ARGS: up to $RETRIES tries, then the exit code; a usage (2) or validation (3) error is final, any other failure is retried
  local n=0 out rc
  while :; do
    n=$((n + 1)); out=$("$EVENT_SH" add "$@" 2>&1); rc=$?
    [ "$rc" != 0 ] || { printf '%s' "$out"; return 0; }
    log "record write failed, attempt $n of $RETRIES, exit $rc: $out"
    [ "$rc" != 2 ] && [ "$rc" != 3 ] && [ "$n" -lt "$RETRIES" ] || return "$rc"
    sleep "$RETRY_SECONDS"
  done
}
report() { # report TEXT: a note 500 routes to the monitor; one try, because a failing writer would only fail again
  "$EVENT_SH" add --code 500 --kind note --seat "$SEAT" --note "${1:0:240}" >/dev/null 2>&1 || log "could not post the report: $1"
}

run_handlers() { # run_handlers EVENT CONTEXT PAYLOAD-FILE
  local ev=$1 ctx=$2 payload=$3 run path
  while IFS= read -r run; do
    path=${run//'${repo}'/$REPO}
    if [ ! -f "$path" ]; then log "skipping handler $run: the file does not exist yet"; continue; fi
    HOOK_EVENT=$ev HOOK_SHA=$SHA HOOK_STATE=$STATE HOOK_CONTEXT=$ctx HOOK_PR=${PR:-} HOOK_RECORD=$RECORD \
      timeout "$HANDLER_SECONDS" bash "$path" < "$payload" >> "$HOOK_LOG" 2>&1
    local rc=$?
    if [ "$rc" = 0 ]; then log "handler $run ran for $ev on $SHA"
    else log "handler $run exited $rc for $ev on $SHA"; report "handler $run exited $rc for $ev on ${SHA:0:7}"; fi
  done < <(jq -r --arg e "$ev" --arg c "$ctx" '.handlers[] | select(.event == $e and (.context == null or .context == $c)) | .run' "$CONFIG")
}

ingest() {
  local ev=${1:-} tmp code ctx action concl note
  [ -n "$ev" ] || die 2 "ingest needs the event name"
  open_log "ingest-$$"
  tmp=$(mktemp -d) || die 4 "no temp directory"; trap 'rm -rf "$tmp"' RETURN
  cat > "$tmp/payload"
  jq -e 'type == "object"' "$tmp/payload" >/dev/null 2>&1 || { log "event $ev: the body is not a JSON object"; return 3; }
  if ! in_list "$(jq -c .events "$CONFIG")" "$ev"; then log "event $ev: not in hook.json events, skipped"; echo "skipped event $ev"; return 0; fi
  PR=; STATE=; SHA=; ctx=
  case $ev in
    status)
      IFS=$'\x1f' read -r ctx SHA STATE < <(jq -r '[.context // "", .sha // "", .state // ""] | join("\u001f")' "$tmp/payload")
      if [ "$ctx" != "$GATE" ]; then log "status $ctx: not $GATE, skipped"; echo "skipped context $ctx"; return 0; fi
      case $STATE in success) code=201;; failure|error) code=422;; pending) code=100;; *) log "status $ctx: unknown state '$STATE'"; return 3;; esac
      note="status $ctx $STATE on ${SHA:0:12}" ;;
    check_run)
      IFS=$'\x1f' read -r action ctx SHA concl PR < <(jq -r '[.action // "", .check_run.name // "", .check_run.head_sha // "", .check_run.conclusion // "", (.check_run.pull_requests[0].number // "" | tostring)] | join("\u001f")' "$tmp/payload")
      if ! in_list "$(jq -c .check_run_actions "$CONFIG")" "$action"; then log "check_run $ctx $action: not in check_run_actions, skipped"; echo "skipped action $action"; return 0; fi
      STATE=${concl:-pending}
      case $concl in success|neutral|skipped) code=201;; "") code=100;; *) code=422;; esac
      note="check_run $ctx $STATE on ${SHA:0:12}" ;;
    pull_request)
      IFS=$'\x1f' read -r action SHA PR < <(jq -r '[.action // "", .pull_request.head.sha // "", (.number // "" | tostring)] | join("\u001f")' "$tmp/payload")
      if ! in_list "$(jq -c .pull_request_actions "$CONFIG")" "$action"; then log "pull_request $action: not in pull_request_actions, skipped"; echo "skipped action $action"; return 0; fi
      STATE=$action; code=100; note="pull_request #$PR $action on ${SHA:0:12}" ;;
  esac
  [[ $SHA =~ ^[0-9a-f]{7,40}$ ]] || { log "event $ev: sha '$SHA' is not 7 to 40 lowercase hex"; return 3; }
  RECORD=$(post --code "$code" --kind note --seat "$SEAT" --sha "$SHA" ${PR:+--pr "$PR"} --note "$note") || {
    local rc=$?; log "event $ev on $SHA: no record after $RETRIES tries"; report "no record written for $ev on ${SHA:0:7} after $RETRIES tries"; return "$rc"; }
  log "$note -> $RECORD"
  run_handlers "$ev" "$ctx" "$tmp/payload"
  echo "recorded $RECORD"
}

serve() {
  command -v python3 >/dev/null || die 4 "python3 is required"
  open_log serve; log "listening on $HOST:$PORT for $SLUG ($(jq -r '.events | join(",")' "$CONFIG"))"
  # python only moves bytes: one thread per delivery, the body to `ingest` on stdin, ingest's exit code to an HTTP status
  exec python3 -I - "$HERE/hook-listener.sh" "$HOST" "$PORT" "$MAX_BODY" <<'PY'
import http.server, subprocess, sys
script, host, port, max_body = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4])
STATUS = {0: 200, 3: 400}
class Handler(http.server.BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass  # ingest logs every delivery
    def reply(self, code, text):
        body = text.encode()
        self.send_response(code)
        self.send_header("Content-Type", "text/plain")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)
    def do_POST(self):
        try:
            size = int(self.headers.get("Content-Length", ""))
        except ValueError:
            return self.reply(411, "Content-Length is required\n")
        if size > max_body:
            return self.reply(413, "body over max_body_bytes\n")
        done = subprocess.run(["bash", script, "ingest", self.headers.get("X-GitHub-Event", "")],
                              input=self.rfile.read(size), capture_output=True)
        self.reply(STATUS.get(done.returncode, 500), done.stdout.decode(errors="replace") or "failed\n")
class Server(http.server.ThreadingHTTPServer):
    daemon_threads = True
Server((host, port), Handler).serve_forever()
PY
}

forward() {
  gh webhook --help >/dev/null 2>&1 || die 4 "the gh webhook extension is missing; install it once with: gh extension install cli/gh-webhook"
  exec gh webhook forward --repo "$SLUG" --events "$(jq -r '.events | join(",")' "$CONFIG")" --url "http://$HOST:$PORT/"
}

page() {
  local unit=${1:-${MONITOR_UNIT:-}}
  [ -n "$unit" ] || die 2 "page needs the failed unit, as an argument or in MONITOR_UNIT"
  open_log "page-$$"
  post --code 423 --kind blocked --seat "$SEAT" --to "$PAGE_TO" --note "$unit failed $LIMIT restarts" > /dev/null || { log "the page for $unit was not written"; return 4; }
  log "paged $PAGE_TO: $unit failed $LIMIT restarts"
}

mode=${1:-}; [ $# -eq 0 ] || shift
load_config
case $mode in
  serve) serve;;
  ingest) ingest "$@";;
  forward) forward;;
  page) page "$@";;
  check) echo "hook config ok: $CONFIG";;
  *) die 2 "usage: hook-listener.sh serve | ingest EVENT | forward | page [UNIT] | check";;
esac
