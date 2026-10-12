---
title: Standing policies: an unanswered escalation takes its policy default at the deadline
at: 2026-10-12T15:41:02Z
type: feat
ticket: WO-20261012-9b2c
sha: null
---

factory/bin/policy.sh reads factory/config/policies.json and, for an escalation a row covers that nobody answered by its deadline, writes a policy.applied 200 record naming the row and wakes the seat; an escalation with no row still waits, and break.glass is refused.
