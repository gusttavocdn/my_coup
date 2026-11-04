# Story 016: Servidor pronto para a internet: limites, configuração e implantação

> **Epic**: online-mobile
> **Status**: Ready
> **Layer**: Core
> **Type**: Integration
> **Estimate**: L
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: —

## Context

**GDD**: `design/game-brief.md` ("servidor como autoridade") and the user's request of 2026-11-03: play over the internet
**Requirement**: the match server can be exposed to strangers without falling over or being abused
**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal). `WebSocketMultiplayerPeer` limits and TLS options in 4.7: check `docs/engine-reference/godot/` before relying on built-in TLS; the plan below terminates TLS in a reverse proxy.

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

- [ ] Port, maximum rooms, maximum connections (total and per IP), maximum message size and the message rate limit come from command-line options or environment variables with documented defaults; none is a literal in server code (they live in one config place).
- [ ] Over the connection limit, new connections are refused with a clear close reason; over the room limit, `create_room` answers a translated error (`server_busy`).
- [ ] A client sending more than the allowed messages per second, or an oversized or malformed message, gets an error and then a disconnect on repeat; the match of the others is not affected.
- [ ] Rooms that sit idle (empty lobby, or no activity for the configured minutes) are removed; a finished match's room is cleaned up when its members leave.
- [ ] The server logs, one line each: start (with the effective config), room created and closed, a player joining and leaving, rejected connections and rate-limit hits; no player-sent text is logged unescaped.
- [ ] A health signal exists for hosts (a `--health` self-check or a tiny HTTP port), and `SIGTERM` closes the server cleanly.
- [ ] A deployment recipe is in the repo: a `Dockerfile` (headless Godot, the project files, a non-root user) and a reverse-proxy example (Caddy or nginx) that terminates TLS and proxies `wss://` to the server's `ws://`.
- [ ] The existing suite stays green and new integration tests cover the limits (room cap, per-IP cap, rate limit, idle cleanup) with an injected clock.

---

## Implementation Notes

Limits belong in `RoomRegistry` and `GameServer` (pure, injectable clock) and in `ServerMain` for the options. Keep the rules engine untouched. The name length and intent validation already exist; do not weaken them. The per-IP count needs the peer's address from the socket layer: confirm the 4.7 API.

---

## Out of Scope

- 017: choosing and using a host. 018: reconnection. Authentication, accounts, rate limits per account, DDoS protection (the host or proxy's job).

---

## Files

- `src/server/server_config.gd`, `src/server/game_server.gd`, `src/server/room_registry.gd`, `src/server/server_main.gd`
- `Dockerfile`, `deploy/Caddyfile`, `docs/` note on running the server
- `tests/integration/server/limits_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/server/limits_test.gd` OR playtest doc; tests waived at `qa.level: minimal`, but this story's last criterion asks for them
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/interface-visual/story-010-response-deadline.md`
- Unlocks: `production/epics/online-mobile/story-017-hosting-and-publish.md`, `production/epics/online-mobile/story-018-basic-reconnection.md`
