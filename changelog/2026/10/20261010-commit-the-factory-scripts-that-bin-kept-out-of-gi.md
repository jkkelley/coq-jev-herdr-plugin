---
title: Commit the factory scripts that **/bin/ kept out of git
at: 2026-10-10T19:54:47Z
type: fix
ticket: WO-20261010-fbad
sha: 920807a
---

gitignore line 21 excluded graph/bin, events/bin, queue/bin, roles/bin and bin/ from PR #1; main had no scripts.
