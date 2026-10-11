---
title: lint fails on a merge conflict marker
at: 2026-10-11T19:06:15Z
type: feat
ticket: WO-20261011-6842
sha: null
---

lint/check-conflict-markers.sh scans tracked files for a column 0 conflict marker, lint.sh calls it, suite case 08 proves pass, fail and skip.
