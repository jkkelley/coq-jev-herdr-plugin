---
title: Break glass grant stores the state root's records tree
at: 2026-10-13T17:29:16Z
type: fix
ticket: WO-20261013-5c06
sha: null
---

The grant file stores records_root and state_root instead of a slot's events/, and the guard posts the closing 201 with that state root.
