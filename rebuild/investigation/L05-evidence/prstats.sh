#!/usr/bin/env bash
# prstats.sh - reproduces the L05 pull request numbers. Read-only (gh GET calls only). Writes prs.json beside itself and prints the numbers.
# Usage: prstats.sh [OUTDIR]
OUT=${1:-$(dirname "$(readlink -f "$0")")}; REPO=jkkelley/coq-jev-herdr-plugin
gh pr list --repo "$REPO" --state all --limit 400 --json number,title,state,createdAt,closedAt,mergedAt,headRefName,files,additions,body,closingIssuesReferences > "$OUT/prs.json" || exit 4
jq -r '
  def pct(p): sort | .[(length * p / 100 | floor)];
  "fetched: " + (now | todate),
  "total PRs: \(length)  merged: \([.[]|select(.state=="MERGED")]|length)  closed unmerged: \([.[]|select(.state=="CLOSED")]|length)  open: \([.[]|select(.state=="OPEN")]|length)",
  "open: " + ([.[]|select(.state=="OPEN")|"#\(.number) created \(.createdAt)"]|join("; ")),
  ( [.[]|select(.state=="MERGED")|((.mergedAt|fromdateiso8601)-(.createdAt|fromdateiso8601))/60] as $m
    | "merged cycle minutes (createdAt to mergedAt): n=\($m|length) median=\($m|sort|.[($m|length/2|floor)]|floor) p90=\($m|pct(90)|floor) max=\($m|max|floor)" ),
  "merged by UTC day: " + ([.[]|select(.state=="MERGED")|.mergedAt[0:10]]|group_by(.)|map("\(.[0]):\(length)")|join(" ")),
  ( [.[]|select(.state=="MERGED")] as $m | "merged PRs whose changed files are ALL under work-orders/ or changelog/ (tickets-only by diff): \([$m[]|select((.files|length)>0 and all(.files[]; .path|test("^(work-orders|changelog)/")))]|length) of \($m|length)" ),
  ( [.[]|select(.state=="MERGED")] as $m | "merged PRs with a closing issue reference: \([$m[]|select((.closingIssuesReferences|length)>0)]|length)" ),
  ( [.[]|select(.state=="MERGED")] as $m | "merged PRs whose body matches (close|fix|resolve)[sd]? #N: \([$m[]|select(.body|test("(?i)(close[sd]?|fix(es|ed)?|resolve[sd]?) +#[0-9]+"))]|length)" ),
  ( [.[]|select(.state=="MERGED")|(.files|length)]|sort|"merged files-per-PR median=\(.[length/2|floor]) max=\(max)" ),
  ( [.[]|select(.state=="MERGED")|.additions]|sort|"merged added-lines-per-PR median=\(.[length/2|floor])" )
' "$OUT/prs.json"
