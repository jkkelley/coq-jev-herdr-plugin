// Host-header check for the bearings page server (tools/bearings/scripts/server.mjs).
//
// What broke: server.mjs matched `host === "<allowed>:<port>"` exactly (the line this module replaces). A Tailscale
// serve front door (HTTPS on 443, or HTTP on 80) forwards the client's original Host header, which carries no
// `:44900`, so every request from the owner's phone over the tailnet got 403 "bad host".
// Why this fix: accept an allowed host name with no port, or with exactly the server's own port. Any other port, any
// unknown name, a userinfo or path smuggled into the header, and an empty header are still refused, so the guard
// against DNS-rebinding (a hostile name resolving to 127.0.0.1) is unchanged: the name must still be on the list.
// The server keeps listening on 127.0.0.1 only (listen_host is not touched); Tailscale is the only way in.
// Rejected: binding listen_host to the tailnet address (exposes the port to the whole tailnet without the proxy and
// breaks the loopback tests), and dropping the check when a header is portless (turns the guard off for rebinding).
// Cost: `localhost` and `127.0.0.1` with no port also pass now; they reach port 80 of the caller's own machine, not
// this server, so nothing new is exposed.
// Config: the tailnet names (ts.net DNS name, short MagicDNS name, tailnet IPv4) are in config/bearings.json allowed_hosts.
export const hostAllowed = (hostHeader, allowedHosts, port) => {
  if (typeof hostHeader !== "string" || !hostHeader) return false;
  const m = /^(\[[0-9a-fA-F:]+\]|[A-Za-z0-9.-]+)(?::(\d{1,5}))?$/.exec(hostHeader);
  if (!m) return false;
  if (m[2] !== undefined && Number(m[2]) !== Number(port)) return false;
  const name = m[1].toLowerCase();
  return allowedHosts.some((h) => h.toLowerCase() === name);
};
