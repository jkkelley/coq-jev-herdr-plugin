# `#SITREP/v1#` payload format

## Contents

- Top level
- stats
- blocks
- items
- links
- queues, block 4 only
- How it is made and sent
- GOOD and NEVER

The page that draws this is `assets/page.html` (`sitrepEl`); the rules it is held to are `STD-owner-sitrep-001.json`; the limits are `config/sitrep.json`.

The message text is the literal prefix `#SITREP/v1#` immediately followed by one JSON object, no whitespace needed.
Anything that does not start with that prefix, or whose JSON does not parse, renders as an ordinary chat bubble.
Only messages from `claude` are treated as panels, so the owner typing the same text gets an ordinary bubble.

## Top level

| Field | Type | Notes |
| --- | --- | --- |
| `scope` | string | Shown as a pill beside the title, for example `STABLE / CREW`. |
| `state` | string | `nominal`, `degraded` or `critical`. Picks the status pill colour. |
| `state_label` | string | The pill text, for example `DEGRADED`. |
| `updated` | string | Stamp as `YYYY-MM-DD HH:MM UTC`. |
| `stats` | array | Up to 4 telemetry cards. |
| `blocks` | array | The five blocks, in fixed order. |

## `stats[]`

| Field | Type | Notes |
| --- | --- | --- |
| `label` | string | Uppercase mono label, for example `CREW`. |
| `value` | string | The figure. Kept as a string so `4d60e5c` and `39` render the same way. |
| `note` | string | Short qualifier beside the figure. |
| `tone` | string | `good`, `warn`, `bad` or `mute`. Colours the note only. |

## `blocks[]`

| Field | Type | Notes |
| --- | --- | --- |
| `n` | string | Block number as text, `01` to `05`. |
| `name` | string | Block name, uppercase. |
| `items` | array | At most 2. Blocks 1, 2, 3 and 5. |
| `queues` | array | Block 4 only. |

The five blocks are fixed and nothing follows block 5:
`01 EXECUTIVE GROUND TRUTH`, `02 DELTA`, `03 ACTIVE OPERATIONS`, `04 QUEUE MATRIX`, `05 TACTICAL NEXT STEPS`.

## `items[]`

| Field | Type | Notes |
| --- | --- | --- |
| `label` | string | Uppercase mono label above the sentence. |
| `text` | string | ONE sentence, 15 words or fewer, no semicolon, no ticket id. |
| `tone` | string | `bad` or `warn` tints the card and the label. Omit for normal. |
| `check` | bool | Draws a tick, for work that is done. |
| `ref` | string | A ticket id. Rendered on its own line under the sentence. |
| `ref_title` | string | That ticket's FULL title, taken from the row or design file itself. Required whenever `ref` is set. |
| `links` | array | Up to 3 link badges. |

## `links[]`

| Field | Type | Notes |
| --- | --- | --- |
| `href` | string | Required. Only `http:` and `https:` are rendered; anything else is dropped silently. |
| `label` | string | Optional. Omit it and the url is minified: a GitHub pull request becomes `repo #18`, anything else becomes `host / last-path-segment`. |

## `queues[]`, block 4 only

| Field | Type | Notes |
| --- | --- | --- |
| `name` | string | Queue name, uppercase. |
| `count` | string | How many are open. |
| `delta` | string | Change since the last briefing, for example `-1`. |
| `tone` | string | `good`, `warn`, `bad` or `mute`. |
| `urgency` | string | Badge text, for example `12 P0` or `1 buildable`. |
| `next_items` | array | Up to 5 objects of `{id, title}`, the id as a chip and the full title beside it. |
| `next` | array | The same five as plain `ID - title` strings. |

Send BOTH `next_items` and `next`.
`next_items` is what a current renderer draws; `next` is what a tab running an older renderer falls back to, instead of printing `[object Object]`.
A stale tab once printed `[object Object]` because only the structured form was sent.

## How it is made and sent

`scripts/sitrep-build.mjs` fills `config/sitrep.template.json` from this repository's events, work orders and open pull requests.
`scripts/sitrep-check.mjs` measures a payload against the standard and exits 1 on a violation.
`scripts/bearings.sh <tier> sitrep --payload FILE` checks, then sends it as a reply, and refuses when the check fails.
`tests/fixtures/sitrep-sent-ok.txt` is a real briefing that was sent: 8 items, 70 words of prose, 0 violations.

## GOOD and NEVER

GOOD: a passing item, one sentence of 15 words or fewer, the ticket on its own line with its full title.

```json
{"label":"FRICTION","tone":"bad","text":"The newest unresolved failure record is code 423, filed 4 hours ago.","ref":"WO-20261001-bb01","ref_title":"Synthetic in progress ticket one"}
```

GOOD: a queue that sends both forms, the structured `next_items` and the plain `next`, at most five of each.

```json
{"name":"STARTABLE","count":"2","delta":"-1","tone":"good","urgency":"2 P0","next_items":[{"id":"WO-20261001-aa01","title":"Synthetic ready ticket one"}],"next":["WO-20261001-aa01 - Synthetic ready ticket one"]}
```

NEVER: an item that fails the checker; each line below breaks a rule, and `tests/fixtures/sitrep-bad.json` holds these three.

```json
{"label":"LONG","text":"This single sentence runs on and on well past the fifteen word limit that the standard sets for every item."}
{"label":"SEMI","text":"One thing happened; then another."}
{"label":"IDS","text":"WO-20261001-aa01 is done.","ref":"WO-20261001-aa01"}
```

NEVER: a third item in a block, a sixth block, a `ref` with no `ref_title`, or a `links` entry that is not an http or https url.
NEVER: a payload sent around `bearings.sh <tier> sitrep`; the checker runs there and a violation sends nothing.
