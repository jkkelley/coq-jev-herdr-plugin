---
title: flow watch writes one 500 per stall
at: 2026-10-11T19:15:12Z
type: feat
ticket: WO-20261011-6842
sha: null
---

factory/bin/flow.sh once|run|status reads factory/config/flow.json, latches each note, and the suite cases 09 and 10 prove gate, belt and pane stalls.
