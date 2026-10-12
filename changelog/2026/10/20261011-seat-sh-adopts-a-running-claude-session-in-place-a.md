---
title: seat.sh adopts a running claude session in place and resumes one from a transcript
at: 2026-10-11T20:01:40Z
type: feat
ticket: WO-20261011-8fb3
sha: null
---

seat.sh --adopt --role R --pane P --session ID names the claude already running in pane P as the role's seat without starting or stopping it, --down on it never kills the pane, and --resume ID restarts a session on either start door.
