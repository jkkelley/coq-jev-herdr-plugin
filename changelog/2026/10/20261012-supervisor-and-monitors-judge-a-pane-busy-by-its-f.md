---
title: Supervisor and monitors judge a pane busy by its foreground processes, not the group id alone
at: 2026-10-12T18:18:29Z
type: fix
ticket: WO-20261012-277d
sha: null
---

pane_busy and busy shared one rule in seat-lib.sh: busy when the foreground group differs from the shell or a foreground process is not a shell named in herdr.json shells, so node wait.mjs in the shell's own group is no longer called dead
