# Story 002: Cadeia de contestação e bloqueio

> **Epic**: coup-online
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Estimate**: L
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-03

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 3
**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

- [ ] After a character action is declared, every other living player gets a response window: pass or challenge. Window closes when all have passed or one challenges.
- [ ] Challenge: the claimant shows the claimed card. If they have it, challenger loses 1 influence; claimant returns that card to the Court deck, shuffles, draws a new one (story 003 owns the swap primitive), and the action proceeds. If they do not, claimant loses 1 influence and the whole action fails with coins refunded.
- [ ] Blockable actions open a block window after challenges: Ajuda Externa (any player claiming Duque), Assassinar (target only, Condessa), Extorquir (target only, Embaixador or Capitão).
- [ ] A block is itself a claim and can be challenged by anyone. Block challenged successfully: block fails, original action proceeds. Block unchallenged or won: action fails.
- [ ] Coins paid for a blocked action are NOT refunded; coins paid for a successfully challenged action ARE refunded.
- [ ] Assassin double danger: if the target challenges the Assassino and loses, the target loses 1 influence for the challenge and the assassination still resolves (target can lose a second one). Same when a bluffed Condessa block is caught.
- [ ] A player eliminated mid-chain (zero influence) leaves the chain immediately; pending effects against them are dropped.
- [ ] Challenges resolve before any action or block effect.
- [ ] Renda and Golpe de Estado never open challenge or block windows.
- [ ] Losing influence to a challenge prompts the owner to choose which card to reveal (the engine exposes a pending choice).

---

## Implementation Notes

Model the turn as an explicit state machine (declare → challenge window → block window → block-challenge window → resolve). Reuse story 001 state and primitives. Source: manual "Contestações", "Ações Contrárias", and "Perigo duplo do Assassino".

---

## Out of Scope

- 003: the card-swap/reshuffle primitive itself and the Embaixador action.
- 004: timers and network delivery of window prompts.

---

## Files

- `src/rules/rules_engine.gd`
- `src/rules/rules_config.gd`
- `tests/unit/rules/challenge_block_chain_test.gd`
- `addons/gdUnit4/` (test framework v6.2.2, downloaded from github.com/godot-gdunit-labs/gdUnit4 at user request)

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/rules/challenge_block_chain_test.gd` (waived at `qa.level: minimal`, still recommended)
**Status**: [x] 21 gdUnit4 tests pass (exit 0); mutation check (refund removed) failed as expected

---

## Dependencies

- Depends on: `production/epics/coup-online/story-001-rules-engine-actions.md`
- Unlocks: `production/epics/coup-online/story-004-match-server-hidden-state.md`

## Completion Notes
**Completed**: 2026-11-03
**Criteria**: 10/10 passing (covered by 21 gdUnit4 tests, run 21/21 green in this session)
**Deviations**: Advisory: `resolve_declared_action` (story 001) removed in favour of response windows; `_replace_card` implemented here instead of story 003; `addons/gdUnit4/` and `.godot/` not yet committed/ignored.
**Test Evidence**: tests/unit/rules/challenge_block_chain_test.gd
**Reviewed by**: self, no independent review
