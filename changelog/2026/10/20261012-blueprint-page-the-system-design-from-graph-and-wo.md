---
title: Blueprint page: the system design from graph/ and work-orders/ as done, in flight and coming up, three tiers dev, uat, stable
at: 2026-10-12T12:48:11Z
type: feat
ticket: WO-20261011-ceea
sha: null
---

report/loop renders a second view from config; report/blueprint serves dev, uat and stable on three ports and promote.sh moves a tagged build forward; bringup.sh lists the three server panes at 3.3.1 to 3.3.3 and recover.sh restarts a killed one; Jenkins runs the suite when report/, graph/ or work-orders/ change.
