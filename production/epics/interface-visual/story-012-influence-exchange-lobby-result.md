# Story 012: Perder influência, troca, lobby e resultado no novo estilo

> **Epic**: interface-visual
> **Status**: Ready
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: M
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: —

## Context

**GDD**: `design/game-brief.md` · design canvas board MobilePerda ("Celular — perder influência")
**Requirement**: Brief MVP features 4 and 6 (loss, exchange, lobby, result), restyled
**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

- [ ] Influence loss screen: the lost-card icon, "VOCÊ PERDE UMA INFLUÊNCIA" in Cinzel, who caused it ("Marina assassinou você. Toque na carta que quer revelar."), my cards large side by side.
- [ ] Tapping a card selects it (raised, red glow, the other dims); the button reads "Revelar Duque" and sends `lose_influence` with that card; "A carta fica virada para cima e sai do jogo." sits above it.
- [ ] Embaixador exchange screen in the same style: the pool of cards (hand plus drawn) face up, tap to choose exactly as many as I have influences, "Confirmar troca" enabled only then, and it sends `exchange` with the chosen indices.
- [ ] Lobby (connect form and room) restyled: Cinzel title, card fan decoration, the same theme, buttons and inputs; the room code is large and copyable.
- [ ] Result screen restyled: winner banner, standings with avatar, rank, name and final cards, "Voltar ao lobby".
- [ ] The stopgap prompt code left in `TableScreen` by stories 008 to 011 is removed; one code path per prompt.
- [ ] Error toasts and the spectator banner use the new style.
- [ ] Retained screenshots, desktop and phone: loss (nothing selected and one selected), exchange (nothing chosen and complete), connect, room, result.

---

## Implementation Notes

Reuse `CardView` raised/glow/dim states. The exchange screen keeps the same intent shape as today (`keep` = indices into hand then drawn). Keep `LobbyScreen` and `ResultScreen` signals unchanged so `ClientMain` only swaps visuals.

---

## Out of Scope

- New rules; animation beyond tilt, raise and glow.

---

## Files

- `src/client/influence_loss_screen.gd`, `src/client/exchange_screen.gd`, `src/client/lobby_screen.gd`, `src/client/result_screen.gd`, `src/client/table_screen.gd`, `src/client/ui_text.gd`, `src/client/preview.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: UI
**Required evidence**: a retained screenshot of each screen touched, in `production/qa/evidence/story-012-influence-exchange-lobby-result/`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/interface-visual/story-008-new-table.md`
- Unlocks: None
