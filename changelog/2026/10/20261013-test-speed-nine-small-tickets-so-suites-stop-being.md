---
title: Test speed: nine small tickets so suites stop being the bottleneck
at: 2026-10-13T15:53:41Z
type: chore
ticket: WO-20261012-cf8d
sha: null
---

A pull request now runs only the suites its changed files touch, and the full suite runs once on main. Cases run in parallel, each prints its time and fails over a budget, and fixed sleeps in the herdr cases become polls.
