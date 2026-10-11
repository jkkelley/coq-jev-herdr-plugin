# Factory board design reference

- `loop-design-iteration-5.html` is the page the owner locked on 2026-10-11 UTC ("ohhhh that's sooooooo goooood thanks, lock that in"), published as https://claude.ai/artifact/4w921E7QAXZ6UzoACsiHYV version 5.
- Its `DATA` block is the shape `report/loop/loop.sh collect` must emit and `schema/loop.schema.json` must constrain; its markup and CSS become `assets/template.html` with the data block replaced by a placeholder the renderer fills.
- The four simulated lines (L2 to L5) exist only to prove the layout; a real collect derives every line from records and ticket files, never from this file.
- Ticket: WO-20261011-616c - Factory board: report/loop renders the lines from records and bearings stable serves it live.
