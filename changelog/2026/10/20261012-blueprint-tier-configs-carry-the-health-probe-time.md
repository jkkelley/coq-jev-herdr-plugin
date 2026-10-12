---
title: Blueprint tier configs carry the health probe timeout; serve.sh --check reads it
at: 2026-10-12T16:31:18Z
type: fix
ticket: WO-20261011-ceea
sha: null
---

serve.sh had timeout=3 typed in; probe_timeout_seconds is now a required field of tier.schema.json and of dev, uat and stable, and a unit test fails if a literal returns.
