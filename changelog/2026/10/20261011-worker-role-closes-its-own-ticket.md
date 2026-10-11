---
title: Worker role closes its own ticket
at: 2026-10-11T14:52:25Z
type: fix
ticket: WO-20261011-9639
sha: null
---

Workers could never run submit or done, so the architect closed c077, 36d7 and 4c5e by hand from main. The allow entry gains both verbs, the playbook renders the close-out order, and the breadcrumb lives in the role file under a new optional breadcrumbs field.
