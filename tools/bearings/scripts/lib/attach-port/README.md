# attach-port (work in progress, 2026-10-10 19:30 UTC)

## Contents

- What this is
- Next steps

## What this is

Verbatim extracts from ~/projects/getting-my-bearings/skills/getting-my-bearings/scripts/server.mjs (Sep 19 version, WK-20260916-066/068/069): the attachment helpers (lines 96-215), the POST /file and GET /file/:id routes (361-423) and the files-aware POST /message (424-462).
assets/page.html and theme.css are already the newer page (they carry the paste and drop composer and the #list element).
Owner ask on the page, m-20261010192521524-wfo6h: paste an image from the clipboard into the chat.

## Next steps

1. Insert attach-helpers.mjs into server.mjs after the readJsonl helper; FILE_MAX_BYTES already reads cfg.file_max_bytes, so add file_max_bytes (25 MiB) to config/bearings.json and its schema.
2. Insert attach-routes.mjs before the /message route and replace the /message route with attach-message.mjs (text is capped by cfg.max_message_chars there).
3. wait.mjs: resolve files.jsonl ids to paths and append " | files: <path>[, <path>]" to the MESSAGE line (newer wait.mjs lines 88-105).
4. tests/inside.sh: one case posting a PNG to /file, one message carrying it, wait prints the path; probe unchanged.
5. Delete this directory when the port is in.
