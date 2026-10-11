// Browser probe for the factory board page. Prints one JSON object and exits 0; tests/browser.sh asserts on its fields.
//   node probe.mjs <design.html> <rendered-dir> <live-dir> <shots-dir>
// 1. parity: the design page and the rendered page, byte-identical full-page screenshots at a desktop and a phone width.
// 2. redraw: the page served at /board from <live-dir> asks /board/data.json; a new data.json is drawn in place, with the
//    fold state and the sideways and page scroll kept and no reload; stopping the server turns the strip to "page offline".
// playwright is installed globally in the test image; ESM import ignores NODE_PATH, so resolve it through createRequire.
import { createRequire } from "node:module";
import fs from "node:fs";
import http from "node:http";
import path from "node:path";
const require = createRequire(
  `${process.env.PLAYWRIGHT_GLOBAL_MODULES || "/usr/lib/node_modules"}/`,
);
const { chromium } = require("playwright");
const [designHtml, renderedDir, liveDir, shots] = process.argv.slice(2);
const out = { parity: [], redraw: {}, errors: [] };
const browser = await chromium.launch();
// The page links Google Fonts. The suite runs with --network=none, so answer every non-local request with an empty 200 and
// both pages fall back to the same fonts; a failed request would be a console error counted below.
// Once the test stops the server on purpose, the page's refused asks are the behaviour under test, not an error.
let serverStopped = false;
const quiet = (pg) => {
  pg.on("pageerror", (e) => out.errors.push(String(e)));
  pg.on(
    "console",
    (m) =>
      m.type() === "error" &&
      !serverStopped &&
      out.errors.push(`console: ${m.text()}`),
  );
  return pg.route(/^https?:\/\/(?!localhost|127\.0\.0\.1)/, (r) =>
    r.fulfill({ status: 200, body: "" }),
  );
};

for (const vp of [
  { width: 1100, height: 900 },
  { width: 390, height: 800 },
]) {
  const ctx = await browser.newContext({
    viewport: vp,
    reducedMotion: "reduce",
  });
  const pg = await ctx.newPage();
  await quiet(pg);
  // Warm-up. The first full-page screenshot a page takes is 11px shorter than every later one, whichever page it is (measured on
  // 2026-10-11 UTC, alternating rendered and design for three rounds at 1100px: 3560, 3571, 3571, 3571, 3571, 3571; at 390px
  // 5446 then 5517 throughout; a plain second load of the design did not cure it, a screenshot did). Without this the page that
  // was shot first looked different from the other. One unmeasured screenshot first and the order stops mattering.
  // Cause not chased: a full-page shot resizes the viewport, and the first resize likely settles a late layout.
  await pg.goto(`file://${designHtml}`, { waitUntil: "load" });
  await pg.evaluate(() => document.fonts.ready);
  await pg.screenshot({ fullPage: true });
  await pg.goto(`file://${path.join(renderedDir, "index.html")}`, { waitUntil: "load" });
  await pg.screenshot({ fullPage: true });
  await pg.goto(`file://${designHtml}`, { waitUntil: "load" });
  await pg.evaluate(() => document.fonts.ready);
  const a = await pg.screenshot({ fullPage: true });
  const domA = await pg.evaluate(
    () => document.querySelector(".wrap").outerHTML,
  );
  await pg.goto(`file://${path.join(renderedDir, "index.html")}`, {
    waitUntil: "load",
  });
  await pg.evaluate(() => document.fonts.ready);
  const b = await pg.screenshot({ fullPage: true });
  // The design calls a stopped belt "queued", a class no rule styles; the entry says "stopped". Same pixels, so compare the DOM as the design spells it.
  const domB = (
    await pg.evaluate(() => document.querySelector(".wrap").outerHTML)
  ).replaceAll('class="belt stopped"', 'class="belt queued"');
  const boxes = () =>
    document.querySelectorAll("body *").length &&
    [...document.querySelectorAll("body *")].map((e) => {
      const r = e.getBoundingClientRect();
      return `${e.tagName}.${String(e.className).replace("belt stopped", "belt queued")}|${Math.round(r.x)},${Math.round(r.y + scrollY)},${Math.round(r.width)},${Math.round(r.height)}|${getComputedStyle(e).fontFamily.slice(0, 40)}`;
    });
  const boxesB = await pg.evaluate(boxes);
  await pg.goto(`file://${designHtml}`, { waitUntil: "load" });
  const boxesA = await pg.evaluate(boxes);
  const dims = () => [
    document.documentElement.scrollWidth,
    document.documentElement.scrollHeight,
    document.body.scrollHeight,
    document.compatMode,
  ];
  const dimsA = await pg.evaluate(dims);
  await pg.goto(`file://${path.join(renderedDir, "index.html")}`, {
    waitUntil: "load",
  });
  out.dims = [
    ...(out.dims || []),
    {
      width: vp.width,
      design: dimsA,
      rendered: await pg.evaluate(dims),
      boxes: [boxesA.length, boxesB.length],
    },
  ];
  const firstBox = boxesA.findIndex((v, i) => v !== boxesB[i]);
  if (firstBox >= 0)
    out.first_box_diff = {
      width: vp.width,
      index: firstBox,
      design: boxesA.slice(firstBox, firstBox + 3),
      rendered: boxesB.slice(firstBox, firstBox + 3),
    };
  if (domA !== domB) {
    let i = 0;
    while (i < domA.length && domA[i] === domB[i]) i++;
    out.parity_dom_diff = {
      width: vp.width,
      at: i,
      design: domA.slice(Math.max(0, i - 80), i + 120),
      rendered: domB.slice(Math.max(0, i - 80), i + 120),
    };
  }
  fs.writeFileSync(path.join(shots, `design-${vp.width}.png`), a);
  fs.writeFileSync(path.join(shots, `rendered-${vp.width}.png`), b);
  out.parity.push({
    width: vp.width,
    same: a.equals(b),
    design_bytes: a.length,
    rendered_bytes: b.length,
  });
  await ctx.close();
}

