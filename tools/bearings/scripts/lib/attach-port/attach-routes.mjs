    // An upload ahead of the message text it will ride in with (WK-20260916-068). The body is
    // the raw file bytes; content-type and x-file-name (percent-encoded, R2) describe it.
    if (req.method === "POST" && url.pathname === "/file") {
      readBinaryBody(req, res, (buf) => {
        if (!buf.length) return send(res, 400, { error: "empty file" });
        const declaredMime = String(
          req.headers["content-type"] || "application/octet-stream",
        )
          .split(";")[0]
          .trim()
          .toLowerCase();
        // B2: the file is kept either way, whatever it is; only whether it is later eligible for
        // inline serving depends on its bytes actually matching what was declared.
        const mime = effectiveMime(declaredMime, buf);
        const name = decodeHeaderName(req.headers["x-file-name"]);
        const id = fileId();
        const ext = EXT_BY_MIME[mime] || "bin";
        const storedPath = path.join(FILES_DIR, `${id}.${ext}`);
        fs.writeFileSync(storedPath, buf);
        const line = {
          id,
          name,
          mime,
          size: buf.length,
          path: storedPath,
          at: new Date().toISOString(),
        };
        fs.appendFileSync(file("files.jsonl"), `${JSON.stringify(line)}\n`);
        touch();
        send(res, 200, { id, name, mime, size: buf.length });
      });
      return;
    }
    // A stored attachment served back. R1: inline only for the four image types nothing browser-
    // side will run as a script, decided on the bytes recorded at upload time (B2), never on a
    // fresh read of the declared type; every response, inline or not, carries nosniff and a CSP
    // that makes even a genuine inline render inert (B1).
    if (req.method === "GET" && /^\/file\/[^/]+$/.test(url.pathname)) {
      const id = url.pathname.slice("/file/".length);
      if (!/^f-[A-Za-z0-9._:-]{1,64}$/.test(id))
        return send(res, 400, { error: "bad file id" });
      const rec = filesNow()[id];
      if (!rec || !fs.existsSync(rec.path))
        return send(res, 404, { error: "not found" });
      if (INLINE_MIME_TYPES.has(rec.mime)) {
        res.writeHead(200, {
          ...FILE_RESPONSE_HEADERS,
          "content-type": rec.mime,
          "content-disposition": dispositionHeader("inline", rec.name),
        });
      } else {
        res.writeHead(200, {
          ...FILE_RESPONSE_HEADERS,
          "content-type": "application/octet-stream",
          "content-disposition": dispositionHeader("attachment", rec.name),
        });
      }
      touch();
      fs.createReadStream(rec.path).pipe(res);
      return;
    }
    // A message typed at the bottom of the page. Retries after a refresh reuse the id, so
    // a message is stored once no matter how many times the page sends it.
