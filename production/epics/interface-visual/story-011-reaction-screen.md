# Story 011: Tela de reação

> **Epic**: interface-visual
> **Status**: Ready
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: M
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: —

## Context

**GDD**: `design/game-brief.md` · design canvas board MobileReacao ("Celular — reagir")
**Requirement**: Brief MVP feature 3 (challenge and block windows), restyled
**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

- [ ] Shown whenever I am eligible to respond in a challenge, block or block-challenge window and have not yet passed.
- [ ] Top strip of opponents with the claimant's ring highlighted, and a draining bar plus "Responda em Ns" driven by `window.seconds_left`, urgent styling in the last 3 seconds.
- [ ] Headline names who does what: "Marina quer assassinar você" (action in accent color, "você" when I am the target), or "Marina declara Duque" for a claim, or "Rafa bloqueia como Condessa" for a block.
- [ ] "ela afirma ter" plus the claimed character's card, large, tilted and glowing.
- [ ] When blocking is possible for me, a primary button "Bloquear com a Condessa" (one per allowed blocker character, bluffing allowed) and, if I really hold that card, that card of mine is raised and glowing.
- [ ] "Desafiar" (subtitle "ela não tem Assassino") and "Aceitar" (subtitle with the consequence, e.g. "perder 1 influência") as two equal buttons under it; touch targets at least 56 px.
- [ ] Phase variants: challenge window (Desafiar / Aceitar), block window (Bloquear / Aceitar), block-challenge window (Desafiar / Aceitar).
- [ ] When the time runs out the server's auto-pass update removes the screen; nothing is sent from the client on expiry.
- [ ] Retained screenshots at desktop and phone sizes for all three window kinds, one with a high-urgency countdown.

---

## Implementation Notes

The countdown counts down locally between server updates from the last `seconds_left`. Hidden information: "ela não tem X" is a label on the Desafiar button, not knowledge of her hand.

---

## Out of Scope

- 010: server timers (this story only reads `seconds_left`). 012: loss and exchange.

---

## Files

- `src/client/reaction_screen.gd`, `src/client/table_screen.gd` (wire-up), `src/client/ui_text.gd`, `src/client/preview.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: UI
**Required evidence**: a retained screenshot of each screen touched, in `production/qa/evidence/story-011-reaction-screen/`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/interface-visual/story-008-new-table.md`, `production/epics/interface-visual/story-010-response-deadline.md`
- Unlocks: None
