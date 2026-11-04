# Story 015: PWA instalável (manifesto, ícones, service worker, iOS)

> **Epic**: online-mobile
> **Status**: Complete
> **Layer**: Platform
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-04

## Context

**GDD**: `design/game-brief.md` and the user's request of 2026-11-03: install the game on the phone
**Requirement**: the Web build installs from the browser on Android and iPhone and opens like an app
**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal). Godot's Web export has "Progressive Web App" options in the preset; confirm what 4.7 generates (manifest, service worker, offline page) before writing any of it by hand.

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

- [ ] The Web preset exports the PWA files: a manifest (name "Coup Online", short name, `display: standalone`, portrait, theme and background colors from the design), a service worker and the icons.
- [ ] Icons: 192x192, 512x512 and a maskable 512x512, generated from the game's art (a card or the crown on the lavender background), plus the iOS `apple-touch-icon` (180x180); the generator is a script in `tools/`.
- [ ] The service worker caches the app shell (page, JS, wasm, pck, fonts) so the installed app opens fast and shows a clear "sem conexão" message instead of a blank page when offline; match traffic is never cached.
- [ ] A new deploy replaces the cached build: the app picks the new version on the next open (or shows "Nova versão: atualizar"), never serving a mix of old and new files.
- [ ] iOS support: the page has the `apple-mobile-web-app-*` meta tags and a status bar style; the lobby explains "Compartilhar → Adicionar à Tela de Início" on iPhone, since Safari has no install prompt.
- [ ] On Android/Chrome the install is offered (a small "Instalar o jogo" button appears when the browser fires the install event) and works.
- [ ] Installability check passes in Lighthouse or Chrome DevTools (manifest valid, service worker registered, served over HTTPS or localhost); the report is kept.
- [ ] A retained screenshot of the install button, and one of the installed app (standalone window) in device emulation.

---

## Implementation Notes

Installing requires HTTPS (localhost counts for testing). Keep the install button and the iOS hint in the HTML shell (story 014's `web/shell.html`) or the lobby, behind `OS.has_feature("web")`. Version the cache with the build id so updates are reliable.

---

## Out of Scope

- 013: the plain Web export. 014: touch and layout. 017: the public URL and TLS. Push notifications, background sync.

---

## Files

export_presets.cfg
web/shell.html
web/offline.html
web/icons/icon-144.png
web/icons/icon-192.png
web/icons/icon-512.png
web/icons/icon-maskable-512.png
web/icons/apple-touch-icon-180.png
tools/make-icons.ps1
tools/build-web.ps1
src/client/lobby_screen.gd
src/client/web_viewport.gd
src/client/ui_text.gd

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: the kept Lighthouse/DevTools installability report plus the two screenshots, in `production/qa/evidence/story-015-installable-pwa/`; tests waived at `qa.level: minimal`
**Status**: [x] Created — production/qa/evidence/story-015-installable-pwa/

---

## Dependencies

- Depends on: `production/epics/online-mobile/story-013-web-client.md`
- Unlocks: `production/epics/online-mobile/story-017-hosting-and-publish.md`

---

## Completion Notes
**Completed**: 2026-11-04
**Criteria**: 8/8 passing (criterion 6 confirmed by the user, backed by a real headed-Chrome install and OS capture of the installed window)
**Deviations**: Advisory — HTTPS, install on a real Android/iPhone and iOS Safari behaviour unverified (story 017); install button and iPhone hint captured with a real/simulated event in emulation; Lighthouse 12+ has no PWA category, so Chrome's `Page.getInstallabilityErrors` (`[]`) is the kept report. Bug found and fixed during real install: `<html lang>` was `en` (Chrome offered Translate), now `pt-BR`.
**Test Evidence**: `production/qa/evidence/story-015-installable-pwa/` (see its README.md); unit tests waived at qa.level minimal
**Reviewed by**: self, no independent review
