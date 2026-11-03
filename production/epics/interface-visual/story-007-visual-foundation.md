# Story 007: Fundação visual: fontes, tema, carta, verso, moeda, avatar e cenário

> **Epic**: interface-visual
> **Status**: Complete
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: L
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-03

## Context

**GDD**: `design/game-brief.md` · design canvas https://claude.ai/artifact/EoVp7sMqQucT3Y2CcEkYna (boards Main, Assassino, Capitao, Embaixador, Condessa, Verso, Moedas)
**Requirement**: Brief art direction ("intriga renascentista: cartas ilustradas, paleta quente e escura")
**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal). Godot's SVG importer does not render `<text>`: card names and ability lines are Labels over text-free SVG art. Check `docs/engine-reference/godot/modules/ui.md` before using Theme/Control APIs.

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

- [ ] Cinzel (600, 700) and Source Sans 3 (400, 600) as `.ttf` with their OFL licenses under `assets/fonts/`; the Theme uses Cinzel for titles and names, Source Sans 3 for body text.
- [ ] Design tokens (lavender scene gradient, ink `#1B1B26`, gold `#E0B24A`, border `#D8D4E0`, per-character accent colors) live in one place (`UiKit`), replacing the current dark palette.
- [ ] `CardView` draws any of the 5 MVP characters face up at any size: portrait art, Cinzel name, accent-colored frame, and the two-row panel (action row and "bloqueia/bloqueado por" row) with the canvas' icons; texts come from `UiText`, not hardcoded in the widget.
- [ ] `CardView` also draws the card back (rosácea dourada), a dimmed "lost" state, and a glow/raised state; it can be tilted by a given angle.
- [ ] Portraits are the canvas' faceted SVGs (text-free) imported under `assets/arte/design/`; the existing painted `assets/arte/*.svg` stay untouched and unused.
- [ ] Gold and silver coin icon and a "moedas" pill (icon + number) exist as reusable widgets.
- [ ] `AvatarView` draws 6 distinct avatars (the canvas' three plus three derived by color) with a ring that can show "turn" and "target" states.
- [ ] `SceneBackdrop` draws the lavender scene (gradient, circles, branch line, house silhouettes) and covers any window size, including portrait phone.
- [ ] A `gallery` preview state shows every piece side by side; retained screenshots at 1280x720 and 540x960, compared with the canvas.
- [ ] A copy of the canvas boards is kept in `design/ui/referencia/` as the reference for the next stories.

---

## Implementation Notes

Split each canvas card into: portrait `<svg>` (260x250 viewBox, no text), frame colors, name, and panel rows. Colors per character from the canvas: Duque `#E0B24A`/`#3A2866`, Assassino `#D8483A`/`#B02E22`, Capitão `#6FB8D0`/`#1B3F5E`, Embaixador `#7FD0B4`/`#1E5448`, Condessa `#E88FAF`/`#6E2140`. Avatars: extract Marina, Rafa and Bia from `Desktop.dc.html`.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 008: the table layout using these pieces.
- Inquisidor card (art may be saved, not wired to any rule).

---

## Files

- `assets/fonts/` (Cinzel and Source Sans 3 variable fonts, OFL licenses)
- `assets/arte/design/` (42 SVGs extracted from the canvas, plus their import files)
- `tools/extract_design_assets.py`
- `design/ui/referencia/` (copy of the canvas boards)
- `src/client/ui_kit.gd`, `src/client/ui_text.gd`, `src/client/card_view.gd`, `src/client/avatar_view.gd`, `src/client/scene_backdrop.gd`, `src/client/coin_pill.gd`
- `src/client/preview.gd`, `src/client/client_main.gd`, `src/client/lobby_screen.gd`, `src/client/result_screen.gd`, `src/client/table_screen.gd` (light-theme adaptation)
- `production/qa/evidence/story-007-visual-foundation/` (gallery screenshots, legacy screens, stamp)

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: UI
**Required evidence**: a retained screenshot of each screen touched, in `production/qa/evidence/story-007-visual-foundation/`
**Status**: [x] gallery screenshots at 1280x720, 1280x1000 and 540x960 plus the five legacy screens re-captured in the new theme, in production/qa/evidence/story-007-visual-foundation/; full test suite 64/64

---

## Dependencies

- Depends on: `production/epics/coup-online/story-006-match-end-results.md`
- Unlocks: `production/epics/interface-visual/story-008-new-table.md`

## Completion Notes
**Completed**: 2026-11-03
**Criteria**: 10/10 passing (gallery screenshots at 1280x720, 1280x1000 and 540x960 viewed; full test suite 64/64 green)
**Deviations**: Advisory: rounded portrait clip (`clip_children`) verified only in the desktop Compatibility renderer, not in a Web export; optional engine-check items not applied (avatar halo can be clipped by a `clip_contents` parent; StyleBoxFlat allocated per `_draw`).
**Test Evidence**: production/qa/evidence/story-007-visual-foundation/ (gallery screenshots, legacy screens, stamp.txt)
**Reviewed by**: self, no independent review
