---
title: compaction-guard owns compaction: step.sh --compact is opt-in; herdr/bin/unfreeze.sh releases and wakes a frozen seat
at: 2026-10-10T21:45:23Z
type: fix
ticket: null
sha: null
---

Four per-step /compact prompts stacked and froze the architect seat for 39 minutes. step.sh no longer queues one. unfreeze.sh <seat|pane> [--force] | --all | --watch releases an expired compaction-guard lease from outside the seat and wakes it; make -C herdr unfreeze SEAT=.. and unfreeze-all. WO-20261010-8fa8 cut for the watcher pane in monitors 1.
