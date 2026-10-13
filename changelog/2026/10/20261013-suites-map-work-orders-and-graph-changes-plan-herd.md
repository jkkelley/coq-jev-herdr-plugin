---
title: Suites map: work-orders and graph changes plan herdr case 12 only
at: 2026-10-13T18:25:46Z
type: fix
ticket: WO-20261013-f1ff
sha: null
---

A row may name cases of a suite; a tickets-only diff plans lint, reindex and CASES=12 bash herdr/tests/run.sh instead of the whole herdr suite, and case 19 fails if the row maps to the whole suite.
