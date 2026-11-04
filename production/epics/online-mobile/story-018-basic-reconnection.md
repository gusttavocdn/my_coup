# Story 018: Reconexão básica e espera por jogador

> **Epic**: online-mobile
> **Status**: Ready
> **Layer**: Core
> **Type**: Integration
> **Estimate**: L
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: —

## Context

**GDD**: `design/game-brief.md` and the user's request of 2026-11-03: play on the phone. The brief leaves out *advanced* reconnection; this story is the basic kind only.
**Requirement**: a phone that sleeps or switches networks rejoins the same seat instead of ending the match for everyone
**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal). Persisting a token on the Web build (`user://` is IndexedDB-backed; iOS can clear it) and WebSocket behaviour when a tab is backgrounded need checking on 4.7 and on real phones.

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

- [ ] When a member's connection drops during a match, the server keeps their seat for a grace period (a config value, default 60 s) instead of aborting; the others see "<nome> desconectou, aguardando..." and the seat is marked as away in the view.
- [ ] Joining a room hands the client a private session token; the client keeps it (in `user://` on every platform) together with the room code.
- [ ] A client that reconnects with a valid token within the grace period gets its seat back and a fresh private view, and the table continues where it was; a wrong or expired token is rejected with a translated error.
- [ ] The client retries by itself with a growing delay, shows a "Reconectando..." strip over the current screen, and returns to the lobby with a clear message only after the grace period ends or the server says the seat is gone.
- [ ] While a player is away, response windows keep their deadline (their auto-pass still happens); their own turn, loss or exchange waits only until the grace period ends, after which the server resolves the wait for them with a safe default (turn passes with Renda, loss reveals a card, exchange keeps the current hand) and logs it.
- [ ] If every human member is away past the grace period the room is closed; if only one member stays connected past it, the match ends for them with a message (no silent hang).
- [ ] A finished match's room does not abort when members leave or reconnect, and the result-screen disconnect no longer pushes remaining players to the lobby while they read the result.
- [ ] Integration tests with a fake clock cover: reconnect inside the window, expiry, wrong token, the safe defaults for turn, loss and exchange, and the away marker in the view; the existing suite stays green.

---

## Implementation Notes

Keep the rules engine untouched; the safe defaults are applied by the room through the normal intents. Tokens are random, per seat, and never shown to other players. This story adds `away` and a `session` message to the room, view and client; keep the old messages working.

---

## Out of Scope

- Rejoining from another device after the token is lost, spectating, persistence across a server restart, account-bound seats.

---

## Files

- `src/server/room.gd`, `src/server/room_registry.gd`, `src/server/game_server.gd`
- `src/client/client_net.gd`, `src/client/client_main.gd`, `src/client/table_screen.gd`, `src/client/ui_text.gd`
- `tests/integration/server/reconnect_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/server/reconnect_test.gd` OR playtest doc; tests waived at `qa.level: minimal`, but this story's last criterion asks for them
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/online-mobile/story-016-internet-ready-server.md`
- Unlocks: `production/epics/online-mobile/story-017-hosting-and-publish.md` (the real-phone test is far more useful with reconnection in place)
