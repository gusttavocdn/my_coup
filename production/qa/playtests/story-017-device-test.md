# Story 017 Device Test (two phones)

**Status: NOT RUN.** This is the template for the real-device test the story requires.
Fill it in after the first publish (`tools/publish.sh`); until then criterion 6 of
`production/epics/online-mobile/story-017-hosting-and-publish.md` is open.

**Date:**
**URL tested:** https://
**Build / release id** (last line of `tools/publish.sh` output):
**Smoke check result before the test** (`tools/smoke-check.sh`): PASS / FAIL

## Devices

| | Device model | OS / version | Browser | Network |
|---|---|---|---|---|
| Phone 1 (Android) | | | Chrome | Wi-Fi / mobile data |
| Phone 2 (iPhone, if available) | | | Safari | Wi-Fi / mobile data |

At least one phone must be on mobile data (not the same Wi-Fi as the other).

## Steps and result

| # | Step | Result (ok / problem) | Notes |
|---|---|---|---|
| 1 | Open the URL on each phone; the lobby loads | | |
| 2 | Android: install with "Instalar o jogo" or the Chrome menu; open from the home screen | | |
| 3 | iPhone: Compartilhar → Adicionar à Tela de Início; open from the home screen | | |
| 4 | Phone 1 creates a room; the 4-letter code appears and can be copied | | |
| 5 | Phone 2 joins with the code | | |
| 6 | Start the match; play until the result screen (include a challenge or block if possible) | | |
| 7 | Keyboard does not cover the name / code fields; no controls under the notch or home bar | | |
| 8 | Turn the screen off for ~10 s during a match and come back (reconnection is story 018: note what happens) | | |

## Problems found

(One line each: device, what happened, how often.)

## Verdict

PASS / PASS WITH NOTES / FAIL
