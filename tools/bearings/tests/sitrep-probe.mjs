// Browser probe for the SITREP panel (WO-20261012-668a). Prints one JSON object and exits 0; tests/sitrep.sh asserts on it.
// Usage: node sitrep-probe.mjs <url> <shot.png> [panel.png]   panel.png is a screenshot of the panel element alone
// Waits until the thread holds the messages the harness wrote, then reports what was drawn for each: a panel, or a bubble.
import { createRequire } from "node:module";
const require = createRequire(`${process.env.PLAYWRIGHT_GLOBAL_MODULES || "/usr/lib/node_modules"}/`);
const { chromium } = require("playwright");
const [url, shot, panelShot] = process.argv.slice(2);
const b = await chromium.launch();
const pg = await b.newPage({ viewport: { width: 1200, height: 1400 } });
const errors = [];
pg.on("pageerror", (e) => errors.push(String(e)));
pg.on("console", (m) => m.type() === "error" && errors.push(`console: ${m.text()}`));
await pg.route(/^https?:\/\/(?!localhost|127\.0\.0\.1)/, (r) => r.fulfill({ status: 200, body: "" }));
await pg.goto(url, { waitUntil: "load" });
await pg.waitForFunction(() => document.querySelectorAll("#thread > *").length >= 3, null, { timeout: 15000 }).catch(() => {});
const out = await pg.evaluate(() => {
  const kids = Array.from(document.querySelectorAll("#thread > *"));
  const panel = document.querySelector(".sitrep");
  return {
    kinds: kids.map((k) => (k.classList.contains("sitrep") ? "panel" : k.classList.contains("bubble") ? "bubble:" + (k.textContent || "").slice(0, 40) : k.className)),
    panels: document.querySelectorAll(".sitrep").length,
    blocks: panel ? panel.querySelectorAll(".sr-block").length : 0,
    stats: panel ? panel.querySelectorAll(".sr-stat").length : 0,
    queues: panel ? panel.querySelectorAll(".sr-q").length : 0,
    refs: panel ? Array.from(panel.querySelectorAll(".sr-ref")).map((r) => r.textContent) : [],
    badges: panel ? Array.from(panel.querySelectorAll("a")).map((a) => a.getAttribute("href")) : [],
    pill: panel ? panel.querySelector(".sr-pill")?.textContent : null,
    object_object: document.body.innerText.includes("[object Object]"),
    // The owner's identical text is drawn as a bubble on purpose, so only the panel is held to showing no braces.
    raw_json_visible: panel ? panel.innerText.includes('{"') : true,
    announcer: document.querySelector("#live-announcer")?.textContent ?? "",
    build_const: (document.documentElement.innerHTML.match(/PAGE_BUILD = "([^"]*)"/) || [])[1] ?? null,
  };
});
if (shot) await pg.screenshot({ path: shot, fullPage: true });
// The thread scrolls inside the page and sits pinned to its newest message, so the panel has to be shot as an element.
// The box clips what it holds, so for this shot only it is let grow to the panel's full height; nothing is asserted after it.
if (panelShot && out.panels) {
  await pg.evaluate(() => {
    const t = document.querySelector("#thread");
    t.style.maxHeight = "none";
    t.style.height = "auto";
    t.style.overflow = "visible";
    document.querySelectorAll("#thread > :not(.sitrep)").forEach((e) => (e.style.display = "none"));
  });
  await pg.locator(".sitrep").first().screenshot({ path: panelShot });
}
console.log(JSON.stringify({ ...out, errors }));
await b.close();
