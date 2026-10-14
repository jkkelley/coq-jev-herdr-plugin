---
title: CI gate 2: coqGate() plans the suites from the diff, runs them as pods and posts coq/gate on the head sha
at: 2026-10-14T00:57:50Z
type: feat
ticket: WO-20261013-ab25
sha: null
---

Jenkinsfile calls the coq-ci library step, drops pollSCM, aborts the previous build per branch and skips fork pull requests before any pod; the step fans out one pod per herdr and factory case, posts coq/gate, and climbs a 5 rung ladder for infrastructure failures only.
