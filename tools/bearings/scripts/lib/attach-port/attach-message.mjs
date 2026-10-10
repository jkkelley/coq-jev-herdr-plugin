    if (req.method === "POST" && url.pathname === "/message") {
      readBody(req, res, (m) => {
        const text = String(m.text || "").trim();
        const knownFiles = filesNow();
        const files = [];
        for (const f of Array.isArray(m.files) ? m.files : []) {
          const rec = knownFiles[f?.id];
          if (!rec)
            return send(res, 400, { error: `unknown file id ${f?.id}` });
          files.push({
            id: rec.id,
            name: rec.name,
            mime: rec.mime,
            size: rec.size,
          });
        }
        if (
          !/^m-[A-Za-z0-9._:-]{1,64}$/.test(String(m.id)) ||
          (!text && !files.length)
        )
          return send(res, 400, {
            error: "message needs an id and text or a file",
          });
        const existing = readJsonl("messages.jsonl").find((x) => x.id === m.id);
        if (existing) return send(res, 200, existing);
        const line = {
          id: m.id,
          from: "you",
          text: text.slice(0, 8000),
          at: typeof m.at === "string" ? m.at : new Date().toISOString(),
          ...(files.length ? { files } : {}),
        };
        fs.appendFileSync(file("messages.jsonl"), `${JSON.stringify(line)}\n`);
        touch();
        send(res, 200, line);
      });
      return;
    }
    if (req.method === "POST" && url.pathname === "/answer") {
