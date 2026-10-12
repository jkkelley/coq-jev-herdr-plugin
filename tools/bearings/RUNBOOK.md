# Runbook - the SITREP panel on a bearings page

## Contents

- Rules that bind
- What this is
- What you get
- Needs
- 1. Put the tool in the repository
- 2. Edit the config
- 3. Build a briefing
- 4. Check it
- 5. Send it
- 6. Prove it
- Changing the panel
- When it goes wrong
- GOOD and NEVER

## Rules that bind

- A briefing is built from records by a script, never typed; every figure is read from a ticket, an event or a pull request.
- A briefing is checked against `standards/STD-owner-sitrep-001.json` before it is sent, and a violation sends nothing.
- A ticket is never named without its full title; the reference sits on its own line under the sentence, never inside it.
- The panel is the owner's locked look.
  Only the words move; `assets/theme.css` and the `sitrep` renderer in `assets/page.html` do not change without an approved sample.
- The surface is the bearings page and nothing else; never a link, never a published page.

## What this is

A message from the agent whose text is `#SITREP/v1#` followed by one JSON object renders on the page as a colored status card, instead of as a chat bubble.
The format is `standards/SITREP-PAYLOAD.md`.
Only a message from the agent draws a panel, so the owner typing the same text gets a bubble.
A payload that does not parse also falls back to a bubble.

## What you get

| Piece | Path | Job |
| --- | --- | --- |
| renderer | `assets/page.html` (`sitrepEl`), `assets/theme.css` | draws the panel from `textContent`, so no payload can become markup |
| build stamp | `scripts/server.mjs` | hashes the page files and reports it on `/state`; a stale tab reloads itself once |
| standards | `standards/STD-owner-sitrep-001.json`, `standards/STD-owner-comms-001.json` | the rules, generic, no owner names or paths |
| limits | `config/sitrep.json` | words per item, items per block, prose budget, ticket id patterns, sources |
| template | `config/sitrep.template.json` | the shape and every sentence of a briefing |
| builder | `scripts/sitrep-build.mjs` | fills the template from tickets, events and open pull requests |
| checker | `scripts/sitrep-check.mjs` | counts the rules, exit 1 on a violation |
| sender | `scripts/bearings.sh <tier> sitrep` | checks, then appends a reply; refuses on a violation |

## Needs

- `node` 20 or newer, `jq`, and `gh` logged in (or a saved `--prs-json` file).
- A running bearings page for the tier (`make serve TIER=stable`), inside herdr.
- Tickets under `work-orders/` whose frontmatter is a JSON object between two `---` lines, and events under `events/YYYY/MM/*.json`.

## 1. Put the tool in the repository

Copy `tools/bearings/` whole.
Nothing in it is specific to one repository except the three config files below.

## 2. Edit the config

- `config/bearings.json`: `project`, tier names and ports, `max_reply_chars` (32000 holds a briefing with full ticket titles).
- `config/sitrep.json` `rules`: the limits, and `ticket_id_patterns`, the regexes that count as a ticket id inside prose.
- `config/sitrep.json` `build`: where tickets and events live (`work_orders_dir`, `events_dir`), the command that lists open pull requests (`prs_command`), the ref that names main (`main_ref`), and how long a failure stays on the briefing (`friction_window_hours`).
- `config/sitrep.template.json`: the blocks, and the sentence of every item.
  `{{name}}` is a fact: `in_progress.count`, `startable.p0`, `friction.code`, `prs.count`.
  `when` drops an item whose fact is empty, `ref_from` fills the ref and its full title from a ticket, `links_from` turns pull requests into link badges.
  A sentence that breaks the standard fails the build, so a template cannot ship a wordy briefing.

## 3. Build a briefing

```sh
make -C tools/bearings sitrep-build TIER=stable OUT=/tmp/briefing.txt
```

The builder prints its counts on stderr: `8 items, 58 words of prose, 5025 characters, 0 violations`.
`SAVE=1` keeps this briefing's queue counts in the tier's state directory, so the next briefing shows a delta; the first one shows `new`.
Exit 3 means the template or the records produce a payload that breaks the standard, and nothing is written.
Exit 4 means a source could not be read, such as `gh` offline.

## 4. Check it

```sh
make -C tools/bearings sitrep-check PAYLOAD=/tmp/briefing.txt
```

Exit 0 means it may be sent.
Exit 1 prints one `VIOLATION` line per broken rule on stderr and means it may not.

## 5. Send it

```sh
make -C tools/bearings sitrep TIER=stable PAYLOAD=/tmp/briefing.txt
make -C tools/bearings sitrep TIER=stable PAYLOAD=/tmp/briefing.txt TO=m-20261012125155555-gvggg
```

The send runs the checker first and exits 3 without writing anything when it fails.
`TO` defaults to the newest message the owner typed on that page; a page with none needs `TO` spelled out.
The payload may be bare JSON or already tagged; what is sent is always the tag plus minified JSON.

## 6. Prove it

```sh
make -C tools/bearings lint
make -C tools/bearings test
```

Run both from the labelled test pane.
The suite checks the rules against a SITREP that was really sent (`tests/fixtures/sitrep-sent-ok.txt`) and against one that breaks them (`tests/fixtures/sitrep-bad.json`), builds from a synthetic repository (`tests/fixtures/repo`), sends and refuses on a live page, and drives a browser to see a panel for the agent, a bubble for the owner, and a bubble for an unparseable payload.

## Changing the panel

- A new fact: add it to `facts` in `scripts/sitrep-build.mjs`, use it in the template, add a case to `tests/sitrep.sh`.
- A new rule: add it to `scripts/lib/sitrep.mjs` and its limit to `config/sitrep.json`; the checker, builder and sender all share that one file.
- A payload field the renderer should draw: change `sitrepEl` in `assets/page.html`, then send the owner a sample before it lands.
  The server stamps the page files, so an open tab reloads itself once; keep `next` beside `next_items` so a tab that has not reloaded still shows text.

## When it goes wrong

- `SITREP refused` on a send: read the `VIOLATION` lines above it; cut the clause that needs a subordinate clause to survive, never raise the limit.
- The panel shows as a bubble of braces: the sender is not the agent (a bubble is the owner's), or the JSON does not parse; run the checker on the file.
- A figure looks wrong: it is a fact from a record; read the ticket frontmatter or the event it came from, then fix that record.
- `open pull requests could not be read`: `gh auth status`, or pass `--prs-json` with a saved listing.

## GOOD and NEVER

GOOD: a briefing from `make sitrep-build`, then `make sitrep-check`, then `make sitrep`, so every figure came from a record and the check ran before the send.
GOOD: a new sentence added to `config/sitrep.template.json` and the build run at once, so a sentence over 15 words fails the build and never reaches the owner.
GOOD: both `next_items` and `next` in every queue, so a tab that has not reloaded still shows text and not `[object Object]`.
GOOD: a build in a repository with no pull requests, run with `--prs-json` on a file holding `[]`, giving a briefing with an empty OPEN PRS queue.
NEVER: typing a count, a title or a ticket id into a payload by hand; the title comes from the ticket file and the figure from a record.
NEVER: raising `max_words_per_item` or `max_prose_words` to make a briefing pass; cut the clause that needs a subordinate clause to survive.
NEVER: a ticket id inside a sentence, or a ticket named without its full title; the reference goes on its own line under the sentence.
NEVER: sending a briefing by writing to `messages.jsonl` or around `bearings.sh sitrep`; the refusal on a violation is what keeps it short.
NEVER: a link, a published page or Markdown in a bubble in place of the panel; the owner reads it on the page or not at all.
