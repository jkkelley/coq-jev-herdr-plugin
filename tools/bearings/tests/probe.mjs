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
// The page links Google Fonts. The suite runs with --network=none, so answer
// every non-local request with an empty 200 instead of letting it fail into
// a console error that the "zero page errors" case would count as a defect.
await pg.route(/^https?:\/\/(?!localhost|127\.0\.0\.1)/, (r) => r.fulfill({ status: 200, body: "" }));
await pg.goto(url, { waitUntil: "load" });
await pg.waitForFunction(() => document.querySelector("#live")?.textContent?.trim() === "Live", null, { timeout: 15000 }).catch(() => {});
const live = (await pg.locator("#live").innerText()).trim();
const card = (await pg.locator("#bearing").innerText()).trim();
// Queue the recommended answer on the first card.
let queued = false;
try {
  await pg.locator("#own").fill("probe words");
  await pg.getByRole("button", { name: /queue answer/i }).click({ timeout: 5000 });
  // A queued answer is held in the page's outbox for its undo window (5 s in
  // page.html), then posted on the next poll. Poll the server from Node for up
  // to 45 s. Not waitForFunction: with interval polling Playwright treats a
  // promise-returning predicate as truthy at once and never waits.
  const deadline = Date.now() + 45000;
  while (Date.now() < deadline) {
    const s = await pg.evaluate(async () => (await (await fetch("state", { cache: "no-store" })).json()).answers);
    if (s && s.P1) { queued = true; break; }
    await pg.waitForTimeout(1000);
  }
  if (!queued) errors.push(`queue: answer never reached the server; outbox=${await pg.evaluate(() => localStorage.getItem("bearings:outbox"))}`);
} catch (e) {
  errors.push(`queue: ${e.message}`);
}
if (shot) await pg.screenshot({ path: shot });
const stateAnswers = await pg.evaluate(async () => (await (await fetch("state", { cache: "no-store" })).json()).answers);
console.log(JSON.stringify({ live, card_head: card.slice(0, 120), queued, errors, state_answers: stateAnswers }));
await b.close();
