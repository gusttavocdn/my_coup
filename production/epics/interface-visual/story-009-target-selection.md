# Story 009: Escolher alvo

> **Epic**: interface-visual
> **Status**: Complete
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: M
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-03

## Context

**GDD**: `design/game-brief.md` · design canvas board MobileAlvo ("Celular — escolher alvo")
**Requirement**: Brief MVP feature 4 (action and target choice), restyled
**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

- [ ] Tapping Golpe de Estado, Assassinar or Extorquir opens the target screen over the table, which stays visible and dimmed behind it.
- [ ] Header pill with the action's icon, its name and cost (e.g. "ASSASSINAR −3 moedas"); my cards stay visible above.
- [ ] Prompt "Escolha quem assassinar" / "extorquir" / "dar o golpe em", in Cinzel.
- [ ] One large avatar per living opponent in the thumb zone (bottom third), with name and "N influências"; eliminated players are not offered.
- [ ] The selected avatar gets a crosshair and a red glow; tapping another moves the selection; nothing is selected at first.
- [ ] Coin projection "5 → 2" for my coins after paying (hidden for Extorquir, which only gains).
- [ ] "Cancelar" returns to the table; the confirm button reads the consequence ("Assassinar Bia") and stays disabled until a target is chosen; confirming sends the `action` intent with that target.
- [ ] Works at 1280x720 (avatars centered) and on a portrait phone; touch targets at least 56 px.
- [ ] Retained screenshots: nothing selected, one selected, for Assassinar and Extorquir, desktop and phone.

---

## Implementation Notes

Reuse `AvatarView`, the coin pill and the medallion icon from story 007/008. Colors: confirm button `#D8483A` for harmful actions. The legal-action rules stay in `RulesConfig`; this screen only collects the target and sends the same intent the old buttons sent.

---

## Out of Scope

- 011 and 012 screens. Changes to server rules.

---

## Files

- `src/client/target_screen.gd` (new)
- `src/client/table_screen.gd` (opens the target screen, stopgap target buttons removed)
- `src/client/preview.gd` (target_* states)
- `production/qa/evidence/story-009-target-selection/`

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: UI
**Required evidence**: a retained screenshot of each screen touched, in `production/qa/evidence/story-009-target-selection/`
**Status**: [x] Captured 2026-11-03 — desktop (1280x720) and phone (540x960): Assassinar and Extorquir, nothing selected and one selected

---

## Dependencies

- Depends on: `production/epics/interface-visual/story-008-new-table.md`
- Unlocks: None

## Completion Notes
**Completed**: 2026-11-03
**Criteria**: 9/9 passing (confirm sends the intent and Cancelar closes the screen: confirmed by the user, not captured; "eliminated not offered" and the Golpe prompt phrase checked in code only)
**Deviations**: Advisory — on desktop the header pill overlaps the dimmed opponents behind; the screen uses the phone-sized column centered. target_screen.gd.uid (engine-generated) not listed under Files.
**Test Evidence**: production/qa/evidence/story-009-target-selection/ (8 screenshots, stamped; tests waived at qa.level minimal)
**Reviewed by**: self, no independent review
