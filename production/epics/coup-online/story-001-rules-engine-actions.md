# Story 001: Motor de regras: ações e influência

> **Epic**: coup-online
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: L
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-03

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 1
**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal). Check `docs/engine-reference/godot/` before using engine APIs.

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

- Rules code is pure GDScript with no Node/scene or network dependency (testable headless; reused by the server).
- Gameplay values (starting coins, costs, deck size) are data-driven, not hardcoded.

---

## Acceptance Criteria

- [ ] Setup: deck of 15 cards (3 each of Duque, Assassino, Capitão, Embaixador, Condessa), shuffled; each player gets 2 face-down cards and 2 coins (1 coin each in a 2-player game); remaining cards form the Court deck; treasury holds the rest of the coins.
- [ ] Turn order is clockwise among living players; a turn is exactly one action, passing is not allowed.
- [ ] General actions: Renda (+1), Ajuda Externa (+2), Golpe de Estado (pay 7, target loses 1 influence, cannot be blocked or challenged).
- [ ] Character actions (declared, resolution awaits story 002): Duque Taxas (+3), Assassino Assassinar (pay 3, target loses 1), Capitão Extorquir (take 2 from target, or 1 if target has 1, 0 if none).
- [ ] A player starting a turn with 10+ coins may only choose Golpe; any other action is rejected.
- [ ] Actions the player cannot pay for are rejected; invalid targets (self, eliminated player) are rejected.
- [ ] Losing influence: owner chooses which face-down card to reveal; revealed cards stay public and no longer count.
- [ ] A player with 0 influence is eliminated: cards stay face up and their coins return to the treasury.
- [ ] The match ends when one player remains; the engine exposes the winner.
- [ ] Rule engine API takes plain data and returns plain data/events (no randomness without an injectable seed).

---

## Implementation Notes

Source: Coup manual (Docs PDF), pages "Preparação", "Ações", "Influência". Keep state as a serializable dictionary/Resource so story 004 can send per-player views.

---

## Out of Scope

- 002: challenge and block flow around declared actions.
- 003: Embaixador Trocar action and challenge-win reshuffle.
- 004: network, rooms, hidden-state views.

---

## Files

- `src/rules/rules_config.gd`
- `src/rules/rules_engine.gd`

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/rules/rules_engine_test.gd` (waived at `qa.level: minimal`, still recommended)
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None
- Unlocks: `production/epics/coup-online/story-002-challenge-block-chain.md`, `production/epics/coup-online/story-003-ambassador-exchange-reshuffle.md`

## Completion Notes
**Completed**: 2026-11-03
**Criteria**: 10/10 passing (confirmed by the user after a throwaway headless smoke run; Ajuda Externa was not exercised by that run)
**Deviations**: None blocking. Advisory: `.godot/` untracked (add to `.gitignore`).
**Test Evidence**: waived at qa.level minimal
**Reviewed by**: self, no independent review
