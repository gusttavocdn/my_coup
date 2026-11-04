# Epic: online-mobile

> **Layer**: Platform / Release (`minimal` tier, built from the brief and the user's request of 2026-11-03)
> **Source**: `design/game-brief.md` (pitch: "amigos ... à distância") and the user's request: play over the internet and install the game on the phone
> **Status**: Ready

## Goal
Take Coup Online from "runs on my machine" to a game friends play over the internet from their phones: a Web build that installs as a PWA on Android and iPhone, a match server safe to expose, and a first real-device test.

## Decisions (2026-11-03, user)
- Install route: **PWA** (install from the browser, no store). Android APK and iOS native are not part of this epic.
- Hosting: **not decided**. Story 017 researches and proposes it; the user approves before anything is deployed.

## Scope
Web export, touch and phone usability, installable PWA, an internet-ready server (limits, configuration, deployment recipe), hosting and publishing, and basic reconnection so a sleeping phone or a network switch does not end the match.

## Out of scope
- Native Android (.apk) and iOS apps, store listings.
- Accounts, ranking, matchmaking, public room lists.
- Advanced reconnection (spectating, rejoining from another device, persistence across server restarts); the brief leaves it out.
- Push notifications.
- Bots, solo mode, the Inquisidor variant (still out of scope in the brief).

## Build order
1. 013 Web build (everything else runs on it)
2. 014 phone usability, 015 PWA (client side)
3. 016 internet-ready server
4. 018 basic reconnection
5. 017 hosting, publishing and a real-phone test (last: it needs all of the above)

## Risks
- Godot 4.7 Web and PWA export details postdate the model's knowledge: every story checks `docs/engine-reference/godot/` first.
- iOS PWAs are the strictest (storage limits, no install prompt, background suspension): test on a real iPhone.
- HTTPS and `wss://` are mandatory for an installable PWA and for a secure page to reach the server.

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 013 | Cliente web: exportar o jogo para o navegador | Integration | Ready | N/A |
| 014 | Uso no celular: toque, teclado, tela cheia e orientação | UI | Ready | N/A |
| 015 | PWA instalável (manifesto, ícones, service worker, iOS) | Integration | Ready | N/A |
| 016 | Servidor pronto para a internet: limites, configuração e implantação | Integration | Ready | N/A |
| 017 | Hospedagem e publicação: proposta, deploy e teste em celular real | Integration | Ready | N/A |
| 018 | Reconexão básica e espera por jogador | Integration | Ready | N/A |
