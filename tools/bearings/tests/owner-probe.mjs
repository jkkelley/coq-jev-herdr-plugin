// Browser probe for the owner lane and the health line (WO-20261013-b221). Prints one JSON object; tests/owner.sh asserts on it.
// Usage: node owner-probe.mjs <url> <shot.png>
import { createRequire } from "node:module";
const require = createRequire(`${process.env.PLAYWRIGHT_GLOBAL_MODULES || "/usr/lib/node_modules"}/`);
const { chromium } = require("playwright");
const [url, shot] = process.argv.slice(2);
const b = await chromium.launch();
const pg = await b.newPage({ viewport: { width: 1200, height: 1400 } });
const errors = [];
pg.on("pageerror", (e) => errors.push(String(e)));
pg.on("console", (m) => m.type() === "error" && errors.push(`console: ${m.text()}`));
await pg.route(/^https?:\/\/(?!localhost|127\.0\.0\.1)/, (r) => r.fulfill({ status: 200, body: "" }));
await pg.goto(url, { waitUntil: "load" });
await pg.waitForFunction(() => document.querySelector("#live")?.textContent?.trim() === "Live", null, { timeout: 15000 }).catch(() => {});
await pg.waitForFunction(() => !document.querySelector("#health")?.hidden, null, { timeout: 15000 }).catch(() => {});
const out = await pg.evaluate(() => ({
  health_hidden: document.querySelector("#health").hidden,
  health_head: document.querySelector("#health-head").textContent,
  health_text: document.querySelector("#health-list").innerText,
  card: document.querySelector("#bearing").innerText,
  list_rows: document.querySelectorAll("#list .item").length,
  object_object: document.body.innerText.includes("[object Object]"),
}));
if (shot) await pg.screenshot({ path: shot, fullPage: true });
console.log(JSON.stringify({ ...out, errors }));
await b.close();
