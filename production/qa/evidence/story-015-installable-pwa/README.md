# Story 015 evidence (2026-11-04)

Tested against `build/web/` served by `python -m http.server` on 127.0.0.1:8000, in a real headless Chrome (fresh profile, mobile emulation 390x844 @2x) driven over CDP. The in-app browser pane cannot register any service worker, so it was not used.

- `tab-report.json`: Chrome's own `Page.getInstallabilityErrors` = `[]` (the DevTools "Installability" check), service worker `activated` with scope `/`, the full shell in the versioned cache (html, js, wasm, pck, fonts-in-pck, offline page, icons, manifest), `beforeinstallprompt` observed (`canInstall: true` before any synthetic event), offline reload still opens the cached app (`offlineCanvas: true`). This JSON is the kept installability report; Lighthouse 12+ no longer ships a PWA category.
- `tab-install-button-SIMULATED-EVENT.png`: lobby with "Instalar o jogo". Chrome fired the real `beforeinstallprompt` before the screenshot; a synthetic event was also dispatched to be sure. Clicking the prompt was not possible headless.
- `app-online-lobby.png` + `app-report.json`: Chrome `--app=` window (standalone display-mode): `coupIsStandalone() = true`, install button hidden. This is the closest to an installed window; a real "Install" through Chrome's UI was not performed.
- `tab-offline-cached-shell.png`, `tab-offline-uncached-navigation.png`: offline, the cached app opens; an uncached navigation shows the Portuguese "Sem conexão" page (needed a build-script patch, now in `tools/build-web.ps1`).
- `update-button-visible.png`, `update-ios-report.json`: simulated new deploy (cache id bumped in the served worker, then restored): old build kept while the new waits, "Nova versão: atualizar" appears, applying it deletes the old cache and keeps the page controlled. `ios-install-hint.png`: with an iPhone user agent the lobby shows "Para instalar: Compartilhar → Adicionar à Tela de Início". (The extra update/install buttons in that shot come from the simulated deploy still being active in that profile.)

## Real install (2026-11-04, rebuilt after `<html lang>` fix)

- Real, headed Chrome, fresh profile. `window.coupInstall()` (what the "Instalar o jogo" button calls) was run with a user gesture; Chrome showed its own "Instale o app / Coup Online" dialog; the "Instalar" button of that dialog was invoked through Windows UI Automation; Chrome opened a standalone "Coup Online" app window.
- `installed-app-window-OS-capture.png`: OS screen capture of that installed window (app title bar with icon, no address bar, install button hidden).
- `installed-app-REAL-INSTALL.png` + `installed-app-report.json`: page inside the installed window: `display-mode: standalone` true, `coupIsStandalone` true, `canInstall` false, service worker controlling the page after a reload.
- Defect found by the first real install and fixed: `web/shell.html` had `<html lang="en">`, so Chrome offered "Translate" over the Portuguese game. Now `lang="pt-BR"`; the rebuilt install shows no translate bubble. All headless checks above were re-run on the rebuilt build and still pass.
- `app-online-lobby.png` (`--app=` window) is superseded by the real install.

Not verified: install on a real Android/iPhone, HTTPS (localhost only), iOS Safari behaviour (story 017).
