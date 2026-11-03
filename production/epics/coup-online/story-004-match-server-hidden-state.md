# Story 004: Servidor de partida: salas e estado oculto

> **Epic**: coup-online
> **Status**: Complete
> **Layer**: Core
> **Type**: Integration
> **Estimate**: L
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-03

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 2
**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal). Godot 4 web export works for GDScript only; browser clients can use WebSocket, not raw TCP/UDP.

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

- Server is the single authority; clients send intents only.

---

## Acceptance Criteria

- [x] **Decision (2026-11-03, user-approved):** headless Godot server in this project, reusing RulesEngine, with WebSocket transport (`WebSocketMultiplayerPeer`, reachable from browser clients). Pure `Room`/`RoomRegistry` layer holds the logic; `GameServer` (Node) only wires sockets and RPCs. Disconnect behaviour (MVP): a player leaving mid-match aborts the room and the others get `match_aborted`.
- [ ] A player can create a room and get a short code; others join by code. Room holds 2-6 players; a 7th join is refused.
- [ ] The host can start the match when 2-6 players are present; no late joins after start.
- [ ] Server runs the rules engine (stories 001-003) and is the only place state mutates.
- [ ] Each client receives a per-player view: own face-down cards, others' card COUNT only, all coins, all revealed cards, whose turn it is, pending prompts. Other players' hidden cards never leave the server.
- [ ] Clients send intents (action, target, pass, challenge, block, card choice); illegal or out-of-turn intents are rejected with a reason and do not change state.
- [ ] Response windows wait for every required player; a response from a non-eligible player is ignored.
- [ ] A disconnected player does not crash the room; MVP behaviour is documented in this file (e.g. match aborts or player auto-passes) — full reconnection is out of scope.
- [ ] Integration test: two simulated clients play a scripted match to completion and the server's final state matches the rules engine.

---

## Implementation Notes

Source: brief "Out of scope" (no accounts, no matchmaking), "Build order" step 2 (playable with 2 players first). Hidden-state filtering is the core risk: write a test that asserts no opponent card identity appears in any message sent to a client.

---

## Out of Scope

- 005: any UI.
- Accounts, ranking, public matchmaking, chat, advanced reconnection.

---

## Files

- `src/server/room.gd`
- `src/server/room_registry.gd`
- `src/server/game_server.gd`
- `tests/integration/server/room_hidden_state_test.gd`

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/server/room_hidden_state_test.gd` OR playtest doc
**Status**: [x] 18 gdUnit4 integration tests pass (full suite 53/53, exit 0); mutation check (opponent hand leaked into view) failed as expected; real WebSocket round trip verified with two Godot processes (scratch script, not retained)

---

## Dependencies

- Depends on: `production/epics/coup-online/story-002-challenge-block-chain.md`, `production/epics/coup-online/story-003-ambassador-exchange-reshuffle.md`
- Unlocks: `production/epics/coup-online/story-005-game-table-client.md`, `production/epics/coup-online/story-006-match-end-results.md`

## Completion Notes
**Completed**: 2026-11-03
**Criteria**: 9/9 passing (covered by 18 gdUnit4 integration tests; full suite 53/53 green in this session)
**Deviations**: Advisory: `GameServer` socket/RPC wiring verified only by a non-retained two-process smoke; browser reachability to be confirmed with the story 005 web export. Optional specialist items not applied (guard double `listen()`, `view_for` non-member guard, eliminated-player leave policy, room-code loop cap).
**Test Evidence**: tests/integration/server/room_hidden_state_test.gd
**Reviewed by**: self, no independent review
