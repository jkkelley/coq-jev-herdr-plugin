---
title: Factory board collects its entry from the records
at: 2026-10-11T15:21:42Z
type: feat
ticket: WO-20261011-616c
sha: null
---

loop.sh collect derives station state, where the work is, by-hand PRs, seats, belt and board bars from events, tickets, role files, the routes table, the herdr pane list and the belt state file, and validates the entry before printing it.
