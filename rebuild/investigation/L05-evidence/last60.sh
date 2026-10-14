#!/usr/bin/env bash
# last60.sh - reproduces the L05 "last 60 commits of main" table. Read-only. Run from anywhere.
# Usage: last60.sh [CLONE] [REF]   defaults: the investigation clone, origin/main at the clone's current fetch.
# Output (TSV on stdout): hash, UTC author time, files_changed, added_lines, tickets_added_lines, kind, category, subject
# kind = tickets-only when every path is under work-orders/ or changelog/ (a ticket-cut or ticket-housekeeping PR by diff, not by subject)
#        code      when any path is outside those two trees
# category (code kind only) is the first matching rule on the subject; see the case statement.
CLONE=${1:-/home/luna/.local/state/coq/coq-jev-herdr-plugin/rebuild/2026/10/investigation/clones/coq}; REF=${2:-origin/main}
export TZ=UTC
for h in $(git -C "$CLONE" log -60 --format=%h "$REF"); do
  subj=$(git -C "$CLONE" log -1 --format=%s "$h"); when=$(git -C "$CLONE" log -1 --format=%ad --date=format-local:%Y-%m-%dT%H:%MZ "$h")
  read -r nf add tadd other < <(git -C "$CLONE" show --numstat --format= "$h" | awk '{a=($1=="-"?0:$1); n++; add+=a; if ($3 ~ /^(work-orders|changelog)\//) {t+=a} else {o++}} END{print n+0, add+0, t+0, o+0}')
  if [ "$other" = 0 ]; then kind=tickets-only; else kind=code; fi
  case $subj in
    *"Roadmap I"*) cat=roadmap-I-script-move;;
    *"Test speed"*) cat=test-speed;;
    *"CI gate"*) cat=ci-gate;;
    *"Cause "*|*"cause "*|*"Main is red"*|*"Pod fix"*|*"Belt frozen"*) cat=cause-or-main-red-fix;;
    *"Sweep"*|*"Duplicate-work audit"*|*"cancelled, superseded"*) cat=housekeeping;;
    *"SPEC-16"*|*"SPEC-17"*) cat=spec;;
    *) cat=other-line-change;;
  esac
  [ "$kind" = code ] || cat=-
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$h" "$when" "$nf" "$add" "$tadd" "$kind" "$cat" "${subj:0:150}"
done
