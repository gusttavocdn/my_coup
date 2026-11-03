# Story 010: Prazo de resposta no servidor

> **Epic**: interface-visual
> **Status**: Ready
> **Layer**: Core
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: —

## Context

**GDD**: `design/game-brief.md` · design canvas board MobileReacao ("Responda em 8s")
**Requirement**: Brief MVP feature 3 (response windows), with a time limit
**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

- Server is the single authority: the clock lives on the server; clients only display the remaining time.

---

## Acceptance Criteria

- [ ] The response time is a data-driven value (default 8 seconds) in one config place, not a literal in server code.
- [ ] When a challenge, block or block-challenge window opens, the room records its deadline from an injectable clock.
- [ ] `Room.tick(now)` makes every eligible player who has not responded pass automatically once the deadline is reached; the window then closes through the normal path (block window, resolution, or end of the chain) and an update message goes to every member.
- [ ] Responses before the deadline behave as today; a challenge or block before the deadline ends or replaces the window, and a new window gets a new deadline.
- [ ] The auto-pass is visible in the event log as `response_timeout` with the player's seat.
- [ ] The per-player view carries `window.seconds_left` and `window.total_seconds` while a window is open, and nothing time-related otherwise.
- [ ] Only response windows have a deadline: a player's own turn, influence loss and Embaixador exchange still wait indefinitely (documented in the room's doc comment).
- [ ] `GameServer` ticks the registry every frame and delivers the resulting messages; no timer state outside the room.
- [ ] Integration tests with a fake clock cover: nobody responds, one of several responds, deadline reset on a follow-up window, tick outside a window is a no-op; the bot matches (stories 006) still finish.

---

## Implementation Notes

Keep `RulesEngine` untouched when possible: the room calls `pass_response` for each straggler, so the rules stay pure and tested. Pass the clock as a `Callable` returning milliseconds so tests do not sleep.

---

## Out of Scope

- 011: the countdown UI. Timeouts for own turn, loss and exchange. Reconnection.

---

## Files

- `src/server/room.gd`, `src/server/room_registry.gd`, `src/server/game_server.gd`, `src/rules/rules_config.gd` (or a server config file)
- `tests/integration/server/response_deadline_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/server/response_deadline_test.gd` OR playtest doc
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/coup-online/story-004-match-server-hidden-state.md`
- Unlocks: `production/epics/interface-visual/story-011-reaction-screen.md`
