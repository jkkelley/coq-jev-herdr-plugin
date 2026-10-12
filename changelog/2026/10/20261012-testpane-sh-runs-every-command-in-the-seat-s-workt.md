---
title: testpane.sh runs every command in the seat's worktree, never the main checkout
at: 2026-10-12T20:25:38Z
type: fix
ticket: WO-20261012-3cb1
sha: null
---

testpane.sh sends ( cd COQ_WORKTREE && command ) and refuses with exit 3 when COQ_WORKTREE is unset or missing, so test and lint results come from the PR head
