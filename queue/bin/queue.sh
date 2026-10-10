#!/usr/bin/env bash
# queue.sh - the work queue and its leases (SPEC-03 s-locks). A directory of
# files: enqueue is a write, dequeue is a rename, a lease is a field with a
# deadline. No lock: distinct filenames, atomic mv. Priority p0..p3, age breaks
# ties. dequeue refuses a ticket whose dependencies are not done (work-order.sh
# next is the oracle when --project is given).
#   queue.sh enqueue --ticket WO-ID [--priority p0..p3] [--from RECORD-ID]
#   queue.sh dequeue --holder SEAT [--project DIR]        prints the ticket it leased, or exit 6 when empty
#   queue.sh renew   --ticket WO-ID --holder SEAT
#   queue.sh release --ticket WO-ID --holder SEAT [--done]
#   queue.sh sweep                                        releases expired leases, prints each (the monitor runs this)
#   queue.sh list [--json]
#   queue.sh check
# QUEUE_CONFIG=<path> points at another config (tests). Exit: 0 ok, 2 usage, 3 validation, 4 io, 6 nothing to dequeue.
set -euo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd); ROOT=$(cd "$HERE/.." && pwd); REPO=$(cd "$ROOT/.." && pwd)
die() { local c=$1; shift; printf 'queue: %s\n' "$*" >&2; exit "$c"; }
command -v jq >/dev/null || die 4 "jq required"
CFG=${QUEUE_CONFIG:-$ROOT/config/queue.json}; [ -f "$CFG" ] || die 4 "config $CFG missing"
cfg() { jq -r --arg k "$1" '.[$k] // empty' "$CFG"; }
ITEMS=$(cfg items_dir | sed "s#\${repo}#$REPO#"); [ -n "$ITEMS" ] || die 3 "config key items_dir missing"
TTL=$(cfg lease_ttl_seconds); DEF=$(cfg default_priority); [ -n "$TTL" ] && [ -n "$DEF" ] || die 3 "config keys lease_ttl_seconds and default_priority required"
mkdir -p "$ITEMS"; now() { date -u +%Y-%m-%dT%H:%M:%SZ; }; stamp() { date -u +%Y%m%dT%H%M%SZ; }
vt() { [[ $1 =~ ^WO-[0-9]{8}-[0-9a-f]{4}$ ]] || die 3 "bad ticket id $1"; }
item_of() { find "$ITEMS" -name "*-$1.json" | head -1; }
sorted() { find "$ITEMS" -name 'p*-*.json' | sort; }
VERB=${1:-}; shift || true
case $VERB in
  enqueue)
    t=""; p=$DEF; from=null
    while [ $# -gt 0 ]; do case $1 in --ticket) t=$2; shift 2;; --priority) p=$2; shift 2;; --from) from=$2; shift 2;; *) die 2 "unknown flag $1";; esac; done
    vt "$t"; [[ $p =~ ^p[0-3]$ ]] || die 3 "bad priority $p"; [ -z "$(item_of "$t")" ] || die 3 "$t already queued"
    f="$ITEMS/$p-$(stamp)-$t.json"
    jq -n --arg t "$t" --arg p "$p" --arg at "$(now)" --arg from "$from" '{schema_version:"1.0.0", ticket:$t, priority:$p, enqueued:$at, from:(if $from=="null" then null else $from end), lease:null}' > "$f.tmp" && mv "$f.tmp" "$f"; basename "$f" ;;
  dequeue)
    holder=""; proj=""
    while [ $# -gt 0 ]; do case $1 in --holder) holder=$2; shift 2;; --project) proj=$2; shift 2;; *) die 2 "unknown flag $1";; esac; done
    [ -n "$holder" ] || die 2 "--holder required"
    startable=""; [ -n "$proj" ] && startable=$(bash ~/.claude/skills/work-order/scripts/work-order.sh next --project "$proj" --json 2>/dev/null | jq -r '.[]?.id // .id? // empty' || true)
    while IFS= read -r f; do   # p0 before p1, older first within a priority
      [ -n "$f" ] || continue; [ "$(jq -r '.lease // empty' "$f")" = "" ] || continue
      t=$(jq -r .ticket "$f"); if [ -n "$proj" ] && ! grep -qx "$t" <<<"$startable"; then continue; fi
      deadline=$(date -u -d "+$TTL seconds" +%Y-%m-%dT%H:%M:%SZ)
      jq --arg h "$holder" --arg at "$(now)" --arg d "$deadline" '.lease={holder:$h, acquired:$at, deadline:$d}' "$f" > "$f.tmp" && mv "$f.tmp" "$f"; printf '%s\n' "$t"; exit 0
    done < <(sorted); exit 6 ;;
  renew)
    t=""; h=""; while [ $# -gt 0 ]; do case $1 in --ticket) t=$2; shift 2;; --holder) h=$2; shift 2;; *) die 2 "unknown flag $1";; esac; done
    vt "$t"; f=$(item_of "$t"); [ -n "$f" ] || die 6 "$t not queued"; [ "$(jq -r '.lease.holder // empty' "$f")" = "$h" ] || die 3 "$t is not leased by $h"
    jq --arg d "$(date -u -d "+$TTL seconds" +%Y-%m-%dT%H:%M:%SZ)" '.lease.deadline=$d' "$f" > "$f.tmp" && mv "$f.tmp" "$f" ;;
  release)
    t=""; h=""; done_=0; while [ $# -gt 0 ]; do case $1 in --ticket) t=$2; shift 2;; --holder) h=$2; shift 2;; --done) done_=1; shift;; *) die 2 "unknown flag $1";; esac; done
    vt "$t"; f=$(item_of "$t"); [ -n "$f" ] || die 6 "$t not queued"; [ "$(jq -r '.lease.holder // empty' "$f")" = "$h" ] || die 3 "$t is not leased by $h"
    if [ "$done_" = 1 ]; then rm -f -- "$f"; else jq '.lease=null' "$f" > "$f.tmp" && mv "$f.tmp" "$f"; fi ;;
  sweep)
    n=$(now); while IFS= read -r f; do [ -n "$f" ] || continue
      d=$(jq -r '.lease.deadline // empty' "$f"); if [ -n "$d" ] && [[ "$d" < "$n" ]]; then jq '.lease=null' "$f" > "$f.tmp" && mv "$f.tmp" "$f"; printf 'released expired lease %s\n' "$(jq -r .ticket "$f")"; fi
    done < <(sorted); true ;;
  list)
    if [ "${1:-}" = --json ]; then sorted | xargs -r jq -s .; else while IFS= read -r f; do [ -n "$f" ] && jq -r '"\(.priority)\t\(.ticket)\t\(.enqueued)\t\(.lease.holder // "-")\t\(.lease.deadline // "-")"' "$f"; done < <(sorted); fi ;;
  check)
    bad=0; while IFS= read -r f; do [ -n "$f" ] || continue; b=$(basename "$f" .json); t=$(jq -r .ticket "$f"); p=$(jq -r .priority "$f"); [ "${b##*-}" = "${t##*-}" ] && [ "${b%%-*}" = "$p" ] || { echo "name/content mismatch: $f" >&2; bad=1; }; done < <(sorted)
    [ "$bad" = 0 ] && echo "queue ok: $(sorted | wc -l) items" || exit 3 ;;
  *) sed -n '2,15p' "$0" >&2; exit 2 ;;
esac
