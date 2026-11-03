# Story 006: Fim de partida: eliminação, vencedor, resultado

> **Epic**: coup-online
> **Status**: Complete
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: M
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-03

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 6
**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

- [ ] When a player loses their second influence, every client shows them as exiled: both cards face up, 0 coins, turn order skips them.
- [ ] The exiled player stays in the room as a spectator: sees public table state, cannot act, never sees hidden cards.
- [ ] When one player remains, the server ends the match and all clients show a result screen naming the winner.
- [ ] The result screen shows each player's final revealed cards and finishing order.
- [ ] From the result screen players can return to the lobby (same room) to start a new match.
- [ ] A full 3-6 player match plays from lobby to result screen with all MVP rules (playtest note in `production/qa/evidence/`).
- [ ] Retained screenshots of an exiled-player view and of the result screen in `production/qa/evidence/`.

---

## Implementation Notes

Elimination and winner logic already live in story 001; this story only surfaces them through server events and UI. Covers the brief's fail state ("perder as 2 cartas e ser exilado") and goal ("último jogador com influência").

---

## Out of Scope

- Ranking, persistence of results, replays.
- Reconnection to finished matches.

---

## Files

- `src/rules/rules_engine.gd`
- `src/server/room.gd`
- `src/server/room_registry.gd`
- `src/client/ui_text.gd`
- `src/client/result_screen.gd`
- `src/client/table_screen.gd`
- `src/client/client_main.gd`
- `src/client/preview.gd`
- `tests/helpers/bot_match.gd`
- `tests/integration/server/full_match_test.gd`
- `tests/integration/server/match_end_test.gd`
- `production/qa/evidence/story-006-match-end-results/` (screenshots, playtest note, stamp)

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: UI
**Required evidence**: a retained screenshot of each screen touched, in `production/qa/evidence/`
**Status**: [x] 3 retained screenshots + playtest-note.md in production/qa/evidence/story-006-match-end-results/; 11 new gdUnit4 tests (full suite 64/64, exit 0); live two-client run to the result screen and back to the lobby

---

## Dependencies

- Depends on: `production/epics/coup-online/story-004-match-server-hidden-state.md`, `production/epics/coup-online/story-005-game-table-client.md`
- Unlocks: None

## Completion Notes
**Completed**: 2026-11-03
**Criteria**: 7/7 passing (3 screenshots viewed, 11 gdUnit4 tests, bot playtest note; full suite 64/64 green in this session)
**Deviations**: Advisory: a member who has not pressed "Voltar ao lobby" is still counted by `start()` (MVP, no readiness check); playtest was automated (bots and scripts), no human playtest; Web export (browser access) not yet done.
**Test Evidence**: production/qa/evidence/story-006-match-end-results/ (screenshots, playtest-note.md, stamp.txt); tests/integration/server/full_match_test.gd, match_end_test.gd
**Reviewed by**: self, no independent review
