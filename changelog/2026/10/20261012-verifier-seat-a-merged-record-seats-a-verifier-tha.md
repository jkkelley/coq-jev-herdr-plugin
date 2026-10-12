---
title: Verifier seat: a merged record seats a verifier that checks main, so no merge waits on the architect
at: 2026-10-12T15:49:15Z
type: feat
ticket: WO-20261012-72a0
sha: null
---

merged 200 now seats the verifier-<ticket> seat on a slot detached at origin/main and takes the merger down; verified 201 and rejected 422 wake the monitor. seat.sh finds an archived ticket for the verifier only.
