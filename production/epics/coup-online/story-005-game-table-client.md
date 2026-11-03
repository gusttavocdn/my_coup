# Story 005: Mesa de jogo (cliente)

> **Epic**: coup-online
> **Status**: Complete
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: L
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-03

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 4
**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal). Web export uses the Compatibility renderer (WebGL 2).

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

- [ ] Lobby screen: create room, join by code, see players, host starts the match.
- [ ] Table shows each player: name, coin count, number of face-down cards (backs only) and their revealed cards face up.
- [ ] Local player sees their own face-down cards face up to them only.
- [ ] Current turn is clearly indicated; on your turn, an action menu shows only legal actions (Golpe forced at 10+ coins; unaffordable actions disabled).
- [ ] Targeted actions ask for a target among living opponents.
- [ ] Response prompts (challenge / block / pass) appear for each eligible window, naming the claimed character and who claimed it.
- [ ] Prompts to choose which card to lose and to pick cards for the Embaixador exchange work with click and touch.
- [ ] An event log lists claims, challenges, blocks and outcomes in order.
- [ ] No interaction depends on hover; layout works at 1280x720 and on a phone-width browser viewport.
- [ ] Retained screenshots of lobby, table (own turn), response prompt and card-choice prompt in `production/qa/evidence/`.

---

## Implementation Notes

Client renders the per-player view from story 004 and sends intents only; no rules logic in scenes. Art direction (brief): Renaissance Italian intrigue, warm dark palette, coin/card sounds (placeholders are fine for MVP).

---

## Out of Scope

- 006: elimination screen, winner and results screen.
- Cosmetics, animations beyond basic feedback, voice chat.

---

## Files

- `src/client/ui_text.gd`
- `src/client/ui_kit.gd`
- `src/client/client_net.gd`
- `src/client/lobby_screen.gd`
- `src/client/table_screen.gd`
- `src/client/client_main.gd`
- `src/client/preview.gd`
- `src/server/server_main.gd`
- `scenes/main.tscn`
- `scenes/preview.tscn`
- `scenes/server.tscn`
- `project.godot`
- `production/qa/evidence/story-005-game-table-client/` (screenshots and stamp)

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: UI
**Required evidence**: a retained screenshot of each screen touched, in `production/qa/evidence/`
**Status**: [x] 13 retained screenshots in production/qa/evidence/story-005-game-table-client/ (lobby, table, prompts, phone width) plus real two-client end-to-end run against scenes/server.tscn

---

## Dependencies

- Depends on: `production/epics/coup-online/story-004-match-server-hidden-state.md`
- Unlocks: `production/epics/coup-online/story-006-match-end-results.md`

## Completion Notes
**Completed**: 2026-11-03
**Criteria**: 10/10 passing (all seen in retained screenshots; 13 images, stamp UNCHANGED)
**Deviations**: Advisory: real two-client run against `scenes/server.tscn` verified only by non-retained scripts; Web export (browser reachability) not yet done; optional engine-check items not applied (log ordering/auto-scroll, disable Start under 2 players).
**Test Evidence**: production/qa/evidence/story-005-game-table-client/ (screenshots + stamp.txt)
**Reviewed by**: self, no independent review
