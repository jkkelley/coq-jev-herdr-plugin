---
title: Merger and tester roles read records from the state root
at: 2026-10-13T17:16:10Z
type: chore
ticket: WO-20261013-73be
sha: null
---

The merger and tester roles each gain one step: records are read and written only through events/bin/event.sh, which resolves the state root, and a slot's or the checkout's events/ is never read. Both playbooks are re-rendered from the roles.
