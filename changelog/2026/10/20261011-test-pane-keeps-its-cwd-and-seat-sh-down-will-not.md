---
title: Test pane keeps its cwd and seat.sh --down will not return a slot past a foreign process
at: 2026-10-11T05:27:41Z
type: fix
ticket: WO-20261011-36d7
sha: null
---

testpane.sh sends the command to the pane inside a subshell; seat.sh --down logs each process in the slot by pid and name and refuses treehouse return --force while a foreign one is there.
