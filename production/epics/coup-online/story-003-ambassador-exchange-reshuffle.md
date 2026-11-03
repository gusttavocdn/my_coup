# Story 003: Troca do Embaixador e reembaralho

> **Epic**: coup-online
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-03

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 5
**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

- [ ] Embaixador Trocar: after challenges pass, the player draws 2 random cards from the Court deck, then keeps any combination of their face-down cards plus the drawn ones, up to the number of influences they still have, and returns the rest to the Court deck.
- [ ] A player with 1 influence left keeps exactly 1 card (returns the rest); with 2, keeps exactly 2.
- [ ] Returned cards are shuffled into the Court deck; total cards in play stays 15.
- [ ] Challenge-win reshuffle: the claimant returns the shown card to the Court deck, deck is shuffled, and they draw 1 random card replacing it (the shown card can come back).
- [ ] A challenged Embaixador claim that is bluffed fails: no cards are drawn, challenger wins, claimant loses influence.
- [ ] Shuffles use an injectable RNG seed so tests are deterministic.
- [ ] Invariant check: after any exchange, no card is duplicated or lost.

---

## Implementation Notes

Source: manual "Trocar" and "Contestações" (the winner returns the card and draws a new one so others cannot track it). The exchange selection is a pending choice, like losing influence, to be answered by the player.

---

## Out of Scope

- 004: hiding drawn cards from other players over the network.
- Inquisitor variant (Investigar, Trocar of one card).

---

## Files

- `src/rules/rules_engine.gd`
- `src/rules/rules_config.gd`
- `tests/unit/rules/exchange_reshuffle_test.gd`

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/rules/exchange_reshuffle_test.gd` (waived at `qa.level: minimal`, still recommended)
**Status**: [x] 14 gdUnit4 tests pass (full suite 35/35, exit 0); mutation check (returned cards dropped) failed as expected

---

## Dependencies

- Depends on: `production/epics/coup-online/story-001-rules-engine-actions.md`
- Unlocks: `production/epics/coup-online/story-004-match-server-hidden-state.md`

## Completion Notes
**Completed**: 2026-11-03
**Criteria**: 7/7 passing (covered by 14 gdUnit4 tests; full suite 35/35 green in this session)
**Deviations**: None
**Test Evidence**: tests/unit/rules/exchange_reshuffle_test.gd
**Reviewed by**: self, no independent review
