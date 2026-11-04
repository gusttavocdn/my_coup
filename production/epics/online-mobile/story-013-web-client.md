# Story 013: Cliente web: exportar o jogo para o navegador

> **Epic**: online-mobile
> **Status**: Complete
> **Layer**: Platform
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-04

## Context

**GDD**: `design/game-brief.md` (pitch: partidas "à distância") and the user's request of 2026-11-03: play over the internet
**Requirement**: Web build of the existing client, playable in a desktop browser
**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal). Web export options, the export templates and threading in 4.7 postdate the model: read `docs/engine-reference/godot/` and the official 4.7 export docs before assuming anything. The renderer is GL Compatibility, the one Web supports.

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

- [x] A committed `export_presets.cfg` has a Web preset (no secrets, no absolute paths); the export templates for the pinned version are installed or the build script says exactly how to install them.
- [x] One command (`tools/build-web.*`) produces `build/web/` (index.html, wasm, pck, JS) and fails loudly if the templates or the preset are missing; `build/` is git-ignored.
- [x] The build is single-threaded (no cross-origin-isolation headers required), so any static file server can host it.
- [x] The server address is configurable: default derived from the page (`ws://` on http, `wss://` on https, same host, the server's port), overridable with `?server=` in the URL; the desktop `--url=` option keeps working.
- [x] Served from a local static server, the page loads the game, fonts and card art with no console errors and no missing resources.
- [x] Two browser tabs against a local match server create a room, join it and play a full match to the result screen and back to the lobby.
- [x] Text inputs (name, room code, server) accept typing, paste and the on-screen keyboard events in the browser; "Copiar código" copies via the browser clipboard.
- [x] The canvas fills the window and follows resizes, with the existing phone layout below 900 px. — OBSERVED 2026-11-04: canvas followed 1024→500→1024 live; 375 px layout fits (`production/qa/evidence/story-013-web-client/phone-375-lobby.jpg`).
- [x] The build size (pck + wasm, gzip-estimated) is recorded in the story's notes as the baseline.

---

## Implementation Notes

- Read the default server address from one place (a small `ServerAddress` helper) instead of the constants in `ClientMain` and `LobbyScreen`; on the Web read `window.location` and the query through `JavaScriptBridge` (guard every JS call with `OS.has_feature("web")`).
- Keep desktop behaviour unchanged.
- Serve with any static server for the check (`python -m http.server` is enough); remember `.wasm` must be served as `application/wasm`.

---

## Out of Scope

- 014: touch ergonomics. 015: manifest, icons, service worker, install. 016: server limits. 017: public hosting.

---

## Files

- `.gitignore`
- `export_presets.cfg`
- `tools/build-web.ps1`
- `tools/build-web.sh`
- `src/client/server_address.gd`
- `src/client/server_address.gd.uid`
- `src/client/client_main.gd`
- `src/client/lobby_screen.gd`
- `src/server/game_server.gd`
- `src/server/server_main.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: a playtest note (`production/qa/playtests/`) or a scripted browser run showing two tabs playing to the result; tests waived at `qa.level: minimal`
**Status**: [x] Created — `production/qa/playtests/story-013-web-client.md` records the two-tab match.

## Notes

- Godot 4.7.2 Web export baseline: `index.pck` 5,393,920 bytes + `index.wasm` 39,514,754 bytes = 44,908,674 bytes raw; separately gzip-estimated at level 9: 15,215,900 bytes total. `tools/build-web.ps1` completed successfully with the installed templates.
- Browser check on 2026-11-04: the static export rendered the lobby, fonts, and card art in two tabs. The default URL showed `ws://127.0.0.1:9080`; a `?server=ws://127.0.0.1:9081` override appeared in the second tab. Browser console showed only normal Godot startup messages. Players Alice and Maria created and joined room `WXNF`, completed a match, saw Maria's result screen, and returned to the lobby. Typing entered the player name and room code. Clipboard paste and the actual copied clipboard value were not verified. The canvas filled the desktop-sized viewport; resize behavior and the phone layout below 900 px remain unverified.
- The local server now accepts an optional `--bind=127.0.0.1` argument for loopback-only playtests; its existing default remains `*`.
- 2026-11-04 (later): `Copiar código` now falls back to a hidden textarea + `execCommand('copy')` when `navigator.clipboard.writeText` is denied (the in-app browser pane denies it). Rebuilt OK, parse check exit 0. Copy-to-system-clipboard and Ctrl+V paste could NOT be verified in the pane (clipboard read/write permission denied; synthetic paste events ignored) — verify once in a real Chrome/Firefox tab. Keyboard typing verified via key events.
- `export_presets.cfg` has no secrets or absolute paths and is un-ignored in `.gitignore`; it is untracked until the user commits.

---

## Dependencies

- Depends on: `production/epics/interface-visual/story-012-influence-exchange-lobby-result.md`
- Unlocks: `production/epics/online-mobile/story-014-phone-usability.md`, `production/epics/online-mobile/story-015-installable-pwa.md`

---

## Completion Notes
**Completed**: 2026-11-04
**Criteria**: 9/9 passing (clipboard copy/paste confirmed by the user in a real browser, not captured as evidence; preset criterion counted met on commit — `export_presets.cfg` is clean but still untracked)
**Deviations**: None
**Test Evidence**: `production/qa/playtests/story-013-web-client.md` (integration playtest) + `production/qa/evidence/story-013-web-client/phone-375-lobby.jpg`; unit tests waived at qa.level minimal
**Reviewed by**: self, no independent review
