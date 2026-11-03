# Story 008: Mesa nova (computador e celular)

> **Epic**: interface-visual
> **Status**: Ready
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: L
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: —

## Context

**GDD**: `design/game-brief.md` · design canvas boards Desktop ("Computador — sua vez") and Mobile ("Celular — sua vez")
**Requirement**: Brief MVP feature 4 (game table), restyled
**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

- [ ] The table is a full-window immersive scene (`SceneBackdrop`) with a minimal HUD floating over it; the same screen adapts from 1280x720 to portrait phone (390x844 logical) without clipped controls.
- [ ] Opponents sit along the top: avatar ring (highlighted on their turn), a fan of card backs for their remaining influences and revealed cards face up, name in Cinzel, coin pill; exiled players dimmed.
- [ ] "ÚLTIMA AÇÃO" caption with the latest event as a headline (e.g. "Rafa perdeu Capitão", character names in their accent color), and pills "Tesouro N" and "Baralho N" from the view.
- [ ] My two cards are drawn large and tilted in the center; a lost card is dimmed and flipped; "Suas moedas N" shows my coins (and "Golpe de Estado a partir de 7" as a hint).
- [ ] On my turn: "SUA VEZ — Escolha uma ação" and the action bar of medallions: Renda (+1), Ajuda Externa (+2), Golpe de Estado (−7), a divider, then Taxar (+3, Duque), Assassinar (−3, Assassino), Extorquir (+2, Capitão), Trocar (Embaixador); no Investigar. A medallion is disabled when unaffordable; at 10+ coins only Golpe is enabled.
- [ ] Actions without target send their intent on tap; targeted ones hand over to the target screen (story 009) — until it exists, the current target buttons stay as a stopgap.
- [ ] Off my turn the same slot says who we wait for; exiled players see "Exilado: assistindo" and no action bar.
- [ ] "Registro" (event log) is a panel at the bottom left on desktop and a button-opened sheet on phone; "Menu" and "Regras" buttons sit in the top corners (Regras opens a short rules sheet; Menu offers leaving the room).
- [ ] Response, loss and exchange prompts still work with the existing controls until stories 011 and 012 replace them, so the game stays playable after this story.
- [ ] Retained screenshots at 1280x720 and 390x844 (540x960 window): own turn, waiting for another player, 10+ coins, exiled spectator.

---

## Implementation Notes

Measurements and spacing from `Desktop.dc.html` and `Mobile.dc.html` (copies in `design/ui/referencia/`). Medallion colors: general actions dark ink with a white ring, character actions filled with the character's accent. Keep the `TableScreen` public API (`apply_update`, `set_room_code`, `show_error`, `reset`, `intent_chosen`) so `ClientMain` does not change.

---

## Out of Scope

- 009: the target selection screen.
- 011: the reaction screen. 012: loss, exchange, lobby, result restyle.
- Investigar and the Inquisidor.

---

## Files

- `src/client/table_screen.gd` (rewrite), `src/client/action_bar.gd`, `src/client/opponent_strip.gd`, `src/client/log_panel.gd`, `src/client/rules_sheet.gd`, `src/client/ui_text.gd`, `src/client/preview.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: UI
**Required evidence**: a retained screenshot of each screen touched, in `production/qa/evidence/story-008-new-table/`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/interface-visual/story-007-visual-foundation.md`
- Unlocks: `production/epics/interface-visual/story-009-target-selection.md`, `production/epics/interface-visual/story-011-reaction-screen.md`, `production/epics/interface-visual/story-012-influence-exchange-lobby-result.md`
