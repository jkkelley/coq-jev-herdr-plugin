---
title: Factory board watch rewrites only on a change
at: 2026-10-11T15:27:36Z
type: feat
ticket: WO-20261011-616c
sha: null
---

loop.sh watch collects every watch_seconds and rewrites the page and data only when the entry changed apart from its time and build number, keeps the last good page when a pass fails, and leaves every output file untouched otherwise.
