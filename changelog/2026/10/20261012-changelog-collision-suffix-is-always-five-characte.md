---
title: Changelog collision suffix is always five characters
at: 2026-10-12T17:46:58Z
type: fix
ticket: WO-20261012-3bb0
sha: null
---

bin/changelog.sh read 16 random bytes for the collision suffix and kept a-z0-9, so it was often shorter than the 5 chars check requires
