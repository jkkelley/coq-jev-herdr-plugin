---
title: Test speed tickets carry the two approval conditions
at: 2026-10-13T15:57:27Z
type: chore
ticket: WO-20261012-cf8d
sha: null
---

The suite map now sends a change to every suite that uses that code, so a writer change also runs the factory and herdr tests. Parallel cases are capped at four by default, set in config, so parallel herdr servers cannot exhaust memory.
