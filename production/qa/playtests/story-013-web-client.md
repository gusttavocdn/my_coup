# Story 013 Web Client Playtest

**Date:** 2026-11-04  
**Build:** Godot 4.7.2 Web export from `tools/build-web.ps1`  
**Static host:** `http://127.0.0.1:8000/`  
**Match server:** `ws://127.0.0.1:9081` (`--bind=127.0.0.1`)  
**Clients:** Two in-app browser tabs

## Steps and result

1. Opened the static web export in two tabs. The lobby, fonts, and card art loaded in both; the console showed only the normal Godot engine, renderer, and single-threaded build startup messages.
2. Confirmed the default server field was `ws://127.0.0.1:9080` and the `?server=ws://127.0.0.1:9081` URL override appeared in the second tab.
3. Entered the names Alice and Maria, created room `WXNF` from Alice's tab, and joined from Maria's tab.
4. Started a match and observed both clients update through turn actions, a challenge, a card loss, and a coup.
5. The result screen named Maria the winner. Returned Maria's tab to the lobby; both clients showed the same room and players.

## Limits observed

- Name and room-code fields accepted keyboard typing.
- Clipboard paste and the browser clipboard's copied room-code value were not verified.
- Mobile viewport behavior and resize response were not verified.
- The in-app browser showed the result screen during the run, but its screenshot could not be retained as a local evidence image.
