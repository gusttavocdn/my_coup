# Epic: coup-online

> **Layer**: MVP (single epic — `minimal` tier, built from the brief)
> **Source**: `design/game-brief.md`
> **Status**: Ready

## Goal
Coup online em tempo real onde amigos blefam, contestam e eliminam uns aos outros em salas de 2 a 6 jogadores.

## Scope
MVP list from the brief (6 items): rules engine, match server, turn flow with challenge/block chain, game table, Ambassador exchange, end of match.

## Build order
1. Rules engine (stories 001-003, no network)
2. Match server with hidden state (004)
3. Game table client (005)
4. End of match (006)

## Rules reference
Manual: `C:\repos\coup_digital\Docs\coup_manual_table_games.pdf`. Base deck is 15 cards, 3 per character (manual example: 3 players leave 9 in the Court deck). The Inquisitor variant and 7+ players are out of scope.

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Motor de regras: ações e influência | Logic | Ready | N/A |
| 002 | Cadeia de contestação e bloqueio | Logic | Ready | N/A |
| 003 | Troca do Embaixador e reembaralho | Logic | Ready | N/A |
| 004 | Servidor de partida: salas e estado oculto | Integration | Ready | N/A |
| 005 | Mesa de jogo (cliente) | UI | Ready | N/A |
| 006 | Fim de partida: eliminação, vencedor, resultado | UI | Ready | N/A |
