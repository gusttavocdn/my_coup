# Story 014 evidence

- `390x844-*`, `360x740-*`, `844x390-*` (png): native preview-harness captures of lobby, turn, target, challenge, loss, result (current source).
- `web-390x844-lobby.jpg`, `web-844x390-lobby.jpg`: browser emulation of the current Web build; the lobby shows the "Entrar em tela cheia" button.
- `web-390x844-lobby-keyboard-SIMULATED.jpg`: emulation cannot open a real keyboard, so `window.coupInsets()` was overridden to report a 330 px keyboard and the room-code field focused. The scroll area shrank to 844-330 px and the focused field stays above it. A real-phone check is still story 017.
- 2026-11-04: an earlier web capture came from a cached old `index.pck` and was replaced; use `?v=<n>` or cache:'reload' when re-testing.
- Hover audit (criterion 2): `UiKit.build_theme` gives Button `pressed` a gold fill + gold border (stronger than `hover`); action bar ring and table corner buttons also react to `pressed`; no tooltips or hover-only controls found.
