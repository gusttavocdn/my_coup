# Epic: interface-visual

> **Layer**: Presentation (`minimal` tier, built from the design canvas and the brief)
> **Source**: design canvas "Cartas e moedas — conjunto original" (https://claude.ai/artifact/EoVp7sMqQucT3Y2CcEkYna) and `design/game-brief.md`
> **Status**: Ready

## Goal
Replace the functional test UI of epic `coup-online` with the designed look: Renaissance-intrigue card set, immersive table scene with a minimal HUD, thumb-zone controls on phones, and the same identity on desktop.

## Decisions (2026-11-03, user)
- Card art: the canvas set (faceted vector portraits), not `assets/arte`.
- Response countdown: implemented for real, with a server-side deadline.
- Fonts: Cinzel and Source Sans 3 (OFL), downloaded into `assets/fonts/`.

## Scope
Visual foundation, new table (desktop and phone), target selection, response deadline (server) and reaction screen, influence loss, Embaixador exchange, lobby and result screens in the new style.

## Out of scope
- Inquisidor and "Investigar" (the canvas draws them; the brief leaves the variant out). The Inquisidor art may be kept in `assets/` unused.
- Animation beyond tilt, raise and glow; sound.
- Account avatars or custom uploads: 6 avatars derived from the canvas' three.

## Build order
1. 007 visual foundation (everything else reuses it)
2. 008 new table, 009 target selection
3. 010 response deadline (server), 011 reaction screen
4. 012 influence loss, exchange, lobby, result

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 007 | Fundação visual: fontes, tema, carta, verso, moeda, avatar e cenário | UI | Complete | N/A |
| 008 | Mesa nova (computador e celular) | UI | Ready | N/A |
| 009 | Escolher alvo | UI | Ready | N/A |
| 010 | Prazo de resposta no servidor | Integration | Ready | N/A |
| 011 | Tela de reação | UI | Ready | N/A |
| 012 | Perder influência, troca, lobby e resultado no novo estilo | UI | Ready | N/A |
