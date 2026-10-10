// Browser probe for a running bearings page. Prints one JSON object and exits 0;
// the harness asserts on its fields. Usage: node probe.mjs <url> <shot.png>
// The playwright package is installed globally in the test image. ESM import
// ignores NODE_PATH, so resolve it through createRequire from the global
// modules dir (tests/Containerfile sets PLAYWRIGHT_GLOBAL_MODULES).
import { createRequire } from "node:module";
const require = createRequire(`${process.env.PLAYWRIGHT_GLOBAL_MODULES || "/usr/lib/node_modules"}/`);
const { chromium } = require("playwright");
const [url, shot] = process.argv.slice(2);
const b = await chromium.launch();
const pg = await b.newPage({ viewport: { width: 1200, height: 900 } });
const errors = [];
pg.on("pageerror", (e) => errors.push(String(e)));
pg.on("console", (m) => m.type() === "error" && errors.push(`console: ${m.text()}`));
await pg.goto(url, { waitUntil: "load" });
await pg.waitForFunction(() => document.querySelector("#live")?.textContent?.trim() === "Live", null, { timeout: 15000 }).catch(() => {});
const live = (await pg.locator("#live").innerText()).trim();
const card = (await pg.locator("#bearing").innerText()).trim();
// Queue the recommended answer on the first card.
let queued = false;
try {
  await pg.locator("#own").fill("probe words");
  await pg.getByRole("button", { name: /queue answer/i }).click({ timeout: 5000 });
  await pg.waitForTimeout(3000); // the page flushes its outbox on the next poll
  queued = true;
} catch (e) {
  errors.push(`queue: ${e.message}`);
}
if (shot) await pg.screenshot({ path: shot });
console.log(JSON.stringify({ live, card_head: card.slice(0, 120), queued, errors }));
await b.close();