// --- redraw in place ---
const read = (f) => fs.readFileSync(path.join(liveDir, f));
const server = http.createServer((req, res) => {
  if (req.url === "/board")
    res
      .writeHead(200, { "content-type": "text/html; charset=utf-8" })
      .end(read("index.html"));
  else if (req.url === "/board/data.json")
    res
      .writeHead(200, { "content-type": "application/json" })
      .end(read("data.json"));
  else res.writeHead(404).end("no");
});
await new Promise((r) => server.listen(0, "127.0.0.1", r));
const url = `http://127.0.0.1:${server.address().port}/board`;
const ctx = await browser.newContext({
  viewport: { width: 1100, height: 700 },
  reducedMotion: "reduce",
});
const pg = await ctx.newPage();
await quiet(pg);
await pg.goto(url, { waitUntil: "load" });
const before = JSON.parse(read("data.json"));
out.redraw.first_headline = await pg.locator("#headline").innerText();
out.redraw.page_live_pill =
  (await pg.locator("#strip").innerText()).includes("PAGE LIVE") ||
  (await pg.locator("#strip").innerText()).toLowerCase().includes("page live");
// Fold line 1, scroll line 2 sideways, scroll the page, mark the document: none of it may be lost by a redraw.
await pg.evaluate(() => {
  window.__marker = "same-document";
  document.querySelector("#L1 details").open = false;
  document.querySelector("#L2 .track").scrollLeft = 250;
  window.scrollTo(0, 120);
});
const next = structuredClone(before);
next.number += 1;
next.headline = "Redrawn in place";
next.lines.push(
  Object.assign(structuredClone(next.lines[1]), {
    id: "L6",
    name: "A new line",
  }),
);
fs.writeFileSync(
  path.join(liveDir, "data.json"),
  JSON.stringify(next, null, 2),
);
const started = Date.now();
await pg
  .waitForFunction(
    () =>
      document.querySelector("#headline")?.textContent === "Redrawn in place",
    null,
    { timeout: 25000 },
  )
  .catch(() => {});
out.redraw.seconds = Math.round((Date.now() - started) / 100) / 10;
out.redraw.headline = await pg.locator("#headline").innerText();
out.redraw.new_line_drawn = (await pg.locator("#L6").count()) === 1;
out.redraw.same_document =
  (await pg.evaluate(() => window.__marker)) === "same-document";
out.redraw.line1_still_folded = !(await pg.evaluate(
  () => document.querySelector("#L1 details").open,
));
out.redraw.line2_scroll = await pg.evaluate(
  () => document.querySelector("#L2 .track").scrollLeft,
);
out.redraw.page_scroll = await pg.evaluate(() => Math.round(window.scrollY));
// The server goes away: the strip says so within a poll.
serverStopped = true;
server.closeAllConnections?.();
await new Promise((r) => server.close(r));
await pg
  .waitForFunction(
    () =>
      /page offline/i.test(document.querySelector("#strip")?.textContent || ""),
    null,
    { timeout: 25000 },
  )
  .catch(() => {});
out.redraw.offline_pill = /page offline/i.test(
  await pg.locator("#strip").innerText(),
);
await ctx.close();
await browser.close();
console.log(JSON.stringify(out));
