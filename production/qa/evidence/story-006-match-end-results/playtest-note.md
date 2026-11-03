# Playtest note: full matches, lobby to result (story 006)

**Date**: 2026-11-03 · **Build**: working tree on `main`, Godot 4.7.2 · **Type**: automated, not a human playtest

## What was played

16 whole matches (3, 4, 5 and 6 players, seeds 1 to 4 each) played through
`RoomRegistry` by random bots (`tests/helpers/bot_match.gd`): create room, join by
code, start, then every turn until one player remained. Bots see only their own
per-player view and send the same intents a client sends (actions, pass,
challenge, block, lose influence, exchange). After every step the helper checks
that the 54 coins and the 15 cards are conserved.
Retained as `tests/integration/server/full_match_test.gd` (3 tests).

## Result

All 16 matches finished with no failure: one living winner, `player_count - 1`
eliminations, standings with one row per player and the winner first.

| Players | Steps (min-max) | Challenges | Blocks | Exchanges |
|---|---|---|---|---|
| 3 | 30-56 | 15 | 7 | 10 |
| 4 | 34-61 | 23 | 13 | 7 |
| 5 | 53-97 | 28 | 18 | 6 |
| 6 | 66-128 | 38 | 23 | 10 |

Totals across the 16 matches (every MVP rule exercised):

- 104 challenges (74 caught a bluff, 30 lost and swapped the shown card)
- 61 blocks (19 bluffed blocks that failed)
- 33 Embaixador exchanges, 25 Extorquir steals
- 92 failed actions, 7 actions dropped because the target was already exiled
- 120 influences lost, 56 players exiled, 16 game-over events

## Also checked live (two real clients against `scenes/server.tscn`)

Two `ClientMain` instances created and joined a room, played to the end
(Renda until 7 coins, then Golpe de Estado), both showed the result screen with
"Fim de jogo: Ana venceu!" and the final cards, and both returned to the same
room through "Voltar ao lobby" (host sees the Start button again).

## Not covered

No human played these matches, so pacing and feel are untested. Browser (Web
export) play is not covered yet.
