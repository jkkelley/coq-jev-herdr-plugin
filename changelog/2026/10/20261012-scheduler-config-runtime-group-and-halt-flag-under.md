---
title: Scheduler config: runtime group and halt flag under the state dir
at: 2026-10-12T20:12:17Z
type: feat
ticket: WO-20261012-e27e
sha: null
---

scheduler.json 1.1.0 gains runtime.image (name and tag), runtime.image_digest (an ENV variable the wrapper exports), runtime.memory and runtime.container_name; halt_flag moves under the state dir the container sees.
