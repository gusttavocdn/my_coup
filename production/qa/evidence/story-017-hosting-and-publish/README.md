# Story 017 evidence (2026-11-04)

Option A (VPS with Docker + Caddy) was chosen. Nothing was deployed: no account, VM,
domain or public certificate exists yet. What was checked locally on Docker Desktop:

- `https-same-origin-lobby.png`: the game served over HTTPS by Caddy from the compose
  stack (`COUP_DOMAIN=localhost`, local CA, headless Chrome with certificate errors
  ignored). The lobby "Servidor" field defaults to `wss://localhost` (same origin as the
  page); the "Instalar o jogo" button is offered (secure context).
- Compose stack (`deploy/docker-compose.yml` + `deploy/Caddyfile`): both containers up,
  server `healthy`; `index.wasm` 39.5 MB sent as 10.6 MB, `index.pck` as 5.6 MB (gzip);
  `Upgrade: websocket` through Caddy returned `101 Switching Protocols`; `http://` redirected
  (308) to `https://`.
- `tools/smoke-check.sh`, run against a local static server and a local match server:
  PASS (page files + a room created by one client and joined by another); FAIL with exit 1
  when the match server is unreachable and when the page is down.
- `tools/publish.sh --dry-run` prints the whole plan; the remote release switch (atomic
  `current` link, re-run is a no-op, last 3 releases kept) was exercised in a Debian container.
- Full suite 91/91, exit 0.

Not verified (needs the user): a real VPS and public certificate, the real `publish.sh` run
over SSH, a second run on the real host, the two-phone test
(`production/qa/playtests/story-017-device-test.md` is an empty template).
