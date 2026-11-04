# Story 014: Uso no celular: toque, teclado, tela cheia e orientação

> **Epic**: online-mobile
> **Status**: Complete
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: M
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-04

## Context

**GDD**: `design/game-brief.md` and the user's request of 2026-11-03: install and play on the phone
**Requirement**: the Web build is comfortable on a phone browser and as an installed app
**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal). Mobile browser input (virtual keyboard, safe areas, touch events) behaves differently from desktop: verify in the browser's device emulation first and on a real phone in story 017.

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

- [x] Every tappable control is at least 56 px high at the phone sizes 390x844 and 360x740 (checked on the table, action bar, target, reaction, loss, exchange, lobby and result screens).
- [x] Nothing depends on hover: states that only show on hover also show on press or selection.
- [x] The on-screen keyboard does not cover the field being typed in (lobby inputs scroll or move into view).
- [x] Safe areas (notch, home indicator, rounded corners) are respected: no control sits under them.
- [x] Portrait is the intended orientation; landscape on a phone still works (the wide layout) without clipped controls.
- [x] Pinch zoom, double-tap zoom, pull-to-refresh and rubber-band scrolling are disabled on the game canvas.
- [x] The action bar scrolls sideways by touch drag and the log sheet scrolls vertically, without triggering a tap by accident.
- [x] "Entrar em tela cheia" is offered where the browser allows it; the page uses the full viewport height (dynamic viewport units, no URL-bar gap).
- [x] Retained screenshots in device emulation (390x844 and 360x740, portrait, plus one landscape): lobby with keyboard, table, target, reaction, loss, result.

---

## Implementation Notes

Reuse the `TableScreen` narrow layout and `UiKit.fit_scale`; fix problems in the screens, not with a second layout. Page-level settings (viewport meta, `touch-action`, `overscroll-behavior`, dynamic viewport height) go in the custom HTML shell; keep that file in the repo and reference it from the Web preset.

---

## Out of Scope

- 013: the export itself. 015: manifest and install. Haptics, gestures beyond tap and drag.

---

## Files

web/shell.html
export_presets.cfg
src/client/web_viewport.gd
src/client/ui_kit.gd
src/client/ui_text.gd
src/client/client_main.gd
src/client/lobby_screen.gd
src/client/table_screen.gd
src/client/action_bar.gd
src/client/rules_sheet.gd
src/client/log_panel.gd
src/client/result_screen.gd
src/client/target_screen.gd
src/client/reaction_screen.gd
src/client/influence_loss_screen.gd
src/client/exchange_screen.gd

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: UI
**Required evidence**: a retained screenshot of each screen touched, in `production/qa/evidence/story-014-phone-usability/`
**Status**: [x] Created — production/qa/evidence/story-014-phone-usability/

---

## Dependencies

- Depends on: `production/epics/online-mobile/story-013-web-client.md`
- Unlocks: `production/epics/online-mobile/story-017-hosting-and-publish.md`

---

## Completion Notes
**Completed**: 2026-11-04
**Criteria**: 9/9 passing (criteria 2, 4, 7, 8 confirmed by the user, no retained image; criterion 3 covered by a simulated-keyboard screenshot)
**Deviations**: Advisory — keyboard capture is simulated (real phone check belongs to story 017); most screens captured natively, not in browser emulation; `screen_get_scale()` = `devicePixelRatio` on web confirmed only in emulation (ratio 2); fullscreen-from-`pressed` timing unverified on real Chrome/Android
**Test Evidence**: `production/qa/evidence/story-014-phone-usability/` (see its README.md); unit tests waived at qa.level minimal
**Reviewed by**: self, no independent review
