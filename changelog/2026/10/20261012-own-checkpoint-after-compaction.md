---
title: Own checkpoint after compaction
at: 2026-10-12T16:49:00Z
type: feat
ticket: WO-20261012-8fb2
sha: null
---

A SessionStart hook with matcher compact prints the seat own newest CONTEXT_STATE.md checkpoint, found by the pane id of its live seat record.
