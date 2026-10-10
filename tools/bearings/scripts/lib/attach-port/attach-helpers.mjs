  // Attachments (WK-20260916-068): one files/ dir per page, one files.jsonl line per upload,
  // the same append-only shape as answers.jsonl and messages.jsonl.
  const FILES_DIR = file("files");
  fs.mkdirSync(FILES_DIR, { recursive: true });
  const FILE_MAX_BYTES = cfg.file_max_bytes;
  // R1 of the WK-20260916-066 design review: inline rendering is an allowlist, not a denylist.
  // Serving a stored file inline puts it on the page's own origin; an HTML file or an SVG (a
  // script container wearing an image's MIME type) would then run as the page, with the page's
  // key and DOM. Only these four ever render inline; everything else, whatever it is, downloads.
  const INLINE_MIME_TYPES = new Set([
    "image/png",
    "image/jpeg",
    "image/gif",
    "image/webp",
  ]);
  // B2 of the design review: an allowlist of claimed types is only as honest as the client, and
  // a browser that sniffs content will render whatever the bytes actually are, on the page's own
  // origin, however the upload declared itself. Checked once at upload time, by magic bytes, not
  // trusted from the content-type header the way EXT_BY_MIME's cosmetic extension is.
  const MAGIC_CHECKS = {
    "image/png": (b) =>
      b.length >= 8 &&
      b[0] === 0x89 &&
      b[1] === 0x50 &&
      b[2] === 0x4e &&
      b[3] === 0x47 &&
      b[4] === 0x0d &&
      b[5] === 0x0a &&
      b[6] === 0x1a &&
      b[7] === 0x0a,
    "image/jpeg": (b) =>
      b.length >= 3 && b[0] === 0xff && b[1] === 0xd8 && b[2] === 0xff,
    "image/gif": (b) =>
      b.length >= 6 &&
      (b.toString("latin1", 0, 6) === "GIF87a" ||
        b.toString("latin1", 0, 6) === "GIF89a"),
    "image/webp": (b) =>
      b.length >= 12 &&
      b.toString("latin1", 0, 4) === "RIFF" &&
      b.toString("latin1", 8, 12) === "WEBP",
  };
  // The file is stored either way (the owner accepts any type); only whether it is later
  // eligible for inline serving changes. A declared type outside the inline set is not checked
  // here at all, since only a false inline claim can turn a render into a script execution.
  const effectiveMime = (declaredMime, buf) => {
    const check = MAGIC_CHECKS[declaredMime];
    return check && !check(buf) ? "application/octet-stream" : declaredMime;
  };
  // B1 and the CSP addition: nosniff belongs on the inline branch too, since a lying declared
  // type is now caught by effectiveMime, but a future inline type added without a magic check
  // should not rely on the allowlist alone. default-src 'none'; sandbox costs nothing for an
  // image and makes even a genuine inline render inert if it somehow carried anything active.
  const FILE_RESPONSE_HEADERS = {
    "x-content-type-options": "nosniff",
    "content-security-policy": "default-src 'none'; sandbox",
    "cache-control": "no-store",
  };
  // Cosmetic only, for a save-as dialog: the server always serves by the MIME type it recorded
  // at upload time, never by guessing from this extension.
  const EXT_BY_MIME = {
    "image/png": "png",
    "image/jpeg": "jpg",
    "image/gif": "gif",
    "image/webp": "webp",
    "application/pdf": "pdf",
    "text/plain": "txt",
    "text/csv": "csv",
    "application/json": "json",
    "application/zip": "zip",
  };
  const fileId = () =>
    `f-${new Date().toISOString().replace(/[^0-9]/g, "")}-${Math.random().toString(36).slice(2, 7)}`;
  // R2 of the design review: a client-supplied name is attacker-shaped data by the time it
  // reaches a header value. Strip CR, LF and quotes regardless of where this name came from or
  // where it is going next, and cap its length so a header is never built from something absurd.
  const sanitizeName = (raw) => {
    const cleaned = String(raw || "")
      .replace(/[\r\n"]/g, "")
      .slice(0, 200)
      .trim();
    return cleaned || "file";
  };
  // x-file-name is a request header, latin-1 by specification; the client percent-encodes it
  // before sending so a Windows filename outside that range survives the trip intact.
  const decodeHeaderName = (raw) => {
    if (!raw) return "file";
    try {
      return sanitizeName(decodeURIComponent(raw));
    } catch {
      return "file";
    }
  };
  // filename*=UTF-8''<percent-encoded>, per R2: a quote or a newline in the name is header
  // injection if it lands inside a plain quoted filename="..." value instead.
  const dispositionHeader = (kind, name) =>
    `${kind}; filename*=UTF-8''${encodeURIComponent(sanitizeName(name))}`;
  const filesNow = () => {
    const byId = {};
    for (const f of readJsonl("files.jsonl")) byId[f.id] = f;
    return byId;
  };
  const readBinaryBody = (req, res, handle) => {
    const declared = Number(req.headers["content-length"] || 0);
    if (declared > FILE_MAX_BYTES) {
      send(res, 413, { error: `file over ${FILE_MAX_BYTES} bytes` });
      req.destroy();
      return;
    }
    // A declared Content-Length past the cap is refused above without reading a byte. A body
    // that lies about its length (no header, or a smaller one) is caught here instead, the same
    // way the existing readBody caps a JSON body: destroy without a graceful response, since the
    // socket has already been torn down mid-upload and nothing sent now would reach the client.
    const chunks = [];
    let size = 0;
    req.on("data", (c) => {
      size += c.length;
      if (size > FILE_MAX_BYTES) return req.destroy();
      chunks.push(c);
    });
    req.on("end", () => {
