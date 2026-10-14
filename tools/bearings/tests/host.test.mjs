// Unit test for scripts/lib/host.mjs (node --test tests/host.test.mjs; also run by tests/inside.sh).
// The Tailscale front door sends a Host header with no port; the loopback callers send one with the server port.
import assert from "node:assert/strict";
import test from "node:test";
import { hostAllowed } from "../scripts/lib/host.mjs";

const ALLOWED = ["127.0.0.1", "localhost", "whoadudette-1.tailef6830.ts.net", "whoadudette-1", "100.122.200.108"];
const PORT = 44900;
const ok = (h) => assert.equal(hostAllowed(h, ALLOWED, PORT), true, `expected ${h} allowed`);
const no = (h) => assert.equal(hostAllowed(h, ALLOWED, PORT), false, `expected ${h} refused`);

test("loopback with the server port still passes", () => {
  ok("127.0.0.1:44900");
  ok("localhost:44900");
});

test("tailnet names pass with no port (Tailscale serve on 443 or 80) and with the server port", () => {
  for (const h of ["whoadudette-1.tailef6830.ts.net", "whoadudette-1", "100.122.200.108"]) {
    ok(h);
    ok(`${h}:44900`);
  }
});

test("name match ignores case", () => {
  ok("WhoAduDette-1.TAILEF6830.ts.net");
});

test("a wrong port is refused even for an allowed name", () => {
  no("127.0.0.1:44901");
  no("whoadudette-1.tailef6830.ts.net:8080");
  no("localhost:0");
});

test("unknown names, lookalikes and rebinding hosts are refused", () => {
  no("evil.example.com");
  no("evil.example.com:44900");
  no("whoadudette-1.tailef6830.ts.net.evil.com");
  no("evilwhoadudette-1");
  no("100.122.200.109");
  no("127.0.0.1.evil.com");
});

test("malformed headers are refused", () => {
  no("");
  no(undefined);
  no("user@127.0.0.1");
  no("127.0.0.1/x");
  no("127.0.0.1:");
  no("127.0.0.1:44900:1");
  no(" 127.0.0.1");
});
